import { Entity, PrimaryColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('webhook_events')
export class WebhookEventEntity {
  @PrimaryColumn()
  id: string; // Provider Event ID (e.g., event_razorpay_123 or txn hash)

  @Column()
  provider: string; // 'razorpay' | 'stripe'

  @Column()
  eventType: string; // 'payment.captured' | 'order.paid' | 'payment.failed'

  @Column('jsonb')
  payload: Record<string, any>;

  @Column({ default: 'PROCESSED' })
  status: 'PROCESSED' | 'FAILED' | 'IGNORED';

  @CreateDateColumn()
  processedAt: Date;
}
