import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

export enum PaymentStatus {
  CREATED = 'CREATED',
  PENDING = 'PENDING',
  AUTHORIZED = 'AUTHORIZED',
  CAPTURED = 'CAPTURED',
  FAILED = 'FAILED',
  CANCELLED = 'CANCELLED',
  REFUND_PENDING = 'REFUND_PENDING',
  REFUNDED = 'REFUNDED',
}

@Entity('payments')
export class PaymentEntity {
  @PrimaryColumn()
  id: string;

  @Column()
  bookingId: string;

  @Column({ default: 'usr_default_1' })
  userId: string;

  @Column('float')
  amount: number;

  @Column({ default: 'INR' })
  currency: string;

  @Column({ default: 'razorpay' })
  provider: string;

  @Column({ nullable: true })
  providerOrderId?: string;

  @Column({ nullable: true })
  providerPaymentId?: string;

  @Column({ nullable: true })
  providerSignature?: string;

  @Column({
    type: 'varchar',
    default: PaymentStatus.CREATED,
  })
  status: PaymentStatus;

  @Column({ nullable: true })
  paymentMethod?: string;

  @Column({ nullable: true })
  failureReason?: string;

  @Column('float', { nullable: true, default: 0 })
  refundAmount?: number;

  @Column({ nullable: true })
  refundId?: string;

  @Column('jsonb', { nullable: true })
  metadata?: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
