import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
  Optional,
  OnModuleInit,
  OnModuleDestroy,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual, In, DataSource } from 'typeorm';
import {
  PaymentReconciliationEntity,
  ReconciliationMismatchCategory,
  ReconciliationStatus,
} from '../../database/entities/payment-reconciliation.entity';
import {
  PaymentEntity,
  PaymentStatus,
  assertValidPaymentStateTransition,
  isValidPaymentStateTransition,
  toMinorUnits,
} from '../../database/entities/payment.entity';
import { BookingEntity, BookingStatus, VALID_BOOKING_TRANSITIONS } from '../../database/entities/booking.entity';
import { WebhookEventEntity } from '../../database/entities/webhook-event.entity';
import { PaymentRecoveryEntity, RecoveryStatus } from '../../database/entities/payment-recovery.entity';
import { IdempotencyRecordEntity } from '../../database/entities/idempotency-record.entity';
import { PaymentConfigService, PaymentMode } from './payment-config.service';
import { SimulatedPaymentAdapter } from './providers/simulated-payment.adapter';
import { RazorpayAdapter } from './providers/razorpay.adapter';
import { IPaymentProvider, ProviderPaymentDetails } from './interfaces/payment-provider.interface';
import { PaymentRecoveryService } from './payment-recovery.service';
import { IdempotencyService } from '../bookings/idempotency.service';

export interface ReconcilePaymentOptions {
  force?: boolean;
  actor?: string;
  notes?: string;
  idempotencyKey?: string;
}

export interface ManualResolveOptions {
  action: string;
  notes: string;
  actor?: string;
  targetPaymentStatus?: PaymentStatus;
  targetBookingStatus?: BookingStatus;
}

export interface ReconciliationQueryFilter {
  status?: ReconciliationStatus;
  mismatchCategory?: ReconciliationMismatchCategory;
  paymentId?: string;
  bookingId?: string;
  requiresManualIntervention?: boolean;
  limit?: number;
  offset?: number;
}

@Injectable()
export class PaymentReconciliationService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PaymentReconciliationService.name);
  private readonly inFlightReconciliations = new Set<string>();
  private schedulerTimer: NodeJS.Timeout | null = null;
  private isBatchRunning = false;

  constructor(
    @InjectRepository(PaymentReconciliationEntity)
    private readonly reconRepo: Repository<PaymentReconciliationEntity>,
    @InjectRepository(PaymentEntity)
    private readonly paymentRepo: Repository<PaymentEntity>,
    @InjectRepository(BookingEntity)
    private readonly bookingRepo: Repository<BookingEntity>,
    @InjectRepository(WebhookEventEntity)
    private readonly webhookRepo: Repository<WebhookEventEntity>,
    @InjectRepository(PaymentRecoveryEntity)
    private readonly recoveryRepo: Repository<PaymentRecoveryEntity>,
    @InjectRepository(IdempotencyRecordEntity)
    private readonly idempotencyRepo: Repository<IdempotencyRecordEntity>,
    @Optional()
    private readonly dataSource?: DataSource,
    @Optional()
    private readonly paymentConfigService?: PaymentConfigService,
    @Optional()
    private readonly simulatedAdapter?: SimulatedPaymentAdapter,
    @Optional()
    private readonly razorpayAdapter?: RazorpayAdapter,
    @Optional()
    private readonly recoveryService?: PaymentRecoveryService,
    @Optional()
    private readonly idempotencyService?: IdempotencyService,
  ) {}

  onModuleInit() {
    if (process.env.ENABLE_RECONCILIATION_SCHEDULER === 'true') {
      const intervalMs = parseInt(process.env.RECONCILIATION_INTERVAL_MS || '60000', 10);
      this.logger.log(`[ReconciliationScheduler] Initialized background scheduler with interval: ${intervalMs}ms`);
      this.schedulerTimer = setInterval(async () => {
        try {
          await this.runScheduledSweep();
        } catch (err) {
          this.logger.error(`[ReconciliationScheduler] Background sweep encountered error: ${err}`);
        }
      }, intervalMs);
    }
  }

  onModuleDestroy() {
    if (this.schedulerTimer) {
      clearInterval(this.schedulerTimer);
      this.schedulerTimer = null;
      this.logger.log('[ReconciliationScheduler] Background scheduler stopped');
    }
  }

  private getActiveProvider(providerName?: string): IPaymentProvider {
    const config = this.paymentConfigService ?? new PaymentConfigService(process.env);
    const mode = config.evaluate().summary.paymentMode;

    if (providerName === 'razorpay' || mode === PaymentMode.RAZORPAY) {
      if (this.razorpayAdapter) return this.razorpayAdapter;
      return new RazorpayAdapter(config);
    }
    return this.simulatedAdapter ?? new SimulatedPaymentAdapter();
  }

  /**
   * Sanitizes resolution reason strings and notes by redacting credentials and tokens.
   */
  sanitizeText(text?: string | any): string {
    if (!text) return '';
    let str = typeof text === 'string' ? text : text.message || JSON.stringify(text);
    str = str
      .replace(/rzp_(?:live|test)_[a-zA-Z0-9]+/gi, '[REDACTED_RZP_KEY]')
      .replace(/(?:key_secret|secret|password|token|bearer)\s*[:=]\s*["']?[^\s,"']+/gi, '$1=[REDACTED]')
      .replace(/eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+/g, '[REDACTED_JWT]')
      .replace(/postgres(?:ql)?:\/\/[^\s]+/gi, '[REDACTED_DB_URL]');

    if (str.includes('\n    at ')) {
      str = str.split('\n    at ')[0].trim();
    }
    return str.substring(0, 500);
  }

  /**
   * Generates a deterministic reconciliation record ID.
   */
  private generateReconId(paymentId: string): string {
    return `recon_${Date.now()}_${paymentId.replace(/[^a-zA-Z0-9]/g, '_').substring(0, 20)}`;
  }

  /**
   * Core Reconcile Method for a single canonical payment ID.
   * Employs fast-path in-memory lock and database-level transactional consistency.
   */
  async reconcilePayment(
    paymentId: string,
    options: ReconcilePaymentOptions = {},
  ): Promise<PaymentReconciliationEntity> {
    if (!paymentId || typeof paymentId !== 'string') {
      throw new BadRequestException('Invalid paymentId for reconciliation');
    }

    const lockKey = paymentId.trim();
    if (this.inFlightReconciliations.has(lockKey) && !options.force) {
      this.logger.warn(`[Reconciliation] Reconcile already in flight for payment: ${paymentId}`);
      const existing = await this.reconRepo.findOne({
        where: { paymentId },
        order: { createdAt: 'DESC' },
      });
      if (existing) return existing;
    }

    this.inFlightReconciliations.add(lockKey);

    try {
      if (this.dataSource && typeof this.dataSource.transaction === 'function') {
        return await this.dataSource.transaction(async (manager) => {
          return await this.executeReconcileWithManager(lockKey, options, manager);
        });
      }
      return await this.executeReconcileWithManager(lockKey, options, null);
    } finally {
      this.inFlightReconciliations.delete(lockKey);
    }
  }

  private async executeReconcileWithManager(
    paymentId: string,
    options: ReconcilePaymentOptions,
    manager: any,
  ): Promise<PaymentReconciliationEntity> {
    // 1. Fetch Payment with pessimistic write lock if in transaction
    let payment: PaymentEntity | null = null;
    if (manager) {
      try {
        payment = await manager.findOne(PaymentEntity, {
          where: { id: paymentId },
          lock: { mode: 'pessimistic_write' },
        });
      } catch {
        payment = await manager.findOne(PaymentEntity, { where: { id: paymentId } });
      }
    } else {
      payment = await this.paymentRepo.findOne({ where: { id: paymentId } });
    }

    // Handle missing canonical payment
    if (!payment) {
      const reconId = this.generateReconId(paymentId);
      const record = (manager ? manager.create(PaymentReconciliationEntity, { id: reconId }) : this.reconRepo.create({ id: reconId }));
      record.paymentId = paymentId;
      record.canonicalPaymentStatus = PaymentStatus.FAILED;
      record.canonicalAmount = 0;
      record.canonicalAmountInMinorUnits = 0;
      record.canonicalCurrency = 'INR';
      record.provider = 'simulated';
      record.mismatchCategory = ReconciliationMismatchCategory.MISSING_CANONICAL_PAYMENT;
      record.status = ReconciliationStatus.FAILED;
      record.attemptCount = 1;
      record.lastAttemptedAt = new Date();
      record.requiresManualIntervention = true;
      record.sanitizedResolutionReason = this.sanitizeText(`Payment record ${paymentId} not found in database`);

      return manager ? await manager.save(record) : await this.reconRepo.save(record);
    }

    const canonicalMinorUnits = toMinorUnits(payment.amount);
    const canonicalCurrency = (payment.currency || 'INR').trim().toUpperCase();
    const providerAdapter = this.getActiveProvider(payment.provider);

    // Retrieve or create reconciliation record
    let reconRecord: PaymentReconciliationEntity | null = null;
    if (manager) {
      reconRecord = await manager.findOne(PaymentReconciliationEntity, {
        where: { paymentId: payment.id },
        order: { createdAt: 'DESC' },
      });
    } else {
      reconRecord = await this.reconRepo.findOne({
        where: { paymentId: payment.id },
        order: { createdAt: 'DESC' },
      });
    }

    if (!reconRecord) {
      reconRecord = (manager ? manager.create(PaymentReconciliationEntity, { id: this.generateReconId(payment.id) }) : this.reconRepo.create({ id: this.generateReconId(payment.id) }));
      reconRecord.paymentId = payment.id;
      reconRecord.bookingId = payment.bookingId;
      reconRecord.quoteId = payment.quoteId;
      reconRecord.provider = payment.provider || 'simulated';
      reconRecord.providerPaymentId = payment.providerPaymentId;
      reconRecord.providerOrderId = payment.providerOrderId;
      reconRecord.canonicalPaymentStatus = payment.status;
      reconRecord.canonicalAmount = payment.amount;
      reconRecord.canonicalAmountInMinorUnits = canonicalMinorUnits;
      reconRecord.canonicalCurrency = canonicalCurrency;
      reconRecord.mismatchCategory = ReconciliationMismatchCategory.NO_MISMATCH;
      reconRecord.status = ReconciliationStatus.IN_PROGRESS;
      reconRecord.attemptCount = 0;
      reconRecord.requiresManualIntervention = false;
    }

    reconRecord.status = ReconciliationStatus.IN_PROGRESS;
    reconRecord.requiresManualIntervention = false;
    reconRecord.canonicalPaymentStatus = payment.status;
    reconRecord.canonicalAmount = payment.amount;
    reconRecord.canonicalAmountInMinorUnits = canonicalMinorUnits;
    reconRecord.canonicalCurrency = canonicalCurrency;
    reconRecord.providerOrderId = payment.providerOrderId;
    reconRecord.providerPaymentId = payment.providerPaymentId;
    reconRecord.attemptCount = (reconRecord.attemptCount || 0) + 1;
    reconRecord.lastAttemptedAt = new Date();

    const saveRecon = async (rec: PaymentReconciliationEntity) => {
      return manager ? await manager.save(rec) : await this.reconRepo.save(rec);
    };

    // 1. Check duplicate provider reference across payments
    if (payment.providerPaymentId) {
      const duplicatePayments = manager
        ? await manager.find(PaymentEntity, { where: { providerPaymentId: payment.providerPaymentId } })
        : await this.paymentRepo.find({ where: { providerPaymentId: payment.providerPaymentId } });

      if (duplicatePayments.length > 1) {
        reconRecord.mismatchCategory = ReconciliationMismatchCategory.DUPLICATE_PROVIDER_REFERENCE;
        reconRecord.status = ReconciliationStatus.REQUIRED;
        reconRecord.requiresManualIntervention = true;
        reconRecord.sanitizedResolutionReason = this.sanitizeText(
          `Duplicate providerPaymentId ${payment.providerPaymentId} shared across ${duplicatePayments.length} payments`,
        );
        return await saveRecon(reconRecord);
      }
    }

    // 2. Fetch associated booking
    let booking: BookingEntity | null = null;
    if (payment.bookingId) {
      booking = manager
        ? await manager.findOne(BookingEntity, { where: { id: payment.bookingId } })
        : await this.bookingRepo.findOne({ where: { id: payment.bookingId } });

      if (!booking) {
        reconRecord.mismatchCategory = ReconciliationMismatchCategory.MISSING_BOOKING;
        reconRecord.status = ReconciliationStatus.REQUIRED;
        reconRecord.requiresManualIntervention = true;
        reconRecord.sanitizedResolutionReason = this.sanitizeText(
          `Associated booking ${payment.bookingId} not found in database`,
        );
        return await saveRecon(reconRecord);
      }
    }

    // 3. Query Provider state safely
    let providerDetails: ProviderPaymentDetails | null = null;
    const lookupId = payment.providerPaymentId || payment.providerOrderId || payment.id;

    try {
      if (typeof providerAdapter.fetchPaymentDetails === 'function') {
        providerDetails = await providerAdapter.fetchPaymentDetails(lookupId, {
          orderId: payment.providerOrderId,
          expectedAmountMinorUnits: canonicalMinorUnits,
          expectedCurrency: canonicalCurrency,
        });
      }
    } catch (err: any) {
      const msg = (err?.message || '').toLowerCase();
      const statusVal = (typeof err?.getStatus === 'function' ? err.getStatus() : err?.status || '').toString();

      if (msg.includes('timeout') || msg.includes('etimedout') || statusVal === '504') {
        reconRecord.mismatchCategory = ReconciliationMismatchCategory.PROVIDER_TIMEOUT;
        reconRecord.status = ReconciliationStatus.REQUIRED;
        reconRecord.nextRetryAt = this.calculateNextRetry(reconRecord.attemptCount);
        reconRecord.sanitizedResolutionReason = this.sanitizeText(err);
        return await saveRecon(reconRecord);
      }

      if (
        msg.includes('unavailable') ||
        msg.includes('econnrefused') ||
        msg.includes('enotfound') ||
        statusVal === '503'
      ) {
        reconRecord.mismatchCategory = ReconciliationMismatchCategory.PROVIDER_UNAVAILABLE;
        reconRecord.status = ReconciliationStatus.REQUIRED;
        reconRecord.nextRetryAt = this.calculateNextRetry(reconRecord.attemptCount);
        reconRecord.sanitizedResolutionReason = this.sanitizeText(err);
        return await saveRecon(reconRecord);
      }

      if (msg.includes('not found') || statusVal === '404') {
        reconRecord.mismatchCategory = ReconciliationMismatchCategory.MISSING_PROVIDER_PAYMENT;
        reconRecord.status = ReconciliationStatus.REQUIRED;
        reconRecord.requiresManualIntervention = true;
        reconRecord.sanitizedResolutionReason = this.sanitizeText(
          `Provider reported payment ${lookupId} not found`,
        );
        return await saveRecon(reconRecord);
      }

      reconRecord.mismatchCategory = ReconciliationMismatchCategory.INVALID_PROVIDER_RESPONSE;
      reconRecord.status = ReconciliationStatus.REQUIRED;
      reconRecord.requiresManualIntervention = true;
      reconRecord.sanitizedResolutionReason = this.sanitizeText(err);
      return await saveRecon(reconRecord);
    }

    if (!providerDetails) {
      reconRecord.mismatchCategory = ReconciliationMismatchCategory.MISSING_PROVIDER_PAYMENT;
      reconRecord.status = ReconciliationStatus.REQUIRED;
      reconRecord.requiresManualIntervention = true;
      reconRecord.sanitizedResolutionReason = this.sanitizeText('Provider returned empty payment details');
      return await saveRecon(reconRecord);
    }

    // Validate provider response format
    if (
      typeof providerDetails.status !== 'string' ||
      typeof providerDetails.amountInMinorUnits !== 'number' ||
      isNaN(providerDetails.amountInMinorUnits) ||
      !providerDetails.currency
    ) {
      reconRecord.mismatchCategory = ReconciliationMismatchCategory.INVALID_PROVIDER_RESPONSE;
      reconRecord.status = ReconciliationStatus.REQUIRED;
      reconRecord.requiresManualIntervention = true;
      reconRecord.sanitizedResolutionReason = this.sanitizeText('Malformed provider response format');
      return await saveRecon(reconRecord);
    }

    const observedMinorUnits = Math.round(providerDetails.amountInMinorUnits);
    const observedCurrency = providerDetails.currency.trim().toUpperCase();
    const observedStatus = providerDetails.status.toLowerCase();

    reconRecord.observedAmountInMinorUnits = observedMinorUnits;
    reconRecord.observedCurrency = observedCurrency;
    reconRecord.observedProviderStatus = observedStatus;

    // 4. Validate Provider Order ID match
    if (
      payment.providerOrderId &&
      providerDetails.orderId &&
      payment.providerOrderId !== providerDetails.orderId
    ) {
      reconRecord.mismatchCategory = ReconciliationMismatchCategory.PROVIDER_ORDER_MISMATCH;
      reconRecord.status = ReconciliationStatus.REQUIRED;
      reconRecord.requiresManualIntervention = true;
      reconRecord.sanitizedResolutionReason = this.sanitizeText(
        `Provider order mismatch: canonical=${payment.providerOrderId}, provider=${providerDetails.orderId}`,
      );
      return await saveRecon(reconRecord);
    }

    // 5. Exact Amount Matching (Minor Units)
    if (canonicalMinorUnits !== observedMinorUnits) {
      reconRecord.mismatchCategory = ReconciliationMismatchCategory.AMOUNT_MISMATCH;
      reconRecord.status = ReconciliationStatus.REQUIRED;
      reconRecord.requiresManualIntervention = true;
      reconRecord.sanitizedResolutionReason = this.sanitizeText(
        `Amount mismatch: canonical=${canonicalMinorUnits} paise, observed=${observedMinorUnits} paise`,
      );
      return await saveRecon(reconRecord);
    }

    // 6. Currency Matching
    if (canonicalCurrency !== observedCurrency) {
      reconRecord.mismatchCategory = ReconciliationMismatchCategory.CURRENCY_MISMATCH;
      reconRecord.status = ReconciliationStatus.REQUIRED;
      reconRecord.requiresManualIntervention = true;
      reconRecord.sanitizedResolutionReason = this.sanitizeText(
        `Currency mismatch: canonical=${canonicalCurrency}, observed=${observedCurrency}`,
      );
      return await saveRecon(reconRecord);
    }

    // 7. Check Webhook Gap
    let hasProcessedWebhook = false;
    if (payment.providerPaymentId || payment.providerOrderId) {
      const webhook = manager
        ? await manager.findOne(WebhookEventEntity, {
            where: [
              ...(payment.providerPaymentId ? [{ providerPaymentId: payment.providerPaymentId }] : []),
              ...(payment.providerOrderId ? [{ providerOrderId: payment.providerOrderId }] : []),
              ...(payment.providerPaymentId ? [{ paymentId: payment.providerPaymentId }] : []),
            ],
          })
        : await this.webhookRepo.findOne({
            where: [
              ...(payment.providerPaymentId ? [{ providerPaymentId: payment.providerPaymentId }] : []),
              ...(payment.providerOrderId ? [{ providerOrderId: payment.providerOrderId }] : []),
              ...(payment.providerPaymentId ? [{ paymentId: payment.providerPaymentId }] : []),
            ],
          });

      if (webhook && (webhook.status === 'PROCESSED' || Boolean(webhook.processedAt))) {
        hasProcessedWebhook = true;
      }
    }

    const isProviderCaptured = observedStatus === 'captured' || observedStatus === 'paid';
    const isProviderRefunded = observedStatus === 'refunded';
    const isProviderFailed = observedStatus === 'failed';

    // 8. Handle Refund Mismatch
    if (isProviderRefunded && payment.status !== PaymentStatus.REFUNDED) {
      if (isValidPaymentStateTransition(payment.status, PaymentStatus.REFUNDED)) {
        payment.status = PaymentStatus.REFUNDED;
        if (manager) await manager.save(payment);
        else await this.paymentRepo.save(payment);

        if (booking && isValidBookingTransition(booking.status, BookingStatus.REFUNDED)) {
          booking.status = BookingStatus.REFUNDED;
          if (manager) await manager.save(booking);
          else await this.bookingRepo.save(booking);
        }

        await this.resolveAssociatedRecovery(payment.id, 'Resolved refund via reconciliation engine', manager);

        reconRecord.mismatchCategory = ReconciliationMismatchCategory.REFUND_STATE_MISMATCH;
        reconRecord.status = ReconciliationStatus.RESOLVED;
        reconRecord.resolutionAction = 'CONFIRMED_REFUND';
        reconRecord.resolvedAt = new Date();
        reconRecord.sanitizedResolutionReason = this.sanitizeText('Provider refund applied to canonical ledger');
        return await saveRecon(reconRecord);
      } else {
        reconRecord.mismatchCategory = ReconciliationMismatchCategory.REFUND_STATE_MISMATCH;
        reconRecord.status = ReconciliationStatus.REQUIRED;
        reconRecord.requiresManualIntervention = true;
        reconRecord.sanitizedResolutionReason = this.sanitizeText(
          `Cannot transition payment from ${payment.status} to REFUNDED`,
        );
        return await saveRecon(reconRecord);
      }
    }

    // 9. Payment State Mismatch Protection & Canonical Transition
    if (payment.status === PaymentStatus.CAPTURED && isProviderFailed) {
      // NON-NEGOTIABLE INVARIANT: Never overwrite CAPTURED -> FAILED directly
      reconRecord.mismatchCategory = ReconciliationMismatchCategory.PAYMENT_STATE_MISMATCH;
      reconRecord.status = ReconciliationStatus.REQUIRED;
      reconRecord.requiresManualIntervention = true;
      reconRecord.resolutionAction = 'NO_OP_PROTECT_CANONICAL';
      reconRecord.sanitizedResolutionReason = this.sanitizeText(
        'Canonical state is CAPTURED but provider reports failed. Kept canonical to prevent illegal regression.',
      );
      return await saveRecon(reconRecord);
    }

    if (
      (payment.status === PaymentStatus.PENDING ||
        payment.status === PaymentStatus.AUTHORIZED ||
        payment.status === PaymentStatus.CREATED) &&
      isProviderCaptured
    ) {
      // Legally transition PENDING/AUTHORIZED -> CAPTURED
      if (isValidPaymentStateTransition(payment.status, PaymentStatus.CAPTURED)) {
        payment.status = PaymentStatus.CAPTURED;
        if (providerDetails.paymentId && !payment.providerPaymentId) {
          payment.providerPaymentId = providerDetails.paymentId;
        }
        if (manager) await manager.save(payment);
        else await this.paymentRepo.save(payment);

        if (booking && (booking.status === BookingStatus.PENDING || booking.status === BookingStatus.FAILED)) {
          booking.status = BookingStatus.CONFIRMED;
          if (manager) await manager.save(booking);
          else await this.bookingRepo.save(booking);
        }

        await this.resolveAssociatedRecovery(payment.id, 'Resolved capture via reconciliation engine', manager);

        const mismatchCat = !hasProcessedWebhook
          ? ReconciliationMismatchCategory.WEBHOOK_GAP
          : ReconciliationMismatchCategory.PAYMENT_STATE_MISMATCH;

        reconRecord.mismatchCategory = mismatchCat;
        reconRecord.status = ReconciliationStatus.RESOLVED;
        reconRecord.resolutionAction = 'CONFIRMED_CAPTURE';
        reconRecord.resolvedAt = new Date();
        reconRecord.sanitizedResolutionReason = this.sanitizeText(
          `Synchronized canonical payment to CAPTURED based on provider capture (WebhookGap=${!hasProcessedWebhook})`,
        );
        return await saveRecon(reconRecord);
      }
    }

    // 10. Booking State Mismatch Resolution
    if (payment.status === PaymentStatus.CAPTURED && booking) {
      if (booking.status === BookingStatus.PENDING || booking.status === BookingStatus.FAILED) {
        booking.status = BookingStatus.CONFIRMED;
        if (manager) await manager.save(booking);
        else await this.bookingRepo.save(booking);

        reconRecord.mismatchCategory = ReconciliationMismatchCategory.BOOKING_STATE_MISMATCH;
        reconRecord.status = ReconciliationStatus.RESOLVED;
        reconRecord.resolutionAction = 'CONFIRMED_BOOKING_REPAIR';
        reconRecord.resolvedAt = new Date();
        reconRecord.sanitizedResolutionReason = this.sanitizeText(
          'Repaired desynchronized booking to CONFIRMED based on canonical CAPTURED payment',
        );
        return await saveRecon(reconRecord);
      }
    }

    // 11. Clean match / Webhook Gap check
    if (payment.status === PaymentStatus.CAPTURED && isProviderCaptured) {
      if (!hasProcessedWebhook) {
        reconRecord.mismatchCategory = ReconciliationMismatchCategory.WEBHOOK_GAP;
        reconRecord.status = ReconciliationStatus.RESOLVED;
        reconRecord.resolutionAction = 'CONFIRMED_CAPTURE_WEBHOOK_GAP_RESOLVED';
        reconRecord.resolvedAt = new Date();
        reconRecord.sanitizedResolutionReason = this.sanitizeText(
          'Payment and Provider match; webhook gap verified and recorded',
        );
      } else {
        reconRecord.mismatchCategory = ReconciliationMismatchCategory.NO_MISMATCH;
        reconRecord.status = ReconciliationStatus.NOT_REQUIRED;
        reconRecord.resolutionAction = 'VERIFIED_CONSISTENT';
        reconRecord.resolvedAt = new Date();
        reconRecord.sanitizedResolutionReason = this.sanitizeText('Canonical ledger and provider in full agreement');
      }
      return await saveRecon(reconRecord);
    }

    // Fallback unhandled state
    reconRecord.mismatchCategory = ReconciliationMismatchCategory.UNKNOWN_PROVIDER_STATE;
    reconRecord.status = ReconciliationStatus.REQUIRED;
    reconRecord.requiresManualIntervention = true;
    reconRecord.sanitizedResolutionReason = this.sanitizeText(
      `Unhandled state combination: DB=${payment.status}, Provider=${observedStatus}`,
    );
    return await saveRecon(reconRecord);
  }

  private async resolveAssociatedRecovery(paymentId: string, reason: string, manager?: any): Promise<void> {
    try {
      const repo = manager ? manager.getRepository(PaymentRecoveryEntity) : this.recoveryRepo;
      const recoveries = await repo.find({
        where: [
          { paymentId, recoveryStatus: In([RecoveryStatus.REQUIRED, RecoveryStatus.IN_PROGRESS]) },
          { resourceId: paymentId, recoveryStatus: In([RecoveryStatus.REQUIRED, RecoveryStatus.IN_PROGRESS]) },
        ],
      });

      for (const rec of recoveries) {
        rec.recoveryStatus = RecoveryStatus.RESOLVED;
        rec.requiresManualIntervention = false;
        rec.resolvedAt = new Date();
        rec.resolutionNotes = this.sanitizeText(reason);
        await repo.save(rec);
      }
    } catch (err) {
      this.logger.error(`[Reconciliation] Failed to resolve associated recovery for ${paymentId}: ${err}`);
    }
  }

  /**
   * Bounded Exponential Backoff calculation (max 1 hour / 3600 seconds).
   */
  private calculateNextRetry(attemptCount: number): Date {
    const delaySec = Math.min(60 * Math.pow(2, Math.max(0, attemptCount - 1)), 3600);
    return new Date(Date.now() + delaySec * 1000);
  }

  /**
   * Triggers background sweep with concurrency protection.
   */
  async runScheduledSweep(): Promise<{ processed: number; resolved: number; failed: number }> {
    if (this.isBatchRunning) {
      this.logger.warn('[ReconciliationScheduler] Sweep skipped: previous batch still in progress');
      return { processed: 0, resolved: 0, failed: 0 };
    }
    this.isBatchRunning = true;
    try {
      return await this.reconcileBatch(20);
    } finally {
      this.isBatchRunning = false;
    }
  }

  /**
   * Batch reconciles pending and retry-eligible records with bounded retry limit.
   */
  async reconcileBatch(limit = 20): Promise<{ processed: number; resolved: number; failed: number }> {
    const boundedLimit = Math.min(Math.max(1, limit || 20), 50);
    const now = new Date();

    const records = await this.reconRepo.find({
      where: [
        { status: ReconciliationStatus.REQUIRED, nextRetryAt: LessThanOrEqual(now) },
        { status: ReconciliationStatus.REQUIRED, attemptCount: 0 },
      ],
      order: { nextRetryAt: 'ASC' },
      take: boundedLimit,
    });

    let processed = 0;
    let resolved = 0;
    let failed = 0;

    for (const record of records) {
      // If record exceeded maximum retry threshold (5 attempts), mark permanently FAILED for operator review
      if (record.attemptCount >= 5) {
        record.status = ReconciliationStatus.FAILED;
        record.requiresManualIntervention = true;
        record.sanitizedResolutionReason = this.sanitizeText(
          'Exceeded maximum retry attempts (5). Retained for manual operator review.',
        );
        await this.reconRepo.save(record);
        failed++;
        processed++;
        continue;
      }

      try {
        const result = await this.reconcilePayment(record.paymentId);
        processed++;
        if (result.status === ReconciliationStatus.RESOLVED || result.status === ReconciliationStatus.NOT_REQUIRED) {
          resolved++;
        } else {
          failed++;
        }
      } catch (err) {
        this.logger.error(`[Reconciliation] Batch item failed for ${record.paymentId}: ${err}`);
        failed++;
      }
    }

    return { processed, resolved, failed };
  }

  /**
   * Manual resolution by administrator / operator.
   * CANNOT bypass canonical payment or booking state transition validators.
   */
  async manualResolve(
    id: string,
    options: ManualResolveOptions,
  ): Promise<PaymentReconciliationEntity> {
    const record = await this.reconRepo.findOne({ where: { id } });
    if (!record) {
      throw new NotFoundException(`Reconciliation record ${id} not found`);
    }

    const sanitizedNotes = this.sanitizeText(options.notes || options.action);

    // If an administrative action requests forcing a payment state transition, validate it strictly!
    if (options.targetPaymentStatus) {
      const payment = await this.paymentRepo.findOne({ where: { id: record.paymentId } });
      if (payment) {
        assertValidPaymentStateTransition(payment.status, options.targetPaymentStatus);
        payment.status = options.targetPaymentStatus;
        await this.paymentRepo.save(payment);
      }
    } else if (options.action.startsWith('FORCE_')) {
      const payment = await this.paymentRepo.findOne({ where: { id: record.paymentId } });
      if (payment) {
        let requestedTarget: PaymentStatus | null = null;
        if (options.action === 'FORCE_CAPTURE') requestedTarget = PaymentStatus.CAPTURED;
        else if (options.action === 'FORCE_REFUND') requestedTarget = PaymentStatus.REFUNDED;
        else if (options.action === 'FORCE_FAIL') requestedTarget = PaymentStatus.FAILED;
        else if (options.action === 'FORCE_CANCEL') requestedTarget = PaymentStatus.CANCELLED;

        if (requestedTarget) {
          assertValidPaymentStateTransition(payment.status, requestedTarget);
          payment.status = requestedTarget;
          await this.paymentRepo.save(payment);
        }
      }
    }

    // If an administrative action requests forcing a booking state transition, validate it strictly!
    if (options.targetBookingStatus && record.bookingId) {
      const booking = await this.bookingRepo.findOne({ where: { id: record.bookingId } });
      if (booking) {
        if (!isValidBookingTransition(booking.status, options.targetBookingStatus)) {
          throw new BadRequestException(
            `Invalid booking state transition from ${booking.status} to ${options.targetBookingStatus}`,
          );
        }
        booking.status = options.targetBookingStatus;
        await this.bookingRepo.save(booking);
      }
    }

    const previousStatus = record.status;
    record.status = ReconciliationStatus.RESOLVED;
    record.requiresManualIntervention = false;
    record.resolutionAction = options.action || 'MANUAL_RESOLUTION';
    record.sanitizedResolutionReason = sanitizedNotes;
    record.resolvedAt = new Date();
    record.metadata = {
      ...record.metadata,
      manualResolution: {
        actor: options.actor || 'admin',
        action: options.action,
        previousStatus,
        newStatus: record.status,
        paymentId: record.paymentId,
        bookingId: record.bookingId || null,
        mismatchCategory: record.mismatchCategory,
        notes: sanitizedNotes,
        resolvedAt: new Date().toISOString(),
      },
    };

    const saved = await this.reconRepo.save(record);
    this.logger.log(`[Reconciliation] Record ${id} manually resolved by ${options.actor || 'admin'}`);
    return saved;
  }

  /**
   * Queries reconciliation records with filters and pagination.
   */
  async getReconciliationRecords(filter: ReconciliationQueryFilter = {}): Promise<{
    items: PaymentReconciliationEntity[];
    total: number;
  }> {
    const query = this.reconRepo.createQueryBuilder('recon');

    if (filter.status) {
      query.andWhere('recon.status = :status', { status: filter.status });
    }
    if (filter.mismatchCategory) {
      query.andWhere('recon.mismatchCategory = :category', { category: filter.mismatchCategory });
    }
    if (filter.paymentId) {
      query.andWhere('recon.paymentId = :paymentId', { paymentId: filter.paymentId });
    }
    if (filter.bookingId) {
      query.andWhere('recon.bookingId = :bookingId', { bookingId: filter.bookingId });
    }
    if (filter.requiresManualIntervention !== undefined) {
      query.andWhere('recon.requiresManualIntervention = :req', { req: filter.requiresManualIntervention });
    }

    query.orderBy('recon.createdAt', 'DESC');
    query.take(filter.limit || 50);
    query.skip(filter.offset || 0);

    const [items, total] = await query.getManyAndCount();
    return { items, total };
  }

  /**
   * Retrieves high-level operational reconciliation summary metrics.
   */
  async getReconciliationSummary(): Promise<{
    totalRecords: number;
    resolvedCount: number;
    requiredCount: number;
    failedCount: number;
    manualInterventionCount: number;
    mismatchBreakdown: Record<string, number>;
  }> {
    const totalRecords = await this.reconRepo.count();
    const resolvedCount = await this.reconRepo.count({
      where: [{ status: ReconciliationStatus.RESOLVED }, { status: ReconciliationStatus.NOT_REQUIRED }],
    });
    const requiredCount = await this.reconRepo.count({
      where: { status: ReconciliationStatus.REQUIRED },
    });
    const failedCount = await this.reconRepo.count({
      where: { status: ReconciliationStatus.FAILED },
    });
    const manualInterventionCount = await this.reconRepo.count({
      where: { requiresManualIntervention: true },
    });

    const categoryCounts = await this.reconRepo
      .createQueryBuilder('recon')
      .select('recon.mismatchCategory', 'category')
      .addSelect('COUNT(recon.id)', 'count')
      .groupBy('recon.mismatchCategory')
      .getRawMany();

    const mismatchBreakdown: Record<string, number> = {};
    for (const cat of categoryCounts) {
      mismatchBreakdown[cat.category] = parseInt(cat.count, 10) || 0;
    }

    return {
      totalRecords,
      resolvedCount,
      requiredCount,
      failedCount,
      manualInterventionCount,
      mismatchBreakdown,
    };
  }
}

function isValidBookingTransition(from: BookingStatus, to: BookingStatus): boolean {
  const allowed = VALID_BOOKING_TRANSITIONS[from] || [];
  return allowed.includes(to);
}
