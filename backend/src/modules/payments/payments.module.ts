import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WebhookEventEntity } from '../../database/entities/webhook-event.entity';
import { BookingEntity } from '../../database/entities/booking.entity';
import { PaymentEntity } from '../../database/entities/payment.entity';
import { User } from '../../database/entities/user.entity';
import { EventEntity } from '../../database/entities/event.entity';
import { ActivityEntity } from '../../database/entities/activity.entity';
import { PaymentService } from './payment.service';
import { RazorpayAdapter } from './providers/razorpay.adapter';
import { SimulatedPaymentAdapter } from './providers/simulated-payment.adapter';
import { WebhooksController } from './webhooks.controller';
import { PaymentsController } from './payments.controller';
import { TwilioSmsAdapter } from '../notifications/providers/twilio-sms.adapter';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      WebhookEventEntity,
      BookingEntity,
      PaymentEntity,
      User,
      EventEntity,
      ActivityEntity,
    ]),
  ],
  controllers: [WebhooksController, PaymentsController],
  providers: [
    PaymentService,
    RazorpayAdapter,
    SimulatedPaymentAdapter,
    TwilioSmsAdapter,
  ],
  exports: [PaymentService, RazorpayAdapter, SimulatedPaymentAdapter, TwilioSmsAdapter],
})
export class PaymentsModule {}
