import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { json, urlencoded } from 'express';
import { DataSource } from 'typeorm';
import { AppModule } from './app.module';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { runSeed } from './database/seeds/seed';

export const isSwaggerEnabled = (env = process.env): boolean => {
  const nodeEnv = (env.NODE_ENV || 'development').toLowerCase();
  if (env.ENABLE_SWAGGER === 'true') {
    return true;
  }
  if (env.ENABLE_SWAGGER === 'false') {
    return false;
  }
  // Default: enabled in development only, disabled in production & staging
  return nodeEnv === 'development';
};

export const getCorsOriginPolicy = (env = process.env) => {
  const nodeEnv = (env.NODE_ENV || 'development').toLowerCase();
  const isProd = nodeEnv === 'production' || nodeEnv === 'staging';
  const rawOrigin = env.CORS_ORIGIN || env.CORS_ALLOWED_ORIGINS;

  if (isProd) {
    // In production/staging, never allow wildcard '*' with credentials
    if (!rawOrigin || rawOrigin.trim() === '*' || rawOrigin.trim() === '') {
      const defaultProdOrigins = ['https://plaza.club', 'https://admin.plaza.club'];
      return (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
        if (!origin || defaultProdOrigins.includes(origin)) {
          callback(null, true);
        } else {
          callback(new Error(`CORS policy rejection: origin ${origin} is not in production allowlist.`));
        }
      };
    }
    const allowedList = rawOrigin.split(',').map((o) => o.trim()).filter(Boolean);
    return (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      if (!origin || allowedList.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error(`CORS policy rejection: origin ${origin} is not allowed.`));
      }
    };
  }

  // Development & Test environments: allow configured origins, or localhost by default
  if (rawOrigin && rawOrigin !== '*') {
    const list = rawOrigin.split(',').map((o) => o.trim()).filter(Boolean);
    return list;
  }

  return (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
    // Allow mobile apps / curl (no origin) or localhost origins
    if (!origin || origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1')) {
      callback(null, true);
    } else {
      callback(null, true);
    }
  };
};

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { rawBody: true });

  // Optional database seed on startup if SEED_DATABASE=true
  if (process.env.SEED_DATABASE === 'true') {
    console.log('🌱 SEED_DATABASE=true detected: triggering database seed on startup...');
    try {
      const dataSource = app.get(DataSource);
      await runSeed(dataSource);
      console.log('✅ Database seed completed successfully on startup.');
    } catch (seedErr) {
      console.error('⚠️ Startup database seed failed (continuing application startup):', seedErr);
    }
  }

  const swaggerActive = isSwaggerEnabled();

  // Security Headers via Helmet
  app.use(
    helmet({
      contentSecurityPolicy: swaggerActive
        ? false // Allows Swagger UI to render assets when Swagger is explicitly active
        : {
            directives: {
              defaultSrc: ["'self'"],
              scriptSrc: ["'self'"],
              styleSrc: ["'self'", "'unsafe-inline'"],
              imgSrc: ["'self'", 'data:', 'https:'],
              connectSrc: ["'self'"],
              frameAncestors: ["'none'"],
              objectSrc: ["'none'"],
            },
          },
      crossOriginEmbedderPolicy: false,
      frameguard: { action: 'deny' },
      hidePoweredBy: true,
      hsts: { maxAge: 31536000, includeSubDomains: true, preload: true },
      noSniff: true,
      xssFilter: true,
    }),
  );

  // Request body size limits with exact rawBody retention for webhook signature verification
  app.use(
    json({
      limit: '2mb',
      verify: (req: any, _res, buf) => {
        req.rawBody = buf;
      },
    }),
  );
  app.use(
    urlencoded({
      extended: true,
      limit: '2mb',
      verify: (req: any, _res, buf) => {
        req.rawBody = buf;
      },
    }),
  );

  // Strict CORS configuration
  app.enableCors({
    origin: getCorsOriginPolicy() as any,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Correlation-ID'],
    credentials: true,
  });

  app.setGlobalPrefix('api/v1');

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  app.useGlobalInterceptors(new TransformInterceptor());
  app.useGlobalFilters(new AllExceptionsFilter());

  // Swagger Documentation Setup (conditionally mounted)
  if (swaggerActive) {
    const config = new DocumentBuilder()
      .setTitle('PLAZA API')
      .setDescription(
        'High-performance REST API for PLAZA - India-wide Super App (Movies, Dining, Events, Activities, Shopping, Stays, Sports)',
      )
      .setVersion('1.0')
      .addBearerAuth()
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);
    console.log(`📚 Swagger documentation enabled at /api/docs`);
  } else {
    console.log(`🔒 Swagger documentation disabled in production/staging mode.`);
  }

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 PLAZA API server running at http://127.0.0.1:${port}/api/v1`);
}

if (process.env.NODE_ENV !== 'test' && !process.env.JEST_WORKER_ID) {
  bootstrap();
}
