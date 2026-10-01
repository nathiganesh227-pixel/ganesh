import {
  Injectable,
  Logger,
  BadRequestException,
  ForbiddenException,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
  ServiceUnavailableException,
  Optional,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RazorpayAdapter } from './providers/razorpay.adapter';
import { SimulatedPaymentAdapter } from './providers/simulated-payment.adapter';
import { IdempotencyService } from '../bookings/idempotency.service';
import {
  IPaymentProvider,
  ProviderPaymentDetails,
  RefundResult,
} from './interfaces/payment-provider.interface';
import {
  PaymentEntity,
  PaymentStatus,
  PaymentErrorCode,
  assertValidPaymentStateTransition,
  toMinorUnits,
} from '../../database/entities/payment.entity';
import {
  PaymentConfigService,
  PaymentMode,
  PaymentConfigStatus,
  SafePaymentConfigSummary,
} from './payment-config.service';

export interface PaymentIntent {
  paymentId: string;
  bookingId: string;
  quoteId?: string;
  amount: number;
  amountInMinorUnits?: number;
  currency: string;
  status: 'PENDING' | 'COMPLETED' | 'FAILED';
  transactionRef: string;
  timestamp: string;
  provider: string;
  orderId?: string;
  keyId?: string;
}

export interface CanonicalQuoteRecord {
  quote: {
    quoteId: string;
    userId?: string;
    bookingId?: string;
    type: string;
    vertical: string;
    subtotal: number;
    discount: number;
    taxes: number;
    tax: number;
    convenienceFee: number;
    fees: number;
    total: number;
    grandTotal: number;
    amountInMinorUnits?: number;
    currency: string;
    expiresAt: string;
    breakdown?: Record<string, any>;
    items?: any[];
  };
  userId?: string;
  bookingId?: string;
  canonicalTotal: number;
  canonicalTotalMinorUnits: number;
  canonicalSubtotalMinorUnits: number;
  canonicalDiscountMinorUnits: number;
  canonicalTaxesMinorUnits: number;
  canonicalFeeMinorUnits: number;
  canonicalCurrency: string;
  status: 'ACTIVE' | 'CONSUMED' | 'CANCELLED';
  consumedByPaymentId?: string;
  consumedByBookingId?: string;
  createdAt: number;
  expiresAt: number;
}

export interface CreateServerPaymentOrderInput {
  quoteId: string;
  bookingId?: string;
  userId: string;
  paymentMethod?: string;
  idempotencyKey?: string;
  // Client-provided financial fields are non-authoritative and validated/ignored for order creation
  clientAmount?: number;
  clientCurrency?: string;
  amount?: number;
  price?: number;
  total?: number;
  subtotal?: number;
  discount?: number;
  tax?: number;
  fee?: number;
  currency?: string;
}

export interface ServerPaymentOrderResponse {
  paymentId: string;
  quoteId: string;
  bookingId: string;
  orderId: string;
  providerOrderId: string;
  amount: number;
  amountInMinorUnits: number;
  currency: string;
  provider: string;
  paymentMode: string;
  status: PaymentStatus;
  keyId?: string;
  merchantName: string;
  description: string;
  expiresAt: string;
  idempotentReplay: boolean;
}

@Injectable()
export class PaymentService {
  private readonly logger = new Logger(PaymentService.name);
  private readonly configService: PaymentConfigService;
  private readonly quoteRegistry = new Map<string, CanonicalQuoteRecord>();

  constructor(
    private readonly razorpayAdapter: RazorpayAdapter,
    private readonly simulatedAdapter: SimulatedPaymentAdapter,
    @Optional()
    @InjectRepository(PaymentEntity)
    private readonly paymentRepo?: Repository<PaymentEntity>,
    @Optional()
    private readonly paymentConfigService?: PaymentConfigService,
    @Optional()
    private readonly idempotencyService?: IdempotencyService,
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
   * Registers a server-generated quote in the canonical payment quote registry
   * with an immutable snapshot of its financial values in integer minor units.
   */
  registerQuote(
    quote: CanonicalQuoteRecord['quote'],
    options?: { userId?: string; bookingId?: string; createdAt?: number; expiresAt?: number },
  ): CanonicalQuoteRecord {
    const canonicalCurrency = 'INR';
    const canonicalTotal = Number(quote.grandTotal ?? quote.total ?? 0);
    const canonicalTotalMinorUnits = toMinorUnits(canonicalTotal);
    const canonicalSubtotalMinorUnits = toMinorUnits(Number(quote.subtotal ?? 0));
    const canonicalDiscountMinorUnits = toMinorUnits(Number(quote.discount ?? 0));
    const canonicalTaxesMinorUnits = toMinorUnits(Number(quote.taxes ?? quote.tax ?? 0));
    const canonicalFeeMinorUnits = toMinorUnits(Number(quote.convenienceFee ?? quote.fees ?? 0));

    quote.currency = canonicalCurrency;
    quote.total = canonicalTotal;
    quote.grandTotal = canonicalTotal;
    quote.amountInMinorUnits = canonicalTotalMinorUnits;

    const expiresAtMs =
      options?.expiresAt ??
      (quote.expiresAt ? Date.parse(quote.expiresAt) : Date.now() + 15 * 60 * 1000);

    const record: CanonicalQuoteRecord = {
      quote,
      userId: options?.userId ?? quote.userId,
      bookingId: options?.bookingId ?? quote.bookingId,
      canonicalTotal,
      canonicalTotalMinorUnits,
      canonicalSubtotalMinorUnits,
      canonicalDiscountMinorUnits,
      canonicalTaxesMinorUnits,
      canonicalFeeMinorUnits,
      canonicalCurrency,
      status: 'ACTIVE',
      createdAt: options?.createdAt ?? Date.now(),
      expiresAt: expiresAtMs,
    };

    this.quoteRegistry.set(quote.quoteId, record);
    return record;
  }

  getQuoteRecord(quoteId: string): CanonicalQuoteRecord | undefined {
    return this.quoteRegistry.get(quoteId);
  }

  cancelQuote(quoteId: string): void {
    const record = this.quoteRegistry.get(quoteId);
    if (record) {
      record.status = 'CANCELLED';
    }
  }

  expireQuote(quoteId: string): void {
    const record = this.quoteRegistry.get(quoteId);
    if (record) {
      record.expiresAt = Date.now() - 1000;
      record.quote.expiresAt = new Date(record.expiresAt).toISOString();
    }
  }

  markQuoteConsumed(quoteId: string, paymentId?: string, bookingId?: string): void {
    const record = this.quoteRegistry.get(quoteId);
    if (record) {
      record.status = 'CONSUMED';
      record.consumedByPaymentId = paymentId;
      record.consumedByBookingId = bookingId;
    }
  }

  /**
   * Validates quote existence, ownership, expiry, consumption state, and financial integrity.
   */
  validateCanonicalQuote(
    quoteId: string,
    context?: {
      userId?: string;
      bookingId?: string;
      expectedTotalMajor?: number;
      clientTotalMajor?: number;
      clientCurrency?: string;
      allowConsumedByPaymentId?: string;
      allowConsumedByBookingId?: string;
    },
  ): CanonicalQuoteRecord {
    if (!quoteId || typeof quoteId !== 'string' || !quoteId.trim()) {
      throw new BadRequestException(
        `${PaymentErrorCode.QUOTE_NOT_FOUND}: Missing or invalid quoteId`,
      );
    }

    const record = this.quoteRegistry.get(quoteId.trim());
    if (!record) {
      throw new BadRequestException(
        `${PaymentErrorCode.QUOTE_NOT_FOUND}: Pricing quote has expired or is invalid. Please recalculate your quote.`,
      );
    }

    // 1. Verify ownership
    if (
      context?.userId &&
      record.userId &&
      record.userId !== 'usr_default_1' &&
      record.userId !== 'user_default' &&
      record.userId !== context.userId
    ) {
      throw new ForbiddenException(
        `${PaymentErrorCode.QUOTE_NOT_OWNED}: Quote belongs to another user`,
      );
    }

    // 2. Verify booking association if quote is already bound to a booking
    if (
      context?.bookingId &&
      record.bookingId &&
      record.bookingId !== context.bookingId
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.QUOTE_BOOKING_MISMATCH}: Quote is associated with a different booking`,
      );
    }

    // 3. Verify quote state (cancelled / already consumed)
    if (record.status === 'CANCELLED') {
      throw new BadRequestException(
        `${PaymentErrorCode.QUOTE_CANCELLED}: Pricing quote has been cancelled`,
      );
    }

    if (record.status === 'CONSUMED') {
      const samePayment =
        context?.allowConsumedByPaymentId &&
        record.consumedByPaymentId === context.allowConsumedByPaymentId;
      const sameBooking =
        context?.allowConsumedByBookingId &&
        record.consumedByBookingId === context.allowConsumedByBookingId;
      if (!samePayment && !sameBooking) {
        throw new BadRequestException(
          `${PaymentErrorCode.QUOTE_ALREADY_CONSUMED}: Pricing quote has already been consumed`,
        );
      }
    }

    // 4. Verify quote expiry
    const quoteExpiresAtMs = record.quote.expiresAt
      ? Date.parse(record.quote.expiresAt)
      : record.expiresAt;
    if (Date.now() > record.expiresAt || (Number.isFinite(quoteExpiresAtMs) && Date.now() > quoteExpiresAtMs)) {
      throw new BadRequestException(
        `${PaymentErrorCode.QUOTE_EXPIRED}: Pricing quote has expired. Please recalculate your quote.`,
      );
    }

    // 5. Verify quote integrity against immutable snapshot
    const currentGrandTotalMinor = toMinorUnits(Number(record.quote.grandTotal ?? 0));
    const currentTotalMinor = toMinorUnits(Number(record.quote.total ?? 0));
    const currentSubtotalMinor = toMinorUnits(Number(record.quote.subtotal ?? 0));
    const currentDiscountMinor = toMinorUnits(Number(record.quote.discount ?? 0));
    const currentTaxesMinor = toMinorUnits(Number(record.quote.taxes ?? record.quote.tax ?? 0));
    const currentFeeMinor = toMinorUnits(Number(record.quote.convenienceFee ?? record.quote.fees ?? 0));
    const currentCurrency = String(record.quote.currency || '').trim().toUpperCase();

    if (
      currentGrandTotalMinor !== record.canonicalTotalMinorUnits ||
      currentTotalMinor !== record.canonicalTotalMinorUnits ||
      currentSubtotalMinor !== record.canonicalSubtotalMinorUnits ||
      currentDiscountMinor !== record.canonicalDiscountMinorUnits ||
      currentTaxesMinor !== record.canonicalTaxesMinorUnits ||
      currentFeeMinor !== record.canonicalFeeMinorUnits
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.QUOTE_TAMPERED}: Pricing quote totals have been altered`,
      );
    }

    if (currentCurrency !== record.canonicalCurrency) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH}: Quote currency mismatch`,
      );
    }

    // 6. Verify against server-recalculated total or client-submitted total if provided
    if (
      context?.expectedTotalMajor !== undefined &&
      toMinorUnits(context.expectedTotalMajor) !== record.canonicalTotalMinorUnits
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Calculated price differs from quote. Pricing may have updated.`,
      );
    }

    if (
      context?.clientTotalMajor !== undefined &&
      toMinorUnits(context.clientTotalMajor) !== record.canonicalTotalMinorUnits
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Submitted total does not match quote total.`,
      );
    }

    if (
      context?.clientCurrency !== undefined &&
      String(context.clientCurrency).trim().toUpperCase() !== record.canonicalCurrency
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH}: Submitted currency does not match quote currency.`,
      );
    }

    return record;
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
   * Safely sets providerOrderId on a PaymentEntity, preventing accidental or malicious reassignment.
   */
  assignProviderOrderId(payment: PaymentEntity, providerOrderId: string): void {
    const trimmed = typeof providerOrderId === 'string' ? providerOrderId.trim() : '';
    if (!trimmed) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_ORDER_MISMATCH}: Provider order ID cannot be empty`,
      );
    }
    if (payment.providerOrderId && payment.providerOrderId !== trimmed) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_ORDER_MISMATCH}: Cannot reassign providerOrderId on payment ${payment.id}`,
      );
    }
    payment.providerOrderId = trimmed;
  }

  /**
   * Safely sets providerPaymentId on a PaymentEntity, preventing dangerous reassignment.
   */
  assignProviderPaymentId(payment: PaymentEntity, providerPaymentId: string): void {
    const trimmed = typeof providerPaymentId === 'string' ? providerPaymentId.trim() : '';
    if (!trimmed) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_ID_MISMATCH}: Provider payment ID cannot be empty`,
      );
    }
    if (payment.providerPaymentId && payment.providerPaymentId !== trimmed) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_ID_MISMATCH}: Cannot overwrite providerPaymentId on payment ${payment.id}`,
      );
    }
    payment.providerPaymentId = trimmed;
  }

  /**
   * Canonical server-authoritative payment order creation from a verified quote.
   * Client-supplied amount, price, total, subtotal, discount, tax, fee, and currency
   * are NEVER trusted or used for financial authorization.
   */
  async createPaymentOrder(
    input: CreateServerPaymentOrderInput,
  ): Promise<ServerPaymentOrderResponse> {
    if (!input?.userId || typeof input.userId !== 'string' || !input.userId.trim()) {
      throw new UnauthorizedException('Authenticated user is required to create a payment order');
    }

    const userId = input.userId.trim();
    const quoteRecord = this.validateCanonicalQuote(input.quoteId, {
      userId,
      bookingId: input.bookingId,
      clientTotalMajor: input.clientAmount,
      clientCurrency: input.clientCurrency ?? input.currency,
    });

    // Bind quote ownership and bookingId if not yet bound
    if (!quoteRecord.userId) {
      quoteRecord.userId = userId;
      quoteRecord.quote.userId = userId;
    }
    const effectiveBookingId =
      input.bookingId || quoteRecord.bookingId || `BK_QUO_${quoteRecord.quote.quoteId}`;
    if (!quoteRecord.bookingId && input.bookingId) {
      quoteRecord.bookingId = input.bookingId;
      quoteRecord.quote.bookingId = input.bookingId;
    }

    // Canonical server-derived money values (client amount/currency NEVER override these)
    const canonicalAmount = quoteRecord.canonicalTotal;
    const canonicalAmountMinorUnits = quoteRecord.canonicalTotalMinorUnits;
    const canonicalCurrency = quoteRecord.canonicalCurrency;

    // Reject negative or zero client-supplied amounts on paid bookings
    if (canonicalAmount > 0) {
      for (const candidate of [input.amount, input.price, input.total, input.clientAmount]) {
        if (candidate !== undefined && (!Number.isFinite(Number(candidate)) || Number(candidate) <= 0)) {
          throw new BadRequestException(
            `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Payment amount must be greater than zero for a paid booking`,
          );
        }
      }
    }

    const activeProvider = this.resolveActiveProvider();
    const paymentMode = this.configService.getPaymentMode();
    const expiresAtIso =
      quoteRecord.quote.expiresAt || new Date(quoteRecord.expiresAt).toISOString();

    // Canonical idempotency check via IdempotencyService
    const requestPayload = {
      quoteId: input.quoteId,
      bookingId: input.bookingId,
      paymentMethod: input.paymentMethod || 'RAZORPAY_CHECKOUT',
    };
    const effectiveIdempotencyKey =
      input.idempotencyKey || `payment:create:${userId}:${quoteRecord.quote.quoteId}`;

    if (this.idempotencyService) {
      const cached = await this.idempotencyService.get(
        userId,
        effectiveIdempotencyKey,
        requestPayload,
      );
      if (cached && (cached as any).idempotentReplay && (cached as any).orderId) {
        this.logger.log(
          `[PaymentService] Returning cached idempotent order ${(cached as any).orderId} for key ${effectiveIdempotencyKey}`,
        );
        return cached as ServerPaymentOrderResponse;
      }
    }

    // Check if an existing compatible payment order already exists for this quote/booking
    if (this.paymentRepo) {
      let existing = await this.paymentRepo.findOne({
        where: { quoteId: quoteRecord.quote.quoteId },
      });
      if (!existing && input.bookingId) {
        existing = await this.paymentRepo.findOne({
          where: { bookingId: input.bookingId },
        });
      }

      if (existing) {
        if (existing.userId && existing.userId !== 'usr_default_1' && existing.userId !== userId) {
          throw new ForbiddenException(
            `${PaymentErrorCode.PAYMENT_NOT_OWNED}: Payment record belongs to another user`,
          );
        }

        if (existing.status === PaymentStatus.CAPTURED) {
          throw new BadRequestException(
            `${PaymentErrorCode.PAYMENT_ALREADY_CAPTURED}: Payment for this quote/booking is already CAPTURED`,
          );
        }

        if (
          (existing.status === PaymentStatus.PENDING || existing.status === PaymentStatus.CREATED) &&
          existing.providerOrderId &&
          existing.provider === activeProvider.providerName &&
          toMinorUnits(existing.amount) === canonicalAmountMinorUnits &&
          existing.currency.toUpperCase() === canonicalCurrency
        ) {
          if (existing.status === PaymentStatus.CREATED) {
            assertValidPaymentStateTransition(PaymentStatus.CREATED, PaymentStatus.PENDING);
            existing.status = PaymentStatus.PENDING;
            await this.paymentRepo.save(existing);
          }

          this.logger.log(
            `[PaymentService] Returning existing compatible order ${existing.providerOrderId} for quote ${quoteRecord.quote.quoteId}`,
          );

          const existingResponse: ServerPaymentOrderResponse = {
            paymentId: existing.id,
            quoteId: quoteRecord.quote.quoteId,
            bookingId: existing.bookingId,
            orderId: existing.providerOrderId,
            providerOrderId: existing.providerOrderId,
            amount: canonicalAmount,
            amountInMinorUnits: canonicalAmountMinorUnits,
            currency: canonicalCurrency,
            provider: existing.provider,
            paymentMode,
            status: existing.status,
            keyId:
              paymentMode === PaymentMode.RAZORPAY
                ? this.configService.getRazorpayKeyId()
                : undefined,
            merchantName: 'PLAZA',
            description: `PLAZA ${(quoteRecord.quote.type || 'Booking').toUpperCase()} Booking`,
            expiresAt: expiresAtIso,
            idempotentReplay: true,
          };

          if (this.idempotencyService) {
            await this.idempotencyService.save(
              userId,
              effectiveIdempotencyKey,
              '/payments/orders',
              existingResponse,
              {
                requestPayload,
                operation: 'payment:create',
                resourceId: existing.id,
              },
            );
          }

          return existingResponse;
        }
      }
    }

    const order = await activeProvider.createOrder({
      bookingId: effectiveBookingId,
      amount: canonicalAmount,
      currency: canonicalCurrency,
      receipt: effectiveBookingId,
      notes: {
        quoteId: quoteRecord.quote.quoteId,
        bookingId: effectiveBookingId,
        userId,
        paymentMethod: input.paymentMethod || 'RAZORPAY_CHECKOUT',
      },
    });

    const paymentId = `PAY_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;

    // Enforce canonical state transition CREATED -> PENDING upon order creation
    const initialStatus = PaymentStatus.CREATED;
    assertValidPaymentStateTransition(initialStatus, PaymentStatus.PENDING);
    const nextStatus = PaymentStatus.PENDING;

    if (this.paymentRepo) {
      const payment = this.paymentRepo.create({
        id: paymentId,
        bookingId: effectiveBookingId,
        quoteId: quoteRecord.quote.quoteId,
        userId,
        amount: canonicalAmount,
        currency: canonicalCurrency,
        provider: activeProvider.providerName,
        status: nextStatus,
        paymentMethod: input.paymentMethod || 'RAZORPAY_CHECKOUT',
        metadata: {
          quoteId: quoteRecord.quote.quoteId,
          orderId: order.orderId,
          amountInMinorUnits: canonicalAmountMinorUnits,
          currency: canonicalCurrency,
          receipt: effectiveBookingId,
        },
      });
      this.assignProviderOrderId(payment, order.orderId);
      await this.paymentRepo.save(payment);
    }

    this.logger.log(
      `[PaymentService] Created payment order ${order.orderId} (paymentId=${paymentId}, quoteId=${quoteRecord.quote.quoteId}, amount=${canonicalAmount} ${canonicalCurrency})`,
    );

    const newResponse: ServerPaymentOrderResponse = {
      paymentId,
      quoteId: quoteRecord.quote.quoteId,
      bookingId: effectiveBookingId,
      orderId: order.orderId,
      providerOrderId: order.orderId,
      amount: canonicalAmount,
      amountInMinorUnits: canonicalAmountMinorUnits,
      currency: canonicalCurrency,
      provider: activeProvider.providerName,
      paymentMode,
      status: nextStatus,
      keyId: order.keyId,
      merchantName: 'PLAZA',
      description: `PLAZA ${(quoteRecord.quote.type || 'Booking').toUpperCase()} Booking`,
      expiresAt: expiresAtIso,
      idempotentReplay: false,
    };

    if (this.idempotencyService) {
      await this.idempotencyService.save(
        userId,
        effectiveIdempotencyKey,
        '/payments/orders',
        newResponse,
        {
          requestPayload,
          operation: 'payment:create',
          resourceId: paymentId,
        },
      );
    }

    return newResponse;
  }

  /**
   * Unified payment processor supporting both simulated and external gateway orders
   */
  async processPayment(
    bookingId: string,
    amount: number,
    paymentMethod = 'UPI_FAST',
    userId = 'usr_default_1',
    quoteId?: string,
  ): Promise<PaymentIntent> {
    let canonicalAmount = amount;
    let canonicalCurrency = 'INR';

    if (quoteId) {
      const quoteRecord = this.validateCanonicalQuote(quoteId, {
        userId,
        bookingId,
      });
      if (!quoteRecord.userId) {
        quoteRecord.userId = userId;
      }
      if (!quoteRecord.bookingId) {
        quoteRecord.bookingId = bookingId;
      }
      canonicalAmount = quoteRecord.canonicalTotal;
      canonicalCurrency = quoteRecord.canonicalCurrency;
    }

    if (canonicalAmount < 0) {
      throw new BadRequestException('Payment amount cannot be negative');
    }

    if (canonicalAmount === 0) {
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
          quoteId,
          userId,
          amount: 0,
          currency: canonicalCurrency,
          provider: 'complimentary',
          status: PaymentStatus.CAPTURED,
          paymentMethod: 'COMPLIMENTARY',
          metadata: { complimentary: true, quoteId },
        });
        await this.paymentRepo.save(payment);
      }

      if (quoteId) {
        this.markQuoteConsumed(quoteId, paymentId, bookingId);
      }

      return {
        paymentId,
        bookingId,
        quoteId,
        amount: 0,
        amountInMinorUnits: 0,
        currency: canonicalCurrency,
        status: 'COMPLETED',
        transactionRef: `TXN_COMPLIMENTARY_${Date.now()}`,
        timestamp: new Date().toISOString(),
        provider: 'complimentary',
      };
    }

    const activeProvider = this.resolveActiveProvider();

    const order = await activeProvider.createOrder({
      bookingId,
      amount: canonicalAmount,
      currency: canonicalCurrency,
      receipt: bookingId,
      notes: { bookingId, quoteId, paymentMethod, userId },
    });

    const paymentId = `PAY_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const transactionRef = `TXN_${paymentMethod.toUpperCase()}_${order.orderId}`;
    const isSimulated = activeProvider.providerName === 'simulated';
    const amountInMinorUnits = toMinorUnits(canonicalAmount);

    if (this.paymentRepo) {
      const payment = this.paymentRepo.create({
        id: paymentId,
        bookingId,
        quoteId,
        userId,
        amount: canonicalAmount,
        currency: canonicalCurrency,
        provider: activeProvider.providerName,
        providerOrderId: order.orderId,
        status: isSimulated ? PaymentStatus.CAPTURED : PaymentStatus.PENDING,
        paymentMethod,
        metadata: {
          quoteId,
          orderId: order.orderId,
          amountInMinorUnits,
          receipt: bookingId,
          notes: { bookingId, quoteId, paymentMethod, userId },
        },
      });
      await this.paymentRepo.save(payment);
    }

    if (isSimulated && quoteId) {
      this.markQuoteConsumed(quoteId, paymentId, bookingId);
    }

    return {
      paymentId,
      bookingId,
      quoteId,
      amount: canonicalAmount,
      amountInMinorUnits,
      currency: canonicalCurrency,
      status: isSimulated ? 'COMPLETED' : 'PENDING',
      transactionRef,
      timestamp: new Date().toISOString(),
      provider: activeProvider.providerName,
      orderId: order.orderId,
      keyId: order.keyId,
    };
  }

  /**
   * Verify checkout signature (HMAC-SHA256 for Razorpay) and validate
   * amount, currency, order ID, payment ID, quote, user/booking association, and provider status.
   */
  async verifyPayment(options: {
    bookingId: string;
    orderId: string;
    paymentId: string;
    signature: string;
    quoteId?: string;
    userId?: string;
    amount?: number;
    amountInMinorUnits?: number;
    currency?: string;
    providerStatus?: string;
    secret?: string;
    idempotencyKey?: string;
  }): Promise<{
    success: boolean;
    idempotentReplay?: boolean;
    payment?: PaymentEntity;
    reason?: string;
  }> {
    const activeProvider = this.resolveActiveProvider();

    if (
      !options?.orderId?.trim() ||
      !options?.paymentId?.trim() ||
      !options?.signature?.trim()
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.INVALID_PAYMENT_SIGNATURE}: Missing required payment verification parameters`,
      );
    }

    const orderId = options.orderId.trim();
    const paymentId = options.paymentId.trim();
    const signature = options.signature.trim();
    const effectiveUserId = options.userId || 'usr_default_1';

    const requestPayload = {
      bookingId: options.bookingId,
      orderId,
      paymentId,
      signature,
      amount: options.amount,
      currency: options.currency,
    };

    const effectiveIdempotencyKey =
      options.idempotencyKey || `payment:verify:${orderId}:${paymentId}`;

    if (this.idempotencyService) {
      const cached = await this.idempotencyService.get(
        effectiveUserId,
        effectiveIdempotencyKey,
        requestPayload,
      );
      if (cached && (cached as any).idempotentReplay !== undefined) {
        this.logger.log(
          `[PaymentService] Returning cached idempotent payment verification for order ${orderId}`,
        );
        return cached as any;
      }
    }

    let paymentRecord: PaymentEntity | undefined;
    if (this.paymentRepo) {
      const byBooking = options.bookingId
        ? await this.paymentRepo.findOne({ where: { bookingId: options.bookingId } })
        : null;
      const byOrder = await this.paymentRepo.findOne({ where: { providerOrderId: orderId } });
      const byProviderPayment = await this.paymentRepo.findOne({
        where: { providerPaymentId: paymentId },
      });

      // Cross-payment / cross-order substitution checks
      if (byBooking && byOrder && byBooking.id !== byOrder.id) {
        throw new BadRequestException(
          `${PaymentErrorCode.PAYMENT_ORDER_MISMATCH}: Provider order belongs to a different payment record`,
        );
      }

      if (byBooking && byProviderPayment && byBooking.id !== byProviderPayment.id) {
        throw new BadRequestException(
          `${PaymentErrorCode.PAYMENT_ID_MISMATCH}: Provider payment ID belongs to a different payment record`,
        );
      }

      if (byOrder && byProviderPayment && byOrder.id !== byProviderPayment.id) {
        throw new BadRequestException(
          `${PaymentErrorCode.PAYMENT_ID_MISMATCH}: Provider payment ID is bound to a different order`,
        );
      }

      paymentRecord = (byBooking || byOrder || byProviderPayment) ?? undefined;

      if (paymentRecord) {
        // Verify booking association
        if (options.bookingId && paymentRecord.bookingId !== options.bookingId) {
          throw new BadRequestException(
            `${PaymentErrorCode.PAYMENT_BOOKING_MISMATCH}: Payment does not belong to booking ${options.bookingId}`,
          );
        }

        // Verify user ownership
        if (
          options.userId &&
          paymentRecord.userId &&
          paymentRecord.userId !== 'usr_default_1' &&
          paymentRecord.userId !== options.userId
        ) {
          throw new ForbiddenException(
            `${PaymentErrorCode.PAYMENT_NOT_OWNED}: Payment belongs to another user`,
          );
        }

        // Verify stored providerOrderId matches
        if (paymentRecord.providerOrderId && paymentRecord.providerOrderId !== orderId) {
          throw new BadRequestException(
            `${PaymentErrorCode.PAYMENT_ORDER_MISMATCH}: Provider order ID does not match stored payment order ID`,
          );
        }

        // Verify providerPaymentId is not reassigned to a different paymentId
        if (paymentRecord.providerPaymentId && paymentRecord.providerPaymentId !== paymentId) {
          throw new BadRequestException(
            `${PaymentErrorCode.PAYMENT_ID_MISMATCH}: Payment already bound to a different providerPaymentId`,
          );
        }

        // Handle already-CAPTURED idempotent replay vs invalid state transitions
        if (paymentRecord.status === PaymentStatus.CAPTURED) {
          const isValidReplaySig = activeProvider.verifyPaymentSignature(
            { orderId, paymentId, signature },
            options.secret,
          );
          if (!isValidReplaySig) {
            throw new UnauthorizedException(
              `${PaymentErrorCode.INVALID_PAYMENT_SIGNATURE}: Invalid payment signature on replay`,
            );
          }
          const replayResponse = {
            success: true,
            idempotentReplay: true,
            payment: paymentRecord,
          };
          if (this.idempotencyService) {
            await this.idempotencyService.save(
              effectiveUserId,
              effectiveIdempotencyKey,
              '/payments/verify',
              replayResponse,
              {
                requestPayload,
                operation: 'payment:verify',
                resourceId: paymentRecord.id,
              },
            );
          }
          return replayResponse;
        }

        // Reject terminal states (FAILED, REFUNDED, REFUND_PENDING, CANCELLED)
        if (paymentRecord.status === PaymentStatus.CREATED) {
          assertValidPaymentStateTransition(PaymentStatus.CREATED, PaymentStatus.PENDING);
          paymentRecord.status = PaymentStatus.PENDING;
        }
        assertValidPaymentStateTransition(paymentRecord.status, PaymentStatus.CAPTURED);

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

    // Validate associated quote if present
    const effectiveQuoteId =
      options.quoteId || paymentRecord?.quoteId || paymentRecord?.metadata?.quoteId;
    let quoteRecord: CanonicalQuoteRecord | undefined;
    if (effectiveQuoteId) {
      quoteRecord = this.validateCanonicalQuote(effectiveQuoteId, {
        userId: options.userId || paymentRecord?.userId,
        bookingId: options.bookingId || paymentRecord?.bookingId,
        allowConsumedByPaymentId: paymentRecord?.id,
        allowConsumedByBookingId: options.bookingId || paymentRecord?.bookingId,
      });
    }

    // Verify cryptographic signature first
    const isValid = activeProvider.verifyPaymentSignature(
      { orderId, paymentId, signature },
      options.secret,
    );

    if (!isValid) {
      this.logger.warn(
        `[PaymentService] Invalid signature for payment ${paymentId}, order ${orderId}`,
      );
      return {
        success: false,
        reason: `${PaymentErrorCode.INVALID_PAYMENT_SIGNATURE}: Invalid payment signature`,
      };
    }

    // Determine canonical expected amount (in minor units) and currency
    const expectedCurrency = (
      quoteRecord?.canonicalCurrency ||
      paymentRecord?.currency ||
      'INR'
    ).toUpperCase();
    const expectedAmountMinorUnits =
      quoteRecord?.canonicalTotalMinorUnits ??
      (paymentRecord ? toMinorUnits(paymentRecord.amount) : undefined);

    if (
      quoteRecord &&
      paymentRecord &&
      toMinorUnits(paymentRecord.amount) !== quoteRecord.canonicalTotalMinorUnits
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Stored payment amount does not match canonical quote amount`,
      );
    }

    if (
      quoteRecord &&
      paymentRecord &&
      paymentRecord.currency.toUpperCase() !== quoteRecord.canonicalCurrency
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH}: Stored payment currency does not match canonical quote currency`,
      );
    }

    // Verify client/caller passed amount or currency if present
    if (
      options.currency !== undefined &&
      String(options.currency).trim().toUpperCase() !== expectedCurrency
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH}: Currency mismatch (expected ${expectedCurrency})`,
      );
    }

    if (
      options.amount !== undefined &&
      expectedAmountMinorUnits !== undefined &&
      toMinorUnits(options.amount) !== expectedAmountMinorUnits
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Amount mismatch (expected ${expectedAmountMinorUnits} minor units)`,
      );
    }

    if (
      options.amountInMinorUnits !== undefined &&
      expectedAmountMinorUnits !== undefined &&
      Math.round(options.amountInMinorUnits) !== expectedAmountMinorUnits
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Amount in minor units mismatch`,
      );
    }

    // Fetch provider-side payment details where supported
    let providerDetails: ProviderPaymentDetails | undefined;
    if (typeof activeProvider.fetchPaymentDetails === 'function') {
      providerDetails = await activeProvider.fetchPaymentDetails(paymentId, {
        orderId,
        expectedAmountMinorUnits,
        expectedCurrency,
      });

      if (providerDetails.paymentId !== paymentId) {
        throw new BadRequestException(
          `${PaymentErrorCode.PAYMENT_ID_MISMATCH}: Provider payment ID mismatch`,
        );
      }

      if (providerDetails.orderId && providerDetails.orderId !== orderId) {
        throw new BadRequestException(
          `${PaymentErrorCode.PAYMENT_ORDER_MISMATCH}: Provider payment is linked to order ${providerDetails.orderId}, expected ${orderId}`,
        );
      }

      if (providerDetails.currency.toUpperCase() !== expectedCurrency) {
        throw new BadRequestException(
          `${PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH}: Provider payment currency ${providerDetails.currency} does not match canonical currency ${expectedCurrency}`,
        );
      }

      if (
        expectedAmountMinorUnits !== undefined &&
        providerDetails.amountInMinorUnits !== expectedAmountMinorUnits
      ) {
        throw new BadRequestException(
          `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Provider payment amount (${providerDetails.amountInMinorUnits}) does not match canonical amount (${expectedAmountMinorUnits})`,
        );
      }

      const effectiveStatus = (
        options.providerStatus ||
        providerDetails.status ||
        'captured'
      ).toLowerCase();
      if (effectiveStatus !== 'captured' && effectiveStatus !== 'authorized') {
        throw new BadRequestException(
          `${PaymentErrorCode.PAYMENT_NOT_VERIFIED}: Provider payment status '${effectiveStatus}' is not eligible for capture`,
        );
      }
    } else if (options.providerStatus) {
      const effectiveStatus = options.providerStatus.toLowerCase();
      if (effectiveStatus !== 'captured' && effectiveStatus !== 'authorized') {
        throw new BadRequestException(
          `${PaymentErrorCode.PAYMENT_NOT_VERIFIED}: Provider payment status '${effectiveStatus}' is not eligible for capture`,
        );
      }
    }

    if (this.paymentRepo && paymentRecord) {
      this.assignProviderOrderId(paymentRecord, orderId);
      this.assignProviderPaymentId(paymentRecord, paymentId);
      paymentRecord.status = PaymentStatus.CAPTURED;
      paymentRecord.providerSignature = 'HMAC_SHA256_VERIFIED';
      paymentRecord.metadata = {
        ...paymentRecord.metadata,
        capturedAt: new Date().toISOString(),
        verification: 'HMAC_SHA256_VERIFIED',
        verifiedAmountInMinorUnits: expectedAmountMinorUnits,
        verifiedCurrency: expectedCurrency,
      };
      await this.paymentRepo.save(paymentRecord);
    }

    if (quoteRecord) {
      this.markQuoteConsumed(
        quoteRecord.quote.quoteId,
        paymentRecord?.id || paymentId,
        options.bookingId || paymentRecord?.bookingId,
      );
    }

    this.logger.log(
      `[PaymentService] Payment verified successfully for booking ${options.bookingId} (orderId=${orderId}, paymentId=${paymentId})`,
    );

    const verificationResult = {
      success: true,
      payment: paymentRecord,
    };

    if (this.idempotencyService) {
      await this.idempotencyService.save(
        effectiveUserId,
        effectiveIdempotencyKey,
        '/payments/verify',
        verificationResult,
        {
          requestPayload,
          operation: 'payment:verify',
          resourceId: paymentRecord?.id || paymentId,
        },
      );
    }

    return verificationResult;
  }

  /**
   * Asserts that a booking's payment has been server-verified and CAPTURED.
   */
  async assertBookingPaymentVerified(
    bookingId: string,
    userId?: string,
  ): Promise<PaymentEntity> {
    if (!this.paymentRepo) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_NOT_VERIFIED}: Payment repository unavailable`,
      );
    }

    const payment = await this.paymentRepo.findOne({ where: { bookingId } });
    if (!payment) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_NOT_VERIFIED}: No payment record found for booking ${bookingId}`,
      );
    }

    if (
      userId &&
      payment.userId &&
      payment.userId !== 'usr_default_1' &&
      payment.userId !== userId
    ) {
      throw new ForbiddenException(
        `${PaymentErrorCode.PAYMENT_NOT_OWNED}: Payment belongs to another user`,
      );
    }

    if (payment.status !== PaymentStatus.CAPTURED) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_NOT_VERIFIED}: Payment for booking ${bookingId} is in ${payment.status} state and has not been verified/captured`,
      );
    }

    return payment;
  }

  /**
   * Record payment failure
   */
  async markPaymentFailed(bookingId: string, reason: string): Promise<PaymentEntity | null> {
    if (!this.paymentRepo) return null;
    const payment = await this.paymentRepo.findOne({ where: { bookingId } });
    if (payment) {
      assertValidPaymentStateTransition(payment.status, PaymentStatus.FAILED);
      payment.status = PaymentStatus.FAILED;
      payment.failureReason = reason;
      await this.paymentRepo.save(payment);
      this.logger.log(`[PaymentService] Payment for booking ${bookingId} marked as FAILED (${reason})`);
      return payment;
    }
    return null;
  }

  /**
   * Unified refund processor with active gateway delegation and full idempotency support.
   */
  async processRefund(
    paymentId: string,
    amount: number,
    reason = 'Booking cancelled by user',
    options?: {
      refundOperationId?: string;
      idempotencyKey?: string;
      userId?: string;
    },
  ): Promise<RefundResult & { idempotentReplay?: boolean }> {
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new BadRequestException(
        `${PaymentErrorCode.REFUND_AMOUNT_INVALID}: Refund amount must be greater than zero`,
      );
    }

    const effectiveUserId = options?.userId || 'usr_default_1';
    const refundOpId = options?.refundOperationId || options?.idempotencyKey;
    const effectiveIdempotencyKey =
      refundOpId || `payment:refund:${paymentId}:${amount}`;

    const requestPayload = {
      paymentId,
      amount,
      reason,
      refundOperationId: refundOpId,
    };

    if (this.idempotencyService) {
      const cached = await this.idempotencyService.get(
        effectiveUserId,
        effectiveIdempotencyKey,
        requestPayload,
      );
      if (cached && (cached as any).refundId) {
        this.logger.log(
          `[PaymentService] Returning cached idempotent refund ${(cached as any).refundId} for key ${effectiveIdempotencyKey}`,
        );
        return { ...(cached as RefundResult), idempotentReplay: true };
      }
    }

    const activeProvider = this.resolveActiveProvider();

    let payment: PaymentEntity | null = null;
    if (this.paymentRepo) {
      payment =
        (await this.paymentRepo.findOne({ where: { id: paymentId } })) ||
        (await this.paymentRepo.findOne({ where: { providerPaymentId: paymentId } })) ||
        (await this.paymentRepo.findOne({ where: { bookingId: paymentId } }));

      if (payment) {
        const targetAmountPaise = toMinorUnits(amount);
        const originalAmountPaise = toMinorUnits(payment.amount);
        const currentRefundedPaise = toMinorUnits(payment.refundAmount || 0);

        // Validate refund balance cannot exceed total payment amount
        if (currentRefundedPaise + targetAmountPaise > originalAmountPaise) {
          throw new BadRequestException(
            `${PaymentErrorCode.REFUND_AMOUNT_INVALID}: Refund amount (${amount}) exceeds remaining refundable balance (${(originalAmountPaise - currentRefundedPaise) / 100})`,
          );
        }

        if (
          payment.status === PaymentStatus.CAPTURED ||
          payment.status === PaymentStatus.AUTHORIZED
        ) {
          assertValidPaymentStateTransition(payment.status, PaymentStatus.REFUND_PENDING);
          payment.status = PaymentStatus.REFUND_PENDING;
          await this.paymentRepo.save(payment);
        } else if (payment.status !== PaymentStatus.REFUND_PENDING) {
          throw new BadRequestException(
            `${PaymentErrorCode.INVALID_PAYMENT_STATE_TRANSITION}: Cannot refund payment in ${payment.status} state`,
          );
        }
      }
    }

    const result = await activeProvider.refund({
      paymentId: payment?.providerPaymentId || paymentId,
      amount,
      reason,
    });

    if (this.paymentRepo && payment) {
      const targetAmountPaise = toMinorUnits(amount);
      const originalAmountPaise = toMinorUnits(payment.amount);
      const newRefundedPaise = toMinorUnits(payment.refundAmount || 0) + targetAmountPaise;

      if (newRefundedPaise >= originalAmountPaise) {
        assertValidPaymentStateTransition(PaymentStatus.REFUND_PENDING, PaymentStatus.REFUNDED);
        payment.status = PaymentStatus.REFUNDED;
      } else {
        assertValidPaymentStateTransition(PaymentStatus.REFUND_PENDING, PaymentStatus.CAPTURED);
        payment.status = PaymentStatus.CAPTURED;
      }

      payment.refundAmount = (payment.refundAmount || 0) + amount;
      payment.refundId = result.refundId;
      payment.metadata = {
        ...payment.metadata,
        refund: result,
        refundedAt: new Date().toISOString(),
        refundOperationId: refundOpId,
      };
      await this.paymentRepo.save(payment);
    }

    const finalResult = {
      ...result,
      idempotentReplay: false,
    };

    if (this.idempotencyService) {
      await this.idempotencyService.save(
        effectiveUserId,
        effectiveIdempotencyKey,
        '/payments/refund',
        finalResult,
        {
          requestPayload,
          operation: 'payment:refund',
          resourceId: payment?.id || paymentId,
        },
      );
    }

    return finalResult;
  }
}
