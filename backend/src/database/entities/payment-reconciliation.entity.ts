import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';
import { PaymentStatus } from './payment.entity';

export enum ReconciliationStatus {
  NOT_REQUIRED = 'NOT_REQUIRED',
  REQUIRED = 'REQUIRED',
  IN_PROGRESS = 'IN_PROGRESS',
  RESOLVED = 'RESOLVED',
  FAILED = 'FAILED',
}

export enum ReconciliationMismatchCategory {
  NO_MISMATCH = 'NO_MISMATCH',
  PAYMENT_STATE_MISMATCH = 'PAYMENT_STATE_MISMATCH',
  BOOKING_STATE_MISMATCH = 'BOOKING_STATE_MISMATCH',
  AMOUNT_MISMATCH = 'AMOUNT_MISMATCH',
  CURRENCY_MISMATCH = 'CURRENCY_MISMATCH',
  PROVIDER_ORDER_MISMATCH = 'PROVIDER_ORDER_MISMATCH',
  PROVIDER_PAYMENT_MISMATCH = 'PROVIDER_PAYMENT_MISMATCH',
  MISSING_PROVIDER_PAYMENT = 'MISSING_PROVIDER_PAYMENT',
  MISSING_CANONICAL_PAYMENT = 'MISSING_CANONICAL_PAYMENT',
  MISSING_BOOKING = 'MISSING_BOOKING',
  WEBHOOK_GAP = 'WEBHOOK_GAP',
  WEBHOOK_STATE_MISMATCH = 'WEBHOOK_STATE_MISMATCH',
  REFUND_STATE_MISMATCH = 'REFUND_STATE_MISMATCH',
  UNKNOWN_PROVIDER_STATE = 'UNKNOWN_PROVIDER_STATE',
  PROVIDER_UNAVAILABLE = 'PROVIDER_UNAVAILABLE',
  PROVIDER_TIMEOUT = 'PROVIDER_TIMEOUT',
  INVALID_PROVIDER_RESPONSE = 'INVALID_PROVIDER_RESPONSE',
  DUPLICATE_PROVIDER_REFERENCE = 'DUPLICATE_PROVIDER_REFERENCE',
  IDEMPOTENCY_CONFLICT = 'IDEMPOTENCY_CONFLICT',
  RECOVERY_REQUIRED = 'RECOVERY_REQUIRED',
}

@Entity('payment_reconciliation_records')
export class PaymentReconciliationEntity {
  @PrimaryColumn()
  id: string; // e.g. recon_1791..._abcd

  @Column()
  @Index('IDX_payment_reconciliation_paymentId')
  paymentId: string;

  @Column({ nullable: true })
  @Index('IDX_payment_reconciliation_bookingId')
  bookingId?: string;

  @Column({ nullable: true })
  quoteId?: string;

  @Column({ default: 'simulated' })
  provider: string;

  @Column({ nullable: true })
  @Index('IDX_payment_reconciliation_providerPaymentId')
  providerPaymentId?: string;

  @Column({ nullable: true })
  @Index('IDX_payment_reconciliation_providerOrderId')
  providerOrderId?: string;

  @Column({
    type: 'varchar',
    default: PaymentStatus.PENDING,
  })
  canonicalPaymentStatus: PaymentStatus;

  @Column({ type: 'varchar', nullable: true })
  observedProviderStatus?: string;

  @Column('float', { default: 0 })
  canonicalAmount: number;

  @Column({ type: 'int', default: 0 })
  canonicalAmountInMinorUnits: number;

  @Column({ type: 'int', nullable: true })
  observedAmountInMinorUnits?: number;

  @Column({ default: 'INR' })
  canonicalCurrency: string;

  @Column({ type: 'varchar', nullable: true })
  observedCurrency?: string;

  @Column({
    type: 'varchar',
    default: ReconciliationMismatchCategory.NO_MISMATCH,
  })
  @Index('IDX_payment_reconciliation_mismatchCategory')
  mismatchCategory: ReconciliationMismatchCategory;

  @Column({
    type: 'varchar',
    default: ReconciliationStatus.REQUIRED,
  })
  @Index('IDX_payment_reconciliation_status')
  status: ReconciliationStatus;

  @Column({ type: 'int', default: 0 })
  attemptCount: number;

  @Column({ type: 'timestamp', nullable: true })
  lastAttemptedAt?: Date;

  @Column({ type: 'timestamp', nullable: true })
  nextRetryAt?: Date;

  @Column({ type: 'timestamp', nullable: true })
  resolvedAt?: Date;

  @Column({ type: 'varchar', nullable: true })
  resolutionAction?: string; // e.g. 'CONFIRMED_CAPTURE' | 'CONFIRMED_REFUND' | 'NO_OP' | 'MANUAL_RESOLUTION'

  @Column({ type: 'text', nullable: true })
  sanitizedResolutionReason?: string;

  @Column({ type: 'boolean', default: false })
  requiresManualIntervention: boolean;

  @Column('jsonb', { nullable: true })
  metadata?: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
