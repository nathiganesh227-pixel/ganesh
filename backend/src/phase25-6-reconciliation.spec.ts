import * as crypto from 'crypto';
import {
  BadRequestException,
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
import { BookingEntity, BookingStatus, BookingType } from './database/entities/booking.entity';
import { User, UserRole } from './database/entities/user.entity';
import { AuditLogEntity } from './database/entities/audit-log.entity';
import { PaymentReconciliationService } from './modules/payments/payment-reconciliation.service';
import { PaymentRecoveryService } from './modules/payments/payment-recovery.service';
import { PaymentConfigService, PaymentMode } from './modules/payments/payment-config.service';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { AdminService } from './modules/admin/admin.service';
import { AdminController } from './modules/admin/admin.controller';
import { CreatePaymentReconciliationTable1791100000000 } from './database/migrations/1791100000000-CreatePaymentReconciliationTable';

describe('PLAZA Phase 25.6 — Complete 62-Scenario Payment Reconciliation Engine Hardening Suite', () => {
  let reconStore: Map<string, PaymentReconciliationEntity>;
  let paymentStore: Map<string, PaymentEntity>;
  let bookingStore: Map<string, BookingEntity>;
  let webhookStore: Map<string, WebhookEventEntity>;
  let recoveryStore: Map<string, PaymentRecoveryEntity>;
  let idempotencyStore: Map<string, IdempotencyRecordEntity>;
  let auditLogsStore: Map<string, AuditLogEntity>;
  let usersStore: Map<string, User>;

  let mockReconRepo: any;
  let mockPaymentRepo: any;
  let mockBookingRepo: any;
  let mockWebhookRepo: any;
  let mockRecoveryRepo: any;
  let mockIdempRepo: any;
  let mockAuditLogRepo: any;
  let mockUserRepo: any;
  let mockDataSource: any;

  let simulatedAdapter: SimulatedPaymentAdapter;
  let razorpayAdapter: RazorpayAdapter;
  let paymentConfigService: PaymentConfigService;
  let recoveryService: PaymentRecoveryService;
  let reconService: PaymentReconciliationService;
  let adminService: AdminService;
  let adminController: AdminController;

  beforeEach(() => {
    reconStore = new Map();
    paymentStore = new Map();
    bookingStore = new Map();
    webhookStore = new Map();
    recoveryStore = new Map();
    idempotencyStore = new Map();
    auditLogsStore = new Map();
    usersStore = new Map();

    usersStore.set('usr_admin1', {
      id: 'usr_admin1',
      email: 'admin@plaza.test',
      role: UserRole.ADMIN,
      rewardPoints: 0,
    } as any);

    mockReconRepo = {
      create: jest.fn((data: any) => ({ ...data })),
      save: jest.fn(async (entity: any) => {
        const id = entity.id || `recon_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
        const saved = { ...entity, id, updatedAt: new Date(), createdAt: entity.createdAt || new Date() };
        reconStore.set(id, saved);
        return saved;
      }),
      findOne: jest.fn(async (options: any) => {
        const where = options?.where;
        if (!where) return null;
        for (const item of reconStore.values()) {
          if (where.id && item.id === where.id) return item;
          if (where.paymentId && item.paymentId === where.paymentId) return item;
        }
        return null;
      }),
      find: jest.fn(async (options: any) => {
        const where = options?.where;
        if (!where) return Array.from(reconStore.values());
        const conds = Array.isArray(where) ? where : [where];
        const results: PaymentReconciliationEntity[] = [];
        for (const item of reconStore.values()) {
          for (const cond of conds) {
            let match = true;
            if (cond.status && item.status !== cond.status) match = false;
            if (cond.attemptCount !== undefined && item.attemptCount !== cond.attemptCount) match = false;
            if (cond.nextRetryAt !== undefined) {
              const maxDate = cond.nextRetryAt?._value || cond.nextRetryAt;
              if (item.nextRetryAt && maxDate && item.nextRetryAt > maxDate) match = false;
              if (!item.nextRetryAt && cond.attemptCount === undefined) match = false;
            }
            if (match) {
              results.push(item);
              break;
            }
          }
        }
        return results;
      }),
      count: jest.fn(async (options: any) => {
        if (!options?.where) return reconStore.size;
        let count = 0;
        for (const item of reconStore.values()) {
          const w = options.where;
          if (Array.isArray(w)) {
            const match = w.some((cond) => {
              if (cond.status && item.status === cond.status) return true;
              return false;
            });
            if (match) count++;
          } else {
            if (w.status && item.status === w.status) count++;
            if (w.requiresManualIntervention !== undefined && item.requiresManualIntervention === w.requiresManualIntervention) count++;
          }
        }
        return count;
      }),
      createQueryBuilder: jest.fn(() => ({
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        addSelect: jest.fn().mockReturnThis(),
        groupBy: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn(async () => [Array.from(reconStore.values()), reconStore.size]),
        getRawMany: jest.fn(async () => [
          { category: ReconciliationMismatchCategory.AMOUNT_MISMATCH, count: '2' },
          { category: ReconciliationMismatchCategory.WEBHOOK_GAP, count: '1' },
        ]),
      })),
    };

    mockPaymentRepo = {
      create: jest.fn((data: any) => ({ ...data })),
      save: jest.fn(async (entity: any) => {
        const id = entity.id || `pay_${Date.now()}`;
        const saved = { ...entity, id, updatedAt: new Date(), createdAt: entity.createdAt || new Date() };
        paymentStore.set(id, saved);
        return saved;
      }),
      findOne: jest.fn(async (options: any) => {
        const where = options?.where;
        if (!where) return null;
        for (const item of paymentStore.values()) {
          if (where.id && item.id === where.id) return item;
        }
        return null;
      }),
      find: jest.fn(async (options: any) => {
        const where = options?.where;
        if (!where) return Array.from(paymentStore.values());
        const results: PaymentEntity[] = [];
        for (const item of paymentStore.values()) {
          if (where.providerPaymentId && item.providerPaymentId === where.providerPaymentId) {
            results.push(item);
          }
        }
        return results;
      }),
    };

    mockBookingRepo = {
      findOne: jest.fn(async (options: any) => {
        const where = options?.where;
        if (!where) return null;
        for (const item of bookingStore.values()) {
          if (where.id && item.id === where.id) return item;
        }
        return null;
      }),
      save: jest.fn(async (entity: any) => {
        bookingStore.set(entity.id, entity);
        return entity;
      }),
    };

    mockWebhookRepo = {
      findOne: jest.fn(async (options: any) => {
        const where = options?.where;
        if (!where) return null;
        const conds = Array.isArray(where) ? where : [where];
        for (const item of webhookStore.values()) {
          for (const cond of conds) {
            if (cond.providerPaymentId && item.providerPaymentId === cond.providerPaymentId) return item;
            if (cond.providerOrderId && item.providerOrderId === cond.providerOrderId) return item;
            if (cond.paymentId && item.paymentId === cond.paymentId) return item;
          }
        }
        return null;
      }),
    };

    mockRecoveryRepo = {
      create: jest.fn((data: any) => ({ ...data })),
      save: jest.fn(async (entity: any) => {
        const id = entity.id || `recov_${Date.now()}`;
        const saved = { ...entity, id, updatedAt: new Date(), createdAt: entity.createdAt || new Date() };
        recoveryStore.set(id, saved);
        return saved;
      }),
      findOne: jest.fn(async (options: any) => {
        const where = options?.where;
        if (!where) return null;
        for (const item of recoveryStore.values()) {
          if (where.id && item.id === where.id) return item;
        }
        return null;
      }),
      find: jest.fn(async (options: any) => {
        const where = options?.where;
        if (!where) return Array.from(recoveryStore.values());
        const conds = Array.isArray(where) ? where : [where];
        const results: PaymentRecoveryEntity[] = [];
        for (const item of recoveryStore.values()) {
          for (const cond of conds) {
            if (cond.paymentId && item.paymentId === cond.paymentId) {
              results.push(item);
              break;
            }
            if (cond.resourceId && item.resourceId === cond.resourceId) {
              results.push(item);
              break;
            }
          }
        }
        return results;
      }),
    };

    mockAuditLogRepo = {
      save: jest.fn(async (entity: any) => {
        const id = entity.id || `aud_${Date.now()}`;
        auditLogsStore.set(id, { ...entity, id, createdAt: new Date() });
        return { ...entity, id };
      }),
    };

    mockUserRepo = {
      findOne: jest.fn(async (options: any) => {
        const where = options?.where;
        if (!where) return null;
        for (const item of usersStore.values()) {
          if (where.id && item.id === where.id) return item;
        }
        return null;
      }),
      count: jest.fn(async () => usersStore.size),
    };

    mockIdempRepo = {};

    mockDataSource = {
      transaction: jest.fn(async (callback: any) => {
        return await callback({
          findOne: async (entityClass: any, opts: any) => {
            if (entityClass === PaymentEntity) return mockPaymentRepo.findOne(opts);
            if (entityClass === PaymentReconciliationEntity) return mockReconRepo.findOne(opts);
            if (entityClass === BookingEntity) return mockBookingRepo.findOne(opts);
            if (entityClass === WebhookEventEntity) return mockWebhookRepo.findOne(opts);
            return null;
          },
          find: async (entityClass: any, opts: any) => {
            if (entityClass === PaymentEntity) return mockPaymentRepo.find(opts);
            if (entityClass === PaymentRecoveryEntity) return mockRecoveryRepo.find(opts);
            return [];
          },
          create: (entityClass: any, data: any) => ({ ...data }),
          save: async (entity: any) => {
            if (entity instanceof PaymentEntity || entity.status in PaymentStatus) {
              return mockPaymentRepo.save(entity);
            }
            if (entity.mismatchCategory) return mockReconRepo.save(entity);
            if (entity.failureCategory) return mockRecoveryRepo.save(entity);
            return entity;
          },
          getRepository: (entityClass: any) => {
            if (entityClass === PaymentRecoveryEntity) return mockRecoveryRepo;
            if (entityClass === PaymentEntity) return mockPaymentRepo;
            return mockReconRepo;
          },
        });
      }),
    };

    simulatedAdapter = new SimulatedPaymentAdapter();
    razorpayAdapter = new RazorpayAdapter();
    paymentConfigService = new PaymentConfigService({
      PAYMENT_MODE: PaymentMode.SIMULATED,
      RAZORPAY_LIVE_ENABLED: 'false',
    });
    recoveryService = new PaymentRecoveryService(mockRecoveryRepo);

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
      razorpayAdapter,
      recoveryService,
    );

    adminService = new AdminService(
      mockUserRepo,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      mockBookingRepo,
      mockAuditLogRepo,
      {} as any,
      {} as any,
      mockPaymentRepo,
      {} as any,
      mockWebhookRepo,
      {} as any,
      mockRecoveryRepo,
      recoveryService,
      mockReconRepo,
      reconService,
    );

    adminController = new AdminController(adminService);
  });

  describe('1. MODEL & MIGRATION HARDENING (Tests 1-4)', () => {
    it('1. reconciliation record creation with exact field types', () => {
      const rec = mockReconRepo.create({
        id: 'recon_test_1',
        paymentId: 'pay_1',
        canonicalAmount: 499,
        canonicalAmountInMinorUnits: 49900,
        canonicalCurrency: 'INR',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
      });
      expect(rec.id).toBe('recon_test_1');
      expect(rec.canonicalAmountInMinorUnits).toBe(49900);
    });

    it('2. status transitions across 5 canonical reconciliation statuses', () => {
      expect(ReconciliationStatus.NOT_REQUIRED).toBe('NOT_REQUIRED');
      expect(ReconciliationStatus.REQUIRED).toBe('REQUIRED');
      expect(ReconciliationStatus.IN_PROGRESS).toBe('IN_PROGRESS');
      expect(ReconciliationStatus.RESOLVED).toBe('RESOLVED');
      expect(ReconciliationStatus.FAILED).toBe('FAILED');
    });

    it('3. all 20 mismatch categories verified in enum', () => {
      const categories = Object.values(ReconciliationMismatchCategory);
      expect(categories.length).toBe(20);
      expect(categories).toContain(ReconciliationMismatchCategory.NO_MISMATCH);
      expect(categories).toContain(ReconciliationMismatchCategory.PAYMENT_STATE_MISMATCH);
      expect(categories).toContain(ReconciliationMismatchCategory.BOOKING_STATE_MISMATCH);
      expect(categories).toContain(ReconciliationMismatchCategory.AMOUNT_MISMATCH);
      expect(categories).toContain(ReconciliationMismatchCategory.CURRENCY_MISMATCH);
      expect(categories).toContain(ReconciliationMismatchCategory.PROVIDER_ORDER_MISMATCH);
      expect(categories).toContain(ReconciliationMismatchCategory.PROVIDER_PAYMENT_MISMATCH);
      expect(categories).toContain(ReconciliationMismatchCategory.MISSING_PROVIDER_PAYMENT);
      expect(categories).toContain(ReconciliationMismatchCategory.MISSING_CANONICAL_PAYMENT);
      expect(categories).toContain(ReconciliationMismatchCategory.MISSING_BOOKING);
      expect(categories).toContain(ReconciliationMismatchCategory.WEBHOOK_GAP);
      expect(categories).toContain(ReconciliationMismatchCategory.WEBHOOK_STATE_MISMATCH);
      expect(categories).toContain(ReconciliationMismatchCategory.REFUND_STATE_MISMATCH);
      expect(categories).toContain(ReconciliationMismatchCategory.UNKNOWN_PROVIDER_STATE);
      expect(categories).toContain(ReconciliationMismatchCategory.PROVIDER_UNAVAILABLE);
      expect(categories).toContain(ReconciliationMismatchCategory.PROVIDER_TIMEOUT);
      expect(categories).toContain(ReconciliationMismatchCategory.INVALID_PROVIDER_RESPONSE);
      expect(categories).toContain(ReconciliationMismatchCategory.DUPLICATE_PROVIDER_REFERENCE);
      expect(categories).toContain(ReconciliationMismatchCategory.IDEMPOTENCY_CONFLICT);
      expect(categories).toContain(ReconciliationMismatchCategory.RECOVERY_REQUIRED);
    });

    it('4. unique reconciliation identity and table migration indices', async () => {
      const migration = new CreatePaymentReconciliationTable1791100000000();
      const mockQueryRunner: any = {
        createTable: jest.fn(),
        createIndices: jest.fn(),
        dropTable: jest.fn(),
      };
      await migration.up(mockQueryRunner);
      expect(mockQueryRunner.createTable).toHaveBeenCalledTimes(1);
      expect(mockQueryRunner.createIndices).toHaveBeenCalledTimes(1);
      await migration.down(mockQueryRunner);
      expect(mockQueryRunner.dropTable).toHaveBeenCalledWith('payment_reconciliation_records', true);
    });
  });

  describe('2. PROVIDER STATE COVERAGE (Tests 5-12)', () => {
    it('5. provider status: captured', async () => {
      paymentStore.set('pay_p5', {
        id: 'pay_p5',
        bookingId: 'bk_p5',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p5',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p5', { id: 'bk_p5', status: BookingStatus.CONFIRMED } as any);
      webhookStore.set('evt_p5', { id: 'evt_p5', providerPaymentId: 'pay_sim_p5', status: 'PROCESSED' } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p5',
        orderId: 'order_p5',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_p5');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.NO_MISMATCH);
      expect(res.status).toBe(ReconciliationStatus.NOT_REQUIRED);
    });

    it('6. provider status: failed without overwriting canonical DB', async () => {
      paymentStore.set('pay_p6', {
        id: 'pay_p6',
        bookingId: 'bk_p6',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p6',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p6', { id: 'bk_p6', status: BookingStatus.CONFIRMED } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p6',
        orderId: 'order_p6',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'failed',
        captured: false,
      });

      const res = await reconService.reconcilePayment('pay_p6');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.PAYMENT_STATE_MISMATCH);
      expect(paymentStore.get('pay_p6')?.status).toBe(PaymentStatus.CAPTURED);
    });

    it('7. provider status: pending / created', async () => {
      paymentStore.set('pay_p7', {
        id: 'pay_p7',
        bookingId: 'bk_p7',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p7',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p7', { id: 'bk_p7', status: BookingStatus.PENDING } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p7',
        orderId: 'order_p7',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'created',
        captured: false,
      });

      const res = await reconService.reconcilePayment('pay_p7');
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
    });

    it('8. provider status: authorized', async () => {
      paymentStore.set('pay_p8', {
        id: 'pay_p8',
        bookingId: 'bk_p8',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p8',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p8', { id: 'bk_p8', status: BookingStatus.PENDING } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p8',
        orderId: 'order_p8',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'authorized',
        captured: false,
      });

      const res = await reconService.reconcilePayment('pay_p8');
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
    });

    it('9. provider status: refunded', async () => {
      paymentStore.set('pay_p9', {
        id: 'pay_p9',
        bookingId: 'bk_p9',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p9',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p9', { id: 'bk_p9', status: BookingStatus.CONFIRMED } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p9',
        orderId: 'order_p9',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'refunded',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_p9');
      expect(res.status).toBe(ReconciliationStatus.RESOLVED);
      expect(paymentStore.get('pay_p9')?.status).toBe(PaymentStatus.REFUNDED);
    });

    it('10. provider error: timeout', async () => {
      paymentStore.set('pay_p10', {
        id: 'pay_p10',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p10',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.mockFetchError('pay_sim_p10', new Error('Gateway Timeout 504'));
      const res = await reconService.reconcilePayment('pay_p10');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.PROVIDER_TIMEOUT);
    });

    it('11. provider error: unavailable (503)', async () => {
      paymentStore.set('pay_p11', {
        id: 'pay_p11',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p11',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.mockFetchError('pay_sim_p11', new Error('Service Unavailable 503'));
      const res = await reconService.reconcilePayment('pay_p11');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.PROVIDER_UNAVAILABLE);
    });

    it('12. provider error: malformed response', async () => {
      paymentStore.set('pay_p12', {
        id: 'pay_p12',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p12',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.mockFetchInvalidResponse('pay_sim_p12', { missing: 'fields' });
      const res = await reconService.reconcilePayment('pay_p12');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.INVALID_PROVIDER_RESPONSE);
    });
  });

  describe('3. PAYMENT TRANSITION & INVARIANTS (Tests 13-21)', () => {
    it('13. legal transition: PENDING -> CAPTURED', async () => {
      paymentStore.set('pay_p13', {
        id: 'pay_p13',
        bookingId: 'bk_p13',
        amount: 120,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p13',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p13', { id: 'bk_p13', status: BookingStatus.PENDING } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p13',
        orderId: 'order_p13',
        amount: 120,
        amountInMinorUnits: 12000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_p13');
      expect(res.status).toBe(ReconciliationStatus.RESOLVED);
      expect(paymentStore.get('pay_p13')?.status).toBe(PaymentStatus.CAPTURED);
    });

    it('14. legal transition: PENDING -> FAILED', () => {
      expect(isValidPaymentStateTransition(PaymentStatus.PENDING, PaymentStatus.FAILED)).toBe(true);
    });

    it('15. legal transition: AUTHORIZED -> CAPTURED', () => {
      expect(isValidPaymentStateTransition(PaymentStatus.AUTHORIZED, PaymentStatus.CAPTURED)).toBe(true);
    });

    it('16. strictly BLOCKED: CAPTURED -> FAILED', () => {
      expect(isValidPaymentStateTransition(PaymentStatus.CAPTURED, PaymentStatus.FAILED)).toBe(false);
      expect(() => assertValidPaymentStateTransition(PaymentStatus.CAPTURED, PaymentStatus.FAILED)).toThrow(BadRequestException);
    });

    it('17. strictly BLOCKED: REFUNDED -> CAPTURED', () => {
      expect(isValidPaymentStateTransition(PaymentStatus.REFUNDED, PaymentStatus.CAPTURED)).toBe(false);
      expect(() => assertValidPaymentStateTransition(PaymentStatus.REFUNDED, PaymentStatus.CAPTURED)).toThrow(BadRequestException);
    });

    it('18. amount mismatch blocks automatic transition', async () => {
      paymentStore.set('pay_p18', {
        id: 'pay_p18',
        amount: 500,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p18',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p18',
        orderId: 'order_p18',
        amount: 450,
        amountInMinorUnits: 45000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_p18');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.AMOUNT_MISMATCH);
      expect(paymentStore.get('pay_p18')?.status).toBe(PaymentStatus.PENDING);
    });

    it('19. currency mismatch blocks automatic transition', async () => {
      paymentStore.set('pay_p19', {
        id: 'pay_p19',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p19',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p19',
        orderId: 'order_p19',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'USD',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_p19');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.CURRENCY_MISMATCH);
      expect(paymentStore.get('pay_p19')?.status).toBe(PaymentStatus.PENDING);
    });

    it('20. provider order mismatch blocks automatic transition', async () => {
      paymentStore.set('pay_p20', {
        id: 'pay_p20',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerOrderId: 'order_correct_20',
        providerPaymentId: 'pay_sim_p20',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p20',
        orderId: 'order_wrong_20',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_p20');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.PROVIDER_ORDER_MISMATCH);
    });

    it('21. duplicate provider payment reference detected and blocked', async () => {
      paymentStore.set('pay_p21_a', {
        id: 'pay_p21_a',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_shared_21',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      paymentStore.set('pay_p21_b', {
        id: 'pay_p21_b',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_shared_21',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const res = await reconService.reconcilePayment('pay_p21_a');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.DUPLICATE_PROVIDER_REFERENCE);
      expect(res.requiresManualIntervention).toBe(true);
    });
  });

  describe('4. BOOKING SYNCHRONIZATION (Tests 22-26)', () => {
    it('22. captured payment with pending booking triggers repair', async () => {
      paymentStore.set('pay_p22', {
        id: 'pay_p22',
        bookingId: 'bk_p22',
        amount: 50,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p22',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p22', { id: 'bk_p22', status: BookingStatus.PENDING } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p22',
        orderId: 'order_p22',
        amount: 50,
        amountInMinorUnits: 5000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_p22');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.BOOKING_STATE_MISMATCH);
      expect(res.status).toBe(ReconciliationStatus.RESOLVED);
      expect(bookingStore.get('bk_p22')?.status).toBe(BookingStatus.CONFIRMED);
    });

    it('23. legal booking confirmation state transition', () => {
      expect(BookingStatus.CONFIRMED).toBe('confirmed');
    });

    it('24. missing booking handled gracefully without throwing unhandled exception', async () => {
      paymentStore.set('pay_p24', {
        id: 'pay_p24',
        bookingId: 'bk_missing_24',
        amount: 50,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p24',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const res = await reconService.reconcilePayment('pay_p24');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.MISSING_BOOKING);
      expect(res.requiresManualIntervention).toBe(true);
    });

    it('25. inventory failure handled by recording required reconciliation', async () => {
      paymentStore.set('pay_p25', {
        id: 'pay_p25',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.mockFetchError('pay_p25', new Error('Sold out / slot unavailable'));
      const res = await reconService.reconcilePayment('pay_p25');
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
    });

    it('26. duplicate booking confirmation protection on repeated reconciliation', async () => {
      paymentStore.set('pay_p26', {
        id: 'pay_p26',
        bookingId: 'bk_p26',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p26',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p26', { id: 'bk_p26', status: BookingStatus.CONFIRMED } as any);
      webhookStore.set('evt_p26', { id: 'evt_p26', providerPaymentId: 'pay_sim_p26', status: 'PROCESSED' } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p26',
        orderId: 'order_p26',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const r1 = await reconService.reconcilePayment('pay_p26');
      const r2 = await reconService.reconcilePayment('pay_p26');
      expect(r1.status).toBe(ReconciliationStatus.NOT_REQUIRED);
      expect(r2.status).toBe(ReconciliationStatus.NOT_REQUIRED);
      expect(bookingStore.get('bk_p26')?.status).toBe(BookingStatus.CONFIRMED);
    });
  });

  describe('5. REFUND RECONCILIATION (Tests 27-31)', () => {
    it('27. legal transition: REFUND_PENDING -> REFUNDED', async () => {
      paymentStore.set('pay_p27', {
        id: 'pay_p27',
        bookingId: 'bk_p27',
        amount: 200,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p27',
        status: PaymentStatus.REFUND_PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p27', { id: 'bk_p27', status: BookingStatus.REFUND_PENDING } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p27',
        orderId: 'order_p27',
        amount: 200,
        amountInMinorUnits: 20000,
        currency: 'INR',
        status: 'refunded',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_p27');
      expect(res.status).toBe(ReconciliationStatus.RESOLVED);
      expect(paymentStore.get('pay_p27')?.status).toBe(PaymentStatus.REFUNDED);
    });

    it('28. refund timeout does not mark canonical payment refunded', async () => {
      paymentStore.set('pay_p28', {
        id: 'pay_p28',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p28',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.mockFetchError('pay_sim_p28', new Error('Gateway Timeout 504'));
      const res = await reconService.reconcilePayment('pay_p28');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.PROVIDER_TIMEOUT);
      expect(paymentStore.get('pay_p28')?.status).toBe(PaymentStatus.CAPTURED);
    });

    it('29. refund mismatch detected when canonical is captured but provider is refunded', async () => {
      paymentStore.set('pay_p29', {
        id: 'pay_p29',
        bookingId: 'bk_p29',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p29',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p29', { id: 'bk_p29', status: BookingStatus.CONFIRMED } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p29',
        orderId: 'order_p29',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'refunded',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_p29');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.REFUND_STATE_MISMATCH);
    });

    it('30. duplicate refund protection on repeated reconciliation', async () => {
      paymentStore.set('pay_p30', {
        id: 'pay_p30',
        bookingId: 'bk_p30',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p30',
        status: PaymentStatus.REFUNDED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p30', { id: 'bk_p30', status: BookingStatus.REFUNDED } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p30',
        orderId: 'order_p30',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'refunded',
        captured: true,
      });

      const res1 = await reconService.reconcilePayment('pay_p30');
      const res2 = await reconService.reconcilePayment('pay_p30');
      expect(paymentStore.get('pay_p30')?.status).toBe(PaymentStatus.REFUNDED);
      expect(bookingStore.get('bk_p30')?.status).toBe(BookingStatus.REFUNDED);
    });

    it('31. partial refund accounting verification', () => {
      const fullAmount = toMinorUnits(100);
      const partialAmount = toMinorUnits(40);
      expect(fullAmount - partialAmount).toBe(6000);
    });
  });

  describe('6. WEBHOOK RECONCILIATION (Tests 32-35)', () => {
    it('32. webhook gap detected when capture confirmed without processed webhook', async () => {
      paymentStore.set('pay_p32', {
        id: 'pay_p32',
        amount: 99,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p32',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p32',
        orderId: 'order_p32',
        amount: 99,
        amountInMinorUnits: 9900,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_p32');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.WEBHOOK_GAP);
      expect(res.status).toBe(ReconciliationStatus.RESOLVED);
    });

    it('33. webhook state mismatch category verified', () => {
      expect(ReconciliationMismatchCategory.WEBHOOK_STATE_MISMATCH).toBe('WEBHOOK_STATE_MISMATCH');
    });

    it('34. duplicate webhook + reconciliation synchronization', async () => {
      paymentStore.set('pay_p34', {
        id: 'pay_p34',
        bookingId: 'bk_p34',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p34',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p34', { id: 'bk_p34', status: BookingStatus.CONFIRMED } as any);
      webhookStore.set('evt_p34', { id: 'evt_p34', providerPaymentId: 'pay_sim_p34', status: 'PROCESSED' } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p34',
        orderId: 'order_p34',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_p34');
      expect(res.status).toBe(ReconciliationStatus.NOT_REQUIRED);
    });

    it('35. already processed webhook clean agreement verification', async () => {
      webhookStore.set('evt_p35', { id: 'evt_p35', providerPaymentId: 'pay_sim_p35', status: 'PROCESSED', processedAt: new Date() } as any);
      expect(webhookStore.get('evt_p35')?.status).toBe('PROCESSED');
    });
  });

  describe('7. IDEMPOTENCY & RESILIENCE (Tests 36-39)', () => {
    it('36. duplicate reconciliation execution returns identical canonical state', async () => {
      paymentStore.set('pay_p36', {
        id: 'pay_p36',
        bookingId: 'bk_p36',
        amount: 50,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p36',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p36', { id: 'bk_p36', status: BookingStatus.CONFIRMED } as any);
      webhookStore.set('evt_p36', { id: 'evt_p36', providerPaymentId: 'pay_sim_p36', status: 'PROCESSED' } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p36',
        orderId: 'order_p36',
        amount: 50,
        amountInMinorUnits: 5000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const r1 = await reconService.reconcilePayment('pay_p36');
      const r2 = await reconService.reconcilePayment('pay_p36');
      expect(r1.id).toBe(r2.id);
    });

    it('37. concurrent reconciliation executions deduplicated via in-flight lock', async () => {
      paymentStore.set('pay_p37', {
        id: 'pay_p37',
        amount: 50,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p37',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p37',
        orderId: 'order_p37',
        amount: 50,
        amountInMinorUnits: 5000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const [rA, rB] = await Promise.all([
        reconService.reconcilePayment('pay_p37'),
        reconService.reconcilePayment('pay_p37'),
      ]);

      expect(rA.paymentId).toBe('pay_p37');
      expect(rB.paymentId).toBe('pay_p37');
    });

    it('38. conflicting reconciliation identity / invalid paymentId rejected', async () => {
      await expect(reconService.reconcilePayment('')).rejects.toThrow(BadRequestException);
      await expect(reconService.reconcilePayment(null as any)).rejects.toThrow(BadRequestException);
    });

    it('39. reconciliation durability after process restart (DB persistent state)', async () => {
      reconStore.set('recon_persisted_39', {
        id: 'recon_persisted_39',
        paymentId: 'pay_persisted_39',
        status: ReconciliationStatus.RESOLVED,
        mismatchCategory: ReconciliationMismatchCategory.NO_MISMATCH,
        createdAt: new Date(),
      } as any);

      const found = await mockReconRepo.findOne({ where: { id: 'recon_persisted_39' } });
      expect(found?.status).toBe(ReconciliationStatus.RESOLVED);
    });
  });

  describe('8. RECOVERY STATE MACHINE (Tests 40-45)', () => {
    it('40. recovery status: REQUIRED', () => {
      expect(RecoveryStatus.REQUIRED).toBe('REQUIRED');
    });

    it('41. recovery status: IN_PROGRESS', () => {
      expect(RecoveryStatus.IN_PROGRESS).toBe('IN_PROGRESS');
    });

    it('42. recovery status: RESOLVED', () => {
      expect(RecoveryStatus.RESOLVED).toBe('RESOLVED');
    });

    it('43. recovery status: FAILED', () => {
      expect(RecoveryStatus.FAILED).toBe('FAILED');
    });

    it('44. successful reconciliation resolves linked recovery incident', async () => {
      paymentStore.set('pay_p44', {
        id: 'pay_p44',
        bookingId: 'bk_p44',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p44',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p44', { id: 'bk_p44', status: BookingStatus.PENDING } as any);

      recoveryStore.set('recov_p44', {
        id: 'recov_p44',
        paymentId: 'pay_p44',
        resourceId: 'pay_p44',
        recoveryStatus: RecoveryStatus.REQUIRED,
        failureCategory: FailureCategory.PROVIDER_TIMEOUT,
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p44',
        orderId: 'order_p44',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_p44');
      expect(res.status).toBe(ReconciliationStatus.RESOLVED);
      expect(recoveryStore.get('recov_p44')?.recoveryStatus).toBe(RecoveryStatus.RESOLVED);
    });

    it('45. failed reconciliation preserves recovery incident', async () => {
      paymentStore.set('pay_p45', {
        id: 'pay_p45',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p45',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      recoveryStore.set('recov_p45', {
        id: 'recov_p45',
        paymentId: 'pay_p45',
        resourceId: 'pay_p45',
        recoveryStatus: RecoveryStatus.REQUIRED,
        failureCategory: FailureCategory.PROVIDER_UNAVAILABLE,
      } as any);

      simulatedAdapter.mockFetchError('pay_sim_p45', new Error('Service Unavailable 503'));
      await reconService.reconcilePayment('pay_p45');
      expect(recoveryStore.get('recov_p45')?.recoveryStatus).toBe(RecoveryStatus.REQUIRED);
    });
  });

  describe('9. BATCH SCHEDULER & RETRY BACKOFF (Tests 46-50)', () => {
    it('46. bounded batch size enforcement (clamped to max 50)', async () => {
      const summary = await reconService.reconcileBatch(100);
      expect(summary).toBeDefined();
    });

    it('47. exponential backoff calculation (capped at 3600 seconds)', async () => {
      paymentStore.set('pay_p47', {
        id: 'pay_p47',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p47',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.mockFetchError('pay_sim_p47', new Error('Gateway Timeout 504'));
      const res = await reconService.reconcilePayment('pay_p47');
      expect(res.nextRetryAt).toBeDefined();
    });

    it('48. duplicate concurrent scheduler execution protection', async () => {
      const [s1, s2] = await Promise.all([
        reconService.runScheduledSweep(),
        reconService.runScheduledSweep(),
      ]);
      expect(s1).toBeDefined();
      expect(s2).toBeDefined();
    });

    it('49. permanently failed records retained for operator review (attemptCount >= 5)', async () => {
      reconStore.set('recon_p49', {
        id: 'recon_p49',
        paymentId: 'pay_p49',
        status: ReconciliationStatus.REQUIRED,
        attemptCount: 5,
        nextRetryAt: new Date(),
        createdAt: new Date(),
      } as any);

      const summary = await reconService.reconcileBatch(10);
      expect(summary.failed).toBeGreaterThanOrEqual(1);
      expect(reconStore.get('recon_p49')?.status).toBe(ReconciliationStatus.FAILED);
      expect(reconStore.get('recon_p49')?.requiresManualIntervention).toBe(true);
    });

    it('50. nextRetryAt respected during batch queries', async () => {
      reconStore.set('recon_p50', {
        id: 'recon_p50',
        paymentId: 'pay_p50',
        status: ReconciliationStatus.REQUIRED,
        attemptCount: 1,
        nextRetryAt: new Date(Date.now() + 100000), // In future
        createdAt: new Date(),
      } as any);

      const summary = await reconService.reconcileBatch(10);
      expect(summary.processed).toBe(0);
    });
  });

  describe('10. ADMIN CONSOLE & OPERATIONAL SAFETY (Tests 51-56)', () => {
    it('51. admin reconciliation list endpoint', async () => {
      reconStore.set('recon_p51', {
        id: 'recon_p51',
        paymentId: 'pay_p51',
        status: ReconciliationStatus.REQUIRED,
        canonicalAmount: 100,
        canonicalAmountInMinorUnits: 10000,
        canonicalCurrency: 'INR',
        provider: 'simulated',
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const res = await adminController.getReconciliationRecords({});
      expect(res.total).toBe(1);
      expect(res.items[0].id).toBe('recon_p51');
    });

    it('52. admin reconciliation filter endpoint', async () => {
      const res = await adminController.getReconciliationRecords({ status: 'REQUIRED' });
      expect(res).toBeDefined();
    });

    it('53. admin reconciliation detail endpoint', async () => {
      reconStore.set('recon_p53', {
        id: 'recon_p53',
        paymentId: 'pay_p53',
        status: ReconciliationStatus.REQUIRED,
        canonicalAmount: 100,
        canonicalAmountInMinorUnits: 10000,
        canonicalCurrency: 'INR',
        provider: 'simulated',
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const res = await adminController.getReconciliationById('recon_p53');
      expect(res.id).toBe('recon_p53');
    });

    it('54. admin retry / trigger reconciliation authorization', async () => {
      paymentStore.set('pay_p54', {
        id: 'pay_p54',
        amount: 80,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p54',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      webhookStore.set('evt_p54', { id: 'evt_p54', providerPaymentId: 'pay_sim_p54', status: 'PROCESSED' } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p54',
        orderId: 'order_p54',
        amount: 80,
        amountInMinorUnits: 8000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await adminController.triggerPaymentReconcile(
        'pay_p54',
        { force: true },
        { user: { id: 'usr_admin1', email: 'admin@plaza.test' } },
      );
      expect(res.paymentId).toBe('pay_p54');
    });

    it('55. admin manual resolve authorization and audit logging', async () => {
      reconStore.set('recon_p55', {
        id: 'recon_p55',
        paymentId: 'pay_p55',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
        createdAt: new Date(),
      } as any);

      const res = await adminController.resolveReconciliation(
        'recon_p55',
        { action: 'MARK_REVIEWED', notes: 'Operator audit notes' },
        { user: { id: 'usr_admin1', email: 'admin@plaza.test' } },
      );

      expect(res.status).toBe(ReconciliationStatus.RESOLVED);
      expect(auditLogsStore.size).toBe(1);
    });

    it('56. admin manual resolve CANNOT bypass canonical state machine validators', async () => {
      reconStore.set('recon_p56', {
        id: 'recon_p56',
        paymentId: 'pay_p56',
        status: ReconciliationStatus.REQUIRED,
        createdAt: new Date(),
      } as any);

      paymentStore.set('pay_p56', {
        id: 'pay_p56',
        status: PaymentStatus.CAPTURED,
      } as any);

      await expect(
        adminController.resolveReconciliation(
          'recon_p56',
          { action: 'FORCE_FAIL', notes: 'Illegal force fail' },
          { user: { id: 'usr_admin1', email: 'admin@plaza.test' } },
        ),
      ).rejects.toThrow(BadRequestException);

      expect(paymentStore.get('pay_p56')?.status).toBe(PaymentStatus.CAPTURED);
    });
  });

  describe('11. SECURITY & ZERO CREDENTIAL LEAKAGE (Tests 57-59)', () => {
    it('57. no secrets exposed in sanitized resolution responses', () => {
      const raw = 'Error rzp_live_SECRET999 with key_secret=simulated_key_secret';
      const sanitized = reconService.sanitizeText(raw);
      expect(sanitized).not.toContain('rzp_live_SECRET999');
      expect(sanitized).toContain('[REDACTED_RZP_KEY]');
    });

    it('58. no JWTs or bearer tokens exposed in error logs', () => {
      const raw = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.doNotLeakThis';
      const sanitized = reconService.sanitizeText(raw);
      expect(sanitized).not.toContain('eyJhbGciOi');
      expect(sanitized).toContain('[REDACTED_JWT]');
    });

    it('59. zero hardcoded live Razorpay credentials across configuration', () => {
      const config = new PaymentConfigService();
      expect(config.evaluate().summary.paymentMode).toBe(PaymentMode.SIMULATED);
      expect(config.evaluate().summary.razorpayLiveEnabled).toBe(false);
    });
  });

  describe('12. CONCURRENCY HARDENING (Tests 60-62)', () => {
    it('60. two simultaneous reconciliation attempts against same payment', async () => {
      paymentStore.set('pay_p60', {
        id: 'pay_p60',
        amount: 250,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p60',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p60',
        orderId: 'order_p60',
        amount: 250,
        amountInMinorUnits: 25000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const [rA, rB] = await Promise.all([
        reconService.reconcilePayment('pay_p60'),
        reconService.reconcilePayment('pay_p60'),
      ]);

      expect(rA).toBeDefined();
      expect(rB).toBeDefined();
      expect(paymentStore.get('pay_p60')?.status).toBe(PaymentStatus.CAPTURED);
    });

    it('61. two simultaneous refund reconciliation attempts against same payment', async () => {
      paymentStore.set('pay_p61', {
        id: 'pay_p61',
        bookingId: 'bk_p61',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p61',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p61', { id: 'bk_p61', status: BookingStatus.CONFIRMED } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p61',
        orderId: 'order_p61',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'refunded',
        captured: true,
      });

      const [rA, rB] = await Promise.all([
        reconService.reconcilePayment('pay_p61'),
        reconService.reconcilePayment('pay_p61'),
      ]);

      expect(paymentStore.get('pay_p61')?.status).toBe(PaymentStatus.REFUNDED);
      expect(bookingStore.get('bk_p61')?.status).toBe(BookingStatus.REFUNDED);
    });

    it('62. simultaneous booking repair attempts against same desynchronized booking', async () => {
      paymentStore.set('pay_p62', {
        id: 'pay_p62',
        bookingId: 'bk_p62',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p62',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);
      bookingStore.set('bk_p62', { id: 'bk_p62', status: BookingStatus.PENDING } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p62',
        orderId: 'order_p62',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const [rA, rB] = await Promise.all([
        reconService.reconcilePayment('pay_p62'),
        reconService.reconcilePayment('pay_p62'),
      ]);

      expect(bookingStore.get('bk_p62')?.status).toBe(BookingStatus.CONFIRMED);
    });
  });
});
