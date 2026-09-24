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
export class SimulatedPaymentAdapter implements IPaymentProvider {
  readonly providerName = 'simulated';
  private readonly logger = new Logger(SimulatedPaymentAdapter.name);

  async createOrder(options: CreatePaymentOrderOptions): Promise<PaymentOrderResult> {
    const orderId = `order_sim_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    this.logger.log(`[Simulated] Created order ${orderId} for ₹${options.amount} (Booking: ${options.bookingId})`);

    return {
      orderId,
      amount: options.amount,
      currency: options.currency || 'INR',
      provider: this.providerName,
      status: 'PAID', // In simulation mode, instant settlement
      raw: { simulated: true },
    };
  }

  verifyWebhookSignature(rawBody: string | Buffer, signature: string, secret: string): boolean {
    const expected = crypto
      .createHmac('sha256', secret)
      .update(typeof rawBody === 'string' ? rawBody : rawBody.toString('utf8'))
      .digest('hex');
    return expected === signature;
  }

  verifyPaymentSignature(options: VerifySignatureOptions, secret: string): boolean {
    const data = `${options.orderId}|${options.paymentId}`;
    const expected = crypto.createHmac('sha256', secret).update(data).digest('hex');
    return expected === options.signature;
  }

  async refund(options: RefundOptions): Promise<RefundResult> {
    const refundId = `rfnd_sim_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    this.logger.log(`[Simulated] Processed refund ${refundId} of ₹${options.amount} for payment ${options.paymentId}`);

    return {
      refundId,
      paymentId: options.paymentId,
      amount: options.amount,
      status: 'REFUNDED',
      timestamp: new Date().toISOString(),
    };
  }
}
