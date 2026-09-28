import {
  BadRequestException,
  ExecutionContext,
  ForbiddenException,
  Logger,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

import {
  PaymentConfigService,
  PaymentConfigStatus,
  PaymentMode,
} from './modules/payments/payment-config.service';
import { PaymentService } from './modules/payments/payment.service';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { PaymentsController } from './modules/payments/payments.controller';
import { WebhooksController } from './modules/payments/webhooks.controller';
import { AppController } from './app.controller';
import { AdminController } from './modules/admin/admin.controller';
import { AdminService } from './modules/admin/admin.service';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from './modules/auth/guards/roles.guard';
import { User, UserRole } from './database/entities/user.entity';
import { BookingEntity, BookingStatus, BookingType } from './database/entities/booking.entity';
import { PaymentEntity, PaymentStatus } from './database/entities/payment.entity';

describe('Phase 25.1 — Razorpay Production Configuration & Payment Mode Hardening', () => {
  const ORIGINAL_ENV = { ...process.env };

  beforeEach(() => {
    process.env = { ...ORIGINAL_ENV };
    delete process.env.PAYMENT_MODE;
    delete process.env.RAZORPAY_LIVE_ENABLED;
    delete process.env.RAZORPAY_KEY_ID;
    delete process.env.RAZORPAY_KEY_SECRET;
    delete process.env.RAZORPAY_WEBHOOK_SECRET;
    process.env.NODE_ENV = 'test';
  });

  afterAll(() => {
    process.env = ORIGINAL_ENV;
  });

  // =========================================================================
  // TEST 1 & TEST 2: SIMULATED MODE & ABSENT CREDENTIALS
  // =========================================================================
  describe('Test 1 & Test 2: SIMULATED Mode & Absent Razorpay Credentials', () => {
    it('Test 1: PAYMENT_MODE=SIMULATED and RAZORPAY_LIVE_ENABLED=false boots safely with simulated adapter and live disabled', () => {
      const env: NodeJS.ProcessEnv = {
        NODE_ENV: 'development',
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      };

      const configService = new PaymentConfigService(env);
      const summary = configService.getSafeSummary();

      expect(summary.paymentMode).toBe(PaymentMode.SIMULATED);
      expect(summary.razorpayLiveEnabled).toBe(false);
      expect(summary.paymentConfigStatus).toBe(PaymentConfigStatus.SIMULATED_READY);
      expect(summary.activeProvider).toBe('simulated');
      expect(summary.liveOperationsAllowed).toBe(false);

      const razorpayAdapter = new RazorpayAdapter(configService);
      const simulatedAdapter = new SimulatedPaymentAdapter();
      const paymentService = new PaymentService(
        razorpayAdapter,
        simulatedAdapter,
        undefined,
        configService,
      );

      expect(razorpayAdapter.isClientInitialized()).toBe(false);
      expect(paymentService.getProvider().providerName).toBe('simulated');
    });

    it('Test 2: PAYMENT_MODE=SIMULATED succeeds when all Razorpay credentials are absent', async () => {
      const env: NodeJS.ProcessEnv = {
        NODE_ENV: 'production',
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      };

      const configService = new PaymentConfigService(env);
      const razorpayAdapter = new RazorpayAdapter(configService);
      const simulatedAdapter = new SimulatedPaymentAdapter();
      const paymentService = new PaymentService(
        razorpayAdapter,
        simulatedAdapter,
        undefined,
        configService,
      );

      const intent = await paymentService.processPayment('PLZ-SIM-101', 1250, 'UPI_FAST', 'usr_1');
      expect(intent.provider).toBe('simulated');
      expect(intent.status).toBe('COMPLETED');
      expect(intent.amount).toBe(1250);
    });
  });

  // =========================================================================
  // TEST 3 & TEST 7: RAZORPAY MODE WITH LIVE DISABLED (SAFETY GATE)
  // =========================================================================
  describe('Test 3 & Test 7: RAZORPAY Mode with RAZORPAY_LIVE_ENABLED=false Safety Gate', () => {
    it('Test 3: PAYMENT_MODE=RAZORPAY + RAZORPAY_LIVE_ENABLED=false boots safely as RAZORPAY_DISABLED and rejects payment operations without simulated fallback', async () => {
      const env: NodeJS.ProcessEnv = {
        NODE_ENV: 'test',
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'false',
      };

      const configService = new PaymentConfigService(env);
      const summary = configService.getSafeSummary();

      expect(summary.paymentMode).toBe(PaymentMode.RAZORPAY);
      expect(summary.razorpayLiveEnabled).toBe(false);
      expect(summary.paymentConfigStatus).toBe(PaymentConfigStatus.RAZORPAY_DISABLED);
      expect(summary.activeProvider).toBe('none');
      expect(summary.liveOperationsAllowed).toBe(false);

      const razorpayAdapter = new RazorpayAdapter(configService);
      const simulatedAdapter = new SimulatedPaymentAdapter();
      const paymentService = new PaymentService(
        razorpayAdapter,
        simulatedAdapter,
        undefined,
        configService,
      );

      // Must NOT fall back to SimulatedPaymentAdapter — must reject safely
      expect(() => paymentService.getProvider()).toThrow(ServiceUnavailableException);
      await expect(
        paymentService.processPayment('PLZ-RZP-DISABLED-1', 999, 'CARD', 'usr_1'),
      ).rejects.toThrow(/RAZORPAY_LIVE_DISABLED/);
      await expect(
        paymentService.processRefund('pay_123', 999, 'Customer cancelled'),
      ).rejects.toThrow(/RAZORPAY_LIVE_DISABLED/);
    });

    it('Test 7: All Razorpay credentials present but RAZORPAY_LIVE_ENABLED=false keeps live operations disabled', async () => {
      const env: NodeJS.ProcessEnv = {
        NODE_ENV: 'production',
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'false',
        RAZORPAY_KEY_ID: 'rzp_test_configured_id_only',
        RAZORPAY_KEY_SECRET: 'configured_secret_value_not_logged',
        RAZORPAY_WEBHOOK_SECRET: 'configured_whsec_value_not_logged',
      };

      const configService = new PaymentConfigService(env);
      const summary = configService.getSafeSummary();

      expect(summary.paymentMode).toBe(PaymentMode.RAZORPAY);
      expect(summary.razorpayConfigured).toBe(true);
      expect(summary.razorpayLiveEnabled).toBe(false);
      expect(summary.paymentConfigStatus).toBe(PaymentConfigStatus.RAZORPAY_DISABLED);
      expect(summary.liveOperationsAllowed).toBe(false);

      const razorpayAdapter = new RazorpayAdapter(configService);
      expect(razorpayAdapter.isClientInitialized()).toBe(false);

      await expect(
        razorpayAdapter.createOrder({ bookingId: 'PLZ-MOV-1', amount: 500 }),
      ).rejects.toThrow(ServiceUnavailableException);

      const simulatedAdapter = new SimulatedPaymentAdapter();
      const paymentService = new PaymentService(
        razorpayAdapter,
        simulatedAdapter,
        undefined,
        configService,
      );

      await expect(
        paymentService.processPayment('PLZ-MOV-1', 500),
      ).rejects.toThrow(/RAZORPAY_LIVE_DISABLED/);
    });
  });

  // =========================================================================
  // TEST 4, TEST 5, TEST 6, TEST 8, TEST 9: FAIL-CLOSED CONFIGURATION VALIDATION
  // =========================================================================
  describe('Test 4, 5, 6, 8, 9: Fail-Closed Validation on Missing Secrets & Invalid Modes', () => {
    it('Test 4: PAYMENT_MODE=RAZORPAY + RAZORPAY_LIVE_ENABLED=true + missing RAZORPAY_KEY_ID fails closed', () => {
      const env: NodeJS.ProcessEnv = {
        NODE_ENV: 'production',
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_SECRET: 'valid_secret_for_test_only',
        RAZORPAY_WEBHOOK_SECRET: 'valid_whsec_for_test_only',
      };

      expect(() => new PaymentConfigService(env)).toThrow(
        /Missing required payment configuration: RAZORPAY_KEY_ID/,
      );
    });

    it('Test 5: PAYMENT_MODE=RAZORPAY + RAZORPAY_LIVE_ENABLED=true + missing RAZORPAY_KEY_SECRET fails closed', () => {
      const env: NodeJS.ProcessEnv = {
        NODE_ENV: 'production',
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: 'rzp_test_id_for_test',
        RAZORPAY_WEBHOOK_SECRET: 'valid_whsec_for_test_only',
      };

      expect(() => new PaymentConfigService(env)).toThrow(
        /Missing required payment configuration: RAZORPAY_KEY_SECRET/,
      );
    });

    it('Test 6: PAYMENT_MODE=RAZORPAY + RAZORPAY_LIVE_ENABLED=true + missing RAZORPAY_WEBHOOK_SECRET fails closed', () => {
      const env: NodeJS.ProcessEnv = {
        NODE_ENV: 'production',
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: 'rzp_test_id_for_test',
        RAZORPAY_KEY_SECRET: 'valid_secret_for_test_only',
      };

      expect(() => new PaymentConfigService(env)).toThrow(
        /Missing required payment configuration: RAZORPAY_WEBHOOK_SECRET/,
      );
    });

    it('Test 8: Invalid PAYMENT_MODE=WHATEVER fails configuration validation closed', () => {
      expect(
        () =>
          new PaymentConfigService({
            PAYMENT_MODE: 'WHATEVER',
            RAZORPAY_LIVE_ENABLED: 'false',
          }),
      ).toThrow(/Invalid PAYMENT_MODE configuration/);

      expect(
        () =>
          new PaymentConfigService({
            PAYMENT_MODE: '',
            RAZORPAY_LIVE_ENABLED: 'false',
          }),
      ).toThrow(/Invalid PAYMENT_MODE configuration/);

      expect(
        () =>
          new PaymentConfigService({
            PAYMENT_MODE: '   ',
            RAZORPAY_LIVE_ENABLED: 'false',
          }),
      ).toThrow(/Invalid PAYMENT_MODE configuration/);
    });

    it('Test 9: Production environment (NODE_ENV=production) with PAYMENT_MODE=RAZORPAY and missing required configuration fails closed', () => {
      const env: NodeJS.ProcessEnv = {
        NODE_ENV: 'production',
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'false',
      };

      expect(() => new PaymentConfigService(env)).toThrow(
        /Missing required payment configuration: RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, RAZORPAY_WEBHOOK_SECRET/,
      );
    });

    it('Rejects empty, whitespace-only, template-placeholder secrets, and malformed RAZORPAY_LIVE_ENABLED values', () => {
      // Empty & whitespace secrets
      expect(
        () =>
          new PaymentConfigService({
            PAYMENT_MODE: 'RAZORPAY',
            RAZORPAY_LIVE_ENABLED: 'true',
            RAZORPAY_KEY_ID: '   ',
            RAZORPAY_KEY_SECRET: '\t\n ',
            RAZORPAY_WEBHOOK_SECRET: '',
          }),
      ).toThrow(/Missing required payment configuration/);

      // Template placeholder values must not pass live validation
      expect(
        () =>
          new PaymentConfigService({
            PAYMENT_MODE: 'RAZORPAY',
            RAZORPAY_LIVE_ENABLED: 'true',
            RAZORPAY_KEY_ID: 'rzp_test_REPLACE_WITH_YOUR_KEY_ID',
            RAZORPAY_KEY_SECRET: 'REPLACE_WITH_YOUR_KEY_SECRET',
            RAZORPAY_WEBHOOK_SECRET: 'whsec_REPLACE_WITH_YOUR_WEBHOOK_SECRET',
          }),
      ).toThrow(/Missing required payment configuration/);

      // Malformed boolean flag
      expect(
        () =>
          new PaymentConfigService({
            PAYMENT_MODE: 'SIMULATED',
            RAZORPAY_LIVE_ENABLED: 'yes_please',
          }),
      ).toThrow(/Invalid RAZORPAY_LIVE_ENABLED configuration/);

      // Contradictory SIMULATED + RAZORPAY_LIVE_ENABLED=true
      expect(
        () =>
          new PaymentConfigService({
            PAYMENT_MODE: 'SIMULATED',
            RAZORPAY_LIVE_ENABLED: 'true',
          }),
      ).toThrow();
    });
  });

  // =========================================================================
  // TEST 10, TEST 11, TEST 12: ENDPOINT & LOG SECRET LEAKAGE AUDIT
  // =========================================================================
  describe('Test 10, 11, 12: Health & Configuration Status Endpoints Never Leak Secrets', () => {
    const SENSITIVE_KEY_ID = 'rzp_test_sensitive_identifier_999';
    const SENSITIVE_KEY_SECRET = 'super_confidential_key_secret_do_not_leak_888';
    const SENSITIVE_WEBHOOK_SECRET = 'super_confidential_whsec_do_not_leak_777';

    it('Test 11: Public health endpoint (GET /api/v1/health) returns 200 UP with paymentMode and leaks zero secrets', () => {
      process.env.PAYMENT_MODE = 'SIMULATED';
      process.env.RAZORPAY_LIVE_ENABLED = 'false';
      process.env.RAZORPAY_KEY_ID = SENSITIVE_KEY_ID;
      process.env.RAZORPAY_KEY_SECRET = SENSITIVE_KEY_SECRET;
      process.env.RAZORPAY_WEBHOOK_SECRET = SENSITIVE_WEBHOOK_SECRET;

      const configService = new PaymentConfigService(process.env);
      const appController = new AppController(configService);
      const health = appController.healthCheck();

      expect(health.status).toBe('UP');
      expect(health.paymentMode).toBe('SIMULATED');

      const serialized = JSON.stringify(health);
      expect(serialized).not.toContain(SENSITIVE_KEY_ID);
      expect(serialized).not.toContain(SENSITIVE_KEY_SECRET);
      expect(serialized).not.toContain(SENSITIVE_WEBHOOK_SECRET);
      expect(serialized).not.toContain('razorpayKeySecret');
      expect(serialized).not.toContain('razorpayWebhookSecret');
    });

    it('Test 10 & Test 12: Admin config-status and system-health expose safe payment state, block unauthorized users, and leak zero secrets', async () => {
      process.env.PAYMENT_MODE = 'RAZORPAY';
      process.env.RAZORPAY_LIVE_ENABLED = 'false';
      process.env.RAZORPAY_KEY_ID = SENSITIVE_KEY_ID;
      process.env.RAZORPAY_KEY_SECRET = SENSITIVE_KEY_SECRET;
      process.env.RAZORPAY_WEBHOOK_SECRET = SENSITIVE_WEBHOOK_SECRET;

      const configService = new PaymentConfigService(process.env);
      const razorpayAdapter = new RazorpayAdapter(configService);
      const simulatedAdapter = new SimulatedPaymentAdapter();
      const paymentService = new PaymentService(
        razorpayAdapter,
        simulatedAdapter,
        undefined,
        configService,
      );

      const mockRepo: any = {
        count: jest.fn().mockResolvedValue(0),
        query: jest.fn().mockResolvedValue([{ 1: 1 }]),
      };

      const adminService = new AdminService(
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        mockRepo,
        paymentService,
      );
      const adminController = new AdminController(adminService);

      // Verify Test 10: Configuration status endpoint
      const configStatus = adminController.getPaymentConfigStatus();
      expect(configStatus).toEqual({
        paymentMode: PaymentMode.RAZORPAY,
        razorpayLiveEnabled: false,
        razorpayConfigured: true,
        paymentConfigStatus: PaymentConfigStatus.RAZORPAY_DISABLED,
        activeProvider: 'none',
        liveOperationsAllowed: false,
        webhookConfigured: true,
      });

      const serializedConfig = JSON.stringify(configStatus);
      expect(serializedConfig).not.toContain(SENSITIVE_KEY_ID);
      expect(serializedConfig).not.toContain(SENSITIVE_KEY_SECRET);
      expect(serializedConfig).not.toContain(SENSITIVE_WEBHOOK_SECRET);

      // Verify Test 12: Admin system-health endpoint
      const sysHealth = await adminController.getSystemHealth();
      expect(sysHealth.status).toBe('HEALTHY');
      expect(sysHealth.paymentMode).toBe(PaymentMode.RAZORPAY);
      expect(sysHealth.razorpayLiveEnabled).toBe(false);
      expect(sysHealth.razorpayConfigured).toBe(true);
      expect(sysHealth.paymentConfigStatus).toBe(PaymentConfigStatus.RAZORPAY_DISABLED);

      const serializedHealth = JSON.stringify(sysHealth);
      expect(serializedHealth).not.toContain(SENSITIVE_KEY_ID);
      expect(serializedHealth).not.toContain(SENSITIVE_KEY_SECRET);
      expect(serializedHealth).not.toContain(SENSITIVE_WEBHOOK_SECRET);

      // Verify RBAC protection on getPaymentConfigStatus
      const jwtService = new JwtService({ secret: 'test_rbac_jwt_secret' });
      const jwtAuthGuard = new JwtAuthGuard(jwtService);
      const rolesGuard = new RolesGuard(new Reflector());

      const makeContext = (headers: Record<string, string>) => {
        const req: any = { headers };
        return {
          switchToHttp: () => ({ getRequest: () => req }),
          getHandler: () => AdminController.prototype.getPaymentConfigStatus,
          getClass: () => AdminController,
        } as unknown as ExecutionContext;
      };

      // Unauthenticated -> 401
      expect(() => jwtAuthGuard.canActivate(makeContext({}))).toThrow(
        UnauthorizedException,
      );

      // Regular USER -> 403
      const userToken = jwtService.sign({
        sub: 'usr_normal_1',
        email: 'user@plaza.app',
        role: UserRole.USER,
      });
      const userCtx = makeContext({ authorization: `Bearer ${userToken}` });
      expect(jwtAuthGuard.canActivate(userCtx)).toBe(true);
      expect(() => rolesGuard.canActivate(userCtx)).toThrow(ForbiddenException);

      // ADMIN -> 200 (allowed)
      const adminToken = jwtService.sign({
        sub: 'usr_admin_1',
        email: 'admin@plaza.app',
        role: UserRole.ADMIN,
      });
      const adminCtx = makeContext({ authorization: `Bearer ${adminToken}` });
      expect(jwtAuthGuard.canActivate(adminCtx)).toBe(true);
      expect(rolesGuard.canActivate(adminCtx)).toBe(true);
    });

    it('Logs only missing variable NAMES and never logs secret values on validation failure', () => {
      const errorSpy = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
      const logSpy = jest.spyOn(Logger.prototype, 'log').mockImplementation(() => undefined);

      try {
        expect(
          () =>
            new PaymentConfigService({
              PAYMENT_MODE: 'RAZORPAY',
              RAZORPAY_LIVE_ENABLED: 'true',
              RAZORPAY_KEY_ID: SENSITIVE_KEY_ID,
              RAZORPAY_KEY_SECRET: SENSITIVE_KEY_SECRET,
              // Missing RAZORPAY_WEBHOOK_SECRET
            }),
        ).toThrow(/Missing required payment configuration: RAZORPAY_WEBHOOK_SECRET/);

        const allLoggedMessages = [
          ...errorSpy.mock.calls.map((c) => JSON.stringify(c)),
          ...logSpy.mock.calls.map((c) => JSON.stringify(c)),
        ].join(' ');

        expect(allLoggedMessages).toContain('RAZORPAY_WEBHOOK_SECRET');
        expect(allLoggedMessages).not.toContain(SENSITIVE_KEY_ID);
        expect(allLoggedMessages).not.toContain(SENSITIVE_KEY_SECRET);
      } finally {
        errorSpy.mockRestore();
        logSpy.mockRestore();
      }
    });
  });

  // =========================================================================
  // REQUIREMENT 16: STATE-MACHINE COMPATIBILITY GUARDS
  // =========================================================================
  describe('Requirement 16: Terminal Payment State-Machine Compatibility', () => {
    it('Prevents FAILED -> CAPTURED, REFUNDED -> CAPTURED, and REFUNDED -> REFUNDED transitions', async () => {
      const env: NodeJS.ProcessEnv = {
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: 'rzp_test_state_machine',
        RAZORPAY_KEY_SECRET: 'state_machine_key_secret',
        RAZORPAY_WEBHOOK_SECRET: 'state_machine_whsec',
      };

      const configService = new PaymentConfigService(env);
      const razorpayAdapter = new RazorpayAdapter(configService);
      const simulatedAdapter = new SimulatedPaymentAdapter();

      let currentPayment: PaymentEntity = {
        id: 'pay_sm_1',
        bookingId: 'bk_sm_1',
        userId: 'usr_1',
        amount: 1000,
        currency: 'INR',
        provider: 'razorpay',
        providerOrderId: 'order_sm_1',
        status: PaymentStatus.FAILED,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const mockPaymentRepo: any = {
        findOne: jest.fn().mockImplementation(async () => currentPayment),
        save: jest.fn().mockImplementation(async (p) => {
          currentPayment = p;
          return p;
        }),
      };

      const paymentService = new PaymentService(
        razorpayAdapter,
        simulatedAdapter,
        mockPaymentRepo,
        configService,
      );

      const validSignature = crypto
        .createHmac('sha256', 'state_machine_key_secret')
        .update('order_sm_1|pay_sm_1')
        .digest('hex');

      // 1. FAILED -> CAPTURED must be rejected
      await expect(
        paymentService.verifyPayment({
          bookingId: 'bk_sm_1',
          orderId: 'order_sm_1',
          paymentId: 'pay_sm_1',
          signature: validSignature,
        }),
      ).rejects.toThrow(BadRequestException);

      // 2. FAILED -> REFUNDED must be rejected
      await expect(
        paymentService.processRefund('pay_sm_1', 1000, 'Attempt refund on failed payment'),
      ).rejects.toThrow(BadRequestException);

      // 3. REFUNDED -> CAPTURED must be rejected
      currentPayment.status = PaymentStatus.REFUNDED;
      await expect(
        paymentService.verifyPayment({
          bookingId: 'bk_sm_1',
          orderId: 'order_sm_1',
          paymentId: 'pay_sm_1',
          signature: validSignature,
        }),
      ).rejects.toThrow(BadRequestException);

      // 4. REFUNDED -> REFUND_PENDING / REFUNDED must be rejected
      await expect(
        paymentService.processRefund('pay_sm_1', 1000, 'Duplicate refund attempt'),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // =========================================================================
  // TEST 13 & TEST 14: FLUTTER & REPOSITORY SECRET SCAN
  // =========================================================================
  describe('Test 13 & Test 14: Flutter & Repository Secret Scan', () => {
    const repoRoot = path.resolve(__dirname, '../..');

    function walkFiles(dir: string, exts: string[], ignoreDirs: string[] = []): string[] {
      if (!fs.existsSync(dir)) return [];
      const results: string[] = [];
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      for (const entry of entries) {
        if (ignoreDirs.includes(entry.name)) continue;
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
          results.push(...walkFiles(fullPath, exts, ignoreDirs));
        } else if (exts.length === 0 || exts.some((ext) => entry.name.endsWith(ext))) {
          results.push(fullPath);
        }
      }
      return results;
    }

    it('Test 13: Flutter lib/ and pubspec contain zero Razorpay server secrets (RAZORPAY_KEY_SECRET / RAZORPAY_WEBHOOK_SECRET)', () => {
      const flutterLibDir = path.join(repoRoot, 'lib');
      const dartFiles = walkFiles(flutterLibDir, ['.dart']);
      expect(dartFiles.length).toBeGreaterThan(0);

      for (const file of dartFiles) {
        const content = fs.readFileSync(file, 'utf8');
        expect(content).not.toContain('RAZORPAY_KEY_SECRET');
        expect(content).not.toContain('RAZORPAY_WEBHOOK_SECRET');
        expect(content).not.toMatch(/rzp_live_[A-Za-z0-9]{8,}/);
        expect(content).not.toMatch(/whsec_[A-Za-z0-9]{8,}/);
      }
    });

    it('Test 14: Repository source & config files contain no real Razorpay live credentials or hardcoded adapter secrets', () => {
      const backendSrcDir = path.join(repoRoot, 'backend/src');
      const tsFiles = walkFiles(backendSrcDir, ['.ts'], ['node_modules', 'dist']).filter(
        (f) => !f.endsWith('.spec.ts'),
      );

      for (const file of tsFiles) {
        const content = fs.readFileSync(file, 'utf8');
        // Ensure no real live Razorpay keys exist
        expect(content).not.toMatch(/rzp_live_[A-Za-z0-9]{8,}/);
        // Ensure old hardcoded fallback test credentials were removed from production source
        expect(content).not.toContain('rzp_test_plaza2026');
        expect(content).not.toContain('secret_test_plaza2026');
        expect(content).not.toContain('whsec_test_plaza2026');
      }

      // Check environment templates and render.yaml
      const configFiles = [
        path.join(repoRoot, 'render.yaml'),
        path.join(repoRoot, 'backend/.env.development'),
        path.join(repoRoot, 'backend/.env.staging.example'),
        path.join(repoRoot, 'backend/.env.production.example'),
      ];

      for (const cfgFile of configFiles) {
        if (fs.existsSync(cfgFile)) {
          const content = fs.readFileSync(cfgFile, 'utf8');
          expect(content).not.toMatch(/rzp_live_[A-Za-z0-9]{8,}/);
          expect(content).toContain('PAYMENT_MODE');
          expect(content).toContain('RAZORPAY_LIVE_ENABLED');
        }
      }
    });
  });
});
