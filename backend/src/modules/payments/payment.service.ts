import {
  Injectable,
  Logger,
  BadRequestException,
  ServiceUnavailableException,
  Optional,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RazorpayAdapter } from './providers/razorpay.adapter';
import { SimulatedPaymentAdapter } from './providers/simulated-payment.adapter';
import { IPaymentProvider, RefundResult } from './interfaces/payment-provider.interface';
import { PaymentEntity, PaymentStatus } from '../../database/entities/payment.entity';
import {
  PaymentConfigService,
  PaymentMode,
  PaymentConfigStatus,
  SafePaymentConfigSummary,
} from './payment-config.service';

export interface PaymentIntent {
  paymentId: string;
  bookingId: string;
  amount: number;
  currency: string;
  status: 'PENDING' | 'COMPLETED' | 'FAILED';
  transactionRef: string;
  timestamp: string;
  provider: string;
  orderId?: string;
  keyId?: string;
}

@Injectable()
export class PaymentService {
  private readonly logger = new Logger(PaymentService.name);
  private readonly configService: PaymentConfigService;

  constructor(
    private readonly razorpayAdapter: RazorpayAdapter,
    private readonly simulatedAdapter: SimulatedPaymentAdapter,
    @Optional()
    @InjectRepository(PaymentEntity)
    private readonly paymentRepo?: Repository<PaymentEntity>,
    @Optional()
    private readonly paymentConfigService?: PaymentConfigService,
  ) {
    this.configService = this.paymentConfigService ?? new PaymentConfigService();
    const summary = this.configService.validateConfiguration();
    this.logger.log(
      `[PaymentService] Initialized with paymentMode=${summary.paymentMode}, status=${summary.paymentConfigStatus}, liveEnabled=${summary.razorpayLiveEnabled}`,
    );
  }

  getConfigService(): PaymentConfigService {
    return this.configService;
  }

  getSafeConfigSummary(): SafePaymentConfigSummary {
    return this.configService.getSafeSummary();
  }

  /**
   * Deterministically resolves the active payment provider.
   * NEVER falls back from RAZORPAY to SIMULATED when live payments are disabled or misconfigured.
   */
  private resolveActiveProvider(): IPaymentProvider {
    const summary = this.configService.validateConfiguration();

    if (summary.paymentMode === PaymentMode.SIMULATED) {
      if (summary.razorpayLiveEnabled) {
        throw new ServiceUnavailableException(
          'Payment configuration conflict: live Razorpay cannot be enabled in SIMULATED mode',
        );
      }
      return this.simulatedAdapter;
    }

    if (summary.paymentMode === PaymentMode.RAZORPAY) {
      this.configService.assertRazorpayLiveOperationAllowed();
      return this.razorpayAdapter;
    }

    throw new ServiceUnavailableException('Unsupported payment mode');
  }

  getProvider(): IPaymentProvider {
    return this.resolveActiveProvider();
  }

  getRazorpayAdapter(): RazorpayAdapter {
    return this.razorpayAdapter;
  }

  getPaymentRepo(): Repository<PaymentEntity> | undefined {
    return this.paymentRepo;
  }

  /**
   * Unified payment processor supporting both simulated and external gateway orders
   */
  async processPayment(
    bookingId: string,
    amount: number,
    paymentMethod = 'UPI_FAST',
    userId = 'usr_default_1',
  ): Promise<PaymentIntent> {
    if (amount < 0) {
      throw new BadRequestException('Payment amount cannot be negative');
    }

    if (amount === 0) {
      // Even for complimentary bookings, ensure configuration itself is valid
      const summary = this.configService.validateConfiguration();
      if (
        summary.paymentMode === PaymentMode.RAZORPAY &&
        summary.paymentConfigStatus === PaymentConfigStatus.RAZORPAY_MISCONFIGURED
      ) {
        throw new ServiceUnavailableException('Razorpay payment configuration is incomplete');
      }

      const paymentId = `PAY_FREE_${Date.now()}`;
      if (this.paymentRepo) {
        const payment = this.paymentRepo.create({
          id: paymentId,
          bookingId,
          userId,
          amount: 0,
          currency: 'INR',
          provider: 'complimentary',
          status: PaymentStatus.CAPTURED,
          paymentMethod: 'COMPLIMENTARY',
          metadata: { complimentary: true },
        });
        await this.paymentRepo.save(payment);
      }

      return {
        paymentId,
        bookingId,
        amount: 0,
        currency: 'INR',
        status: 'COMPLETED',
        transactionRef: `TXN_COMPLIMENTARY_${Date.now()}`,
        timestamp: new Date().toISOString(),
        provider: 'complimentary',
      };
    }

    const activeProvider = this.resolveActiveProvider();

    const order = await activeProvider.createOrder({
      bookingId,
      amount,
      currency: 'INR',
      receipt: bookingId,
      notes: { bookingId, paymentMethod, userId },
    });

    const paymentId = `PAY_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const transactionRef = `TXN_${paymentMethod.toUpperCase()}_${order.orderId}`;
    const isSimulated = activeProvider.providerName === 'simulated';

    if (this.paymentRepo) {
      const payment = this.paymentRepo.create({
        id: paymentId,
        bookingId,
        userId,
        amount,
        currency: 'INR',
        provider: activeProvider.providerName,
        providerOrderId: order.orderId,
        status: isSimulated ? PaymentStatus.CAPTURED : PaymentStatus.CREATED,
        paymentMethod,
        metadata: {
          orderId: order.orderId,
          receipt: bookingId,
          notes: { bookingId, paymentMethod, userId },
        },
      });
      await this.paymentRepo.save(payment);
    }

    return {
      paymentId,
      bookingId,
      amount,
      currency: 'INR',
      status: 'COMPLETED',
      transactionRef,
      timestamp: new Date().toISOString(),
      provider: activeProvider.providerName,
      orderId: order.orderId,
      keyId: order.keyId,
    };
  }

  /**
   * Verify checkout signature (HMAC-SHA256 for Razorpay)
   */
  async verifyPayment(options: {
    bookingId: string;
    orderId: string;
    paymentId: string;
    signature: string;
    secret?: string;
  }): Promise<{ success: boolean; payment?: PaymentEntity; reason?: string }> {
    const activeProvider = this.resolveActiveProvider();

    let paymentRecord: PaymentEntity | undefined;
    if (this.paymentRepo) {
      paymentRecord =
        (await this.paymentRepo.findOne({
          where: [
            { bookingId: options.bookingId },
            { providerOrderId: options.orderId },
            { id: options.paymentId },
          ],
        })) ?? undefined;

      if (paymentRecord) {
        if (
          paymentRecord.status === PaymentStatus.FAILED ||
          paymentRecord.status === PaymentStatus.REFUNDED ||
          paymentRecord.status === PaymentStatus.REFUND_PENDING
        ) {
          throw new BadRequestException(
            `Invalid payment state transition: cannot transition from ${paymentRecord.status} to CAPTURED`,
          );
        }

        if (
          paymentRecord.provider &&
          paymentRecord.provider !== activeProvider.providerName &&
          paymentRecord.provider !== 'complimentary'
        ) {
          throw new BadRequestException(
            `Payment mode mismatch: cannot verify ${paymentRecord.provider} payment while in ${activeProvider.providerName} mode`,
          );
        }
      }
    }

    const isValid = activeProvider.verifyPaymentSignature(
      {
        orderId: options.orderId,
        paymentId: options.paymentId,
        signature: options.signature,
      },
      options.secret,
    );

    if (!isValid) {
      this.logger.warn(
        `[PaymentService] Invalid signature for payment ${options.paymentId}, order ${options.orderId}`,
      );
      return { success: false, reason: 'Invalid payment signature' };
    }

    if (this.paymentRepo && paymentRecord) {
      paymentRecord.status = PaymentStatus.CAPTURED;
      paymentRecord.providerPaymentId = options.paymentId;
      paymentRecord.providerSignature = options.signature;
      paymentRecord.metadata = {
        ...paymentRecord.metadata,
        capturedAt: new Date().toISOString(),
        verification: 'HMAC_SHA256_VERIFIED',
      };
      await this.paymentRepo.save(paymentRecord);
    }

    this.logger.log(`[PaymentService] Payment verified successfully for booking ${options.bookingId}`);
    return { success: true, payment: paymentRecord };
  }

  /**
   * Record payment failure
   */
  async markPaymentFailed(bookingId: string, reason: string): Promise<PaymentEntity | null> {
    if (!this.paymentRepo) return null;
    const payment = await this.paymentRepo.findOne({ where: { bookingId } });
    if (payment) {
      if (
        payment.status === PaymentStatus.CAPTURED ||
        payment.status === PaymentStatus.REFUNDED ||
        payment.status === PaymentStatus.REFUND_PENDING
      ) {
        throw new BadRequestException(
          `Invalid payment state transition: cannot transition from ${payment.status} to FAILED`,
        );
      }
      payment.status = PaymentStatus.FAILED;
      payment.failureReason = reason;
      await this.paymentRepo.save(payment);
      this.logger.log(`[PaymentService] Payment for booking ${bookingId} marked as FAILED (${reason})`);
      return payment;
    }
    return null;
  }

  /**
   * Unified refund processor with active gateway delegation
   */
  async processRefund(
    paymentId: string,
    amount: number,
    reason = 'Booking cancelled by user',
  ): Promise<RefundResult> {
    const activeProvider = this.resolveActiveProvider();

    let payment: PaymentEntity | null = null;
    if (this.paymentRepo) {
      payment = await this.paymentRepo.findOne({
        where: [
          { id: paymentId },
          { providerPaymentId: paymentId },
          { bookingId: paymentId },
        ],
      });

      if (payment) {
        if (
          payment.status === PaymentStatus.REFUNDED ||
          payment.status === PaymentStatus.REFUND_PENDING
        ) {
          throw new BadRequestException(
            `Invalid payment state transition: payment is already in ${payment.status} state`,
          );
        }
        if (payment.status === PaymentStatus.FAILED) {
          throw new BadRequestException(
            'Invalid payment state transition: cannot refund a FAILED payment',
          );
        }
      }
    }

    const result = await activeProvider.refund({
      paymentId,
      amount,
      reason,
    });

    if (this.paymentRepo && payment) {
      payment.status = PaymentStatus.REFUNDED;
      payment.refundAmount = amount;
      payment.refundId = result.refundId;
      payment.metadata = {
        ...payment.metadata,
        refund: result,
      };
      await this.paymentRepo.save(payment);
    }

    return result;
  }
}
