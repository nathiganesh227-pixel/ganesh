import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export enum FailureCategory {
  VALIDATION_FAILURE = 'VALIDATION_FAILURE',
  AUTHORIZATION_FAILURE = 'AUTHORIZATION_FAILURE',
  PROVIDER_DECLINED = 'PROVIDER_DECLINED',
  PROVIDER_TIMEOUT = 'PROVIDER_TIMEOUT',
  PROVIDER_UNAVAILABLE = 'PROVIDER_UNAVAILABLE',
  NETWORK_ERROR = 'NETWORK_ERROR',
  DATABASE_FAILURE = 'DATABASE_FAILURE',
  BOOKING_CONFIRMATION_FAILURE = 'BOOKING_CONFIRMATION_FAILURE',
  INVENTORY_FAILURE = 'INVENTORY_FAILURE',
  REWARD_FAILURE = 'REWARD_FAILURE',
  NOTIFICATION_FAILURE = 'NOTIFICATION_FAILURE',
  REFUND_FAILURE = 'REFUND_FAILURE',
  UNKNOWN_PROVIDER_OUTCOME = 'UNKNOWN_PROVIDER_OUTCOME',
}

export enum RecoveryStatus {
  REQUIRED = 'REQUIRED',
  IN_PROGRESS = 'IN_PROGRESS',
  RESOLVED = 'RESOLVED',
  FAILED = 'FAILED',
}

@Entity('payment_recovery_records')
export class PaymentRecoveryEntity {
  @PrimaryColumn()
  id: string; // e.g. recov_1790..._abcd

  @Column({ default: 'payment' })
  resourceType: string; // 'payment' | 'booking' | 'refund' | 'order'

  @Column()
  @Index('IDX_payment_recovery_resourceId')
  resourceId: string;

  @Column({ nullable: true })
  @Index('IDX_payment_recovery_paymentId')
  paymentId?: string;

  @Column({ nullable: true })
  @Index('IDX_payment_recovery_bookingId')
  bookingId?: string;

  @Column({ nullable: true })
  providerOrderId?: string;

  @Column({ nullable: true })
  providerPaymentId?: string;

  @Column({
    type: 'varchar',
    default: FailureCategory.UNKNOWN_PROVIDER_OUTCOME,
  })
  @Index('IDX_payment_recovery_failureCategory')
  failureCategory: FailureCategory;

  @Column({
    type: 'varchar',
    default: RecoveryStatus.REQUIRED,
  })
  @Index('IDX_payment_recovery_recoveryStatus')
  recoveryStatus: RecoveryStatus;

  @Column({ type: 'text', nullable: true })
  safeFailureReason?: string;

  @Column({ type: 'int', default: 0 })
  retryCount: number;

  @Column({ type: 'boolean', default: false })
  requiresManualIntervention: boolean;

  @Column({ type: 'text', nullable: true })
  resolutionNotes?: string;

  @Column({ type: 'timestamp', nullable: true })
  lastRetryAt?: Date;

  @Column('jsonb', { nullable: true })
  metadata?: Record<string, any>;

  @Column({ type: 'timestamp', nullable: true })
  resolvedAt?: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
