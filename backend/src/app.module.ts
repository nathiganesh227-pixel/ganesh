import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { LoggingMiddleware } from './common/middleware/logging.middleware';
import { AppController } from './app.controller';

import { User } from './database/entities/user.entity';
import { MovieEntity } from './database/entities/movie.entity';
import { TheatreEntity } from './database/entities/theatre.entity';
import { RestaurantEntity } from './database/entities/restaurant.entity';
import { EventEntity } from './database/entities/event.entity';
import { ActivityEntity } from './database/entities/activity.entity';
import { ProductEntity } from './database/entities/product.entity';
import { HotelEntity } from './database/entities/hotel.entity';
import { SportsVenueEntity } from './database/entities/sports-venue.entity';
import { BookingEntity } from './database/entities/booking.entity';
import { PlanEntity } from './database/entities/plan.entity';
import { RewardEntity } from './database/entities/reward.entity';
import { NotificationEntity } from './database/entities/notification.entity';
import { WebhookEventEntity } from './database/entities/webhook-event.entity';
import { IdempotencyRecordEntity } from './database/entities/idempotency-record.entity';

import { MoviesModule } from './modules/movies/movies.module';
import { DiningModule } from './modules/dining/dining.module';
import { EventsModule } from './modules/events/events.module';
import { ActivitiesModule } from './modules/activities/activities.module';
import { ShoppingModule } from './modules/shopping/shopping.module';
import { StaysModule } from './modules/stays/stays.module';
import { SportsModule } from './modules/sports/sports.module';
import { BookingsModule } from './modules/bookings/bookings.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { PlansModule } from './modules/plans/plans.module';
import { RewardsModule } from './modules/rewards/rewards.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { SearchModule } from './modules/search/search.module';
import { AuthModule } from './modules/auth/auth.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 120,
      },
    ]),
    TypeOrmModule.forRoot({
      type: 'postgres',
      ...(process.env.DATABASE_URL
        ? {
            url: process.env.DATABASE_URL,
            ssl:
              process.env.DB_SSL === 'false'
                ? false
                : process.env.DB_SSL === 'true' ||
                  process.env.NODE_ENV === 'production' ||
                  process.env.DATABASE_URL.includes('render.com') ||
                  process.env.DATABASE_URL.includes('sslmode=require') ||
                  Boolean(process.env.RENDER)
                ? { rejectUnauthorized: false }
                : false,
          }
        : {
            host: process.env.DB_HOST || 'localhost',
            port: parseInt(process.env.DB_PORT || '5432', 10),
            username: process.env.DB_USER || 'nathigopiganesh',
            password: process.env.DB_PASSWORD || '',
            database: process.env.DB_NAME || 'plaza_dev',
            ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
          }),
      entities: [
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
        PlanEntity,
        RewardEntity,
        NotificationEntity,
        WebhookEventEntity,
        IdempotencyRecordEntity,
      ],
      synchronize:
        process.env.DB_SYNC === 'true' ||
        (process.env.NODE_ENV !== 'production' && !process.env.DATABASE_URL),
      migrations: [__dirname + '/database/migrations/*{.ts,.js}'],
      migrationsRun:
        process.env.DB_MIGRATIONS_RUN === 'true' ||
        (Boolean(process.env.DATABASE_URL) && process.env.DB_MIGRATIONS_RUN !== 'false'),
    }),
    MoviesModule,
    DiningModule,
    EventsModule,
    ActivitiesModule,
    ShoppingModule,
    StaysModule,
    SportsModule,
    PaymentsModule,
    BookingsModule,
    PlansModule,
    RewardsModule,
    NotificationsModule,
    SearchModule,
    AuthModule,
  ],
  controllers: [AppController],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggingMiddleware).forRoutes('*');
  }
}
