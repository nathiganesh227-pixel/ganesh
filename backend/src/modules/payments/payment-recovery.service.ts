import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  PaymentRecoveryEntity,
  FailureCategory,
  RecoveryStatus,
} from '../../database/entities/payment-recovery.entity';

export interface RecordIncidentOptions {
  resourceType?: string;
  resourceId: string;
  paymentId?: string;
  bookingId?: string;
  providerOrderId?: string;
  providerPaymentId?: string;
  failureCategory: FailureCategory;
  recoveryStatus?: RecoveryStatus;
  rawError?: any;
  safeFailureReason?: string;
  metadata?: Record<string, any>;
}

@Injectable()
export class PaymentRecoveryService {
  private readonly logger = new Logger(PaymentRecoveryService.name);

  constructor(
    @InjectRepository(PaymentRecoveryEntity)
    private readonly recoveryRepo: Repository<PaymentRecoveryEntity>,
  ) {}

  /**
   * Sanitizes failure messages by stripping sensitive keys, secrets, JWTs, and stack traces.
   */
  sanitizeReason(reason?: string | any): string {
    if (!reason) return 'Unknown error';
    let text = typeof reason === 'string' ? reason : reason.message || JSON.stringify(reason);

    // Redact potential secrets, keys, and tokens
    text = text
      .replace(/rzp_(?:live|test)_[a-zA-Z0-9]+/gi, '[REDACTED_RZP_KEY]')
      .replace(/(?:key_secret|secret|password|token|bearer)\s*[:=]\s*["']?[^\s,"']+/gi, '$1=[REDACTED]')
      .replace(/eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+/g, '[REDACTED_JWT]');

    // Strip internal Node/Nest stack traces
    if (text.includes('\n    at ')) {
      text = text.split('\n    at ')[0].trim();
    }

    return text.substring(0, 500);
  }

  /**
   * Deterministically classifies an error into a canonical FailureCategory.
   */
  classifyError(err: any): FailureCategory {
    if (!err) return FailureCategory.UNKNOWN_PROVIDER_OUTCOME;

    const message = (typeof err === 'string' ? err : err.message || '').toLowerCase();
    const statusVal = (typeof err?.getStatus === 'function' ? err.getStatus() : err?.status || err?.statusCode || '').toString();
    const code = (err.code || statusVal).toString().toLowerCase();

    if (
      message.includes('signature') ||
      message.includes('tamper') ||
      message.includes('quote_tampered') ||
      message.includes('invalid_payment_signature') ||
      statusVal === '401'
    ) {
      return FailureCategory.AUTHORIZATION_FAILURE;
    }

    if (
      message.includes('timeout') ||
      message.includes('etimedout') ||
      message.includes('esockettimedout') ||
      message.includes('gateway timeout') ||
      code === '504' ||
      statusVal === '504'
    ) {
      return FailureCategory.PROVIDER_TIMEOUT;
    }

    if (
      message.includes('econnrefused') ||
      message.includes('enotfound') ||
      message.includes('503') ||
      message.includes('service unavailable') ||
      message.includes('maintenance') ||
      code === '503' ||
      statusVal === '503'
    ) {
      return FailureCategory.PROVIDER_UNAVAILABLE;
    }

    if (
      message.includes('network') ||
      message.includes('socket hang up') ||
      message.includes('econnreset')
    ) {
      return FailureCategory.NETWORK_ERROR;
    }

    if (
      message.includes('refund') ||
      message.includes('refund_failed')
    ) {
      return FailureCategory.REFUND_FAILURE;
    }

    if (
      message.includes('sms') ||
      message.includes('notification') ||
      message.includes('twilio')
    ) {
      return FailureCategory.NOTIFICATION_FAILURE;
    }

    if (
      message.includes('reward') ||
      message.includes('coin balance') ||
      message.includes('rewards balance')
    ) {
      return FailureCategory.REWARD_FAILURE;
    }

    if (
      message.includes('inventory') ||
      message.includes('ticket tier') ||
      message.includes('sold out') ||
      message.includes('slot count')
    ) {
      return FailureCategory.INVENTORY_FAILURE;
    }

    if (
      message.includes('booking') ||
      message.includes('booking confirmation') ||
      message.includes('already have an active table')
    ) {
      return FailureCategory.BOOKING_CONFIRMATION_FAILURE;
    }

    if (
      message.includes('declined') ||
      message.includes('insufficient_funds') ||
      message.includes('card_declined') ||
      message.includes('issuing bank') ||
      message.includes('payment_failed')
    ) {
      return FailureCategory.PROVIDER_DECLINED;
    }

    if (
      message.includes('database') ||
      message.includes('queryfailed') ||
      message.includes('typeorm') ||
      message.includes('postgres') ||
      message.includes('transaction')
    ) {
      return FailureCategory.DATABASE_FAILURE;
    }

    if (
      message.includes('mismatch') ||
      message.includes('quote_not_found') ||
      message.includes('quote_expired') ||
      message.includes('quote_booking_mismatch') ||
      message.includes('payment_amount_mismatch') ||
      message.includes('payment_currency_mismatch') ||
      message.includes('payment_order_mismatch') ||
      message.includes('refund_amount_invalid') ||
      message.includes('invalid') ||
      message.includes('not supported') ||
      message.includes('validation') ||
      message.includes('bad request') ||
      statusVal === '400'
    ) {
      return FailureCategory.VALIDATION_FAILURE;
    }

    return FailureCategory.UNKNOWN_PROVIDER_OUTCOME;
  }

  /**
   * Identifies whether the failure outcome is uncertain from the provider perspective.
   */
  isUnknownOutcome(category: FailureCategory): boolean {
    return (
      category === FailureCategory.PROVIDER_TIMEOUT ||
      category === FailureCategory.NETWORK_ERROR ||
      category === FailureCategory.PROVIDER_UNAVAILABLE ||
      category === FailureCategory.UNKNOWN_PROVIDER_OUTCOME
    );
  }

  /**
   * Persists a durable recovery incident.
   */
  async recordIncident(options: RecordIncidentOptions): Promise<PaymentRecoveryEntity> {
    const safeReason =
      options.safeFailureReason || this.sanitizeReason(options.rawError);

    const incidentId = `recov_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;

    const entity = this.recoveryRepo.create({
      id: incidentId,
      resourceType: options.resourceType || 'payment',
      resourceId: options.resourceId,
      paymentId: options.paymentId,
      bookingId: options.bookingId,
      providerOrderId: options.providerOrderId,
      providerPaymentId: options.providerPaymentId,
      failureCategory: options.failureCategory,
      recoveryStatus: options.recoveryStatus || RecoveryStatus.REQUIRED,
      safeFailureReason: safeReason,
      metadata: options.metadata || {},
    });

    const saved = await this.recoveryRepo.save(entity);

    this.logger.warn(
      `[PaymentRecovery] Incident recorded: ID=${saved.id}, Category=${saved.failureCategory}, Status=${saved.recoveryStatus}, Resource=${saved.resourceId}`,
    );

    return saved;
  }

  /**
   * Lists unresolved recovery incidents for operations/monitoring.
   */
  async getPendingIncidents(limit = 50): Promise<PaymentRecoveryEntity[]> {
    return this.recoveryRepo.find({
      where: [
        { recoveryStatus: RecoveryStatus.REQUIRED },
        { recoveryStatus: RecoveryStatus.IN_PROGRESS },
      ],
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }

  /**
   * Retrieves a single incident by ID.
   */
  async getIncidentById(id: string): Promise<PaymentRecoveryEntity | null> {
    return this.recoveryRepo.findOne({ where: { id } });
  }

  /**
   * Marks a recovery incident as RESOLVED.
   */
  async resolveIncident(
    id: string,
    notes?: string,
  ): Promise<PaymentRecoveryEntity | null> {
    const incident = await this.recoveryRepo.findOne({ where: { id } });
    if (!incident) return null;

    incident.recoveryStatus = RecoveryStatus.RESOLVED;
    incident.requiresManualIntervention = false;
    incident.resolvedAt = new Date();
    if (notes) {
      const sanitized = this.sanitizeReason(notes);
      incident.resolutionNotes = sanitized;
      incident.metadata = {
        ...incident.metadata,
        resolutionNotes: sanitized,
      };
    }

    const saved = await this.recoveryRepo.save(incident);
    this.logger.log(`[PaymentRecovery] Incident ${id} marked as RESOLVED`);
    return saved;
  }
}
