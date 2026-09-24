import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { RazorpayAdapter } from './providers/razorpay.adapter';
import { SimulatedPaymentAdapter } from './providers/simulated-payment.adapter';
import { IPaymentProvider, PaymentOrderResult, RefundResult } from './interfaces/payment-provider.interface';

export interface PaymentIntent {
  paymentId: string;
  bookingId: string;
  amount: number;
  currency: string;
  status: 'PENDING' | 'COMPLETED' | 'FAILED';
  transactionRef: string;
  timestamp: string;
  provider: string;
}

@Injectable()
export class PaymentService {
  private readonly logger = new Logger(PaymentService.name);
  private readonly activeProvider: IPaymentProvider;

  constructor(
    private readonly razorpayAdapter: RazorpayAdapter,
    private readonly simulatedAdapter: SimulatedPaymentAdapter,
  ) {
    const providerType = process.env.PAYMENT_PROVIDER || 'razorpay';
    if (providerType === 'razorpay') {
      this.activeProvider = this.razorpayAdapter;
    } else {
      this.activeProvider = this.simulatedAdapter;
    }
    this.logger.log(`[PaymentService] Initialized with active provider: ${this.activeProvider.providerName}`);
  }

  getProvider(): IPaymentProvider {
    return this.activeProvider;
  }

  getRazorpayAdapter(): RazorpayAdapter {
    return this.razorpayAdapter;
  }

  /**
   * Unified payment processor supporting both simulated and external gateway orders
   */
  async processPayment(
    bookingId: string,
    amount: number,
    paymentMethod = 'UPI_FAST',
  ): Promise<PaymentIntent> {
    if (amount < 0) {
      throw new BadRequestException('Payment amount cannot be negative');
    }

    if (amount === 0) {
      return {
        paymentId: `PAY_FREE_${Date.now()}`,
        bookingId,
        amount: 0,
        currency: 'INR',
        status: 'COMPLETED',
        transactionRef: `TXN_COMPLIMENTARY_${Date.now()}`,
        timestamp: new Date().toISOString(),
        provider: 'complimentary',
      };
    }

    const order = await this.activeProvider.createOrder({
      bookingId,
      amount,
      currency: 'INR',
      receipt: bookingId,
      notes: { bookingId, paymentMethod },
    });

    const paymentId = `PAY_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const transactionRef = `TXN_${paymentMethod.toUpperCase()}_${order.orderId}`;

    return {
      paymentId,
      bookingId,
      amount,
      currency: 'INR',
      status: 'COMPLETED',
      transactionRef,
      timestamp: new Date().toISOString(),
      provider: this.activeProvider.providerName,
    };
  }

  /**
   * Unified refund processor with active gateway delegation
   */
  async processRefund(
    paymentId: string,
    amount: number,
    reason = 'Booking cancelled by user',
  ): Promise<RefundResult> {
    return this.activeProvider.refund({
      paymentId,
      amount,
      reason,
    });
  }
}
