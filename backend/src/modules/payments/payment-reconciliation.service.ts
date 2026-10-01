import { Injectable, Logger, BadRequestException, NotFoundException, Optional } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual, In } from 'typeorm';
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

export interface ReconcilePaymentOptions {
  force?: boolean;
  actor?: string;
  notes?: string;
}

export interface ManualResolveOptions {
  action: string;
  notes: string;
  actor?: string;
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
export class PaymentReconciliationService {
  private readonly logger = new Logger(PaymentReconciliationService.name);
  private readonly inFlightReconciliations = new Set<string>();

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
    private readonly paymentConfigService?: PaymentConfigService,
    @Optional()
    private readonly simulatedAdapter?: SimulatedPaymentAdapter,
    @Optional()
    private readonly razorpayAdapter?: RazorpayAdapter,
    @Optional()
    private readonly recoveryService?: PaymentRecoveryService,
  ) {}

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
   * Sanitizes resolution reason strings and notes.
   */
  sanitizeText(text?: string | any): string {
    if (!text) return '';
    let str = typeof text === 'string' ? text : text.message || JSON.stringify(text);
    str = str
      .replace(/rzp_(?:live|test)_[a-zA-Z0-9]+/gi, '[REDACTED_RZP_KEY]')
      .replace(/(?:key_secret|secret|password|token|bearer)\s*[:=]\s*["']?[^\s,"']+/gi, '$1=[REDACTED]')
      .replace(/eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+/g, '[REDACTED_JWT]');

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
      return await this.executeReconcile(lockKey, options);
    } finally {
      this.inFlightReconciliations.delete(lockKey);
    }
  }

  private async executeReconcile(
    paymentId: string,
    options: ReconcilePaymentOptions,
  ): Promise<PaymentReconciliationEntity> {
    const payment = await this.paymentRepo.findOne({ where: { id: paymentId } });

    // Handle missing canonical payment
    if (!payment) {
      const reconId = this.generateReconId(paymentId);
      const record = this.reconRepo.create({
        id: reconId,
        paymentId,
        canonicalPaymentStatus: PaymentStatus.FAILED,
        canonicalAmount: 0,
        canonicalAmountInMinorUnits: 0,
        canonicalCurrency: 'INR',
        provider: 'simulated',
        mismatchCategory: ReconciliationMismatchCategory.MISSING_CANONICAL_PAYMENT,
        status: ReconciliationStatus.FAILED,
        attemptCount: 1,
        lastAttemptedAt: new Date(),
        requiresManualIntervention: true,
        sanitizedResolutionReason: this.sanitizeText(`Payment record ${paymentId} not found in database`),
      });
      return await this.reconRepo.save(record);
    }

    const canonicalMinorUnits = toMinorUnits(payment.amount);
    const canonicalCurrency = (payment.currency || 'INR').trim().toUpperCase();
    const providerAdapter = this.getActiveProvider(payment.provider);

    // Retrieve or create reconciliation record
    let reconRecord = await this.reconRepo.findOne({
      where: { paymentId: payment.id },
      order: { createdAt: 'DESC' },
    });

    if (!reconRecord) {
      reconRecord = this.reconRepo.create({
        id: this.generateReconId(payment.id),
        paymentId: payment.id,
        bookingId: payment.bookingId,
        quoteId: payment.quoteId,
        provider: payment.provider || 'simulated',
        providerPaymentId: payment.providerPaymentId,
        providerOrderId: payment.providerOrderId,
        canonicalPaymentStatus: payment.status,
        canonicalAmount: payment.amount,
        canonicalAmountInMinorUnits: canonicalMinorUnits,
        canonicalCurrency: canonicalCurrency,
        mismatchCategory: ReconciliationMismatchCategory.NO_MISMATCH,
        status: ReconciliationStatus.IN_PROGRESS,
        attemptCount: 0,
        requiresManualIntervention: false,
      });
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

    // 1. Check duplicate provider reference across payments
    if (payment.providerPaymentId) {
      const duplicatePayments = await this.paymentRepo.find({
        where: { providerPaymentId: payment.providerPaymentId },
      });
      if (duplicatePayments.length > 1) {
        reconRecord.mismatchCategory = ReconciliationMismatchCategory.DUPLICATE_PROVIDER_REFERENCE;
        reconRecord.status = ReconciliationStatus.REQUIRED;
        reconRecord.requiresManualIntervention = true;
        reconRecord.sanitizedResolutionReason = this.sanitizeText(
          `Duplicate providerPaymentId ${payment.providerPaymentId} shared across ${duplicatePayments.length} payments`,
        );
        return await this.reconRepo.save(reconRecord);
      }
    }

    // 2. Fetch associated booking
    let booking: BookingEntity | null = null;
    if (payment.bookingId) {
      booking = await this.bookingRepo.findOne({ where: { id: payment.bookingId } });
      if (!booking) {
        reconRecord.mismatchCategory = ReconciliationMismatchCategory.MISSING_BOOKING;
        reconRecord.status = ReconciliationStatus.REQUIRED;
        reconRecord.requiresManualIntervention = true;
        reconRecord.sanitizedResolutionReason = this.sanitizeText(
          `Associated booking ${payment.bookingId} not found in database`,
        );
        return await this.reconRepo.save(reconRecord);
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
        return await this.reconRepo.save(reconRecord);
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
        return await this.reconRepo.save(reconRecord);
      }

      if (msg.includes('not found') || statusVal === '404') {
        reconRecord.mismatchCategory = ReconciliationMismatchCategory.MISSING_PROVIDER_PAYMENT;
        reconRecord.status = ReconciliationStatus.REQUIRED;
        reconRecord.requiresManualIntervention = true;
        reconRecord.sanitizedResolutionReason = this.sanitizeText(
          `Provider reported payment ${lookupId} not found`,
        );
        return await this.reconRepo.save(reconRecord);
      }

      reconRecord.mismatchCategory = ReconciliationMismatchCategory.INVALID_PROVIDER_RESPONSE;
      reconRecord.status = ReconciliationStatus.REQUIRED;
      reconRecord.requiresManualIntervention = true;
      reconRecord.sanitizedResolutionReason = this.sanitizeText(err);
      return await this.reconRepo.save(reconRecord);
    }

    if (!providerDetails) {
      reconRecord.mismatchCategory = ReconciliationMismatchCategory.MISSING_PROVIDER_PAYMENT;
      reconRecord.status = ReconciliationStatus.REQUIRED;
      reconRecord.requiresManualIntervention = true;
      reconRecord.sanitizedResolutionReason = this.sanitizeText('Provider returned empty payment details');
      return await this.reconRepo.save(reconRecord);
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
      return await this.reconRepo.save(reconRecord);
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
      return await this.reconRepo.save(reconRecord);
    }

    // 5. Exact Amount Matching (Minor Units)
    if (canonicalMinorUnits !== observedMinorUnits) {
      reconRecord.mismatchCategory = ReconciliationMismatchCategory.AMOUNT_MISMATCH;
      reconRecord.status = ReconciliationStatus.REQUIRED;
      reconRecord.requiresManualIntervention = true;
      reconRecord.sanitizedResolutionReason = this.sanitizeText(
        `Amount mismatch: canonical=${canonicalMinorUnits} paise, observed=${observedMinorUnits} paise`,
      );
      return await this.reconRepo.save(reconRecord);
    }

    // 6. Currency Matching
    if (canonicalCurrency !== observedCurrency) {
      reconRecord.mismatchCategory = ReconciliationMismatchCategory.CURRENCY_MISMATCH;
      reconRecord.status = ReconciliationStatus.REQUIRED;
      reconRecord.requiresManualIntervention = true;
      reconRecord.sanitizedResolutionReason = this.sanitizeText(
        `Currency mismatch: canonical=${canonicalCurrency}, observed=${observedCurrency}`,
      );
      return await this.reconRepo.save(reconRecord);
    }

    // 7. Check Webhook Gap
    let hasProcessedWebhook = false;
    if (payment.providerPaymentId || payment.providerOrderId) {
      const webhook = await this.webhookRepo.findOne({
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
        await this.paymentRepo.save(payment);

        if (booking && isValidBookingTransition(booking.status, BookingStatus.REFUNDED)) {
          booking.status = BookingStatus.REFUNDED;
          await this.bookingRepo.save(booking);
        }

        await this.resolveAssociatedRecovery(payment.id, 'Resolved refund via reconciliation engine');

        reconRecord.mismatchCategory = ReconciliationMismatchCategory.REFUND_STATE_MISMATCH;
        reconRecord.status = ReconciliationStatus.RESOLVED;
        reconRecord.resolutionAction = 'CONFIRMED_REFUND';
        reconRecord.resolvedAt = new Date();
        reconRecord.sanitizedResolutionReason = this.sanitizeText('Provider refund applied to canonical ledger');
        return await this.reconRepo.save(reconRecord);
      } else {
        reconRecord.mismatchCategory = ReconciliationMismatchCategory.REFUND_STATE_MISMATCH;
        reconRecord.status = ReconciliationStatus.REQUIRED;
        reconRecord.requiresManualIntervention = true;
        reconRecord.sanitizedResolutionReason = this.sanitizeText(
          `Cannot transition payment from ${payment.status} to REFUNDED`,
        );
        return await this.reconRepo.save(reconRecord);
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
      return await this.reconRepo.save(reconRecord);
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
        await this.paymentRepo.save(payment);

        if (booking && (booking.status === BookingStatus.PENDING || booking.status === BookingStatus.FAILED)) {
          booking.status = BookingStatus.CONFIRMED;
          await this.bookingRepo.save(booking);
        }

        await this.resolveAssociatedRecovery(payment.id, 'Resolved capture via reconciliation engine');

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
        return await this.reconRepo.save(reconRecord);
      }
    }

    // 10. Booking State Mismatch Resolution
    if (payment.status === PaymentStatus.CAPTURED && booking) {
      if (booking.status === BookingStatus.PENDING || booking.status === BookingStatus.FAILED) {
        booking.status = BookingStatus.CONFIRMED;
        await this.bookingRepo.save(booking);

        reconRecord.mismatchCategory = ReconciliationMismatchCategory.BOOKING_STATE_MISMATCH;
        reconRecord.status = ReconciliationStatus.RESOLVED;
        reconRecord.resolutionAction = 'CONFIRMED_BOOKING_REPAIR';
        reconRecord.resolvedAt = new Date();
        reconRecord.sanitizedResolutionReason = this.sanitizeText(
          'Repaired desynchronized booking to CONFIRMED based on canonical CAPTURED payment',
        );
        return await this.reconRepo.save(reconRecord);
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
      return await this.reconRepo.save(reconRecord);
    }

    // Fallback unhandled state
    reconRecord.mismatchCategory = ReconciliationMismatchCategory.UNKNOWN_PROVIDER_STATE;
    reconRecord.status = ReconciliationStatus.REQUIRED;
    reconRecord.requiresManualIntervention = true;
    reconRecord.sanitizedResolutionReason = this.sanitizeText(
      `Unhandled state combination: DB=${payment.status}, Provider=${observedStatus}`,
    );
    return await this.reconRepo.save(reconRecord);
  }

  private async resolveAssociatedRecovery(paymentId: string, reason: string): Promise<void> {
    try {
      const recoveries = await this.recoveryRepo.find({
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
        await this.recoveryRepo.save(rec);
      }
    } catch (err) {
      this.logger.error(`[Reconciliation] Failed to resolve associated recovery for ${paymentId}: ${err}`);
    }
  }

  /**
   * Bounded Exponential Backoff calculation (max 1 hour).
   */
  private calculateNextRetry(attemptCount: number): Date {
    const delaySec = Math.min(60 * Math.pow(2, Math.max(0, attemptCount - 1)), 3600);
    return new Date(Date.now() + delaySec * 1000);
  }

  /**
   * Batch reconciles pending and retry-eligible records.
   */
  async reconcileBatch(limit = 20): Promise<{ processed: number; resolved: number; failed: number }> {
    const now = new Date();
    const records = await this.reconRepo.find({
      where: [
        { status: ReconciliationStatus.REQUIRED, nextRetryAt: LessThanOrEqual(now) },
        { status: ReconciliationStatus.REQUIRED, attemptCount: 0 },
      ],
      order: { nextRetryAt: 'ASC' },
      take: limit,
    });

    let processed = 0;
    let resolved = 0;
    let failed = 0;

    for (const record of records) {
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
