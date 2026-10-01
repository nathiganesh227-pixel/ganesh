import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WebhookEventEntity } from '../../database/entities/webhook-event.entity';
import { BookingEntity } from '../../database/entities/booking.entity';
import { PaymentEntity } from '../../database/entities/payment.entity';
import { User } from '../../database/entities/user.entity';
import { EventEntity } from '../../database/entities/event.entity';
import { ActivityEntity } from '../../database/entities/activity.entity';
import { IdempotencyRecordEntity } from '../../database/entities/idempotency-record.entity';
import { AuthModule } from '../auth/auth.module';
import { PaymentConfigService } from './payment-config.service';
import { PaymentService } from './payment.service';
import { RazorpayAdapter } from './providers/razorpay.adapter';
import { SimulatedPaymentAdapter } from './providers/simulated-payment.adapter';
import { WebhooksController } from './webhooks.controller';
import { PaymentsController } from './payments.controller';
import { TwilioSmsAdapter } from '../notifications/providers/twilio-sms.adapter';
import { IdempotencyService } from '../bookings/idempotency.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      WebhookEventEntity,
      BookingEntity,
      PaymentEntity,
      User,
      EventEntity,
      ActivityEntity,
      IdempotencyRecordEntity,
    ]),
    AuthModule,
  ],
  controllers: [WebhooksController, PaymentsController],
  providers: [
    PaymentConfigService,
    PaymentService,
    RazorpayAdapter,
    SimulatedPaymentAdapter,
    TwilioSmsAdapter,
    IdempotencyService,
  ],
  exports: [
    PaymentConfigService,
    PaymentService,
    RazorpayAdapter,
    SimulatedPaymentAdapter,
    TwilioSmsAdapter,
    IdempotencyService,
  ],
})
export class PaymentsModule {}
