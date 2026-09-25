import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';

import { User } from './entities/user.entity';
import { MovieEntity } from './entities/movie.entity';
import { TheatreEntity } from './entities/theatre.entity';
import { RestaurantEntity } from './entities/restaurant.entity';
import { EventEntity } from './entities/event.entity';
import { ActivityEntity } from './entities/activity.entity';
import { ProductEntity } from './entities/product.entity';
import { HotelEntity } from './entities/hotel.entity';
import { SportsVenueEntity } from './entities/sports-venue.entity';
import { BookingEntity } from './entities/booking.entity';
import { PlanEntity } from './entities/plan.entity';
import { RewardEntity } from './entities/reward.entity';
import { NotificationEntity } from './entities/notification.entity';
import { WebhookEventEntity } from './entities/webhook-event.entity';
import { IdempotencyRecordEntity } from './entities/idempotency-record.entity';

dotenv.config();

export const ALL_ENTITIES = [
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
];

export const AppDataSource = new DataSource(
  process.env.DATABASE_URL
    ? {
        type: 'postgres',
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
        entities: ALL_ENTITIES,
        migrations: [path.join(__dirname, 'migrations', '*{.ts,.js}')],
        synchronize: false,
      }
    : {
        type: 'postgres',
        host: process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.DB_PORT || '5432', 10),
        username: process.env.DB_USER || 'nathigopiganesh',
        password: process.env.DB_PASSWORD || '',
        database: process.env.DB_NAME || 'plaza_dev',
        ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
        entities: ALL_ENTITIES,
        migrations: [path.join(__dirname, 'migrations', '*{.ts,.js}')],
        synchronize: false,
      },
);
