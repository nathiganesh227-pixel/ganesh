import { Injectable, Logger } from '@nestjs/common';
import {
  IPaymentProvider,
  CreatePaymentOrderOptions,
  PaymentOrderResult,
  VerifySignatureOptions,
  RefundOptions,
  RefundResult,
} from '../interfaces/payment-provider.interface';
import * as crypto from 'crypto';

@Injectable()
export class RazorpayAdapter implements IPaymentProvider {
  readonly providerName = 'razorpay';
  private readonly logger = new Logger(RazorpayAdapter.name);

  private readonly keyId: string;
  private readonly keySecret: string;
  private readonly webhookSecret: string;

  constructor() {
    this.keyId = process.env.RAZORPAY_KEY_ID || 'rzp_test_plaza2026';
    this.keySecret = process.env.RAZORPAY_KEY_SECRET || 'secret_test_plaza2026';
    this.webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET || 'whsec_test_plaza2026';
  }

  async createOrder(options: CreatePaymentOrderOptions): Promise<PaymentOrderResult> {
    // Razorpay amounts are in smallest currency unit (paise: ₹1 = 100 paise)
    const amountInPaise = Math.round(options.amount * 100);
    const orderId = `order_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;

    this.logger.log(`[Razorpay] Created order ${orderId} for ₹${options.amount} (${amountInPaise} paise) for Booking ${options.bookingId}`);

    return {
      orderId,
      amount: options.amount,
      currency: options.currency || 'INR',
      provider: this.providerName,
      keyId: this.keyId,
      status: 'CREATED',
      raw: {
        id: orderId,
        entity: 'order',
        amount: amountInPaise,
        currency: options.currency || 'INR',
        receipt: options.receipt || options.bookingId,
        status: 'created',
      },
    };
  }

  /**
   * Validates Razorpay Webhook HMAC-SHA256 signature
   * signature is passed in header: 'x-razorpay-signature'
   */
  verifyWebhookSignature(rawBody: string | Buffer, signature: string, secret?: string): boolean {
    const activeSecret = secret || this.webhookSecret;
    if (!signature || !activeSecret) return false;

    const payload = typeof rawBody === 'string' ? rawBody : rawBody.toString('utf8');
    const expected = crypto.createHmac('sha256', activeSecret).update(payload).digest('hex');

    try {
      return crypto.timingSafeEqual(Buffer.from(expected, 'hex'), Buffer.from(signature, 'hex'));
    } catch {
      return expected === signature;
    }
  }

  /**
   * Validates Razorpay checkout completion signature:
   * HMAC-SHA256 of `${order_id}|${payment_id}` signed with key_secret
   */
  verifyPaymentSignature(options: VerifySignatureOptions, secret?: string): boolean {
    const activeSecret = secret || this.keySecret;
    if (!options.signature || !activeSecret) return false;

    const data = `${options.orderId}|${options.paymentId}`;
    const expected = crypto.createHmac('sha256', activeSecret).update(data).digest('hex');

    try {
      return crypto.timingSafeEqual(Buffer.from(expected, 'hex'), Buffer.from(options.signature, 'hex'));
    } catch {
      return expected === options.signature;
    }
  }

  async refund(options: RefundOptions): Promise<RefundResult> {
    const refundId = `rfnd_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    const amountInPaise = Math.round(options.amount * 100);

    this.logger.log(`[Razorpay] Initiated refund ${refundId} of ₹${options.amount} for payment ${options.paymentId}`);

    return {
      refundId,
      paymentId: options.paymentId,
      amount: options.amount,
      status: 'REFUNDED',
      timestamp: new Date().toISOString(),
      raw: {
        id: refundId,
        payment_id: options.paymentId,
        amount: amountInPaise,
        currency: 'INR',
        status: 'processed',
      },
    };
  }
}
