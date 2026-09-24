import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WebhookEventEntity } from '../../database/entities/webhook-event.entity';
import { BookingEntity } from '../../database/entities/booking.entity';
import { PaymentService } from './payment.service';
import { RazorpayAdapter } from './providers/razorpay.adapter';
import { SimulatedPaymentAdapter } from './providers/simulated-payment.adapter';
import { WebhooksController } from './webhooks.controller';
import { TwilioSmsAdapter } from '../notifications/providers/twilio-sms.adapter';

@Module({
  imports: [TypeOrmModule.forFeature([WebhookEventEntity, BookingEntity])],
  controllers: [WebhooksController],
  providers: [
    PaymentService,
    RazorpayAdapter,
    SimulatedPaymentAdapter,
    TwilioSmsAdapter,
  ],
  exports: [PaymentService, RazorpayAdapter, SimulatedPaymentAdapter],
})
export class PaymentsModule {}
