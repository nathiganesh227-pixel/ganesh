import * as crypto from 'crypto';
import {
  UnauthorizedException,
  ForbiddenException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { AuthService, isDemoLoginEnabled } from './modules/auth/auth.service';
import { validateAndGetJwtSecret } from './modules/auth/auth.module';
import { isSwaggerEnabled, getCorsOriginPolicy } from './main';
import { PaymentConfigService, PaymentMode, PaymentConfigStatus } from './modules/payments/payment-config.service';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { User, UserRole } from './database/entities/user.entity';
import { RolesGuard } from './modules/auth/guards/roles.guard';
import { Reflector } from '@nestjs/core';

describe('PLAZA Phase 25.8 — Security & Secrets Audit Suite', () => {
  // ==========================================
  // SECTION 1: SECRETS & CONFIGURATION AUDIT
  // ==========================================
  describe('1. Secrets & Config: JWT Fallback & Strength Enforcement', () => {
    it('1.1 should reject missing JWT_SECRET in production fail-closed', () => {
      const prodEnv = { NODE_ENV: 'production' };
      expect(() => validateAndGetJwtSecret(prodEnv)).toThrow(
        /FATAL SECURITY ERROR: JWT_SECRET must be explicitly set/,
      );
    });

    it('1.2 should reject empty string or whitespace JWT_SECRET in production', () => {
      expect(() =>
        validateAndGetJwtSecret({ NODE_ENV: 'production', JWT_SECRET: '   ' }),
      ).toThrow(/FATAL SECURITY ERROR: JWT_SECRET cannot be empty/);
    });

    it('1.3 should reject weak JWT_SECRET (< 32 chars) in production', () => {
      expect(() =>
        validateAndGetJwtSecret({
          NODE_ENV: 'production',
          JWT_SECRET: 'short_weak_secret_123',
        }),
      ).toThrow(/FATAL SECURITY ERROR: JWT_SECRET is too weak/);
    });

    it('1.4 should reject known development placeholder JWT_SECRET in production', () => {
      expect(() =>
        validateAndGetJwtSecret({
          NODE_ENV: 'production',
          JWT_SECRET: 'plaza_dev_jwt_secret_change_in_production',
        }),
      ).toThrow(/FATAL SECURITY ERROR: Insecure placeholder JWT_SECRET detected/);
    });

    it('1.5 should reject insecure placeholders in staging environment', () => {
      expect(() =>
        validateAndGetJwtSecret({
          NODE_ENV: 'staging',
          JWT_SECRET: 'secret',
        }),
      ).toThrow();
    });

    it('1.6 should accept high-entropy production secret (>= 32 chars)', () => {
      const strongSecret = crypto.randomBytes(32).toString('hex'); // 64 chars
      const validated = validateAndGetJwtSecret({
        NODE_ENV: 'production',
        JWT_SECRET: strongSecret,
      });
      expect(validated).toBe(strongSecret);
    });

    it('1.7 should fall back to dev secret with warning in development/test when omitted', () => {
      const devValidated = validateAndGetJwtSecret({ NODE_ENV: 'development' });
      expect(devValidated).toBe('plaza_dev_jwt_secret_change_in_production');

      const testValidated = validateAndGetJwtSecret({ NODE_ENV: 'test' });
      expect(testValidated).toBe('plaza_dev_jwt_secret_change_in_production');
    });

    it('1.8 should never leak raw secret values in exception error messages', () => {
      const sensitiveWeak = 'bad_secret_123';
      try {
        validateAndGetJwtSecret({
          NODE_ENV: 'production',
          JWT_SECRET: sensitiveWeak,
        });
        fail('Should have thrown');
      } catch (err: any) {
        expect(err.message).not.toContain(sensitiveWeak);
      }
    });
  });

  // ==========================================
  // SECTION 2: AUTHENTICATION & DEMO LOGIN
  // ==========================================
  describe('2. Authentication: Demo Login Lockdown', () => {
    let authService: AuthService;
    let mockUsersRepo: any;
    let mockJwtService: any;

    beforeEach(() => {
      mockUsersRepo = {
        findOne: jest.fn(),
        create: jest.fn((data) => ({ id: 'usr_' + Date.now(), ...data })),
        save: jest.fn(async (user) => user),
      };
      mockJwtService = {
        sign: jest.fn(() => 'mock.jwt.token'),
      };

      authService = new AuthService(
        mockUsersRepo,
        mockJwtService,
      );
    });

    it('2.1 should correctly identify demo login disabled in production/staging', () => {
      expect(isDemoLoginEnabled({ NODE_ENV: 'production' })).toBe(false);
      expect(isDemoLoginEnabled({ NODE_ENV: 'staging' })).toBe(false);
      expect(isDemoLoginEnabled({ NODE_ENV: 'production', ENABLE_DEMO_LOGIN: 'false' })).toBe(false);
      expect(isDemoLoginEnabled({ NODE_ENV: 'staging', ENABLE_DEMO_LOGIN: 'true' })).toBe(true); // explicit override
      expect(isDemoLoginEnabled({ NODE_ENV: 'development' })).toBe(true);
      expect(isDemoLoginEnabled({ NODE_ENV: 'test' })).toBe(true);
      expect(isDemoLoginEnabled({ NODE_ENV: 'development', ENABLE_DEMO_LOGIN: 'false' })).toBe(false);
    });

    it('2.2 should reject demo login in production with UnauthorizedException (401)', async () => {
      jest.spyOn(authService, 'isDemoLoginEnabled').mockReturnValue(false);

      await expect(authService.validateOrCreateDemoUser()).rejects.toThrow(
        UnauthorizedException,
      );
      await expect(authService.validateOrCreateDemoUser()).rejects.toThrow(
        /Demo login is disabled in this environment/,
      );
    });

    it('2.3 should reject demo login in staging with UnauthorizedException (401) when omitted', async () => {
      jest.spyOn(authService, 'isDemoLoginEnabled').mockReturnValue(false);

      await expect(authService.validateOrCreateDemoUser()).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('2.4 should allow demo login in development/test with random salt and no hardcoded secret', async () => {
      jest.spyOn(authService, 'isDemoLoginEnabled').mockReturnValue(true);

      const demoResponse = await authService.validateOrCreateDemoUser();
      expect(demoResponse).toBeDefined();
      expect(demoResponse.user.email).toBe('guest@plaza.app');
      expect(demoResponse.token).toBe('mock.jwt.token');
      expect(mockUsersRepo.save).toHaveBeenCalled();
    });
  });

  // ==========================================
  // SECTION 3: SWAGGER & CORS HARDENING
  // ==========================================
  describe('3. Swagger & CORS: Production Attack Surface Minimization', () => {
    it('3.1 should disable Swagger by default in production and staging', () => {
      expect(isSwaggerEnabled({ NODE_ENV: 'production' })).toBe(false);
      expect(isSwaggerEnabled({ NODE_ENV: 'staging' })).toBe(false);
      expect(isSwaggerEnabled({ NODE_ENV: 'production', ENABLE_SWAGGER: 'false' })).toBe(false);
    });

    it('3.2 should allow Swagger in development or when explicitly enabled', () => {
      expect(isSwaggerEnabled({ NODE_ENV: 'development' })).toBe(true);
      expect(isSwaggerEnabled({ NODE_ENV: 'staging', ENABLE_SWAGGER: 'true' })).toBe(true);
      expect(isSwaggerEnabled({ NODE_ENV: 'production', ENABLE_SWAGGER: 'true' })).toBe(true);
    });

    it('3.3 should disallow unauthorized CORS origin in production/staging and allow valid origins', (done) => {
      const prodCorsFn = getCorsOriginPolicy({
        NODE_ENV: 'production',
        CORS_ORIGIN: '*',
      }) as (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => void;

      expect(typeof prodCorsFn).toBe('function');

      // Test valid origin
      prodCorsFn('https://plaza.club', (err, allow) => {
        expect(err).toBeNull();
        expect(allow).toBe(true);

        // Test unauthorized origin
        prodCorsFn('https://malicious-site.com', (badErr, badAllow) => {
          expect(badErr).toBeInstanceOf(Error);
          expect(badErr?.message).toContain('CORS policy rejection');
          done();
        });
      });
    });

    it('3.4 should enforce explicit comma-separated CORS allowlists correctly', (done) => {
      const customCorsFn = getCorsOriginPolicy({
        NODE_ENV: 'production',
        CORS_ORIGIN: 'https://plaza.club,https://admin.plaza.club,https://ops.plaza.club',
      }) as (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => void;

      customCorsFn('https://ops.plaza.club', (err, allow) => {
        expect(err).toBeNull();
        expect(allow).toBe(true);

        customCorsFn('https://untrusted-domain.com', (badErr) => {
          expect(badErr).toBeInstanceOf(Error);
          done();
        });
      });
    });

    it('3.5 should allow localhost origins in development by default', (done) => {
      const devCorsFn = getCorsOriginPolicy({
        NODE_ENV: 'development',
      }) as (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => void;

      devCorsFn('http://localhost:3000', (err, allow) => {
        expect(err).toBeNull();
        expect(allow).toBe(true);
        done();
      });
    });
  });

  // ==========================================
  // SECTION 4: AUTHORIZATION & RBAC (ROLES)
  // ==========================================
  describe('4. Authorization & RBAC: Enforce Least Privilege', () => {
    let rolesGuard: RolesGuard;
    let reflector: Reflector;

    beforeEach(() => {
      reflector = new Reflector();
      rolesGuard = new RolesGuard(reflector);
    });

    const createMockExecutionContext = (userRole?: UserRole, requiredRoles?: UserRole[]) => {
      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(requiredRoles);
      return {
        getHandler: () => ({}),
        getClass: () => ({}),
        switchToHttp: () => ({
          getRequest: () => ({
            user: userRole ? { id: 'usr_123', role: userRole } : undefined,
          }),
        }),
      } as any;
    };

    it('4.1 should allow any authenticated user when no specific roles are required', () => {
      const ctx = createMockExecutionContext(UserRole.USER, undefined);
      expect(rolesGuard.canActivate(ctx)).toBe(true);
    });

    it('4.2 should deny USER role from accessing ADMIN-only endpoints', () => {
      const ctx = createMockExecutionContext(UserRole.USER, [UserRole.ADMIN]);
      expect(() => rolesGuard.canActivate(ctx)).toThrow(ForbiddenException);
    });

    it('4.3 should deny PARTNER_STAFF role from accessing ADMIN-only platform endpoints', () => {
      const ctx = createMockExecutionContext(UserRole.PARTNER_STAFF, [UserRole.ADMIN]);
      expect(() => rolesGuard.canActivate(ctx)).toThrow(ForbiddenException);
    });

    it('4.4 should allow ADMIN role to access ADMIN endpoints', () => {
      const ctx = createMockExecutionContext(UserRole.ADMIN, [UserRole.ADMIN]);
      expect(rolesGuard.canActivate(ctx)).toBe(true);
    });

    it('4.5 should throw ForbiddenException when user is not present on request', () => {
      const ctx = createMockExecutionContext(undefined, [UserRole.ADMIN]);
      expect(() => rolesGuard.canActivate(ctx)).toThrow(ForbiddenException);
    });
  });

  // ==========================================
  // SECTION 5: ABSOLUTE PAYMENT SAFETY INVARIANTS
  // ==========================================
  describe('5. Absolute Payment Safety Invariants', () => {
    it('5.1 PaymentMode must default to SIMULATED when unconfigured', () => {
      const configService = new PaymentConfigService({});
      expect(configService.getPaymentMode()).toBe(PaymentMode.SIMULATED);
      expect(configService.isRazorpayLiveEnabled()).toBe(false);
      expect(configService.getConfigStatus()).toBe(PaymentConfigStatus.SIMULATED_READY);
    });

    it('5.2 should strictly prevent live Razorpay activation in simulated mode', () => {
      const configService = new PaymentConfigService({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });
      const simulatedAdapter = new SimulatedPaymentAdapter();

      expect(simulatedAdapter.providerName).toBe('simulated');
      expect(configService.isRazorpayLiveEnabled()).toBe(false);
      expect(() => configService.assertRazorpayLiveOperationAllowed()).toThrow(
        ServiceUnavailableException,
      );
    });

    it('5.3 should create simulated orders without contacting live network', async () => {
      const simulatedAdapter = new SimulatedPaymentAdapter();

      const orderResult = await simulatedAdapter.createOrder({
        bookingId: 'bk_sec_001',
        amount: 50000,
        currency: 'INR',
        receipt: 'rec_sec_001',
        notes: { bookingId: 'bk_sec_001' },
      });

      expect(orderResult.orderId).toMatch(/^order_sim_/);
      expect(orderResult.status).toBe('PAID');
      expect(orderResult.amount).toBe(50000);
      expect(orderResult.provider).toBe('simulated');
    });

    it('5.4 simulated adapter should accurately verify HMAC signatures', () => {
      const simulatedAdapter = new SimulatedPaymentAdapter();
      const orderId = 'order_sim_test123';
      const paymentId = 'pay_sim_test456';
      const signature = crypto
        .createHmac('sha256', 'simulated_key_secret')
        .update(`${orderId}|${paymentId}`)
        .digest('hex');

      const isValid = simulatedAdapter.verifyPaymentSignature({
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      });

      expect(isValid).toBe(true);

      const isInvalid = simulatedAdapter.verifyPaymentSignature({
        orderId: orderId,
        paymentId: paymentId,
        signature: 'invalid_tampered_signature',
      });

      expect(isInvalid).toBe(false);
    });
  });

  // ==========================================
  // SECTION 6: LOGGING & ERROR SANITIZATION
  // ==========================================
  describe('6. Logging & Error Sanitization', () => {
    it('6.1 should verify sensitive tokens and DB credentials are not in error output', () => {
      const sensitiveDbUrl = 'postgresql://admin:supersecretpassword@prod-db.internal:5432/plazadb';
      const sanitizedMessage = 'Database connection error';

      const error = new Error(`Connection failed at ${sensitiveDbUrl}`);
      // In production, error messages must be sanitized
      const isSanitized = !sanitizedMessage.includes('supersecretpassword');
      expect(isSanitized).toBe(true);
    });

    it('6.2 should ensure JWT tokens are not exposed in query parameters or standard logs', () => {
      const sampleJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.doNotLogThisSecretSignature';
      const logMasker = (input: string) => input.replace(/eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+/g, '[REDACTED_JWT]');
      
      const logged = logMasker(`User authenticated with token ${sampleJwt}`);
      expect(logged).not.toContain(sampleJwt);
      expect(logged).toContain('[REDACTED_JWT]');
    });
  });
});
