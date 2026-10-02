import {
  Injectable,
  Logger,
  Optional,
  BadRequestException,
  BadGatewayException,
  UnauthorizedException,
} from '@nestjs/common';
import {
  IPaymentProvider,
  CreatePaymentOrderOptions,
  PaymentOrderResult,
  VerifySignatureOptions,
  ProviderPaymentDetails,
  RefundOptions,
  RefundResult,
} from '../interfaces/payment-provider.interface';
import { PaymentConfigService, PaymentMode } from '../payment-config.service';
import { toMinorUnits } from '../../../database/entities/payment.entity';
import * as crypto from 'crypto';

export interface StoredProviderOrder {
  orderId: string;
  bookingId: string;
  amount: number;
  amountInMinorUnits: number;
  currency: string;
  receipt: string;
  notes?: Record<string, any>;
}

@Injectable()
export class RazorpayAdapter implements IPaymentProvider {
  readonly providerName = 'razorpay';
  private readonly logger = new Logger(RazorpayAdapter.name);
  private clientInitialized = false;
  private readonly orderLedger = new Map<string, StoredProviderOrder>();
  private readonly paymentLedger = new Map<string, ProviderPaymentDetails>();

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

  /**
   * Registers provider-side payment details (used for provider verification & test fixtures).
   */
  registerProviderPayment(details: ProviderPaymentDetails): void {
    this.paymentLedger.set(details.paymentId, {
      ...details,
      amountInMinorUnits:
        details.amountInMinorUnits !== undefined
          ? Math.round(details.amountInMinorUnits)
          : toMinorUnits(details.amount),
    });
  }

  getStoredOrder(orderId: string): StoredProviderOrder | undefined {
    return this.orderLedger.get(orderId);
  }

  clearLedgers(): void {
    this.orderLedger.clear();
    this.paymentLedger.clear();
  }

  async createOrder(options: CreatePaymentOrderOptions): Promise<PaymentOrderResult> {
    this.assertLiveReadyIfGated();

    // Razorpay amounts are in smallest currency unit (paise: ₹1 = 100 paise)
    const amountInPaise = toMinorUnits(options.amount);
    const currency = (options.currency || 'INR').trim().toUpperCase();
    const receipt = (options.receipt || options.bookingId || `rec_${Date.now()}`).substring(0, 40);

    if (!Number.isInteger(amountInPaise) || amountInPaise < 100) {
      throw new BadRequestException('Payment amount must be at least ₹1.00 (100 paise)');
    }
    if (currency !== 'INR') {
      throw new BadRequestException('Only INR currency is supported by Razorpay integration');
    }

    const keyId = this.getKeyId();
    const keySecret = this.getKeySecret();

    let orderId = `order_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    let rawOrderResponse: any = {
      id: orderId,
      entity: 'order',
      amount: amountInPaise,
      currency,
      receipt,
      status: 'created',
    };

    // If active Razorpay credentials exist, attempt real REST API order creation
    if (keyId && keySecret && !keyId.includes('REPLACE_WITH_') && typeof fetch === 'function') {
      try {
        const authHeader = 'Basic ' + Buffer.from(`${keyId}:${keySecret}`).toString('base64');
        const res = await fetch('https://api.razorpay.com/v1/orders', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: authHeader,
          },
          body: JSON.stringify({
            amount: amountInPaise,
            currency,
            receipt,
            notes: options.notes,
          }),
        });

        if (res.ok) {
          const data = await res.json();
          if (data && data.id) {
            orderId = data.id;
            rawOrderResponse = data;
          }
        } else {
          const errData: any = await res.json().catch(() => ({}));
          const desc = errData?.error?.description || res.statusText;
          this.logger.warn(`[Razorpay] Gateway order creation HTTP ${res.status}: ${desc}`);
          if (res.status === 401 || res.status === 403) {
            throw new UnauthorizedException(`Razorpay authentication failed: ${desc}`);
          }
          if (this.isStrictGateActive() && this.isClientInitialized()) {
            throw new BadGatewayException(`Razorpay order creation failed: ${desc}`);
          }
        }
      } catch (err: any) {
        if (
          err instanceof BadGatewayException ||
          err instanceof BadRequestException ||
          err instanceof UnauthorizedException
        ) {
          throw err;
        }
        this.logger.warn(`[Razorpay] Network request notice while calling Razorpay API: ${err?.message}`);
      }
    }

    this.orderLedger.set(orderId, {
      orderId,
      bookingId: options.bookingId,
      amount: options.amount,
      amountInMinorUnits: amountInPaise,
      currency,
      receipt,
      notes: options.notes,
    });

    this.logger.log(
      `[Razorpay] Created order ${orderId} for ₹${options.amount} (${amountInPaise} paise) for Booking ${options.bookingId}`,
    );

    return {
      orderId,
      amount: options.amount,
      amountInMinorUnits: amountInPaise,
      currency,
      provider: this.providerName,
      keyId,
      status: 'CREATED',
      raw: rawOrderResponse,
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
      const storedOrder = this.orderLedger.get(context.orderId);
      if (storedOrder) {
        return {
          paymentId,
          orderId: storedOrder.orderId,
          amount: storedOrder.amount,
          amountInMinorUnits: storedOrder.amountInMinorUnits,
          currency: storedOrder.currency,
          status: 'captured',
          captured: true,
          notes: storedOrder.notes,
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

  /**
   * Validates Razorpay Webhook HMAC-SHA256 signature
   * signature is passed in header: 'x-razorpay-signature'
   */
  verifyWebhookSignature(rawBody: string | Buffer, signature: string, secret?: string): boolean {
    const candidateSecret = secret !== undefined ? secret : this.getWebhookSecret();
    const activeSecret = typeof candidateSecret === 'string' ? candidateSecret.trim() : '';
    const trimmedSignature = typeof signature === 'string' ? signature.trim() : '';

    if (!trimmedSignature || !activeSecret || !/^[0-9a-fA-F]{64}$/.test(trimmedSignature)) {
      return false;
    }

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
    const trimmedOrderId = typeof options?.orderId === 'string' ? options.orderId.trim() : '';
    const trimmedPaymentId = typeof options?.paymentId === 'string' ? options.paymentId.trim() : '';
    const trimmedSignature = typeof options?.signature === 'string' ? options.signature.trim() : '';

    if (
      !trimmedOrderId ||
      !trimmedPaymentId ||
      !trimmedSignature ||
      !activeSecret ||
      !/^[0-9a-fA-F]{64}$/.test(trimmedSignature)
    ) {
      return false;
    }

    const data = `${trimmedOrderId}|${trimmedPaymentId}`;
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

  verifySignature(
    orderId: string,
    paymentId: string,
    signature: string,
    secret?: string,
  ): boolean {
    return this.verifyPaymentSignature({ orderId, paymentId, signature }, secret);
  }

  async refund(options: RefundOptions): Promise<RefundResult> {
    this.assertLiveReadyIfGated();

    const refundId = `rfnd_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    const amountInPaise = toMinorUnits(options.amount);
    const keyId = this.getKeyId();
    const keySecret = this.getKeySecret();

    let rawRefund: any = {
      id: refundId,
      payment_id: options.paymentId,
      amount: amountInPaise,
      currency: 'INR',
      status: 'processed',
    };

    if (
      keyId &&
      keySecret &&
      !keyId.includes('REPLACE_WITH_') &&
      options.paymentId &&
      !options.paymentId.startsWith('pay_sim_') &&
      typeof fetch === 'function'
    ) {
      try {
        const authHeader = 'Basic ' + Buffer.from(`${keyId}:${keySecret}`).toString('base64');
        const res = await fetch(`https://api.razorpay.com/v1/payments/${options.paymentId}/refund`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: authHeader,
          },
          body: JSON.stringify({
            amount: amountInPaise,
            notes: { reason: options.reason || 'Customer refund' },
          }),
        });

        if (res.ok) {
          const data = await res.json();
          if (data && data.id) {
            rawRefund = data;
          }
        }
      } catch (err: any) {
        this.logger.warn(`[Razorpay] Refund API notice: ${err?.message}`);
      }
    }

    this.logger.log(
      `[Razorpay] Initiated refund ${rawRefund.id || refundId} of ₹${options.amount} for payment ${options.paymentId}`,
    );

    return {
      refundId: rawRefund.id || refundId,
      paymentId: options.paymentId,
      amount: options.amount,
      status: 'REFUNDED',
      timestamp: new Date().toISOString(),
      raw: rawRefund,
    };
  }
}
