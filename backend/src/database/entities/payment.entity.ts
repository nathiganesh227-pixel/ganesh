import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { BadRequestException } from '@nestjs/common';

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

export enum PaymentErrorCode {
  QUOTE_EXPIRED = 'QUOTE_EXPIRED',
  QUOTE_NOT_FOUND = 'QUOTE_NOT_FOUND',
  QUOTE_NOT_OWNED = 'QUOTE_NOT_OWNED',
  QUOTE_CANCELLED = 'QUOTE_CANCELLED',
  QUOTE_ALREADY_CONSUMED = 'QUOTE_ALREADY_CONSUMED',
  QUOTE_TAMPERED = 'QUOTE_TAMPERED',
  QUOTE_BOOKING_MISMATCH = 'QUOTE_BOOKING_MISMATCH',
  PAYMENT_NOT_FOUND = 'PAYMENT_NOT_FOUND',
  PAYMENT_NOT_OWNED = 'PAYMENT_NOT_OWNED',
  PAYMENT_BOOKING_MISMATCH = 'PAYMENT_BOOKING_MISMATCH',
  INVALID_PAYMENT_SIGNATURE = 'INVALID_PAYMENT_SIGNATURE',
  PAYMENT_ORDER_MISMATCH = 'PAYMENT_ORDER_MISMATCH',
  PAYMENT_AMOUNT_MISMATCH = 'PAYMENT_AMOUNT_MISMATCH',
  PAYMENT_CURRENCY_MISMATCH = 'PAYMENT_CURRENCY_MISMATCH',
  PAYMENT_ID_MISMATCH = 'PAYMENT_ID_MISMATCH',
  PAYMENT_ALREADY_CAPTURED = 'PAYMENT_ALREADY_CAPTURED',
  PAYMENT_NOT_VERIFIED = 'PAYMENT_NOT_VERIFIED',
  INVALID_PAYMENT_STATE_TRANSITION = 'INVALID_PAYMENT_STATE_TRANSITION',
  RAZORPAY_LIVE_DISABLED = 'RAZORPAY_LIVE_DISABLED',
  RAZORPAY_MISCONFIGURED = 'RAZORPAY_MISCONFIGURED',
}

/**
 * Canonical Payment State Machine Transitions.
 * Direct CREATED -> CAPTURED or CREATED -> REFUNDED is forbidden.
 * Terminal/failure states (FAILED, REFUNDED, CANCELLED) cannot transition to CAPTURED or AUTHORIZED.
 */
export const VALID_PAYMENT_TRANSITIONS: Record<PaymentStatus, PaymentStatus[]> = {
  [PaymentStatus.CREATED]: [
    PaymentStatus.PENDING,
    PaymentStatus.AUTHORIZED,
    PaymentStatus.FAILED,
    PaymentStatus.CANCELLED,
  ],
  [PaymentStatus.PENDING]: [
    PaymentStatus.AUTHORIZED,
    PaymentStatus.CAPTURED,
    PaymentStatus.FAILED,
    PaymentStatus.CANCELLED,
  ],
  [PaymentStatus.AUTHORIZED]: [
    PaymentStatus.CAPTURED,
    PaymentStatus.FAILED,
    PaymentStatus.CANCELLED,
  ],
  [PaymentStatus.CAPTURED]: [
    PaymentStatus.REFUND_PENDING,
    PaymentStatus.REFUNDED,
  ],
  [PaymentStatus.REFUND_PENDING]: [
    PaymentStatus.REFUNDED,
  ],
  [PaymentStatus.REFUNDED]: [],
  [PaymentStatus.FAILED]: [],
  [PaymentStatus.CANCELLED]: [],
};

export function isValidPaymentStateTransition(
  from: PaymentStatus,
  to: PaymentStatus,
): boolean {
  const allowed = VALID_PAYMENT_TRANSITIONS[from] || [];
  return allowed.includes(to);
}

export function assertValidPaymentStateTransition(
  from: PaymentStatus,
  to: PaymentStatus,
): void {
  if (!isValidPaymentStateTransition(from, to)) {
    throw new BadRequestException(
      `${PaymentErrorCode.INVALID_PAYMENT_STATE_TRANSITION}: Invalid payment state transition: cannot transition from ${from} to ${to}`,
    );
  }
}

/**
 * Converts a major currency unit amount (e.g. ₹499) into integer minor units (e.g. 49900 paise).
 * Never compares floating-point money values directly.
 */
export function toMinorUnits(amountMajor: number): number {
  if (typeof amountMajor !== 'number' || !Number.isFinite(amountMajor) || amountMajor < 0) {
    throw new BadRequestException(
      `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Invalid monetary amount`,
    );
  }
  return Math.round(amountMajor * 100);
}

@Entity('payments')
export class PaymentEntity {
  @PrimaryColumn()
  id: string;

  @Column()
  bookingId: string;

  @Column({ nullable: true })
  quoteId?: string;

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
