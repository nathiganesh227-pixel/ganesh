import {
  Controller,
  Post,
  Headers,
  Body,
  UnauthorizedException,
  BadRequestException,
  Logger,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiHeader } from '@nestjs/swagger';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RazorpayAdapter } from './providers/razorpay.adapter';
import { WebhookEventEntity } from '../../database/entities/webhook-event.entity';
import { BookingEntity, BookingStatus } from '../../database/entities/booking.entity';
import { TwilioSmsAdapter } from '../notifications/providers/twilio-sms.adapter';

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
  ) {}

  @Post('razorpay')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Process Razorpay webhook events with HMAC-SHA256 signature verification' })
  @ApiHeader({ name: 'x-razorpay-signature', description: 'HMAC-SHA256 signature calculated with webhook secret' })
  async handleRazorpayWebhook(
    @Headers('x-razorpay-signature') signature: string,
    @Body() body: any,
  ) {
    if (!signature) {
      throw new UnauthorizedException('Missing x-razorpay-signature header');
    }

    // 1. Verify HMAC-SHA256 signature
    const rawPayload = typeof body === 'string' ? body : JSON.stringify(body);
    const isValid = this.razorpayAdapter.verifyWebhookSignature(rawPayload, signature);

    if (!isValid) {
      this.logger.warn('[Webhook] Rejected invalid HMAC-SHA256 signature on Razorpay webhook');
      throw new UnauthorizedException('Invalid Razorpay webhook signature');
    }

    // 2. Idempotency Protection (prevent replay attacks)
    const eventId =
      body.id ||
      body.event_id ||
      body.payload?.payment?.entity?.id ||
      `evt_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;

    const existingEvent = await this.webhookRepo.findOne({ where: { id: eventId } });
    if (existingEvent) {
      this.logger.log(`[Webhook] Duplicate event ${eventId} ignored (already processed)`);
      return { status: 'ignored', reason: 'already_processed', eventId };
    }

    const eventType = body.event || 'unknown';
    this.logger.log(`[Webhook] Processing verified event: ${eventType} (ID: ${eventId})`);

    // 3. Process Event Types
    try {
      if (eventType === 'payment.captured' || eventType === 'order.paid') {
        await this.handlePaymentCaptured(body);
      } else if (eventType === 'payment.failed') {
        await this.handlePaymentFailed(body);
      } else if (eventType === 'refund.processed') {
        await this.handleRefundProcessed(body);
      }

      // 4. Record event as PROCESSED in idempotency ledger
      const recorded = this.webhookRepo.create({
        id: eventId,
        provider: 'razorpay',
        eventType,
        payload: typeof body === 'object' ? body : { raw: body },
        status: 'PROCESSED',
      });
      await this.webhookRepo.save(recorded);

      return { success: true, eventId, event: eventType };
    } catch (err: any) {
      this.logger.error(`[Webhook] Error processing event ${eventId}: ${err.message}`);
      throw new BadRequestException(`Webhook processing error: ${err.message}`);
    }
  }

  private async handlePaymentCaptured(body: any) {
    const paymentEntity = body.payload?.payment?.entity;
    const orderEntity = body.payload?.order?.entity;

    const bookingId =
      paymentEntity?.notes?.bookingId ||
      orderEntity?.receipt ||
      orderEntity?.notes?.bookingId;

    if (!bookingId) {
      this.logger.warn('[Webhook] No bookingId found in webhook payload');
      return;
    }

    const booking = await this.bookingRepo.findOne({ where: { id: bookingId } });
    if (booking) {
      booking.status = BookingStatus.UPCOMING;
      booking.metadata = {
        ...booking.metadata,
        payment: {
          paymentId: paymentEntity?.id || `PAY_${Date.now()}`,
          orderId: orderEntity?.id,
          amount: (paymentEntity?.amount || 0) / 100,
          status: 'COMPLETED',
          provider: 'razorpay',
          capturedAt: new Date().toISOString(),
        },
      };
      await this.bookingRepo.save(booking);

      // Dispatch automated SMS confirmation
      await this.notificationAdapter.sendSms({
        to: '+919876543210',
        message: `Your PLAZA booking #${booking.id} (${booking.title}) is confirmed! Show your QR code pass at venue.`,
      });

      this.logger.log(`[Webhook] Booking ${booking.id} transitioned to UPCOMING/CONFIRMED via webhook`);
    }
  }

  private async handlePaymentFailed(body: any) {
    const paymentEntity = body.payload?.payment?.entity;
    const bookingId = paymentEntity?.notes?.bookingId;

    if (bookingId) {
      const booking = await this.bookingRepo.findOne({ where: { id: bookingId } });
      if (booking) {
        booking.status = BookingStatus.FAILED;
        booking.metadata = {
          ...booking.metadata,
          failureReason: paymentEntity?.error_description || 'Payment authorization failed',
        };
        await this.bookingRepo.save(booking);
        this.logger.log(`[Webhook] Booking ${booking.id} marked as FAILED`);
      }
    }
  }

  private async handleRefundProcessed(body: any) {
    const refundEntity = body.payload?.refund?.entity;
    const paymentId = refundEntity?.payment_id;

    if (paymentId) {
      const booking = await this.bookingRepo
        .createQueryBuilder('b')
        .where("b.metadata->'payment'->>'paymentId' = :pId", { pId: paymentId })
        .getOne();

      if (booking) {
        booking.status = BookingStatus.CANCELLED;
        booking.metadata = {
          ...booking.metadata,
          refund: {
            refundId: refundEntity.id,
            amount: (refundEntity.amount || 0) / 100,
            status: 'REFUNDED',
            processedAt: new Date().toISOString(),
          },
        };
        await this.bookingRepo.save(booking);
        this.logger.log(`[Webhook] Booking ${booking.id} marked as CANCELLED with refund ${refundEntity.id}`);
      }
    }
  }
}
