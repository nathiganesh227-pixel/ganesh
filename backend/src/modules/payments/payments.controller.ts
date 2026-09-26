import {
  Controller,
  Post,
  Body,
  UnauthorizedException,
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
import { PaymentEntity, PaymentStatus } from '../../database/entities/payment.entity';
import { BookingEntity, BookingStatus, BookingType } from '../../database/entities/booking.entity';
import { User } from '../../database/entities/user.entity';
import { EventEntity } from '../../database/entities/event.entity';
import { ActivityEntity } from '../../database/entities/activity.entity';
import { TwilioSmsAdapter } from '../notifications/providers/twilio-sms.adapter';

export class VerifyPaymentDto {
  bookingId: string;
  razorpayOrderId: string;
  razorpayPaymentId: string;
  razorpaySignature: string;
}

export class PaymentFailedDto {
  bookingId: string;
  reason?: string;
}

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
  ) {}

  @Post('verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cryptographically verify Razorpay checkout completion signature and confirm booking' })
  async verifyPayment(@Body() body: VerifyPaymentDto) {
    const { bookingId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = body;

    if (!bookingId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
      throw new BadRequestException('Missing required payment verification parameters');
    }

    // 1. Verify HMAC-SHA256 signature
    const isValid = this.razorpayAdapter.verifyPaymentSignature({
      orderId: razorpayOrderId,
      paymentId: razorpayPaymentId,
      signature: razorpaySignature,
    });

    if (!isValid) {
      this.logger.warn(`[PaymentVerify] Invalid HMAC signature for payment ${razorpayPaymentId}, order ${razorpayOrderId}`);
      throw new UnauthorizedException('Invalid payment signature verification failed');
    }

    // 2. Fetch booking
    const booking = await this.bookingRepo.findOne({ where: { id: bookingId } });
    if (!booking) {
      throw new NotFoundException(`Booking #${bookingId} not found`);
    }

    // 3. Update or create PaymentEntity
    let payment = await this.paymentRepo.findOne({
      where: [
        { bookingId },
        { providerOrderId: razorpayOrderId },
        { providerPaymentId: razorpayPaymentId },
      ],
    });

    if (payment) {
      payment.status = PaymentStatus.CAPTURED;
      payment.providerPaymentId = razorpayPaymentId;
      payment.providerSignature = razorpaySignature;
      payment.metadata = {
        ...payment.metadata,
        verifiedAt: new Date().toISOString(),
        verification: 'HMAC_SHA256_VERIFIED',
      };
      await this.paymentRepo.save(payment);
    } else {
      payment = this.paymentRepo.create({
        id: `PAY_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
        bookingId,
        userId: booking.userId,
        amount: booking.totalPrice,
        currency: 'INR',
        provider: 'razorpay',
        providerOrderId: razorpayOrderId,
        providerPaymentId: razorpayPaymentId,
        providerSignature: razorpaySignature,
        status: PaymentStatus.CAPTURED,
        paymentMethod: 'RAZORPAY_CHECKOUT',
        metadata: {
          verifiedAt: new Date().toISOString(),
          verification: 'HMAC_SHA256_VERIFIED',
        },
      });
      await this.paymentRepo.save(payment);
    }

    // 4. Update Booking Status (if still pending)
    const isFirstConfirmation = booking.status === BookingStatus.PENDING || !booking.metadata?.paymentVerified;
    booking.status = BookingStatus.UPCOMING;
    booking.metadata = {
      ...booking.metadata,
      paymentVerified: true,
      payment: {
        paymentId: razorpayPaymentId,
        orderId: razorpayOrderId,
        amount: booking.totalPrice,
        status: 'COMPLETED',
        provider: 'razorpay',
        verifiedAt: new Date().toISOString(),
      },
    };

    // 5. Idempotent Rewards Points Awarding (only on first confirmation)
    if (isFirstConfirmation && !booking.metadata?.rewardAwarded && this.userRepo) {
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
          this.logger.log(`[PaymentVerify] Awarded ${pointsToAward} reward points to user ${user.id} for booking ${booking.id}`);
        }
      }
    }

    await this.bookingRepo.save(booking);

    // 6. Dispatch SMS Notification
    if (this.notificationAdapter) {
      await this.notificationAdapter.sendSms({
        to: '+919876543210',
        message: `Your PLAZA booking #${booking.id} (${booking.title}) is confirmed! Show your QR code pass at venue.`,
      });
    }

    this.logger.log(`[PaymentVerify] Booking #${bookingId} successfully confirmed via HMAC signature verification`);
    return {
      success: true,
      bookingId,
      status: PaymentStatus.CAPTURED,
      booking,
    };
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

    // 1. Update PaymentEntity status
    const payment = await this.paymentRepo.findOne({ where: { bookingId } });
    if (payment) {
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
    if (booking.type === BookingType.EVENT && booking.metadata?.eventId && booking.metadata?.tierId && this.eventRepo) {
      const event = await this.eventRepo.findOne({ where: { id: booking.metadata.eventId } });
      if (event && event.ticketTiers) {
        const tier = event.ticketTiers.find((t) => t.id === booking.metadata.tierId);
        if (tier) {
          tier.remainingCount += booking.metadata.ticketCount || 1;
          await this.eventRepo.save(event);
          this.logger.log(`[PaymentFailed] Restored ${booking.metadata.ticketCount} tickets for event ${event.id}`);
        }
      }
    } else if (booking.type === BookingType.ACTIVITY && booking.metadata?.activityId && booking.metadata?.timeSlot && this.activityRepo) {
      const act = await this.activityRepo.findOne({ where: { id: booking.metadata.activityId } });
      if (act && act.timeSlots) {
        const slot = act.timeSlots.find((s) => s.time === booking.metadata.timeSlot);
        if (slot) {
          slot.availableSlots += booking.metadata.numberOfPeople || 1;
          slot.isFillingFast = slot.availableSlots <= 2;
          await this.activityRepo.save(act);
          this.logger.log(`[PaymentFailed] Restored ${booking.metadata.numberOfPeople} spots for activity ${act.id}`);
        }
      }
    }

    this.logger.log(`[PaymentFailed] Booking #${bookingId} marked as FAILED and inventory restored.`);
    return {
      success: true,
      bookingId,
      status: BookingStatus.FAILED,
      reason,
    };
  }
}
