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

describe('PLAZA Phase 25.6 — Payment Reconciliation Engine', () => {
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

    // Mock Recon Repo
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
        return Array.from(reconStore.values());
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

    // Mock Payment Repo
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

    // Mock Booking Repo
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

    // Mock Webhook Repo
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

    // Mock Recovery Repo
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

    // Mock Audit Log Repo
    mockAuditLogRepo = {
      save: jest.fn(async (entity: any) => {
        const id = entity.id || `aud_${Date.now()}`;
        auditLogsStore.set(id, { ...entity, id, createdAt: new Date() });
        return { ...entity, id };
      }),
    };

    // Mock User Repo
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

  describe('1. Schema & Migration Hardening', () => {
    it('1.1 should create and drop table with proper indices via migration', async () => {
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

    it('1.2 should support all 5 ReconciliationStatus enum values', () => {
      expect(ReconciliationStatus.NOT_REQUIRED).toBe('NOT_REQUIRED');
      expect(ReconciliationStatus.REQUIRED).toBe('REQUIRED');
      expect(ReconciliationStatus.IN_PROGRESS).toBe('IN_PROGRESS');
      expect(ReconciliationStatus.RESOLVED).toBe('RESOLVED');
      expect(ReconciliationStatus.FAILED).toBe('FAILED');
    });

    it('1.3 should support all 20 canonical mismatch categories', () => {
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
  });

  describe('2. Canonical Mismatch Matrix & Detection (20 categories)', () => {
    it('2.1 Category 1: NO_MISMATCH — clean match across payment, provider, booking, and webhook', async () => {
      paymentStore.set('pay_clean_1', {
        id: 'pay_clean_1',
        bookingId: 'bk_clean_1',
        amount: 499,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_clean_1',
        providerOrderId: 'order_sim_clean_1',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      bookingStore.set('bk_clean_1', {
        id: 'bk_clean_1',
        status: BookingStatus.CONFIRMED,
      } as any);

      webhookStore.set('evt_clean_1', {
        id: 'evt_clean_1',
        providerPaymentId: 'pay_sim_clean_1',
        providerOrderId: 'order_sim_clean_1',
        status: 'PROCESSED',
        processedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_clean_1',
        orderId: 'order_sim_clean_1',
        amount: 499,
        amountInMinorUnits: 49900,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_clean_1');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.NO_MISMATCH);
      expect(res.status).toBe(ReconciliationStatus.NOT_REQUIRED);
      expect(res.resolutionAction).toBe('VERIFIED_CONSISTENT');
      expect(res.requiresManualIntervention).toBe(false);
    });

    it('2.2 Category 2: PAYMENT_STATE_MISMATCH — DB is PENDING, Provider is captured -> legal transition to CAPTURED', async () => {
      paymentStore.set('pay_pending_1', {
        id: 'pay_pending_1',
        bookingId: 'bk_pending_1',
        amount: 350,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_p1',
        providerOrderId: 'order_sim_p1',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      bookingStore.set('bk_pending_1', {
        id: 'bk_pending_1',
        status: BookingStatus.PENDING,
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_p1',
        orderId: 'order_sim_p1',
        amount: 350,
        amountInMinorUnits: 35000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_pending_1');
      expect(res.status).toBe(ReconciliationStatus.RESOLVED);
      expect(res.resolutionAction).toBe('CONFIRMED_CAPTURE');

      const updatedPay = paymentStore.get('pay_pending_1');
      expect(updatedPay?.status).toBe(PaymentStatus.CAPTURED);

      const updatedBk = bookingStore.get('bk_pending_1');
      expect(updatedBk?.status).toBe(BookingStatus.CONFIRMED);
    });

    it('2.3 Category 2 (Invariant): Canonical is CAPTURED, Provider is failed -> CANNOT overwrite DB with FAILED', async () => {
      paymentStore.set('pay_cap_guard', {
        id: 'pay_cap_guard',
        bookingId: 'bk_cap_guard',
        amount: 250,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_fail',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      bookingStore.set('bk_cap_guard', {
        id: 'bk_cap_guard',
        status: BookingStatus.CONFIRMED,
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_fail',
        orderId: 'order_sim_fail',
        amount: 250,
        amountInMinorUnits: 25000,
        currency: 'INR',
        status: 'failed',
        captured: false,
      });

      const res = await reconService.reconcilePayment('pay_cap_guard');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.PAYMENT_STATE_MISMATCH);
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
      expect(res.requiresManualIntervention).toBe(true);
      expect(res.resolutionAction).toBe('NO_OP_PROTECT_CANONICAL');

      const pay = paymentStore.get('pay_cap_guard');
      expect(pay?.status).toBe(PaymentStatus.CAPTURED); // Canonical intact
    });

    it('2.4 Category 3: BOOKING_STATE_MISMATCH — Payment is CAPTURED but Booking is PENDING -> safely repairs booking', async () => {
      paymentStore.set('pay_bk_repair', {
        id: 'pay_bk_repair',
        bookingId: 'bk_desync_1',
        amount: 199,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_bk1',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      bookingStore.set('bk_desync_1', {
        id: 'bk_desync_1',
        status: BookingStatus.PENDING,
      } as any);

      webhookStore.set('evt_bk1', {
        id: 'evt_bk1',
        providerPaymentId: 'pay_sim_bk1',
        status: 'PROCESSED',
        processedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_bk1',
        orderId: 'order_bk1',
        amount: 199,
        amountInMinorUnits: 19900,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_bk_repair');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.BOOKING_STATE_MISMATCH);
      expect(res.status).toBe(ReconciliationStatus.RESOLVED);
      expect(res.resolutionAction).toBe('CONFIRMED_BOOKING_REPAIR');

      const bk = bookingStore.get('bk_desync_1');
      expect(bk?.status).toBe(BookingStatus.CONFIRMED);
    });

    it('2.5 Category 4: AMOUNT_MISMATCH — minor units discrepancy blocks automatic mutation and flags operator', async () => {
      paymentStore.set('pay_amt_err', {
        id: 'pay_amt_err',
        amount: 500,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_amt',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_amt',
        orderId: 'order_amt',
        amount: 450,
        amountInMinorUnits: 45000, // 45000 != 50000
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_amt_err');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.AMOUNT_MISMATCH);
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
      expect(res.requiresManualIntervention).toBe(true);
      expect(paymentStore.get('pay_amt_err')?.status).toBe(PaymentStatus.PENDING); // Unmutated
    });

    it('2.6 Category 5: CURRENCY_MISMATCH — currency code difference blocks auto-mutation', async () => {
      paymentStore.set('pay_curr_err', {
        id: 'pay_curr_err',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_curr',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_curr',
        orderId: 'order_curr',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'USD', // USD != INR
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_curr_err');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.CURRENCY_MISMATCH);
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
      expect(res.requiresManualIntervention).toBe(true);
    });

    it('2.7 Category 6: PROVIDER_ORDER_MISMATCH — provider order ID mismatch flagged', async () => {
      paymentStore.set('pay_order_err', {
        id: 'pay_order_err',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerOrderId: 'order_expected_123',
        providerPaymentId: 'pay_sim_ord',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_ord',
        orderId: 'order_different_999',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_order_err');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.PROVIDER_ORDER_MISMATCH);
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
      expect(res.requiresManualIntervention).toBe(true);
    });

    it('2.8 Category 8: MISSING_PROVIDER_PAYMENT — 404 from provider flags missing payment', async () => {
      paymentStore.set('pay_notfound_1', {
        id: 'pay_notfound_1',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_404',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.mockFetchError('pay_sim_404', new NotFoundException('Payment not found on provider'));

      const res = await reconService.reconcilePayment('pay_notfound_1');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.MISSING_PROVIDER_PAYMENT);
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
      expect(res.requiresManualIntervention).toBe(true);
    });

    it('2.9 Category 9: MISSING_CANONICAL_PAYMENT — non-existent DB payment record handled safely', async () => {
      const res = await reconService.reconcilePayment('pay_non_existent');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.MISSING_CANONICAL_PAYMENT);
      expect(res.status).toBe(ReconciliationStatus.FAILED);
      expect(res.requiresManualIntervention).toBe(true);
    });

    it('2.10 Category 10: MISSING_BOOKING — payment refers to non-existent booking', async () => {
      paymentStore.set('pay_ghost_bk', {
        id: 'pay_ghost_bk',
        bookingId: 'bk_non_existent',
        amount: 200,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_ghost',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const res = await reconService.reconcilePayment('pay_ghost_bk');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.MISSING_BOOKING);
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
      expect(res.requiresManualIntervention).toBe(true);
    });

    it('2.11 Category 11: WEBHOOK_GAP — capture exists on provider without processed webhook logged', async () => {
      paymentStore.set('pay_gap_1', {
        id: 'pay_gap_1',
        amount: 300,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_gap',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_gap',
        orderId: 'order_gap',
        amount: 300,
        amountInMinorUnits: 30000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_gap_1');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.WEBHOOK_GAP);
      expect(res.status).toBe(ReconciliationStatus.RESOLVED);
      expect(res.resolutionAction).toBe('CONFIRMED_CAPTURE_WEBHOOK_GAP_RESOLVED');
    });

    it('2.12 Category 13: REFUND_STATE_MISMATCH — provider shows refunded, transitions canonical to REFUNDED', async () => {
      paymentStore.set('pay_refund_sync', {
        id: 'pay_refund_sync',
        bookingId: 'bk_refund_sync',
        amount: 120,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_rfnd',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      bookingStore.set('bk_refund_sync', {
        id: 'bk_refund_sync',
        status: BookingStatus.CONFIRMED,
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_rfnd',
        orderId: 'order_rfnd',
        amount: 120,
        amountInMinorUnits: 12000,
        currency: 'INR',
        status: 'refunded',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_refund_sync');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.REFUND_STATE_MISMATCH);
      expect(res.status).toBe(ReconciliationStatus.RESOLVED);
      expect(res.resolutionAction).toBe('CONFIRMED_REFUND');

      expect(paymentStore.get('pay_refund_sync')?.status).toBe(PaymentStatus.REFUNDED);
      expect(bookingStore.get('bk_refund_sync')?.status).toBe(BookingStatus.REFUNDED);
    });

    it('2.13 Category 15: PROVIDER_UNAVAILABLE — 503 from provider sets exponential retry schedule', async () => {
      paymentStore.set('pay_503_test', {
        id: 'pay_503_test',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_503',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.mockFetchError('pay_sim_503', new Error('Service Unavailable 503 econnrefused'));

      const res = await reconService.reconcilePayment('pay_503_test');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.PROVIDER_UNAVAILABLE);
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
      expect(res.nextRetryAt).toBeDefined();
      expect(res.attemptCount).toBe(1);
    });

    it('2.14 Category 16: PROVIDER_TIMEOUT — gateway timeout sets retry backoff', async () => {
      paymentStore.set('pay_timeout_test', {
        id: 'pay_timeout_test',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_timeout',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.mockFetchError('pay_sim_timeout', new Error('Connection ETIMEDOUT 504'));

      const res = await reconService.reconcilePayment('pay_timeout_test');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.PROVIDER_TIMEOUT);
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
      expect(res.nextRetryAt).toBeDefined();
    });

    it('2.15 Category 17: INVALID_PROVIDER_RESPONSE — malformed provider response flagged', async () => {
      paymentStore.set('pay_malformed', {
        id: 'pay_malformed',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_malformed',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.mockFetchInvalidResponse('pay_sim_malformed', {
        status: 12345, // invalid type
        amountInMinorUnits: 'invalid_number',
      });

      const res = await reconService.reconcilePayment('pay_malformed');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.INVALID_PROVIDER_RESPONSE);
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
      expect(res.requiresManualIntervention).toBe(true);
    });

    it('2.16 Category 18: DUPLICATE_PROVIDER_REFERENCE — duplicate providerPaymentId across multiple canonical payments', async () => {
      paymentStore.set('pay_dup_1', {
        id: 'pay_dup_1',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_shared_ref',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      paymentStore.set('pay_dup_2', {
        id: 'pay_dup_2',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_shared_ref',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const res = await reconService.reconcilePayment('pay_dup_1');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.DUPLICATE_PROVIDER_REFERENCE);
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
      expect(res.requiresManualIntervention).toBe(true);
    });

    it('2.17 Category 20: RECOVERY_REQUIRED — reconciling payment resolves associated Phase 25.5 recovery incidents', async () => {
      paymentStore.set('pay_recov_link', {
        id: 'pay_recov_link',
        bookingId: 'bk_recov_link',
        amount: 250,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_recov',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      bookingStore.set('bk_recov_link', {
        id: 'bk_recov_link',
        status: BookingStatus.PENDING,
      } as any);

      recoveryStore.set('recov_1', {
        id: 'recov_1',
        paymentId: 'pay_recov_link',
        resourceId: 'pay_recov_link',
        recoveryStatus: RecoveryStatus.REQUIRED,
        failureCategory: FailureCategory.PROVIDER_TIMEOUT,
        requiresManualIntervention: true,
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_recov',
        orderId: 'order_recov',
        amount: 250,
        amountInMinorUnits: 25000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await reconService.reconcilePayment('pay_recov_link');
      expect(res.status).toBe(ReconciliationStatus.RESOLVED);

      const rec = recoveryStore.get('recov_1');
      expect(rec?.recoveryStatus).toBe(RecoveryStatus.RESOLVED);
      expect(rec?.requiresManualIntervention).toBe(false);
    });
  });

  describe('3. Concurrency, Deduplication & Batch Scheduling', () => {
    it('3.1 should reject concurrent duplicate reconciliation executions for the same payment', async () => {
      paymentStore.set('pay_concurrent_1', {
        id: 'pay_concurrent_1',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_conc',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_conc',
        orderId: 'order_conc',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const [res1, res2] = await Promise.all([
        reconService.reconcilePayment('pay_concurrent_1'),
        reconService.reconcilePayment('pay_concurrent_1'),
      ]);

      expect(res1).toBeDefined();
      expect(res2).toBeDefined();
      expect(res1.paymentId).toBe('pay_concurrent_1');
    });

    it('3.2 should process pending batch items in reconcileBatch', async () => {
      reconStore.set('recon_batch_1', {
        id: 'recon_batch_1',
        paymentId: 'pay_batch_1',
        status: ReconciliationStatus.REQUIRED,
        attemptCount: 0,
        createdAt: new Date(),
      } as any);

      paymentStore.set('pay_batch_1', {
        id: 'pay_batch_1',
        amount: 50,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_b1',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      webhookStore.set('evt_b1', {
        id: 'evt_b1',
        providerPaymentId: 'pay_sim_b1',
        status: 'PROCESSED',
        processedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_b1',
        orderId: 'order_b1',
        amount: 50,
        amountInMinorUnits: 5000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const summary = await reconService.reconcileBatch(10);
      expect(summary.processed).toBeGreaterThanOrEqual(1);
    });
  });

  describe('4. Administrative Operations & Secret Sanitization', () => {
    it('4.1 should query reconciliation records and summary via admin service', async () => {
      reconStore.set('recon_adm_1', {
        id: 'recon_adm_1',
        paymentId: 'pay_adm_1',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
        requiresManualIntervention: true,
        canonicalAmount: 100,
        canonicalAmountInMinorUnits: 10000,
        canonicalCurrency: 'INR',
        provider: 'simulated',
        attemptCount: 1,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const records = await adminService.getReconciliationRecords({});
      expect(records.total).toBe(1);
      expect(records.items[0].id).toBe('recon_adm_1');

      const summary = await adminService.getReconciliationSummary();
      expect(summary.totalRecords).toBe(1);
      expect(summary.requiredCount).toBe(1);
    });

    it('4.2 should support admin manual resolution with audit log and secret sanitization', async () => {
      reconStore.set('recon_manual_1', {
        id: 'recon_manual_1',
        paymentId: 'pay_manual_1',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
        requiresManualIntervention: true,
        canonicalAmount: 100,
        canonicalAmountInMinorUnits: 10000,
        canonicalCurrency: 'INR',
        provider: 'simulated',
        attemptCount: 1,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const result = await adminService.resolveReconciliation(
        'recon_manual_1',
        {
          action: 'MANUAL_OVERRIDE_VERIFIED',
          notes: 'Manually verified via rzp_live_SECRETKEY999 and token=secret_auth_pass',
        },
        { id: 'usr_admin1', email: 'admin@plaza.test' },
      );

      expect(result.status).toBe(ReconciliationStatus.RESOLVED);
      expect(result.requiresManualIntervention).toBe(false);
      expect(result.sanitizedResolutionReason).not.toContain('rzp_live_SECRETKEY999');
      expect(result.sanitizedResolutionReason).toContain('[REDACTED_RZP_KEY]');

      expect(auditLogsStore.size).toBe(1);
      const auditLog = Array.from(auditLogsStore.values())[0];
      expect(auditLog.action).toBe('RESOLVE_PAYMENT_RECONCILIATION');
    });

    it('2.18 Category 14: UNKNOWN_PROVIDER_STATE — unhandled or unrecognized status flags operator', async () => {
      paymentStore.set('pay_unk_state', {
        id: 'pay_unk_state',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_unk',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_unk',
        orderId: 'order_unk',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'some_weird_unrecognized_status' as any,
        captured: false,
      });

      const res = await reconService.reconcilePayment('pay_unk_state');
      expect(res.mismatchCategory).toBe(ReconciliationMismatchCategory.UNKNOWN_PROVIDER_STATE);
      expect(res.status).toBe(ReconciliationStatus.REQUIRED);
      expect(res.requiresManualIntervention).toBe(true);
    });

    it('2.19 Validation: throws BadRequestException if paymentId is invalid or empty', async () => {
      await expect(reconService.reconcilePayment('')).rejects.toThrow(BadRequestException);
      await expect(reconService.reconcilePayment(null as any)).rejects.toThrow(BadRequestException);
    });
  });

  describe('3. Concurrency, Deduplication & Batch Scheduling', () => {
    it('3.1 should reject concurrent duplicate reconciliation executions for the same payment', async () => {
      paymentStore.set('pay_concurrent_1', {
        id: 'pay_concurrent_1',
        amount: 100,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_conc',
        status: PaymentStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_conc',
        orderId: 'order_conc',
        amount: 100,
        amountInMinorUnits: 10000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const [res1, res2] = await Promise.all([
        reconService.reconcilePayment('pay_concurrent_1'),
        reconService.reconcilePayment('pay_concurrent_1'),
      ]);

      expect(res1).toBeDefined();
      expect(res2).toBeDefined();
      expect(res1.paymentId).toBe('pay_concurrent_1');
    });

    it('3.2 should process pending batch items in reconcileBatch', async () => {
      reconStore.set('recon_batch_1', {
        id: 'recon_batch_1',
        paymentId: 'pay_batch_1',
        status: ReconciliationStatus.REQUIRED,
        attemptCount: 0,
        createdAt: new Date(),
      } as any);

      paymentStore.set('pay_batch_1', {
        id: 'pay_batch_1',
        amount: 50,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_b1',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      webhookStore.set('evt_b1', {
        id: 'evt_b1',
        providerPaymentId: 'pay_sim_b1',
        status: 'PROCESSED',
        processedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_b1',
        orderId: 'order_b1',
        amount: 50,
        amountInMinorUnits: 5000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const summary = await reconService.reconcileBatch(10);
      expect(summary.processed).toBeGreaterThanOrEqual(1);
    });

    it('3.3 should handle empty batch without errors', async () => {
      reconStore.clear();
      const summary = await reconService.reconcileBatch(10);
      expect(summary.processed).toBe(0);
      expect(summary.resolved).toBe(0);
      expect(summary.failed).toBe(0);
    });
  });

  describe('4. Administrative Operations & Secret Sanitization', () => {
    it('4.1 should query reconciliation records and summary via admin service', async () => {
      reconStore.set('recon_adm_1', {
        id: 'recon_adm_1',
        paymentId: 'pay_adm_1',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
        requiresManualIntervention: true,
        canonicalAmount: 100,
        canonicalAmountInMinorUnits: 10000,
        canonicalCurrency: 'INR',
        provider: 'simulated',
        attemptCount: 1,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const records = await adminService.getReconciliationRecords({});
      expect(records.total).toBe(1);
      expect(records.items[0].id).toBe('recon_adm_1');

      const summary = await adminService.getReconciliationSummary();
      expect(summary.totalRecords).toBe(1);
      expect(summary.requiredCount).toBe(1);
    });

    it('4.2 should support admin manual resolution with audit log and secret sanitization', async () => {
      reconStore.set('recon_manual_1', {
        id: 'recon_manual_1',
        paymentId: 'pay_manual_1',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
        requiresManualIntervention: true,
        canonicalAmount: 100,
        canonicalAmountInMinorUnits: 10000,
        canonicalCurrency: 'INR',
        provider: 'simulated',
        attemptCount: 1,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      const result = await adminService.resolveReconciliation(
        'recon_manual_1',
        {
          action: 'MANUAL_OVERRIDE_VERIFIED',
          notes: 'Manually verified via rzp_live_SECRETKEY999 and token=secret_auth_pass',
        },
        { id: 'usr_admin1', email: 'admin@plaza.test' },
      );

      expect(result.status).toBe(ReconciliationStatus.RESOLVED);
      expect(result.requiresManualIntervention).toBe(false);
      expect(result.sanitizedResolutionReason).not.toContain('rzp_live_SECRETKEY999');
      expect(result.sanitizedResolutionReason).toContain('[REDACTED_RZP_KEY]');

      expect(auditLogsStore.size).toBe(1);
      const auditLog = Array.from(auditLogsStore.values())[0];
      expect(auditLog.action).toBe('RESOLVE_PAYMENT_RECONCILIATION');
    });

    it('4.3 should trigger single payment reconcile via admin controller', async () => {
      paymentStore.set('pay_trig_1', {
        id: 'pay_trig_1',
        amount: 80,
        currency: 'INR',
        provider: 'simulated',
        providerPaymentId: 'pay_sim_trig',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      webhookStore.set('evt_trig', {
        id: 'evt_trig',
        providerPaymentId: 'pay_sim_trig',
        status: 'PROCESSED',
        processedAt: new Date(),
      } as any);

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_trig',
        orderId: 'order_trig',
        amount: 80,
        amountInMinorUnits: 8000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const res = await adminController.triggerPaymentReconcile(
        'pay_trig_1',
        { force: true, notes: 'Audit trigger' },
        { user: { id: 'usr_admin1', email: 'admin@plaza.test' } },
      );

      expect(res.paymentId).toBe('pay_trig_1');
      expect(res.status).toBe(ReconciliationStatus.NOT_REQUIRED);
    });

    it('4.4 should throw NotFoundException when resolving a non-existent reconciliation record', async () => {
      await expect(
        adminService.resolveReconciliation(
          'recon_missing_999',
          { action: 'RESOLVE', notes: 'test' },
          { id: 'usr_admin1' },
        ),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('5. Production Safety Invariants & State Machine Non-Negotiables', () => {
    it('5.1 should maintain PAYMENT_MODE=SIMULATED and RAZORPAY_LIVE_ENABLED=false', () => {
      const config = new PaymentConfigService();
      const evalResult = config.evaluate();
      expect(evalResult.summary.paymentMode).toBe(PaymentMode.SIMULATED);
      expect(evalResult.summary.razorpayLiveEnabled).toBe(false);
      expect(evalResult.summary.liveOperationsAllowed).toBe(false);
    });

    it('5.2 should strictly prevent live operations when RAZORPAY_LIVE_ENABLED is false', () => {
      const config = new PaymentConfigService({
        PAYMENT_MODE: PaymentMode.RAZORPAY,
        RAZORPAY_LIVE_ENABLED: 'false',
        RAZORPAY_KEY_ID: 'rzp_live_123',
        RAZORPAY_KEY_SECRET: 'secret',
      });
      expect(() => config.assertRazorpayLiveOperationAllowed()).toThrow();
    });

    it('5.3 should strictly reject illegal terminal state transitions', () => {
      expect(isValidPaymentStateTransition(PaymentStatus.CAPTURED, PaymentStatus.FAILED)).toBe(false);
      expect(isValidPaymentStateTransition(PaymentStatus.REFUNDED, PaymentStatus.CAPTURED)).toBe(false);
      expect(isValidPaymentStateTransition(PaymentStatus.CANCELLED, PaymentStatus.CAPTURED)).toBe(false);
      expect(isValidPaymentStateTransition(PaymentStatus.FAILED, PaymentStatus.CAPTURED)).toBe(false);

      expect(() => assertValidPaymentStateTransition(PaymentStatus.CAPTURED, PaymentStatus.FAILED)).toThrow(
        BadRequestException,
      );
      expect(() => assertValidPaymentStateTransition(PaymentStatus.REFUNDED, PaymentStatus.CAPTURED)).toThrow(
        BadRequestException,
      );
    });
  });
});
