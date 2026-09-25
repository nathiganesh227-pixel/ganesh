import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AuthModule } from '../auth/auth.module';

import { User } from '../../database/entities/user.entity';
import { MovieEntity } from '../../database/entities/movie.entity';
import { TheatreEntity } from '../../database/entities/theatre.entity';
import { RestaurantEntity } from '../../database/entities/restaurant.entity';
import { EventEntity } from '../../database/entities/event.entity';
import { ActivityEntity } from '../../database/entities/activity.entity';
import { ProductEntity } from '../../database/entities/product.entity';
import { HotelEntity } from '../../database/entities/hotel.entity';
import { SportsVenueEntity } from '../../database/entities/sports-venue.entity';
import { BookingEntity } from '../../database/entities/booking.entity';
import { AuditLogEntity } from '../../database/entities/audit-log.entity';
import { ScreenEntity } from '../../database/entities/screen.entity';
import { ShowEntity } from '../../database/entities/show.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      MovieEntity,
      TheatreEntity,
      RestaurantEntity,
      EventEntity,
      ActivityEntity,
      ProductEntity,
      HotelEntity,
      SportsVenueEntity,
      BookingEntity,
      AuditLogEntity,
      ScreenEntity,
      ShowEntity,
    ]),
    AuthModule,
  ],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}
