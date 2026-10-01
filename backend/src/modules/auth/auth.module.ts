import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { User } from '../../database/entities/user.entity';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from './guards/roles.guard';

const KNOWN_PLACEHOLDER_SECRETS = new Set([
  'plaza_dev_jwt_secret_change_in_production',
  'secret',
  'changeme',
  'placeholder',
  '123456',
  'jwt_secret',
  'password',
  'default_secret',
  'admin',
]);

export const validateAndGetJwtSecret = (env = process.env): string => {
  const nodeEnv = (env.NODE_ENV || 'development').toLowerCase();
  const rawSecret = env.JWT_SECRET;
  const isStrictEnv = nodeEnv === 'production' || nodeEnv === 'staging';

  if (isStrictEnv) {
    if (rawSecret === undefined) {
      throw new Error(`FATAL SECURITY ERROR: JWT_SECRET must be explicitly set in ${nodeEnv}. Application startup aborted.`);
    }
    const secret = rawSecret.trim();
    if (secret.length === 0) {
      throw new Error(`FATAL SECURITY ERROR: JWT_SECRET cannot be empty or whitespace in ${nodeEnv}. Application startup aborted.`);
    }
    if (KNOWN_PLACEHOLDER_SECRETS.has(secret.toLowerCase())) {
      throw new Error(`FATAL SECURITY ERROR: Insecure placeholder JWT_SECRET detected in ${nodeEnv}. Application startup aborted.`);
    }
    if (secret.length < 32) {
      throw new Error(`FATAL SECURITY ERROR: JWT_SECRET is too weak in ${nodeEnv} (must be at least 32 characters long, got ${secret.length}). Application startup aborted.`);
    }
    return secret;
  }

  // Development & Test environments
  if (rawSecret && rawSecret.trim().length > 0) {
    return rawSecret.trim();
  }
  return 'plaza_dev_jwt_secret_change_in_production';
};

@Module({
  imports: [
    TypeOrmModule.forFeature([User]),
    JwtModule.register({
      secret: validateAndGetJwtSecret(),
      signOptions: { expiresIn: (process.env.JWT_EXPIRES_IN as any) || '7d' },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtAuthGuard, RolesGuard],
  exports: [AuthService, JwtAuthGuard, RolesGuard, JwtModule],
})
export class AuthModule {}
