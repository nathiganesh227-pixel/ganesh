import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BookingEntity } from '../../database/entities/booking.entity';
import { IdempotencyRecordEntity } from '../../database/entities/idempotency-record.entity';
import { BookingsService } from './bookings.service';
import { IdempotencyService } from './idempotency.service';
import { BookingsController } from './bookings.controller';
import { AuthModule } from '../auth/auth.module';
import { PaymentsModule } from '../payments/payments.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([BookingEntity, IdempotencyRecordEntity]),
    AuthModule,
    PaymentsModule,
  ],
  controllers: [BookingsController],
  providers: [BookingsService, IdempotencyService],
  exports: [BookingsService, IdempotencyService],
})
export class BookingsModule {}

