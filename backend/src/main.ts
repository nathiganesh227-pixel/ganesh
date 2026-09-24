import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { json, urlencoded } from 'express';
import { AppModule } from './app.module';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Security Headers via Helmet
  app.use(
    helmet({
      contentSecurityPolicy: false, // Allows Swagger UI to render assets
      crossOriginEmbedderPolicy: false,
    }),
  );

  // Request body size limits (prevents payload flood attacks)
  app.use(json({ limit: '2mb' }));
  app.use(urlencoded({ extended: true, limit: '2mb' }));

  // Strict CORS configuration
  app.enableCors({
    origin: process.env.CORS_ORIGIN || '*',
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

  // Swagger Documentation Setup
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

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 PLAZA API server running at http://127.0.0.1:${port}/api/v1`);
  console.log(`📚 Swagger documentation at http://127.0.0.1:${port}/api/docs`);
}
bootstrap();
