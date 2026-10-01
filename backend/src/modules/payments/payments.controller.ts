import {
  Controller,
  Post,
  Body,
  Request,
  Headers,
  UseGuards,
  UnauthorizedException,
  ForbiddenException,
  NotFoundException,
  BadRequestException,
  Logger,
  HttpCode,
  HttpStatus,
  Optional,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PaymentService } from './payment.service';
import { RazorpayAdapter } from './providers/razorpay.adapter';
import { IdempotencyService } from '../bookings/idempotency.service';
import {
  PaymentEntity,
  PaymentStatus,
  PaymentErrorCode,
  assertValidPaymentStateTransition,
  toMinorUnits,
} from '../../database/entities/payment.entity';
import { BookingEntity, BookingStatus, BookingType } from '../../database/entities/booking.entity';
import { User } from '../../database/entities/user.entity';
import { EventEntity } from '../../database/entities/event.entity';
import { ActivityEntity } from '../../database/entities/activity.entity';
import { TwilioSmsAdapter } from '../notifications/providers/twilio-sms.adapter';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

export class CreatePaymentOrderDto {
  quoteId: string;
  bookingId?: string;
  paymentMethod?: string;
  idempotencyKey?: string;
  // Informational / non-authoritative client fields (ignored by server for order creation)
  amount?: number;
  price?: number;
  total?: number;
  subtotal?: number;
  discount?: number;
  tax?: number;
  fee?: number;
  currency?: string;
}

export class VerifyPaymentDto {
  bookingId: string;
  razorpayOrderId: string;
  razorpayPaymentId: string;
  razorpaySignature: string;
  quoteId?: string;
  userId?: string;
  amount?: number;
  amountInMinorUnits?: number;
  currency?: string;
  providerStatus?: string;
  idempotencyKey?: string;
}

export class PaymentFailedDto {
  bookingId: string;
  reason?: string;
}

import { PaymentRecoveryService } from './payment-recovery.service';
import { FailureCategory, RecoveryStatus } from '../../database/entities/payment-recovery.entity';

@ApiTags('payments')
@Controller('payments')
export class PaymentsController {
  private readonly logger = new Logger(PaymentsController.name);

  constructor(
    private readonly paymentService: PaymentService,
    private readonly razorpayAdapter: RazorpayAdapter,
    @InjectRepository(BookingEntity)
    private readonly bookingRepo: Repository<BookingEntity>,
    @InjectRepository(PaymentEntity)
    private readonly paymentRepo: Repository<PaymentEntity>,
    @Optional()
    @InjectRepository(User)
    private readonly userRepo?: Repository<User>,
    @Optional()
    @InjectRepository(EventEntity)
    private readonly eventRepo?: Repository<EventEntity>,
    @Optional()
    @InjectRepository(ActivityEntity)
    private readonly activityRepo?: Repository<ActivityEntity>,
    @Optional()
    private readonly notificationAdapter?: TwilioSmsAdapter,
    @Optional()
    private readonly idempotencyService?: IdempotencyService,
    @Optional()
    private readonly recoveryService?: PaymentRecoveryService,
  ) {}

  @Post('orders')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Create server-authoritative payment order from canonical quote',
  })
  async createPaymentOrder(
    @Body() body: CreatePaymentOrderDto,
    @Request() req?: any,
    @Headers('idempotency-key') idempotencyKeyHeader?: string,
    @Headers('x-idempotency-key') xIdempotencyKeyHeader?: string,
  ) {
    const jwtUserId = req?.user?.sub || req?.user?.id;
    if (!jwtUserId) {
      throw new UnauthorizedException('Authentication token is required to create a payment order');
    }

    if (body?.bookingId) {
      const booking = await this.bookingRepo.findOne({ where: { id: body.bookingId } });
      if (!booking) {
        throw new NotFoundException(
          `${PaymentErrorCode.PAYMENT_NOT_FOUND}: Booking #${body.bookingId} not found`,
        );
      }
      if (
        booking.userId &&
        booking.userId !== 'user_default' &&
        booking.userId !== 'usr_default_1' &&
        booking.userId !== jwtUserId
      ) {
        throw new ForbiddenException(
          `${PaymentErrorCode.PAYMENT_NOT_OWNED}: Booking belongs to another user`,
        );
      }
    }

    const effectiveIdempotencyKey =
      idempotencyKeyHeader || xIdempotencyKeyHeader || body?.idempotencyKey;

    return this.paymentService.createPaymentOrder({
      quoteId: body?.quoteId,
      bookingId: body?.bookingId,
      userId: jwtUserId,
      paymentMethod: body?.paymentMethod,
      amount: body?.amount,
      price: body?.price,
      total: body?.total,
      subtotal: body?.subtotal,
      discount: body?.discount,
      tax: body?.tax,
      fee: body?.fee,
      currency: body?.currency,
      idempotencyKey: effectiveIdempotencyKey,
    });
  }

  @Post('verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Cryptographically verify Razorpay checkout completion signature and confirm booking',
  })
  async verifyPayment(
    @Body() body: VerifyPaymentDto,
    @Request() req?: any,
    @Headers('idempotency-key') idempotencyKeyHeader?: string,
    @Headers('x-idempotency-key') xIdempotencyKeyHeader?: string,
  ) {
    const {
      bookingId,
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature,
      quoteId,
      amount,
      amountInMinorUnits,
      currency,
      providerStatus,
    } = body || ({} as VerifyPaymentDto);

    if (
      !bookingId?.trim() ||
      !razorpayOrderId?.trim() ||
      !razorpayPaymentId?.trim() ||
      !razorpaySignature?.trim()
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.INVALID_PAYMENT_SIGNATURE}: Missing required payment verification parameters`,
      );
    }

    if (
      process.env.PAYMENT_MODE === 'RAZORPAY' &&
      String(process.env.RAZORPAY_LIVE_ENABLED || '').trim().toLowerCase() !== 'true'
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.RAZORPAY_LIVE_DISABLED}: Razorpay live payments are disabled (RAZORPAY_LIVE_DISABLED). Simulated fallback is forbidden.`,
      );
    }

    // Never trust client-supplied userId when authenticated JWT identity is present
    const jwtUserId = req?.user?.sub || req?.user?.id;
    if (jwtUserId && body.userId && body.userId !== jwtUserId) {
      throw new ForbiddenException(
        `${PaymentErrorCode.PAYMENT_NOT_OWNED}: Authenticated user does not match request userId`,
      );
    }
    const effectiveUserId = jwtUserId || body.userId;

    const effectiveIdempotencyKey =
      idempotencyKeyHeader || xIdempotencyKeyHeader || body.idempotencyKey;

    const requestPayload = {
      bookingId,
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature,
      quoteId,
      amount,
      amountInMinorUnits,
      currency,
    };

    if (this.idempotencyService && effectiveIdempotencyKey) {
      const cached = await this.idempotencyService.get(
        effectiveUserId || 'usr_default_1',
        effectiveIdempotencyKey,
        requestPayload,
      );
      if (cached) {
        this.logger.log(
          `[PaymentVerify] Returning cached idempotent verification for booking ${bookingId}`,
        );
        return { ...(cached as any), idempotentReplay: true };
      }
    }

    // 1. Verify HMAC-SHA256 signature using server-side secret
    const isValid = this.razorpayAdapter.verifyPaymentSignature({
      orderId: razorpayOrderId,
      paymentId: razorpayPaymentId,
      signature: razorpaySignature,
    });

    if (!isValid) {
      this.logger.warn(
        `[PaymentVerify] Invalid HMAC signature for payment ${razorpayPaymentId}, order ${razorpayOrderId}`,
      );
      if (this.recoveryService) {
        await this.recoveryService.recordIncident({
          resourceType: 'payment',
          resourceId: razorpayPaymentId,
          bookingId,
          providerOrderId: razorpayOrderId,
          providerPaymentId: razorpayPaymentId,
          failureCategory: FailureCategory.AUTHORIZATION_FAILURE,
          safeFailureReason: 'Invalid payment signature verification failed',
        });
      }
      throw new UnauthorizedException(
        `${PaymentErrorCode.INVALID_PAYMENT_SIGNATURE}: Invalid payment signature verification failed`,
      );
    }

    // 2. Fetch booking & validate user ownership
    const booking = await this.bookingRepo.findOne({ where: { id: bookingId } });
    if (!booking) {
      throw new NotFoundException(
        `${PaymentErrorCode.PAYMENT_NOT_FOUND}: Booking #${bookingId} not found`,
      );
    }

    if (
      effectiveUserId &&
      booking.userId &&
      booking.userId !== 'user_default' &&
      booking.userId !== 'usr_default_1' &&
      booking.userId !== effectiveUserId
    ) {
      throw new ForbiddenException(
        `${PaymentErrorCode.PAYMENT_NOT_OWNED}: Booking #${bookingId} belongs to another user`,
      );
    }

    // 3. Lookup payment records & detect cross-payment / cross-order substitution
    const byBooking = await this.paymentRepo.findOne({ where: { bookingId } });
    const byOrder = await this.paymentRepo.findOne({
      where: { providerOrderId: razorpayOrderId },
    });
    const byPaymentId = await this.paymentRepo.findOne({
      where: { providerPaymentId: razorpayPaymentId },
    });

    if (byBooking && byOrder && byBooking.id !== byOrder.id) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_ORDER_MISMATCH}: Provider order belongs to another payment record`,
      );
    }

    if (byBooking && byPaymentId && byBooking.id !== byPaymentId.id) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_ID_MISMATCH}: Provider payment ID belongs to another payment record`,
      );
    }

    if (byOrder && byPaymentId && byOrder.id !== byPaymentId.id) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_ID_MISMATCH}: Provider payment ID belongs to another order`,
      );
    }

    let payment = byBooking || byOrder || byPaymentId;

    if (payment) {
      if (payment.bookingId && payment.bookingId !== bookingId) {
        throw new BadRequestException(
          `${PaymentErrorCode.PAYMENT_BOOKING_MISMATCH}: Payment does not belong to booking #${bookingId}`,
        );
      }

      if (
        effectiveUserId &&
        payment.userId &&
        payment.userId !== 'usr_default_1' &&
        payment.userId !== effectiveUserId
      ) {
        throw new ForbiddenException(
          `${PaymentErrorCode.PAYMENT_NOT_OWNED}: Payment belongs to another user`,
        );
      }

      if (
        payment.userId &&
        booking.userId &&
        payment.userId !== 'usr_default_1' &&
        booking.userId !== 'user_default' &&
        payment.userId !== booking.userId
      ) {
        throw new ForbiddenException(
          `${PaymentErrorCode.PAYMENT_NOT_OWNED}: Payment user does not match booking user`,
        );
      }

      if (payment.providerOrderId && payment.providerOrderId !== razorpayOrderId) {
        throw new BadRequestException(
          `${PaymentErrorCode.PAYMENT_ORDER_MISMATCH}: Provider order ID does not match stored payment order ID`,
        );
      }

      if (payment.providerPaymentId && payment.providerPaymentId !== razorpayPaymentId) {
        throw new BadRequestException(
          `${PaymentErrorCode.PAYMENT_ID_MISMATCH}: Cannot overwrite existing providerPaymentId on payment`,
        );
      }
    }

    if (
      booking.metadata?.payment?.orderId &&
      booking.metadata.payment.orderId !== razorpayOrderId
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_ORDER_MISMATCH}: Provider order ID does not match booking order ID`,
      );
    }

    if (
      booking.metadata?.paymentVerified &&
      booking.metadata?.payment?.paymentId &&
      booking.metadata.payment.paymentId !== razorpayPaymentId
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_ID_MISMATCH}: Cannot overwrite verified providerPaymentId on booking`,
      );
    }

    // 4. Idempotent duplicate verification handling
    if (
      (payment && payment.status === PaymentStatus.CAPTURED) ||
      (booking.metadata?.paymentVerified === true &&
        booking.metadata?.payment?.paymentId === razorpayPaymentId &&
        booking.metadata?.payment?.orderId === razorpayOrderId)
    ) {
      this.logger.log(
        `[PaymentVerify] Idempotent duplicate verification for booking #${bookingId} (order=${razorpayOrderId}, payment=${razorpayPaymentId})`,
      );
      return {
        success: true,
        idempotentReplay: true,
        bookingId,
        status: PaymentStatus.CAPTURED,
        booking,
      };
    }

    // 5. Validate payment & booking state machine transitions
    if (payment) {
      if (payment.status === PaymentStatus.CREATED) {
        assertValidPaymentStateTransition(PaymentStatus.CREATED, PaymentStatus.PENDING);
        payment.status = PaymentStatus.PENDING;
      }
      assertValidPaymentStateTransition(payment.status, PaymentStatus.CAPTURED);
    }

    if (
      booking.status === BookingStatus.FAILED ||
      booking.status === BookingStatus.CANCELLED ||
      booking.status === BookingStatus.REFUNDED ||
      booking.status === BookingStatus.REFUND_PENDING
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.INVALID_PAYMENT_STATE_TRANSITION}: Invalid booking state transition: cannot capture payment for ${booking.status} booking`,
      );
    }

    // 6. Validate associated quote if present
    const effectiveQuoteId =
      quoteId || payment?.quoteId || payment?.metadata?.quoteId || booking.metadata?.quoteId;
    const quoteRecord = effectiveQuoteId
      ? this.paymentService.validateCanonicalQuote(effectiveQuoteId, {
          userId: effectiveUserId || booking.userId,
          bookingId,
          expectedTotalMajor: booking.totalPrice,
          allowConsumedByPaymentId: payment?.id,
          allowConsumedByBookingId: bookingId,
        })
      : undefined;

    // 7. Verify canonical amount (in integer minor units), currency, order ID, payment ID, and provider status
    const canonicalCurrency = (
      quoteRecord?.canonicalCurrency ||
      payment?.currency ||
      'INR'
    ).toUpperCase();
    const canonicalAmountMinorUnits =
      quoteRecord?.canonicalTotalMinorUnits ?? toMinorUnits(booking.totalPrice);

    if (payment && toMinorUnits(payment.amount) !== canonicalAmountMinorUnits) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Stored payment amount does not match canonical booking/quote amount`,
      );
    }

    if (payment && payment.currency.toUpperCase() !== canonicalCurrency) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH}: Stored payment currency does not match canonical currency`,
      );
    }

    if (currency !== undefined && String(currency).trim().toUpperCase() !== canonicalCurrency) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH}: Client currency does not match canonical currency ${canonicalCurrency}`,
      );
    }

    if (amount !== undefined && toMinorUnits(Number(amount)) !== canonicalAmountMinorUnits) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Client amount does not match canonical amount`,
      );
    }

    if (
      amountInMinorUnits !== undefined &&
      Math.round(Number(amountInMinorUnits)) !== canonicalAmountMinorUnits
    ) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Client minor-unit amount does not match canonical amount`,
      );
    }

    // Server-side provider payment details verification
    let providerDetails: any;
    try {
      providerDetails = await this.razorpayAdapter.fetchPaymentDetails(razorpayPaymentId, {
        orderId: razorpayOrderId,
        expectedAmountMinorUnits: canonicalAmountMinorUnits,
        expectedCurrency: canonicalCurrency,
      });
    } catch (fetchErr: any) {
      const category =
        this.recoveryService?.classifyError(fetchErr) ||
        FailureCategory.UNKNOWN_PROVIDER_OUTCOME;

      if (this.recoveryService) {
        await this.recoveryService.recordIncident({
          resourceType: 'payment',
          resourceId: payment?.id || razorpayPaymentId,
          paymentId: payment?.id || razorpayPaymentId,
          bookingId,
          providerOrderId: razorpayOrderId,
          providerPaymentId: razorpayPaymentId,
          failureCategory: category,
          rawError: fetchErr,
        });
      }

      throw fetchErr;
    }

    if (providerDetails.paymentId !== razorpayPaymentId) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_ID_MISMATCH}: Provider payment ID mismatch`,
      );
    }

    if (providerDetails.orderId && providerDetails.orderId !== razorpayOrderId) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_ORDER_MISMATCH}: Provider payment is attached to order ${providerDetails.orderId}, expected ${razorpayOrderId}`,
      );
    }

    if (providerDetails.currency.toUpperCase() !== canonicalCurrency) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH}: Provider payment currency ${providerDetails.currency} does not match canonical currency ${canonicalCurrency}`,
      );
    }

    if (providerDetails.amountInMinorUnits !== canonicalAmountMinorUnits) {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Provider payment amount (${providerDetails.amountInMinorUnits} paise) does not match canonical amount (${canonicalAmountMinorUnits} paise)`,
      );
    }

    const effectiveProviderStatus = (
      providerStatus ||
      providerDetails.status ||
      'captured'
    ).toLowerCase();
    if (effectiveProviderStatus !== 'captured' && effectiveProviderStatus !== 'authorized') {
      throw new BadRequestException(
        `${PaymentErrorCode.PAYMENT_NOT_VERIFIED}: Provider payment status '${effectiveProviderStatus}' is not eligible for capture`,
      );
    }

    // 8. Persist CAPTURED PaymentEntity
    if (payment) {
      this.paymentService.assignProviderOrderId(payment, razorpayOrderId);
      this.paymentService.assignProviderPaymentId(payment, razorpayPaymentId);
      payment.status = PaymentStatus.CAPTURED;
      payment.providerSignature = 'HMAC_SHA256_VERIFIED';
      payment.metadata = {
        ...payment.metadata,
        verifiedAt: new Date().toISOString(),
        verification: 'HMAC_SHA256_VERIFIED',
        verifiedAmountInMinorUnits: canonicalAmountMinorUnits,
        verifiedCurrency: canonicalCurrency,
      };
      await this.paymentRepo.save(payment);
    } else {
      payment = this.paymentRepo.create({
        id: `PAY_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
        bookingId,
        quoteId: effectiveQuoteId,
        userId: booking.userId,
        amount: booking.totalPrice,
        currency: canonicalCurrency,
        provider: 'razorpay',
        providerOrderId: razorpayOrderId,
        providerPaymentId: razorpayPaymentId,
        providerSignature: 'HMAC_SHA256_VERIFIED',
        status: PaymentStatus.CAPTURED,
        paymentMethod: 'RAZORPAY_CHECKOUT',
        metadata: {
          quoteId: effectiveQuoteId,
          verifiedAt: new Date().toISOString(),
          verification: 'HMAC_SHA256_VERIFIED',
          verifiedAmountInMinorUnits: canonicalAmountMinorUnits,
          verifiedCurrency: canonicalCurrency,
        },
      });
      await this.paymentRepo.save(payment);
    }

    if (effectiveQuoteId) {
      this.paymentService.markQuoteConsumed(effectiveQuoteId, payment.id, bookingId);
    }

    // 9. Update Booking Status (if still pending)
    const isFirstConfirmation =
      booking.status === BookingStatus.PENDING || !booking.metadata?.paymentVerified;
    booking.status = BookingStatus.UPCOMING;
    booking.metadata = {
      ...booking.metadata,
      paymentVerified: true,
      payment: {
        paymentId: razorpayPaymentId,
        orderId: razorpayOrderId,
        amount: booking.totalPrice,
        amountInMinorUnits: canonicalAmountMinorUnits,
        currency: canonicalCurrency,
        status: 'COMPLETED',
        provider: 'razorpay',
        verifiedAt: new Date().toISOString(),
      },
    };

    // 10. Idempotent Rewards Points Awarding (only on first confirmation)
    if (isFirstConfirmation && !booking.metadata?.rewardAwarded && this.userRepo) {
      try {
        let pointsToAward = 0;
        if (booking.type === BookingType.MOVIE) {
          pointsToAward = Math.round(booking.totalPrice * 0.1);
        } else if (booking.type === BookingType.DINING) {
          pointsToAward = 100;
        } else {
          pointsToAward = Math.round(booking.totalPrice * 0.05);
        }

        if (pointsToAward > 0) {
          const user = await this.userRepo.findOne({ where: { id: booking.userId } });
          if (user) {
            user.rewardPoints = (user.rewardPoints || 0) + pointsToAward;
            await this.userRepo.save(user);
            booking.metadata.rewardAwarded = true;
            booking.metadata.rewardPoints = pointsToAward;
            this.logger.log(
              `[PaymentVerify] Awarded ${pointsToAward} reward points to user ${user.id} for booking ${booking.id}`,
            );
          }
        }
      } catch (rewardErr: any) {
        this.logger.warn(
          `[PaymentVerify] Reward processing failed for booking ${booking.id}: ${rewardErr.message}`,
        );
        if (this.recoveryService) {
          await this.recoveryService.recordIncident({
            resourceType: 'reward',
            resourceId: booking.id,
            bookingId: booking.id,
            paymentId: payment?.id,
            failureCategory: FailureCategory.REWARD_FAILURE,
            rawError: rewardErr,
          });
        }
      }
    }

    try {
      await this.bookingRepo.save(booking);
    } catch (bookingSaveErr: any) {
      this.logger.error(
        `[PaymentVerify] Booking confirmation save failed for booking ${booking.id}: ${bookingSaveErr.message}`,
      );
      if (this.recoveryService) {
        await this.recoveryService.recordIncident({
          resourceType: 'booking',
          resourceId: booking.id,
          bookingId: booking.id,
          paymentId: payment?.id,
          failureCategory: FailureCategory.BOOKING_CONFIRMATION_FAILURE,
          rawError: bookingSaveErr,
        });
      }
      throw bookingSaveErr;
    }

    // 11. Dispatch SMS Notification only on first confirmation
    if (isFirstConfirmation && this.notificationAdapter) {
      try {
        await this.notificationAdapter.sendSms({
          to: '+919876543210',
          message: `Your PLAZA booking #${booking.id} (${booking.title}) is confirmed! Show your QR code pass at venue.`,
        });
      } catch (smsErr: any) {
        this.logger.warn(
          `[PaymentVerify] SMS notification dispatch failed for booking ${booking.id}: ${smsErr.message}`,
        );
        if (this.recoveryService) {
          await this.recoveryService.recordIncident({
            resourceType: 'notification',
            resourceId: booking.id,
            bookingId: booking.id,
            paymentId: payment?.id,
            failureCategory: FailureCategory.NOTIFICATION_FAILURE,
            rawError: smsErr,
          });
        }
      }
    }

    this.logger.log(
      `[PaymentVerify] Booking #${bookingId} successfully confirmed via HMAC signature verification`,
    );
    const result = {
      success: true,
      bookingId,
      status: PaymentStatus.CAPTURED,
      booking,
    };

    if (this.idempotencyService && effectiveIdempotencyKey) {
      await this.idempotencyService.save(
        effectiveUserId || booking.userId || 'usr_default_1',
        effectiveIdempotencyKey,
        '/payments/verify',
        result,
        {
          requestPayload,
          operation: 'payment:verify',
          resourceId: bookingId,
        },
      );
    }

    return result;
  }

  @Post('failed')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Handle failed payment authorization and restore reserved inventory' })
  async handlePaymentFailure(@Body() body: PaymentFailedDto) {
    const { bookingId, reason = 'Payment was declined or cancelled by user' } = body;

    const booking = await this.bookingRepo.findOne({ where: { id: bookingId } });
    if (!booking) {
      throw new NotFoundException(`Booking #${bookingId} not found`);
    }

    // 1. Update PaymentEntity status via canonical state machine validator
    const payment = await this.paymentRepo.findOne({ where: { bookingId } });
    if (payment) {
      assertValidPaymentStateTransition(payment.status, PaymentStatus.FAILED);
      payment.status = PaymentStatus.FAILED;
      payment.failureReason = reason;
      await this.paymentRepo.save(payment);
    }

    // 2. Mark booking as FAILED
    booking.status = BookingStatus.FAILED;
    booking.metadata = {
      ...booking.metadata,
      failureReason: reason,
      failedAt: new Date().toISOString(),
    };
    await this.bookingRepo.save(booking);

    // 3. Restore reserved inventory (tickets or activity spots)
    if (
      booking.type === BookingType.EVENT &&
      booking.metadata?.eventId &&
      booking.metadata?.tierId &&
      this.eventRepo
    ) {
      const event = await this.eventRepo.findOne({ where: { id: booking.metadata.eventId } });
      if (event && event.ticketTiers) {
        const tier = event.ticketTiers.find((t) => t.id === booking.metadata.tierId);
        if (tier) {
          tier.remainingCount += booking.metadata.ticketCount || 1;
          await this.eventRepo.save(event);
          this.logger.log(
            `[PaymentFailed] Restored ${booking.metadata.ticketCount} tickets for event ${event.id}`,
          );
        }
      }
    } else if (
      booking.type === BookingType.ACTIVITY &&
      booking.metadata?.activityId &&
      booking.metadata?.timeSlot &&
      this.activityRepo
    ) {
      const act = await this.activityRepo.findOne({ where: { id: booking.metadata.activityId } });
      if (act && act.timeSlots) {
        const slot = act.timeSlots.find((s) => s.time === booking.metadata.timeSlot);
        if (slot) {
          slot.availableSlots += booking.metadata.numberOfPeople || 1;
          slot.isFillingFast = slot.availableSlots <= 2;
          await this.activityRepo.save(act);
          this.logger.log(
            `[PaymentFailed] Restored ${booking.metadata.numberOfPeople} spots for activity ${act.id}`,
          );
        }
      }
    }

    this.logger.log(
      `[PaymentFailed] Booking #${bookingId} marked as FAILED and inventory restored.`,
    );
    return {
      success: true,
      bookingId,
      status: BookingStatus.FAILED,
      reason,
    };
  }
}
