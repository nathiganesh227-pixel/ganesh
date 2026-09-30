export interface CreatePaymentOrderOptions {
  bookingId: string;
  amount: number;
  currency?: string;
  receipt?: string;
  notes?: Record<string, any>;
}

export interface PaymentOrderResult {
  orderId: string;
  amount: number;
  amountInMinorUnits?: number;
  currency: string;
  provider: string;
  keyId?: string;
  status: 'CREATED' | 'PAID' | 'FAILED';
  raw?: any;
}

export interface VerifySignatureOptions {
  orderId: string;
  paymentId: string;
  signature: string;
}

export type ProviderPaymentStatus =
  | 'captured'
  | 'authorized'
  | 'created'
  | 'failed'
  | 'refunded';

export interface ProviderPaymentDetails {
  paymentId: string;
  orderId: string;
  amount: number;
  amountInMinorUnits: number;
  currency: string;
  status: ProviderPaymentStatus;
  captured: boolean;
  method?: string;
  notes?: Record<string, any>;
}

export interface RefundOptions {
  paymentId: string;
  amount: number;
  reason?: string;
}

export interface RefundResult {
  refundId: string;
  paymentId: string;
  amount: number;
  status: 'REFUNDED' | 'FAILED';
  timestamp: string;
  raw?: any;
}

export interface IPaymentProvider {
  readonly providerName: string;

  /**
   * Create an external order / payment intent with the provider
   */
  createOrder(options: CreatePaymentOrderOptions): Promise<PaymentOrderResult>;

  /**
   * Cryptographically verify an inbound webhook signature (e.g. HMAC-SHA256)
   */
  verifyWebhookSignature(rawBody: string | Buffer, signature: string, secret?: string): boolean;

  /**
   * Verify checkout completion signature from client
   */
  verifyPaymentSignature(options: VerifySignatureOptions, secret?: string): boolean;

  /**
   * Retrieve provider-side payment details (amount, currency, order_id, status)
   */
  fetchPaymentDetails?(
    paymentId: string,
    context?: {
      orderId?: string;
      expectedAmountMinorUnits?: number;
      expectedCurrency?: string;
    },
  ): Promise<ProviderPaymentDetails>;

  /**
   * Process a refund with the payment provider
   */
  refund(options: RefundOptions): Promise<RefundResult>;
}
