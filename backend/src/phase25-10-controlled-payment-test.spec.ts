import * as crypto from 'crypto';
import {
  BadRequestException,
  ForbiddenException,
  ServiceUnavailableException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import {
  PaymentEntity,
  PaymentStatus,
  PaymentErrorCode,
  assertValidPaymentStateTransition,
  isValidPaymentStateTransition,
  toMinorUnits,
} from './database/entities/payment.entity';
import {
  BookingEntity,
  BookingStatus,
  BookingType,
  VALID_BOOKING_TRANSITIONS,
} from './database/entities/booking.entity';
import {
  PaymentReconciliationEntity,
  ReconciliationStatus,
  ReconciliationMismatchCategory,
} from './database/entities/payment-reconciliation.entity';
import {
  PaymentRecoveryEntity,
  FailureCategory,
  RecoveryStatus,
} from './database/entities/payment-recovery.entity';
import { WebhookEventEntity } from './database/entities/webhook-event.entity';
import { IdempotencyRecordEntity } from './database/entities/idempotency-record.entity';
import { User, UserRole } from './database/entities/user.entity';
import { AuditLogEntity } from './database/entities/audit-log.entity';
import { PaymentConfigService, PaymentMode, PaymentConfigStatus } from './modules/payments/payment-config.service';
import { PaymentReconciliationService } from './modules/payments/payment-reconciliation.service';
import { PaymentRecoveryService } from './modules/payments/payment-recovery.service';
import { IdempotencyService } from './modules/bookings/idempotency.service';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { ControlledPaymentTestService } from './modules/payments/controlled-payment-test.service';
import { RolesGuard } from './modules/auth/guards/roles.guard';
import { Reflector } from '@nestjs/core';

describe('PLAZA Phase 25.10 — Controlled Production Payment Test Safeguards Suite', () => {
  let paymentStore: Map<string, PaymentEntity>;
  let bookingStore: Map<string, BookingEntity>;
  let reconStore: Map<string, PaymentReconciliationEntity>;
  let recoveryStore: Map<string, PaymentRecoveryEntity>;
  let idempotencyStore: Map<string, IdempotencyRecordEntity>;
  let auditLogsStore: Map<string, AuditLogEntity>;

  let mockPaymentRepo: any;
  let mockBookingRepo: any;
  let mockReconRepo: any;
  let mockRecoveryRepo: any;
  let mockIdempRepo: any;
  let mockWebhookRepo: any;
  let mockAuditLogRepo: any;
  let mockDataSource: any;

  let simulatedAdapter: SimulatedPaymentAdapter;
  let paymentConfigService: PaymentConfigService;
  let recoveryService: PaymentRecoveryService;
  let reconService: PaymentReconciliationService;
  let idempotencyService: IdempotencyService;

  const adminActor = {
    id: 'usr_admin_ops_01',
    email: 'admin.ops@plaza.club',
    role: UserRole.ADMIN,
  };

  const nonAdminActor = {
    id: 'usr_customer_99',
    email: 'guest@plaza.club',
    role: UserRole.USER,
  };

  beforeEach(() => {
    paymentStore = new Map();
    bookingStore = new Map();
    reconStore = new Map();
    recoveryStore = new Map();
    idempotencyStore = new Map();
    auditLogsStore = new Map();

    mockPaymentRepo = {
      create: jest.fn((entity) => ({ id: `pay_${Date.now()}`, ...entity })),
      save: jest.fn(async (entity) => {
        const id = entity.id || `pay_${Date.now()}`;
        const saved = { ...entity, id, updatedAt: new Date() };
        paymentStore.set(id, saved);
        return saved;
      }),
      findOne: jest.fn(async ({ where }) => {
        for (const item of paymentStore.values()) {
          if (where.id && item.id === where.id) return item;
          if (where.bookingId && item.bookingId === where.bookingId) return item;
          if (where.providerOrderId && item.providerOrderId === where.providerOrderId) return item;
        }
        return null;
      }),
      find: jest.fn(async () => Array.from(paymentStore.values())),
    };

    mockBookingRepo = {
      create: jest.fn((entity) => ({ id: `bk_${Date.now()}`, ...entity })),
      save: jest.fn(async (entity) => {
        const id = entity.id || `bk_${Date.now()}`;
        const saved = { ...entity, id, updatedAt: new Date() };
        bookingStore.set(id, saved);
        return saved;
      }),
      findOne: jest.fn(async ({ where }) => {
        for (const item of bookingStore.values()) {
          if (where.id && item.id === where.id) return item;
        }
        return null;
      }),
    };

    mockReconRepo = {
      create: jest.fn((entity) => ({ id: `recon_${Date.now()}`, ...entity })),
      save: jest.fn(async (entity) => {
        const id = entity.id || `recon_${Date.now()}`;
        const saved = { ...entity, id, updatedAt: new Date() };
        reconStore.set(id, saved);
        return saved;
      }),
      findOne: jest.fn(async ({ where }) => {
        for (const item of reconStore.values()) {
          if (where.id && item.id === where.id) return item;
          if (where.paymentId && item.paymentId === where.paymentId) return item;
        }
        return null;
      }),
      find: jest.fn(async () => Array.from(reconStore.values())),
    };

    mockRecoveryRepo = {
      create: jest.fn((entity) => ({ id: `recov_${Date.now()}`, ...entity })),
      save: jest.fn(async (entity) => {
        const id = entity.id || `recov_${Date.now()}`;
        const saved = { ...entity, id, updatedAt: new Date() };
        recoveryStore.set(id, saved);
        return saved;
      }),
      findOne: jest.fn(async ({ where }) => {
        for (const item of recoveryStore.values()) {
          if (where.id && item.id === where.id) return item;
          if (where.paymentId && item.paymentId === where.paymentId) return item;
        }
        return null;
      }),
      find: jest.fn(async (options: any) => {
        const where = options?.where;
        if (!where) return Array.from(recoveryStore.values());
        return Array.from(recoveryStore.values()).filter((item) => {
          if (where.recoveryStatus && item.recoveryStatus !== where.recoveryStatus) return false;
          return true;
        });
      }),
    };

    mockIdempRepo = {
      create: jest.fn((entity) => ({ id: `idemp_${Date.now()}`, ...entity })),
      save: jest.fn(async (entity) => {
        idempotencyStore.set(entity.key, entity);
        return entity;
      }),
      findOne: jest.fn(async ({ where }) => idempotencyStore.get(where.key) || null),
    };

    mockWebhookRepo = {
      create: jest.fn((entity) => ({ id: `wh_${Date.now()}`, ...entity })),
      save: jest.fn(async (entity) => entity),
      findOne: jest.fn(async () => null),
    };

    mockAuditLogRepo = {
      create: jest.fn((entity) => ({ id: `aud_${Date.now()}`, ...entity })),
      save: jest.fn(async (entity) => {
        const id = entity.id || `aud_${Date.now()}`;
        auditLogsStore.set(id, entity);
        return entity;
      }),
      find: jest.fn(async () => Array.from(auditLogsStore.values())),
    };

    mockDataSource = {
      transaction: jest.fn(async (callback: any) => {
        return await callback({
          findOne: async (entityClass: any, opts: any) => {
            if (entityClass === PaymentEntity) return mockPaymentRepo.findOne(opts);
            if (entityClass === PaymentReconciliationEntity) return mockReconRepo.findOne(opts);
            if (entityClass === BookingEntity) return mockBookingRepo.findOne(opts);
            if (entityClass === PaymentRecoveryEntity) return mockRecoveryRepo.findOne(opts);
            return null;
          },
          find: async (entityClass: any, opts: any) => {
            if (entityClass === PaymentEntity) return mockPaymentRepo.find(opts);
            if (entityClass === PaymentRecoveryEntity) return mockRecoveryRepo.find(opts);
            if (entityClass === PaymentReconciliationEntity) return mockReconRepo.find(opts);
            return [];
          },
          create: (entityClass: any, data: any) => ({ ...data }),
          save: async (entity: any) => {
            if (entity.totalPrice !== undefined) return mockBookingRepo.save(entity);
            if (entity.amount !== undefined) return mockPaymentRepo.save(entity);
            if (entity.mismatchCategory !== undefined) return mockReconRepo.save(entity);
            if (entity.failureCategory !== undefined) return mockRecoveryRepo.save(entity);
            return entity;
          },
        });
      }),
    };

    paymentConfigService = new PaymentConfigService({
      PAYMENT_MODE: 'SIMULATED',
      RAZORPAY_LIVE_ENABLED: 'false',
    });
    simulatedAdapter = new SimulatedPaymentAdapter();
    recoveryService = new PaymentRecoveryService(mockRecoveryRepo);
    idempotencyService = new IdempotencyService(mockIdempRepo);
    reconService = new PaymentReconciliationService(
      mockReconRepo,
      mockPaymentRepo,
      mockBookingRepo,
      mockWebhookRepo,
      mockRecoveryRepo,
      mockIdempRepo,
      mockDataSource,
      paymentConfigService,
      simulatedAdapter,
      new RazorpayAdapter(paymentConfigService),
      recoveryService,
      idempotencyService,
    );
  });

  // =========================================================================
  // SECTION 1: PREFLIGHT CHECKLIST & FAIL-CLOSED SAFETY GATES
  // =========================================================================
  describe('1. Preflight Checklist & Fail-Closed Safety Gates', () => {
    it('1.1 should fail closed when ENABLE_CONTROLLED_PRODUCTION_PAYMENT_TEST is false or omitted', async () => {
      const controlledService = new ControlledPaymentTestService(
        mockPaymentRepo,
        mockBookingRepo,
        mockReconRepo,
        mockRecoveryRepo,
        mockIdempRepo,
        paymentConfigService,
        reconService,
        recoveryService,
        simulatedAdapter,
        new RazorpayAdapter(paymentConfigService),
        mockDataSource,
        {
          ENABLE_CONTROLLED_PRODUCTION_PAYMENT_TEST: 'false',
          PAYMENT_MODE: 'SIMULATED',
          RAZORPAY_LIVE_ENABLED: 'false',
        },
      );

      const preflight = await controlledService.runPreflightCheck();
      expect(preflight.passed).toBe(false);
      expect(preflight.checks.optInEnabled).toBe(false);
      expect(preflight.rejectionReasons).toContain('ENABLE_CONTROLLED_PRODUCTION_PAYMENT_TEST is not true');

      await expect(controlledService.createControlledTestOrder(adminActor)).rejects.toThrow(
        ServiceUnavailableException,
      );
    });

    it('1.2 should pass preflight check when explicit opt-in is enabled in safe simulated mode', async () => {
      const controlledService = new ControlledPaymentTestService(
        mockPaymentRepo,
        mockBookingRepo,
        mockReconRepo,
        mockRecoveryRepo,
        mockIdempRepo,
        paymentConfigService,
        reconService,
        recoveryService,
        simulatedAdapter,
        new RazorpayAdapter(paymentConfigService),
        mockDataSource,
        {
          ENABLE_CONTROLLED_PRODUCTION_PAYMENT_TEST: 'true',
          PAYMENT_MODE: 'SIMULATED',
          RAZORPAY_LIVE_ENABLED: 'false',
        },
      );

      const preflight = await controlledService.runPreflightCheck();
      expect(preflight.passed).toBe(true);
      expect(preflight.checks.optInEnabled).toBe(true);
      expect(preflight.checks.testCountWithinLimit).toBe(true);
      expect(preflight.checks.serverAuthoritativeAmountConfigured).toBe(true);
      expect(preflight.details.fixedTestAmount).toBe(1.0);
      expect(preflight.details.testCurrency).toBe('INR');
      expect(preflight.rejectionReasons).toHaveLength(0);
    });

    it('1.3 should fail closed if payment configuration is invalid or misconfigured', async () => {
      expect(() => {
        new PaymentConfigService({
          PAYMENT_MODE: 'RAZORPAY',
          RAZORPAY_LIVE_ENABLED: 'true',
          // Missing required credentials
        });
      }).toThrow(/Missing required payment configuration/);
    });
  });

  // =========================================================================
  // SECTION 2: HARD TRANSACTION LIMITS & SERVER-AUTHORITATIVE AMOUNT
  // =========================================================================
  describe('2. Hard Transaction Limits & Server-Authoritative Amount', () => {
    let controlledService: ControlledPaymentTestService;

    beforeEach(() => {
      controlledService = new ControlledPaymentTestService(
        mockPaymentRepo,
        mockBookingRepo,
        mockReconRepo,
        mockRecoveryRepo,
        mockIdempRepo,
        paymentConfigService,
        reconService,
        recoveryService,
        simulatedAdapter,
        new RazorpayAdapter(paymentConfigService),
        mockDataSource,
        {
          ENABLE_CONTROLLED_PRODUCTION_PAYMENT_TEST: 'true',
          PAYMENT_MODE: 'SIMULATED',
          RAZORPAY_LIVE_ENABLED: 'false',
        },
      );
    });

    it('2.1 should enforce MAX_CONTROLLED_TESTS = 1 invariant', () => {
      expect(controlledService.MAX_CONTROLLED_TESTS).toBe(1);
      expect(controlledService.getExecutedTestCount()).toBe(0);
      expect(controlledService.isGateClosed()).toBe(false);
    });

    it('2.2 should strictly use server-controlled amount ₹1.00 (100 paise)', async () => {
      const order = await controlledService.createControlledTestOrder(adminActor);
      expect(order.amount).toBe(1.0);
      expect(order.amountInMinorUnits).toBe(100);
      expect(order.currency).toBe('INR');
      expect(order.controlledProductionPaymentTest).toBe(true);
    });

    it('2.3 should isolate test booking with dedicated metadata', async () => {
      const order = await controlledService.createControlledTestOrder(adminActor);
      const booking = await mockBookingRepo.findOne({ where: { id: order.bookingId } });
      expect(booking).toBeDefined();
      expect(booking.title).toContain('[CONTROLLED_PRODUCTION_TEST]');
      expect(booking.metadata.controlledProductionPaymentTest).toBe(true);
      expect(booking.metadata.testId).toBe(order.testId);
    });
  });

  // =========================================================================
  // SECTION 3: END-TO-END CONTROLLED TRANSACTION LIFECYCLE
  // =========================================================================
  describe('3. End-to-End Controlled Transaction Lifecycle & Verification', () => {
    let controlledService: ControlledPaymentTestService;

    beforeEach(() => {
      controlledService = new ControlledPaymentTestService(
        mockPaymentRepo,
        mockBookingRepo,
        mockReconRepo,
        mockRecoveryRepo,
        mockIdempRepo,
        paymentConfigService,
        reconService,
        recoveryService,
        simulatedAdapter,
        new RazorpayAdapter(paymentConfigService),
        mockDataSource,
        {
          ENABLE_CONTROLLED_PRODUCTION_PAYMENT_TEST: 'true',
          PAYMENT_MODE: 'SIMULATED',
          RAZORPAY_LIVE_ENABLED: 'false',
        },
      );
    });

    it('3.1 should execute the complete controlled flow: Order -> Verify -> Reconcile', async () => {
      // 1. Create order
      const order = await controlledService.createControlledTestOrder(adminActor);
      expect(order.status).toBe(PaymentStatus.PENDING);

      // Register mock provider payment for verification
      const providerPaymentId = `pay_sim_${order.testId}`;
      simulatedAdapter.registerProviderPayment({
        paymentId: providerPaymentId,
        orderId: order.providerOrderId,
        amount: 1.0,
        amountInMinorUnits: 100,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      // 2. Verify payment independently on server
      const verification = await controlledService.verifyControlledPayment(
        order.testId,
        providerPaymentId,
        'simulated_hmac_sig_123',
      );

      expect(verification.paymentStatus).toBe(PaymentStatus.CAPTURED);
      expect(verification.bookingStatus).toBe(BookingStatus.CONFIRMED);
      expect(verification.reconciliationStatus).toBe(ReconciliationStatus.RESOLVED);
      expect(controlledService.getExecutedTestCount()).toBe(1);
    });

    it('3.2 should permanently refuse a second test payment after max count is reached', async () => {
      // First transaction
      const order = await controlledService.createControlledTestOrder(adminActor);
      simulatedAdapter.registerProviderPayment({
        paymentId: `pay_sim_${order.testId}`,
        orderId: order.providerOrderId,
        amount: 1.0,
        amountInMinorUnits: 100,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      await controlledService.verifyControlledPayment(order.testId, `pay_sim_${order.testId}`);
      expect(controlledService.isGateClosed()).toBe(true);

      // Second transaction attempt -> rejected
      await expect(controlledService.createControlledTestOrder(adminActor)).rejects.toThrow(
        ServiceUnavailableException,
      );
    });
  });

  // =========================================================================
  // SECTION 4: IMMEDIATE ROLLBACK / REFUND & POST-REFUND RECONCILIATION
  // =========================================================================
  describe('4. Immediate Rollback / Refund & Post-Refund Reconciliation', () => {
    let controlledService: ControlledPaymentTestService;

    beforeEach(() => {
      controlledService = new ControlledPaymentTestService(
        mockPaymentRepo,
        mockBookingRepo,
        mockReconRepo,
        mockRecoveryRepo,
        mockIdempRepo,
        paymentConfigService,
        reconService,
        recoveryService,
        simulatedAdapter,
        new RazorpayAdapter(paymentConfigService),
        mockDataSource,
        {
          ENABLE_CONTROLLED_PRODUCTION_PAYMENT_TEST: 'true',
          PAYMENT_MODE: 'SIMULATED',
          RAZORPAY_LIVE_ENABLED: 'false',
        },
      );
    });

    it('4.1 should execute canonical rollback: CAPTURED -> REFUND_PENDING -> REFUNDED', async () => {
      const order = await controlledService.createControlledTestOrder(adminActor);
      simulatedAdapter.registerProviderPayment({
        paymentId: `pay_sim_${order.testId}`,
        orderId: order.providerOrderId,
        amount: 1.0,
        amountInMinorUnits: 100,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      await controlledService.verifyControlledPayment(order.testId, `pay_sim_${order.testId}`);

      // Execute immediate rollback
      const refundResult = await controlledService.rollbackControlledTest(order.testId, adminActor);
      expect(refundResult.paymentStatus).toBe(PaymentStatus.REFUNDED);
      expect(refundResult.refundAmount).toBe(1.0);
      expect(refundResult.refundId).toMatch(/^rfnd_cpt_/);
      expect(refundResult.gateClosed).toBe(true);

      // Verify payment entity in store
      const paymentInDb = await mockPaymentRepo.findOne({ where: { id: `pay_${order.testId}` } });
      expect(paymentInDb.status).toBe(PaymentStatus.REFUNDED);
      expect(paymentInDb.refundAmount).toBe(1.0);
    });

    it('4.2 should reject duplicate refund attempts idempotently', async () => {
      const order = await controlledService.createControlledTestOrder(adminActor);
      simulatedAdapter.registerProviderPayment({
        paymentId: `pay_sim_${order.testId}`,
        orderId: order.providerOrderId,
        amount: 1.0,
        amountInMinorUnits: 100,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      await controlledService.verifyControlledPayment(order.testId, `pay_sim_${order.testId}`);
      await controlledService.rollbackControlledTest(order.testId, adminActor);

      // Duplicate refund attempt -> rejected because status is already REFUNDED (not CAPTURED)
      await expect(controlledService.rollbackControlledTest(order.testId, adminActor)).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  // =========================================================================
  // SECTION 5: RBAC & AUDIT LOGGING
  // =========================================================================
  describe('5. RBAC & Audit Trail Enforcement', () => {
    let rolesGuard: RolesGuard;
    let reflector: Reflector;

    beforeEach(() => {
      reflector = new Reflector();
      rolesGuard = new RolesGuard(reflector);
    });

    const createCtx = (userRole?: UserRole) => {
      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([UserRole.ADMIN, UserRole.SUPER_ADMIN]);
      return {
        getHandler: () => ({}),
        getClass: () => ({}),
        switchToHttp: () => ({
          getRequest: () => ({
            user: userRole ? { id: 'usr_test', role: userRole } : undefined,
          }),
        }),
      } as any;
    };

    it('5.1 should permit ADMIN role to access controlled test endpoints', () => {
      expect(rolesGuard.canActivate(createCtx(UserRole.ADMIN))).toBe(true);
      expect(rolesGuard.canActivate(createCtx(UserRole.SUPER_ADMIN))).toBe(true);
    });

    it('5.2 should strictly reject USER and PARTNER roles from controlled test', () => {
      expect(() => rolesGuard.canActivate(createCtx(UserRole.USER))).toThrow(ForbiddenException);
      expect(() => rolesGuard.canActivate(createCtx(UserRole.PARTNER_OWNER))).toThrow(ForbiddenException);
      expect(() => rolesGuard.canActivate(createCtx(UserRole.PARTNER_MANAGER))).toThrow(ForbiddenException);
      expect(() => rolesGuard.canActivate(createCtx(UserRole.PARTNER_STAFF))).toThrow(ForbiddenException);
    });
  });
});
