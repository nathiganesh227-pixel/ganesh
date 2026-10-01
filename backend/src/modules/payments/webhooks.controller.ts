import {
  Controller,
  Post,
  Headers,
  Body,
  Req,
  UnauthorizedException,
  BadRequestException,
  Logger,
  HttpCode,
  HttpStatus,
  Optional,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiHeader } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RazorpayAdapter } from './providers/razorpay.adapter';
import { WebhookEventEntity } from '../../database/entities/webhook-event.entity';
import { BookingEntity, BookingStatus, BookingType } from '../../database/entities/booking.entity';
import {
  PaymentEntity,
  PaymentStatus,
  PaymentErrorCode,
  assertValidPaymentStateTransition,
  toMinorUnits,
} from '../../database/entities/payment.entity';
import { User } from '../../database/entities/user.entity';
import { EventEntity } from '../../database/entities/event.entity';
import { ActivityEntity } from '../../database/entities/activity.entity';
import { TwilioSmsAdapter } from '../notifications/providers/twilio-sms.adapter';
import { PaymentRecoveryService } from './payment-recovery.service';
import { FailureCategory, RecoveryStatus } from '../../database/entities/payment-recovery.entity';

@ApiTags('webhooks')
@Controller('webhooks')
export class WebhooksController {
  private readonly logger = new Logger(WebhooksController.name);

  constructor(
    private readonly razorpayAdapter: RazorpayAdapter,
    @InjectRepository(WebhookEventEntity)
    private readonly webhookRepo: Repository<WebhookEventEntity>,
    @InjectRepository(BookingEntity)
    private readonly bookingRepo: Repository<BookingEntity>,
    private readonly notificationAdapter: TwilioSmsAdapter,
    @Optional()
    @InjectRepository(PaymentEntity)
    private readonly paymentRepo?: Repository<PaymentEntity>,
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
    private readonly recoveryService?: PaymentRecoveryService,
  ) {}

  @Post('razorpay')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Process Razorpay webhook events with HMAC-SHA256 signature verification' })
  @ApiHeader({ name: 'x-razorpay-signature', description: 'HMAC-SHA256 signature calculated with webhook secret' })
  async handleRazorpayWebhook(
    @Headers('x-razorpay-signature') signature: string,
    @Body() body: any,
    @Req() req?: any,
  ) {
    if (!signature) {
      throw new UnauthorizedException('Missing x-razorpay-signature header');
    }

    // 1. Verify HMAC-SHA256 signature with raw unparsed body
    let rawPayload: string;
    if (req?.rawBody) {
      rawPayload = Buffer.isBuffer(req.rawBody) ? req.rawBody.toString('utf8') : String(req.rawBody);
    } else if (typeof body === 'string') {
      rawPayload = body;
    } else {
      rawPayload = JSON.stringify(body);
    }

    const isValid = this.razorpayAdapter.verifyWebhookSignature(rawPayload, signature);
    if (!isValid) {
      this.logger.warn('[Webhook] Rejected invalid HMAC-SHA256 signature on Razorpay webhook');
      throw new UnauthorizedException('Invalid Razorpay webhook signature');
    }

    // 2. Parse payload safely
    let parsedBody: any;
    if (typeof body === 'string') {
      try {
        parsedBody = JSON.parse(body);
      } catch {
        parsedBody = {};
      }
    } else {
      parsedBody = body || {};
    }

    // 3. Extract event identifiers and financial fields
    const paymentEntity = parsedBody.payload?.payment?.entity;
    const orderEntity = parsedBody.payload?.order?.entity;
    const refundEntity = parsedBody.payload?.refund?.entity;

    const eventId =
      parsedBody.id ||
      parsedBody.event_id ||
      paymentEntity?.id ||
      `evt_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;

    const eventType = parsedBody.event || 'unknown';

    const providerPaymentId = paymentEntity?.id || refundEntity?.payment_id || null;
    const providerOrderId = orderEntity?.id || paymentEntity?.order_id || null;
    const bookingId =
      paymentEntity?.notes?.bookingId ||
      orderEntity?.receipt ||
      orderEntity?.notes?.bookingId ||
      refundEntity?.notes?.bookingId ||
      null;

    const amountInMinorUnits =
      paymentEntity?.amount ?? refundEntity?.amount ?? orderEntity?.amount ?? null;
    const amount = amountInMinorUnits != null ? Number(amountInMinorUnits) / 100 : null;
    const currency =
      paymentEntity?.currency || orderEntity?.currency || refundEntity?.currency || 'INR';

    // 4. Idempotency Protection / Replay Prevention
    const existingEvent = await this.webhookRepo.findOne({ where: { id: eventId } });
    if (existingEvent) {
      if (existingEvent.status === 'PROCESSED') {
        this.logger.log(`[Webhook] Duplicate event ${eventId} ignored (already processed)`);
        return {
          success: true,
          status: 'ignored',
          reason: 'already_processed',
          eventId,
          idempotentReplay: true,
        };
      }
      if (existingEvent.status === 'PROCESSING') {
        this.logger.log(`[Webhook] Event ${eventId} is currently processing; ignoring duplicate replay`);
        return {
          success: true,
          status: 'ignored',
          reason: 'already_processing',
          eventId,
        };
      }
    }

    // 5. Initial durable event registration (status: PROCESSING)
    let webhookRecord = existingEvent;
    if (!webhookRecord) {
      webhookRecord = this.webhookRepo.create({
        id: eventId,
        provider: 'razorpay',
        eventType,
        status: 'PROCESSING',
        providerPaymentId: providerPaymentId || undefined,
        providerOrderId: providerOrderId || undefined,
        bookingId: bookingId || undefined,
        amount: amount != null ? amount : undefined,
        amountInMinorUnits: amountInMinorUnits != null ? amountInMinorUnits : undefined,
        currency,
        payload: typeof parsedBody === 'object' ? parsedBody : { raw: parsedBody },
        receivedAt: new Date(),
      });

      try {
        await this.webhookRepo.save(webhookRecord);
      } catch (saveErr: any) {
        // Concurrency protection against duplicate simultaneous inserts
        const duplicate = await this.webhookRepo.findOne({ where: { id: eventId } });
        if (duplicate && duplicate.status === 'PROCESSED') {
          return {
            success: true,
            status: 'ignored',
            reason: 'already_processed',
            eventId,
            idempotentReplay: true,
          };
        }
      }
    }

    this.logger.log(`[Webhook] Processing verified event: ${eventType} (ID: ${eventId})`);

    // 6. Dispatch Event Processing
    try {
      if (eventType === 'payment.captured' || eventType === 'order.paid') {
        await this.handlePaymentCaptured(
          parsedBody,
          bookingId,
          providerPaymentId,
          providerOrderId,
          amountInMinorUnits,
          currency,
        );
      } else if (eventType === 'payment.failed') {
        await this.handlePaymentFailed(parsedBody, bookingId, providerPaymentId);
      } else if (eventType === 'refund.processed') {
        await this.handleRefundProcessed(parsedBody, providerPaymentId);
      } else {
        // Unhandled / safely ignored event types (e.g. invoice.paid, dispute.created)
        this.logger.log(`[Webhook] Safely ignored unhandled event type: ${eventType}`);
        webhookRecord.status = 'IGNORED';
        webhookRecord.processedAt = new Date();
        await this.webhookRepo.save(webhookRecord);
        return { success: true, status: 'ignored', eventId, event: eventType };
      }

      // Mark event as PROCESSED in idempotency ledger
      webhookRecord.status = 'PROCESSED';
      webhookRecord.processedAt = new Date();
      await this.webhookRepo.save(webhookRecord);

      return { success: true, eventId, event: eventType, status: 'processed' };
    } catch (err: any) {
      this.logger.error(`[Webhook] Error processing event ${eventId}: ${err.message}`);
      webhookRecord.status = 'FAILED';
      webhookRecord.failureReason = err.message;
      await this.webhookRepo.save(webhookRecord);

      if (err instanceof BadRequestException || err instanceof UnauthorizedException) {
        throw err;
      }
      throw new BadRequestException(`Webhook processing error: ${err.message}`);
    }
  }

  private async handlePaymentCaptured(
    body: any,
    bookingId: string | null,
    providerPaymentId: string | null,
    providerOrderId: string | null,
    amountInMinorUnits: number | null,
    currency: string,
  ) {
    const paymentEntity = body.payload?.payment?.entity;
    const orderEntity = body.payload?.order?.entity;

    const resolvedBookingId =
      bookingId ||
      paymentEntity?.notes?.bookingId ||
      orderEntity?.receipt ||
      orderEntity?.notes?.bookingId;

    if (!resolvedBookingId && !providerOrderId && !providerPaymentId) {
      this.logger.warn('[Webhook] No bookingId or payment identifiers found in webhook payload');
      return;
    }

    let booking: BookingEntity | null = null;
    if (resolvedBookingId) {
      booking = await this.bookingRepo.findOne({ where: { id: resolvedBookingId } });
    }

    // 1. Validate & Update Dedicated PaymentEntity
    let payment: PaymentEntity | null = null;
    if (this.paymentRepo) {
      const searchConditions: any[] = [];
      if (resolvedBookingId) searchConditions.push({ bookingId: resolvedBookingId });
      if (providerOrderId) searchConditions.push({ providerOrderId });
      if (providerPaymentId) searchConditions.push({ providerPaymentId });
      if (paymentEntity?.id) searchConditions.push({ id: paymentEntity.id });

      if (searchConditions.length > 0) {
        payment = await this.paymentRepo.findOne({ where: searchConditions });
      }

      if (payment) {
        // Financial validations
        if (payment.currency && currency && payment.currency.toUpperCase() !== currency.toUpperCase()) {
          throw new BadRequestException(
            `${PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH}: Currency mismatch: expected ${payment.currency}, got ${currency}`,
          );
        }

        const expectedPaise = toMinorUnits(Number(payment.amount));
        if (
          amountInMinorUnits != null &&
          expectedPaise != null &&
          Number(amountInMinorUnits) !== expectedPaise
        ) {
          throw new BadRequestException(
            `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Amount mismatch: expected ${expectedPaise} paise, received ${amountInMinorUnits} paise`,
          );
        }

        if (
          payment.providerOrderId &&
          providerOrderId &&
          payment.providerOrderId !== providerOrderId
        ) {
          throw new BadRequestException(
            `${PaymentErrorCode.PAYMENT_ORDER_MISMATCH}: Provider order ID mismatch: expected ${payment.providerOrderId}, got ${providerOrderId}`,
          );
        }

        if (payment.status === PaymentStatus.CAPTURED) {
          if (
            payment.providerPaymentId &&
            providerPaymentId &&
            payment.providerPaymentId !== providerPaymentId
          ) {
            throw new BadRequestException(
              `${PaymentErrorCode.PAYMENT_ID_MISMATCH}: Cannot overwrite providerPaymentId on already CAPTURED payment`,
            );
          }
          this.logger.log(
            `[Webhook] Payment for booking ${resolvedBookingId || payment.bookingId} already CAPTURED; skipping duplicate transition`,
          );
          return;
        }

        if (payment.status === PaymentStatus.CREATED) {
          assertValidPaymentStateTransition(PaymentStatus.CREATED, PaymentStatus.PENDING);
          payment.status = PaymentStatus.PENDING;
        }
        assertValidPaymentStateTransition(payment.status, PaymentStatus.CAPTURED);
        payment.status = PaymentStatus.CAPTURED;
        payment.providerPaymentId = providerPaymentId || payment.providerPaymentId;
        payment.providerOrderId = providerOrderId || payment.providerOrderId;
        await this.paymentRepo.save(payment);
      }
    }

    // 2. Validate & Update BookingEntity
    if (booking) {
      // Validate booking financial amount if payment record was not present
      if (!payment && amountInMinorUnits != null) {
        const expectedBookingPaise = toMinorUnits(Number(booking.totalPrice));
        if (Number(amountInMinorUnits) !== expectedBookingPaise) {
          throw new BadRequestException(
            `${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Amount mismatch: expected ${expectedBookingPaise} paise, received ${amountInMinorUnits} paise`,
          );
        }
      }

      if (booking.status === BookingStatus.FAILED || booking.status === BookingStatus.CANCELLED) {
        throw new BadRequestException(
          `Invalid booking state transition: cannot capture payment for ${booking.status} booking`,
        );
      }

      const isFirstConfirmation =
        booking.status === BookingStatus.PENDING || !booking.metadata?.paymentVerified;

      booking.status = BookingStatus.UPCOMING;
      booking.metadata = {
        ...booking.metadata,
        paymentVerified: true,
        payment: {
          paymentId: providerPaymentId || payment?.providerPaymentId || `PAY_${Date.now()}`,
          orderId: providerOrderId || payment?.providerOrderId,
          amount: amountInMinorUnits ? Number(amountInMinorUnits) / 100 : Number(booking.totalPrice),
          status: 'COMPLETED',
          provider: 'razorpay',
          capturedAt: new Date().toISOString(),
        },
      };

      // 3. Idempotent Rewards Awarding (Exactly Once)
      if (isFirstConfirmation && !booking.metadata?.rewardAwarded && this.userRepo) {
        let pointsToAward = 0;
        if (booking.type === BookingType.MOVIE) {
          pointsToAward = Math.round(Number(booking.totalPrice) * 0.1);
        } else if (booking.type === BookingType.DINING) {
          pointsToAward = 100;
        } else {
          pointsToAward = Math.round(Number(booking.totalPrice) * 0.05);
        }

        if (pointsToAward > 0) {
          const user = await this.userRepo.findOne({ where: { id: booking.userId } });
          if (user) {
            user.rewardPoints = (user.rewardPoints || 0) + pointsToAward;
            await this.userRepo.save(user);
            booking.metadata.rewardAwarded = true;
            booking.metadata.rewardPoints = pointsToAward;
          }
        }
      }

      await this.bookingRepo.save(booking);

      // 4. Dispatch Automated SMS Confirmation (Exactly Once on first confirmation)
      if (isFirstConfirmation) {
        await this.notificationAdapter.sendSms({
          to: '+919876543210',
          message: `Your PLAZA booking #${booking.id} (${booking.title}) is confirmed! Show your QR code pass at venue.`,
        });
      }

      this.logger.log(`[Webhook] Booking ${booking.id} transitioned to UPCOMING/CONFIRMED via webhook`);
    }
  }

  private async handlePaymentFailed(
    body: any,
    bookingId: string | null,
    providerPaymentId: string | null,
  ) {
    const paymentEntity = body.payload?.payment?.entity;
    const resolvedBookingId = bookingId || paymentEntity?.notes?.bookingId;
    const failureReason = paymentEntity?.error_description || 'Payment authorization failed';

    // 1. Update PaymentEntity
    if (this.paymentRepo) {
      const searchConditions: any[] = [];
      if (resolvedBookingId) searchConditions.push({ bookingId: resolvedBookingId });
      if (providerPaymentId) searchConditions.push({ providerPaymentId });
      if (paymentEntity?.id) searchConditions.push({ id: paymentEntity.id });

      if (searchConditions.length > 0) {
        const payment = await this.paymentRepo.findOne({ where: searchConditions });
        if (payment) {
          // Never regress already captured or refunded payments
          if (
            payment.status === PaymentStatus.CAPTURED ||
            payment.status === PaymentStatus.REFUNDED
          ) {
            this.logger.warn(
              `[Webhook] Ignored payment.failed for payment ${payment.id} with status ${payment.status}`,
            );
            return;
          }
          assertValidPaymentStateTransition(payment.status, PaymentStatus.FAILED);
          payment.status = PaymentStatus.FAILED;
          payment.failureReason = failureReason;
          await this.paymentRepo.save(payment);
        }
      }
    }

    // 2. Update BookingEntity
    if (resolvedBookingId) {
      const booking = await this.bookingRepo.findOne({ where: { id: resolvedBookingId } });
      if (booking) {
        // Never regress confirmed or completed bookings
        if (
          booking.status === BookingStatus.UPCOMING ||
          booking.status === BookingStatus.COMPLETED
        ) {
          this.logger.warn(
            `[Webhook] Ignored payment.failed for booking ${booking.id} with status ${booking.status}`,
          );
          return;
        }

        booking.status = BookingStatus.FAILED;
        booking.metadata = {
          ...booking.metadata,
          failureReason,
        };
        await this.bookingRepo.save(booking);

        // Restore inventory if applicable
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
            }
          }
        }

        this.logger.log(`[Webhook] Booking ${booking.id} marked as FAILED`);
      }
    }
  }

  private async handleRefundProcessed(body: any, providerPaymentId: string | null) {
    const refundEntity = body.payload?.refund?.entity;
    const paymentId = refundEntity?.payment_id || providerPaymentId;
    const refundId = refundEntity?.id || `rfd_${Date.now()}`;
    const refundAmount = (refundEntity?.amount || 0) / 100;

    let booking: BookingEntity | null = null;
    if (paymentId) {
      if (this.bookingRepo.createQueryBuilder) {
        booking = await this.bookingRepo
          .createQueryBuilder('b')
          .where("b.metadata->'payment'->>'paymentId' = :pId", { pId: paymentId })
          .getOne();
      } else {
        const allBookings = await this.bookingRepo.find();
        booking =
          allBookings.find((b) => b.metadata?.payment?.paymentId === paymentId) || null;
      }
    }

    if (booking) {
      booking.status = BookingStatus.CANCELLED;
      booking.metadata = {
        ...booking.metadata,
        refund: {
          refundId,
          amount: refundAmount,
          status: 'REFUNDED',
          processedAt: new Date().toISOString(),
        },
      };

      // Reverse reward points if previously awarded
      if (booking.metadata?.rewardAwarded && booking.metadata?.rewardPoints && this.userRepo) {
        const user = await this.userRepo.findOne({ where: { id: booking.userId } });
        if (user) {
          user.rewardPoints = Math.max(0, (user.rewardPoints || 0) - booking.metadata.rewardPoints);
          await this.userRepo.save(user);
          booking.metadata.rewardAwarded = false;
          booking.metadata.rewardPointsReversed = true;
        }
      }

      await this.bookingRepo.save(booking);
      this.logger.log(`[Webhook] Booking ${booking.id} marked as CANCELLED with refund ${refundId}`);
    }

    // Update dedicated PaymentEntity
    if (this.paymentRepo && paymentId) {
      const payment = await this.paymentRepo.findOne({
        where: [
          { providerPaymentId: paymentId },
          { id: paymentId },
          ...(booking ? [{ bookingId: booking.id }] : []),
        ],
      });
      if (payment) {
        if (payment.status === PaymentStatus.CAPTURED) {
          assertValidPaymentStateTransition(PaymentStatus.CAPTURED, PaymentStatus.REFUND_PENDING);
          assertValidPaymentStateTransition(PaymentStatus.REFUND_PENDING, PaymentStatus.REFUNDED);
        }
        payment.status = PaymentStatus.REFUNDED;
        payment.refundAmount = refundAmount;
        payment.refundId = refundId;
        await this.paymentRepo.save(payment);
      }
    }
  }
}
