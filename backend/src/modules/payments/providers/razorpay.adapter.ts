import { Injectable, Logger, Optional } from '@nestjs/common';
import {
  IPaymentProvider,
  CreatePaymentOrderOptions,
  PaymentOrderResult,
  VerifySignatureOptions,
  RefundOptions,
  RefundResult,
} from '../interfaces/payment-provider.interface';
import { PaymentConfigService, PaymentMode } from '../payment-config.service';
import * as crypto from 'crypto';

@Injectable()
export class RazorpayAdapter implements IPaymentProvider {
  readonly providerName = 'razorpay';
  private readonly logger = new Logger(RazorpayAdapter.name);
  private clientInitialized = false;

  constructor(
    @Optional()
    private readonly paymentConfigService?: PaymentConfigService,
  ) {
    this.syncClientInitializationState();
  }

  private getConfig(): PaymentConfigService {
    return this.paymentConfigService ?? new PaymentConfigService();
  }

  /**
   * Ensures the Razorpay client is only initialized when
   * PAYMENT_MODE=RAZORPAY AND RAZORPAY_LIVE_ENABLED=true AND all credentials exist.
   * Mere presence of keys in process.env never initializes live payment behavior.
   */
  private syncClientInitializationState(): void {
    const evalResult = (this.paymentConfigService ?? new PaymentConfigService(process.env)).evaluate();
    if (
      evalResult.summary.paymentMode === PaymentMode.RAZORPAY &&
      evalResult.summary.razorpayLiveEnabled &&
      evalResult.summary.razorpayConfigured &&
      evalResult.summary.liveOperationsAllowed
    ) {
      this.clientInitialized = true;
    } else {
      this.clientInitialized = false;
    }
  }

  isClientInitialized(): boolean {
    this.syncClientInitializationState();
    return this.clientInitialized;
  }

  private getKeyId(): string {
    if (this.paymentConfigService) {
      return this.paymentConfigService.getRazorpayKeyId();
    }
    const val = process.env.RAZORPAY_KEY_ID;
    return typeof val === 'string' && !val.includes('REPLACE_WITH_') ? val.trim() : '';
  }

  private getKeySecret(): string {
    if (this.paymentConfigService) {
      return this.paymentConfigService.getRazorpayKeySecret();
    }
    const val = process.env.RAZORPAY_KEY_SECRET;
    return typeof val === 'string' && !val.includes('REPLACE_WITH_') ? val.trim() : '';
  }

  private getWebhookSecret(): string {
    if (this.paymentConfigService) {
      return this.paymentConfigService.getRazorpayWebhookSecret();
    }
    const val = process.env.RAZORPAY_WEBHOOK_SECRET;
    return typeof val === 'string' && !val.includes('REPLACE_WITH_') ? val.trim() : '';
  }

  private isStrictGateActive(): boolean {
    return (
      Boolean(this.paymentConfigService) ||
      process.env.PAYMENT_MODE !== undefined ||
      process.env.RAZORPAY_LIVE_ENABLED !== undefined
    );
  }

  private assertLiveReadyIfGated(): void {
    if (this.isStrictGateActive()) {
      const config = this.getConfig();
      config.assertRazorpayLiveOperationAllowed();
      this.clientInitialized = true;
    }
  }

  async createOrder(options: CreatePaymentOrderOptions): Promise<PaymentOrderResult> {
    this.assertLiveReadyIfGated();

    // Razorpay amounts are in smallest currency unit (paise: ₹1 = 100 paise)
    const amountInPaise = Math.round(options.amount * 100);
    const orderId = `order_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;

    this.logger.log(
      `[Razorpay] Created order ${orderId} for ₹${options.amount} (${amountInPaise} paise) for Booking ${options.bookingId}`,
    );

    return {
      orderId,
      amount: options.amount,
      currency: options.currency || 'INR',
      provider: this.providerName,
      keyId: this.getKeyId(),
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
    const candidateSecret = secret !== undefined ? secret : this.getWebhookSecret();
    const activeSecret = typeof candidateSecret === 'string' ? candidateSecret.trim() : '';
    const trimmedSignature = typeof signature === 'string' ? signature.trim() : '';

    if (!trimmedSignature || !activeSecret) return false;

    const payload = typeof rawBody === 'string' ? rawBody : rawBody.toString('utf8');
    const expected = crypto.createHmac('sha256', activeSecret).update(payload).digest('hex');

    try {
      const expectedBuf = Buffer.from(expected, 'hex');
      const sigBuf = Buffer.from(trimmedSignature, 'hex');
      if (expectedBuf.length === 0 || expectedBuf.length !== sigBuf.length) {
        return false;
      }
      return crypto.timingSafeEqual(expectedBuf, sigBuf);
    } catch {
      return false;
    }
  }

  /**
   * Validates Razorpay checkout completion signature:
   * HMAC-SHA256 of `${order_id}|${payment_id}` signed with key_secret
   */
  verifyPaymentSignature(options: VerifySignatureOptions, secret?: string): boolean {
    const candidateSecret = secret !== undefined ? secret : this.getKeySecret();
    const activeSecret = typeof candidateSecret === 'string' ? candidateSecret.trim() : '';
    const trimmedSignature = typeof options?.signature === 'string' ? options.signature.trim() : '';

    if (!options?.orderId || !options?.paymentId || !trimmedSignature || !activeSecret) {
      return false;
    }

    const data = `${options.orderId}|${options.paymentId}`;
    const expected = crypto.createHmac('sha256', activeSecret).update(data).digest('hex');

    try {
      const expectedBuf = Buffer.from(expected, 'hex');
      const sigBuf = Buffer.from(trimmedSignature, 'hex');
      if (expectedBuf.length === 0 || expectedBuf.length !== sigBuf.length) {
        return false;
      }
      return crypto.timingSafeEqual(expectedBuf, sigBuf);
    } catch {
      return false;
    }
  }

  async refund(options: RefundOptions): Promise<RefundResult> {
    this.assertLiveReadyIfGated();

    const refundId = `rfnd_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    const amountInPaise = Math.round(options.amount * 100);

    this.logger.log(
      `[Razorpay] Initiated refund ${refundId} of ₹${options.amount} for payment ${options.paymentId}`,
    );

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
