import { Injectable, Logger } from '@nestjs/common';
import {
  IPaymentProvider,
  CreatePaymentOrderOptions,
  PaymentOrderResult,
  VerifySignatureOptions,
  ProviderPaymentDetails,
  RefundOptions,
  RefundResult,
} from '../interfaces/payment-provider.interface';
import { toMinorUnits } from '../../../database/entities/payment.entity';
import * as crypto from 'crypto';

@Injectable()
export class SimulatedPaymentAdapter implements IPaymentProvider {
  readonly providerName = 'simulated';
  private readonly logger = new Logger(SimulatedPaymentAdapter.name);
  private readonly orderLedger = new Map<
    string,
    { orderId: string; bookingId: string; amount: number; amountInMinorUnits: number; currency: string }
  >();
  private readonly paymentLedger = new Map<string, ProviderPaymentDetails>();

  registerProviderPayment(details: ProviderPaymentDetails): void {
    this.paymentLedger.set(details.paymentId, {
      ...details,
      amountInMinorUnits:
        details.amountInMinorUnits !== undefined
          ? Math.round(details.amountInMinorUnits)
          : toMinorUnits(details.amount),
    });
  }

  async createOrder(options: CreatePaymentOrderOptions): Promise<PaymentOrderResult> {
    const orderId = `order_sim_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const amountInMinorUnits = toMinorUnits(options.amount);
    const currency = (options.currency || 'INR').trim().toUpperCase();

    this.orderLedger.set(orderId, {
      orderId,
      bookingId: options.bookingId,
      amount: options.amount,
      amountInMinorUnits,
      currency,
    });

    this.logger.log(`[Simulated] Created order ${orderId} for ₹${options.amount} (Booking: ${options.bookingId})`);

    return {
      orderId,
      amount: options.amount,
      amountInMinorUnits,
      currency,
      provider: this.providerName,
      status: 'PAID', // In simulation mode, instant settlement
      raw: { simulated: true, amountInMinorUnits, currency },
    };
  }

  async fetchPaymentDetails(
    paymentId: string,
    context?: {
      orderId?: string;
      expectedAmountMinorUnits?: number;
      expectedCurrency?: string;
    },
  ): Promise<ProviderPaymentDetails> {
    const registered = this.paymentLedger.get(paymentId);
    if (registered) {
      return registered;
    }

    if (context?.orderId) {
      const stored = this.orderLedger.get(context.orderId);
      if (stored) {
        return {
          paymentId,
          orderId: stored.orderId,
          amount: stored.amount,
          amountInMinorUnits: stored.amountInMinorUnits,
          currency: stored.currency,
          status: 'captured',
          captured: true,
        };
      }
    }

    const minorUnits = context?.expectedAmountMinorUnits ?? 0;
    return {
      paymentId,
      orderId: context?.orderId || '',
      amount: minorUnits / 100,
      amountInMinorUnits: minorUnits,
      currency: (context?.expectedCurrency || 'INR').toUpperCase(),
      status: 'captured',
      captured: true,
    };
  }

  verifyWebhookSignature(rawBody: string | Buffer, signature: string, secret = 'simulated_webhook_secret'): boolean {
    const trimmedSig = typeof signature === 'string' ? signature.trim() : '';
    const trimmedSecret = typeof secret === 'string' ? secret.trim() : '';
    if (!trimmedSig || !trimmedSecret) return false;

    const expected = crypto
      .createHmac('sha256', trimmedSecret)
      .update(typeof rawBody === 'string' ? rawBody : rawBody.toString('utf8'))
      .digest('hex');

    try {
      const expectedBuf = Buffer.from(expected, 'hex');
      const sigBuf = Buffer.from(trimmedSig, 'hex');
      if (expectedBuf.length === 0 || expectedBuf.length !== sigBuf.length) return false;
      return crypto.timingSafeEqual(expectedBuf, sigBuf);
    } catch {
      return false;
    }
  }

  verifyPaymentSignature(options: VerifySignatureOptions, secret = 'simulated_key_secret'): boolean {
    const trimmedOrderId = typeof options?.orderId === 'string' ? options.orderId.trim() : '';
    const trimmedPaymentId = typeof options?.paymentId === 'string' ? options.paymentId.trim() : '';
    const trimmedSig = typeof options?.signature === 'string' ? options.signature.trim() : '';
    const trimmedSecret = typeof secret === 'string' ? secret.trim() : '';

    if (!trimmedOrderId || !trimmedPaymentId || !trimmedSig || !trimmedSecret) {
      return false;
    }

    const data = `${trimmedOrderId}|${trimmedPaymentId}`;
    const expected = crypto.createHmac('sha256', trimmedSecret).update(data).digest('hex');

    try {
      const expectedBuf = Buffer.from(expected, 'hex');
      const sigBuf = Buffer.from(trimmedSig, 'hex');
      if (expectedBuf.length === 0 || expectedBuf.length !== sigBuf.length) return false;
      return crypto.timingSafeEqual(expectedBuf, sigBuf);
    } catch {
      return false;
    }
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
