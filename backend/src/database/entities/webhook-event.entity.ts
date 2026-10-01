import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export type WebhookProcessingStatus = 'RECEIVED' | 'PROCESSING' | 'PROCESSED' | 'FAILED' | 'IGNORED';

@Entity('webhook_events')
export class WebhookEventEntity {
  @PrimaryColumn()
  id: string; // Provider Event ID (e.g., evt_razorpay_123 or txn hash)

  @Column({ default: 'razorpay' })
  provider: string; // 'razorpay' | 'simulated' | 'stripe'

  @Index('IDX_webhook_events_eventType')
  @Column()
  eventType: string; // 'payment.captured' | 'order.paid' | 'payment.failed' | 'refund.processed'

  @Column('jsonb')
  payload: Record<string, any>;

  @Index('IDX_webhook_events_status')
  @Column({ default: 'RECEIVED' })
  status: WebhookProcessingStatus;

  @Index('IDX_webhook_events_providerPaymentId')
  @Column({ nullable: true })
  providerPaymentId?: string;

  @Index('IDX_webhook_events_providerOrderId')
  @Column({ nullable: true })
  providerOrderId?: string;

  @Column({ nullable: true })
  paymentId?: string;

  @Index('IDX_webhook_events_bookingId')
  @Column({ nullable: true })
  bookingId?: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  amount?: number;

  @Column({ type: 'integer', nullable: true })
  amountInMinorUnits?: number;

  @Column({ length: 10, default: 'INR' })
  currency: string;

  @Column({ type: 'text', nullable: true })
  failureReason?: string;

  @CreateDateColumn()
  receivedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  processedAt?: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
