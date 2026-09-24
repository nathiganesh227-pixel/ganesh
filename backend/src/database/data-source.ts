import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config();

export const AppDataSource = new DataSource(
  process.env.DATABASE_URL
    ? {
        type: 'postgres',
        url: process.env.DATABASE_URL,
        ssl:
          process.env.DB_SSL === 'true' || process.env.DATABASE_URL?.includes('sslmode=require')
            ? { rejectUnauthorized: false }
            : false,
        entities: [path.join(__dirname, 'entities', '*.entity{.ts,.js}')],
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
        entities: [path.join(__dirname, 'entities', '*.entity{.ts,.js}')],
        migrations: [path.join(__dirname, 'migrations', '*{.ts,.js}')],
        synchronize: false,
      },
);

