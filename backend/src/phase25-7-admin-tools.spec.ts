import * as crypto from 'crypto';
import {
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import {
  PaymentEntity,
  PaymentStatus,
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
import { BookingEntity, BookingStatus, BookingType, VALID_BOOKING_TRANSITIONS } from './database/entities/booking.entity';
import { User, UserRole } from './database/entities/user.entity';
import { AuditLogEntity } from './database/entities/audit-log.entity';
import { PaymentReconciliationService } from './modules/payments/payment-reconciliation.service';
import { PaymentRecoveryService } from './modules/payments/payment-recovery.service';
import { PaymentConfigService, PaymentMode } from './modules/payments/payment-config.service';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { AdminService } from './modules/admin/admin.service';
import { AdminController } from './modules/admin/admin.controller';

describe('PLAZA Phase 25.7 — Admin Reconciliation & Incident Tools Production Operations Suite', () => {
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
  let paymentRecoveryService: PaymentRecoveryService;
  let paymentReconciliationService: PaymentReconciliationService;
  let adminService: AdminService;
  let adminController: AdminController;

  const mockAdminUser = {
    id: 'usr_admin_1',
    email: 'admin@plaza.app',
    name: 'Super Admin',
    role: UserRole.ADMIN,
  };

  const mockOperatorUser = {
    id: 'usr_op_1',
    email: 'operator@plaza.app',
    name: 'Ops Manager',
    role: UserRole.OPERATOR,
  };

  beforeEach(() => {
    reconStore = new Map();
    paymentStore = new Map();
    bookingStore = new Map();
    webhookStore = new Map();
    recoveryStore = new Map();
    idempotencyStore = new Map();
    auditLogsStore = new Map();
    usersStore = new Map();

    const buildMockRepo = (store: Map<string, any>) => ({
      find: jest.fn(async (options?: any) => {
        let results = Array.from(store.values());
        if (options?.where) {
          const matchCondition = (item: any, cond: any) => {
            return Object.entries(cond).every(([k, v]: [string, any]) => {
              if (v && typeof v === 'object' && v._type) {
                if (v._type === 'lessThanOrEqual') {
                  return item[k] && new Date(item[k]).getTime() <= new Date(v._value).getTime();
                }
              }
              return item[k] === v;
            });
          };

          if (Array.isArray(options.where)) {
            results = results.filter((item) =>
              options.where.some((cond: any) => matchCondition(item, cond)),
            );
          } else {
            results = results.filter((item) => matchCondition(item, options.where));
          }
        }
        if (options?.take) {
          results = results.slice(0, options.take);
        }
        return results;
      }),
      findOne: jest.fn(async (options?: any) => {
        const results = Array.from(store.values());
        if (options?.where) {
          if (Array.isArray(options.where)) {
            return results.find((item) =>
              options.where.some((cond: any) =>
                Object.entries(cond).every(([k, v]) => item[k] === v),
              ),
            ) || null;
          }
          return results.find((item) =>
            Object.entries(options.where).every(([k, v]) => item[k] === v),
          ) || null;
        }
        return results[0] || null;
      }),
      count: jest.fn(async (options?: any) => {
        let results = Array.from(store.values());
        if (options?.where) {
          if (Array.isArray(options.where)) {
            results = results.filter((item) =>
              options.where.some((cond: any) =>
                Object.entries(cond).every(([k, v]) => item[k] === v),
              ),
            );
          } else {
            results = results.filter((item) =>
              Object.entries(options.where).every(([k, v]) => item[k] === v),
            );
          }
        }
        return results.length;
      }),
      create: jest.fn((data: any) => ({ ...data })),
      save: jest.fn(async (entity: any) => {
        const id = entity.id || `ent_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
        const saved = { ...entity, id, updatedAt: new Date(), createdAt: entity.createdAt || new Date() };
        store.set(id, saved);
        return saved;
      }),
      createQueryBuilder: jest.fn(() => {
        let conditions: Array<(item: any) => boolean> = [];
        let limitVal = 50;
        let offsetVal = 0;
        const qb: any = {
          select: jest.fn(() => qb),
          addSelect: jest.fn(() => qb),
          groupBy: jest.fn(() => qb),
          where: jest.fn(() => qb),
          andWhere: jest.fn((sql: string, params: any) => {
            if (params?.status) {
              conditions.push((i) => i.status === params.status || i.recoveryStatus === params.status);
            }
            if (params?.category) {
              conditions.push((i) => i.mismatchCategory === params.category);
            }
            if (params?.cat) {
              conditions.push((i) => i.failureCategory === params.cat);
            }
            if (params?.paymentId) {
              conditions.push((i) => i.paymentId === params.paymentId);
            }
            if (params?.bookingId) {
              conditions.push((i) => i.bookingId === params.bookingId);
            }
            if (params?.req !== undefined) {
              conditions.push((i) => i.requiresManualIntervention === params.req);
            }
            if (params?.statuses) {
              conditions.push((i) => params.statuses.includes(i.status));
            }
            return qb;
          }),
          orderBy: jest.fn(() => qb),
          skip: jest.fn((offset: number) => {
            offsetVal = offset;
            return qb;
          }),
          take: jest.fn((limit: number) => {
            limitVal = limit;
            return qb;
          }),
          getManyAndCount: jest.fn(async () => {
            let filtered = Array.from(store.values());
            for (const cond of conditions) {
              filtered = filtered.filter(cond);
            }
            const total = filtered.length;
            const items = filtered.slice(offsetVal, offsetVal + limitVal);
            return [items, total];
          }),
          getMany: jest.fn(async () => {
            let filtered = Array.from(store.values());
            for (const cond of conditions) {
              filtered = filtered.filter(cond);
            }
            return filtered.slice(offsetVal, offsetVal + limitVal);
          }),
          getRawMany: jest.fn(async () => {
            const counts: Record<string, number> = {};
            for (const item of store.values()) {
              if (item.mismatchCategory) {
                counts[item.mismatchCategory] = (counts[item.mismatchCategory] || 0) + 1;
              }
            }
            return Object.entries(counts).map(([category, count]) => ({ category, count: String(count) }));
          }),
        };
        return qb;
      }),
    });

    mockReconRepo = buildMockRepo(reconStore);
    mockPaymentRepo = buildMockRepo(paymentStore);
    mockBookingRepo = buildMockRepo(bookingStore);
    mockWebhookRepo = buildMockRepo(webhookStore);
    mockRecoveryRepo = buildMockRepo(recoveryStore);
    mockIdempRepo = buildMockRepo(idempotencyStore);
    mockAuditLogRepo = buildMockRepo(auditLogsStore);
    mockUserRepo = buildMockRepo(usersStore);

    simulatedAdapter = new SimulatedPaymentAdapter();
    razorpayAdapter = new RazorpayAdapter();
    paymentConfigService = new PaymentConfigService({
      PAYMENT_MODE: PaymentMode.SIMULATED,
      RAZORPAY_LIVE_ENABLED: 'false',
    });

    paymentRecoveryService = new PaymentRecoveryService(mockRecoveryRepo as any);

    paymentReconciliationService = new PaymentReconciliationService(
      mockReconRepo as any,
      mockPaymentRepo as any,
      mockBookingRepo as any,
      mockWebhookRepo as any,
      mockRecoveryRepo as any,
      mockIdempRepo as any,
      undefined,
      paymentConfigService,
      simulatedAdapter,
      razorpayAdapter,
      paymentRecoveryService,
    );

    adminService = new AdminService(
      mockUserRepo as any,
      buildMockRepo(new Map()) as any,
      buildMockRepo(new Map()) as any,
      buildMockRepo(new Map()) as any,
      buildMockRepo(new Map()) as any,
      buildMockRepo(new Map()) as any,
      buildMockRepo(new Map()) as any,
      buildMockRepo(new Map()) as any,
      buildMockRepo(new Map()) as any,
      mockBookingRepo as any,
      mockAuditLogRepo as any,
      buildMockRepo(new Map()) as any,
      buildMockRepo(new Map()) as any,
      mockPaymentRepo as any,
      buildMockRepo(new Map()) as any,
      mockWebhookRepo as any,
      undefined,
      mockRecoveryRepo as any,
      paymentRecoveryService,
      mockReconRepo as any,
      paymentReconciliationService,
    );

    adminController = new AdminController(adminService);
  });

  describe('1. Reconciliation & Incident Dashboard Aggregates', () => {
    it('1.1 should return accurate aggregate metrics and safety config summary', async () => {
      // Seed reconciliation records
      await mockReconRepo.save({
        id: 'rec_1',
        paymentId: 'pay_1',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
        requiresManualIntervention: true,
      });
      await mockReconRepo.save({
        id: 'rec_2',
        paymentId: 'pay_2',
        status: ReconciliationStatus.RESOLVED,
        mismatchCategory: ReconciliationMismatchCategory.NO_MISMATCH,
        requiresManualIntervention: false,
      });
      await mockReconRepo.save({
        id: 'rec_3',
        paymentId: 'pay_3',
        status: ReconciliationStatus.FAILED,
        mismatchCategory: ReconciliationMismatchCategory.PROVIDER_ORDER_MISMATCH,
        requiresManualIntervention: true,
      });

      // Seed recovery records
      await mockRecoveryRepo.save({
        id: 'recv_1',
        paymentId: 'pay_4',
        recoveryStatus: RecoveryStatus.REQUIRED,
        failureCategory: FailureCategory.UNKNOWN_PROVIDER_OUTCOME,
        requiresManualIntervention: true,
      });

      // Seed webhook events
      await mockWebhookRepo.save({
        id: 'evt_1',
        eventType: 'payment.captured',
        status: 'PROCESSED',
        receivedAt: new Date(),
      });
      await mockWebhookRepo.save({
        id: 'evt_2',
        eventType: 'payment.failed',
        status: 'FAILED',
        failureReason: 'Signature mismatch',
        receivedAt: new Date(),
      });

      const dashboard = await adminController.getReconciliationDashboard();

      expect(dashboard).toBeDefined();
      expect(dashboard.reconciliation.total).toBe(3);
      expect(dashboard.reconciliation.required).toBe(1);
      expect(dashboard.reconciliation.resolved).toBe(1);
      expect(dashboard.reconciliation.failed).toBe(1);

      expect(dashboard.recovery.total).toBe(1);
      expect(dashboard.recovery.required).toBe(1);

      expect(dashboard.webhooks.total).toBe(2);
      expect(dashboard.webhooks.processed).toBe(1);
      expect(dashboard.webhooks.failed).toBe(1);

      expect(dashboard.mismatches.AMOUNT_MISMATCH).toBe(1);
      expect(dashboard.mismatches.PROVIDER_ORDER_MISMATCH).toBe(1);
      expect(dashboard.mismatches.NO_MISMATCH).toBe(1);

      expect(dashboard.manualInterventionRequired).toBe(3); // 2 recon + 1 recovery

      // Invariants: zero real money, simulated mode active
      expect(dashboard.paymentConfig.paymentMode).toBe('SIMULATED');
      expect(dashboard.paymentConfig.razorpayLiveEnabled).toBe(false);
      expect(dashboard.paymentConfig.livePaymentBlocked).toBe(true);
      expect(dashboard.paymentConfig.status).toBe('SIMULATED_SAFE');
    });

    it('1.2 should return summary endpoint metrics correctly', async () => {
      await mockReconRepo.save({
        id: 'rec_sum_1',
        paymentId: 'pay_sum_1',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.CURRENCY_MISMATCH,
        requiresManualIntervention: true,
      });

      const summary = await adminController.getReconciliationSummary();
      expect(summary.totalRecords).toBe(1);
      expect(summary.requiredCount).toBe(1);
      expect(summary.manualInterventionCount).toBe(1);
      expect(summary.mismatchBreakdown.CURRENCY_MISMATCH).toBe(1);
    });
  });

  describe('2. List and Filter Operations', () => {
    beforeEach(async () => {
      await mockReconRepo.save({
        id: 'recon_a',
        paymentId: 'pay_100',
        bookingId: 'bk_100',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
        canonicalPaymentStatus: PaymentStatus.CAPTURED,
        observedProviderStatus: 'AUTHORIZED',
        canonicalAmount: 1500,
        canonicalAmountInMinorUnits: 150000,
        observedAmountInMinorUnits: 120000,
        canonicalCurrency: 'INR',
        observedCurrency: 'INR',
        requiresManualIntervention: true,
        attemptCount: 1,
      });

      await mockReconRepo.save({
        id: 'recon_b',
        paymentId: 'pay_200',
        bookingId: 'bk_200',
        status: ReconciliationStatus.RESOLVED,
        mismatchCategory: ReconciliationMismatchCategory.NO_MISMATCH,
        canonicalPaymentStatus: PaymentStatus.CAPTURED,
        observedProviderStatus: 'CAPTURED',
        canonicalAmount: 500,
        canonicalAmountInMinorUnits: 50000,
        observedAmountInMinorUnits: 50000,
        canonicalCurrency: 'INR',
        observedCurrency: 'INR',
        requiresManualIntervention: false,
        attemptCount: 0,
      });
    });

    it('2.1 should filter reconciliation records by status', async () => {
      const result = await adminController.getReconciliationRecords({
        status: ReconciliationStatus.REQUIRED,
      });
      expect(result.total).toBe(1);
      expect(result.items[0].id).toBe('recon_a');
      expect(result.items[0].mismatchCategory).toBe('AMOUNT_MISMATCH');
    });

    it('2.2 should filter reconciliation records by mismatch category', async () => {
      const result = await adminController.getReconciliationRecords({
        mismatchCategory: ReconciliationMismatchCategory.NO_MISMATCH,
      });
      expect(result.total).toBe(1);
      expect(result.items[0].id).toBe('recon_b');
    });

    it('2.3 should filter reconciliation records by paymentId and bookingId', async () => {
      const resultByPay = await adminController.getReconciliationRecords({ paymentId: 'pay_100' });
      expect(resultByPay.total).toBe(1);
      expect(resultByPay.items[0].paymentId).toBe('pay_100');

      const resultByBk = await adminController.getReconciliationRecords({ bookingId: 'bk_200' });
      expect(resultByBk.total).toBe(1);
      expect(resultByBk.items[0].bookingId).toBe('bk_200');
    });

    it('2.4 should filter reconciliation records by requiresManualIntervention', async () => {
      const result = await adminController.getReconciliationRecords({
        requiresManualIntervention: true,
      });
      expect(result.total).toBe(1);
      expect(result.items[0].requiresManualIntervention).toBe(true);
    });
  });

  describe('3. Unified Incident Center', () => {
    beforeEach(async () => {
      await mockRecoveryRepo.save({
        id: 'rec_inc_1',
        paymentId: 'pay_inc_1',
        bookingId: 'bk_inc_1',
        failureCategory: FailureCategory.UNKNOWN_PROVIDER_OUTCOME,
        recoveryStatus: RecoveryStatus.REQUIRED,
        safeFailureReason: 'Gateway gateway timeout during capture',
        requiresManualIntervention: true,
        createdAt: new Date('2026-09-30T10:00:00Z'),
      });

      await mockReconRepo.save({
        id: 'recon_inc_2',
        paymentId: 'pay_inc_2',
        bookingId: 'bk_inc_2',
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
        status: ReconciliationStatus.REQUIRED,
        sanitizedResolutionReason: 'Price difference detected between quote and provider',
        requiresManualIntervention: true,
        createdAt: new Date('2026-09-30T11:00:00Z'),
      });

      await mockWebhookRepo.save({
        id: 'evt_wh_3',
        eventType: 'payment.failed',
        status: 'FAILED',
        failureReason: 'Signature verification error',
        receivedAt: new Date('2026-09-30T12:00:00Z'),
      });
    });

    it('3.1 should list unified incidents across recovery, reconciliation, and webhooks', async () => {
      const result = await adminController.getIncidents({ type: 'ALL' });
      expect(result.total).toBe(3);
      expect(result.incidents.map((i: any) => i.type)).toEqual(
        expect.arrayContaining(['RECOVERY', 'RECONCILIATION', 'WEBHOOK']),
      );
    });

    it('3.2 should filter unified incidents by type', async () => {
      const recOnly = await adminController.getIncidents({ type: 'RECOVERY' });
      expect(recOnly.total).toBe(1);
      expect(recOnly.incidents[0].type).toBe('RECOVERY');
      expect(recOnly.incidents[0].id).toBe('rec_inc_1');

      const reconOnly = await adminController.getIncidents({ type: 'RECONCILIATION' });
      expect(reconOnly.total).toBe(1);
      expect(reconOnly.incidents[0].type).toBe('RECONCILIATION');
      expect(reconOnly.incidents[0].id).toBe('recon_inc_2');

      const whOnly = await adminController.getIncidents({ type: 'WEBHOOK' });
      expect(whOnly.total).toBe(1);
      expect(whOnly.incidents[0].type).toBe('WEBHOOK');
    });

    it('3.3 should filter unified incidents by search string', async () => {
      const result = await adminController.getIncidents({ search: 'pay_inc_1' });
      expect(result.total).toBe(1);
      expect(result.incidents[0].paymentId).toBe('pay_inc_1');
    });

    it('3.4 should retrieve unified incident details by ID with linked entities', async () => {
      await mockPaymentRepo.save({
        id: 'pay_inc_1',
        amount: 1200,
        currency: 'INR',
        status: PaymentStatus.AUTHORIZED,
        provider: 'simulated',
        providerPaymentId: 'pay_gw_inc_1',
      });

      await mockBookingRepo.save({
        id: 'bk_inc_1',
        title: 'Kalki 2898 AD',
        type: BookingType.MOVIE,
        status: BookingStatus.PENDING,
        totalPrice: 1200,
      });

      const details = await adminController.getIncidentById('rec_inc_1');
      expect(details).toBeDefined();
      expect(details.id).toBe('rec_inc_1');
      expect(details.type).toBe('RECOVERY');
      expect(details.payment).toBeDefined();
      expect(details.payment.id).toBe('pay_inc_1');
      expect(details.booking).toBeDefined();
      expect(details.booking.title).toBe('Kalki 2898 AD');
      expect(details.timeline).toBeDefined();
      expect(details.timeline.length).toBeGreaterThan(0);
    });
  });

  describe('4. Reconciliation Detail & Operational Timeline', () => {
    it('4.1 should return canonical vs observed comparison and chronological timeline', async () => {
      const now = new Date();
      await mockBookingRepo.save({
        id: 'bk_timeline_1',
        title: 'Dining at Jewel of Nizam',
        type: BookingType.DINING,
        status: BookingStatus.CONFIRMED,
        totalPrice: 2500,
        createdAt: new Date(now.getTime() - 3600000),
      });

      await mockPaymentRepo.save({
        id: 'pay_timeline_1',
        bookingId: 'bk_timeline_1',
        amount: 2500,
        currency: 'INR',
        status: PaymentStatus.CAPTURED,
        provider: 'simulated',
        providerPaymentId: 'pay_gw_time_1',
        providerOrderId: 'order_gw_time_1',
        createdAt: new Date(now.getTime() - 3500000),
        updatedAt: new Date(now.getTime() - 3000000),
      });

      await mockWebhookRepo.save({
        id: 'evt_time_1',
        eventType: 'payment.captured',
        status: 'PROCESSED',
        providerPaymentId: 'pay_gw_time_1',
        providerOrderId: 'order_gw_time_1',
        receivedAt: new Date(now.getTime() - 3200000),
      });

      await mockReconRepo.save({
        id: 'recon_timeline_1',
        paymentId: 'pay_timeline_1',
        bookingId: 'bk_timeline_1',
        provider: 'simulated',
        providerPaymentId: 'pay_gw_time_1',
        providerOrderId: 'order_gw_time_1',
        canonicalPaymentStatus: PaymentStatus.CAPTURED,
        observedProviderStatus: 'CAPTURED',
        canonicalAmount: 2500,
        canonicalAmountInMinorUnits: 250000,
        observedAmountInMinorUnits: 250000,
        canonicalCurrency: 'INR',
        observedCurrency: 'INR',
        mismatchCategory: ReconciliationMismatchCategory.NO_MISMATCH,
        status: ReconciliationStatus.RESOLVED,
        resolvedAt: new Date(now.getTime() - 1000000),
        sanitizedResolutionReason: 'Reconciled automatically by engine',
        createdAt: new Date(now.getTime() - 2000000),
        requiresManualIntervention: false,
        attemptCount: 1,
      });

      const detail = await adminController.getReconciliationById('recon_timeline_1');

      expect(detail.id).toBe('recon_timeline_1');
      expect(detail.canonicalVsObserved).toBeDefined();
      expect(detail.canonicalVsObserved.status.matches).toBe(true);
      expect(detail.canonicalVsObserved.amount.matches).toBe(true);
      expect(detail.canonicalVsObserved.currency.matches).toBe(true);

      expect(detail.timeline).toBeDefined();
      expect(detail.timeline.length).toBeGreaterThanOrEqual(4);

      // Verify chronological sorting (each event timestamp >= previous timestamp)
      for (let i = 1; i < detail.timeline.length; i++) {
        const prev = new Date(detail.timeline[i - 1].timestamp).getTime();
        const curr = new Date(detail.timeline[i].timestamp).getTime();
        expect(curr).toBeGreaterThanOrEqual(prev);
      }
    });
  });

  describe('5. Manual Reconcile & Manual Resolve Actions', () => {
    it('5.1 should trigger single payment reconcile and record audit log', async () => {
      await mockPaymentRepo.save({
        id: 'pay_trig_1',
        bookingId: 'bk_trig_1',
        amount: 1000,
        currency: 'INR',
        status: PaymentStatus.CAPTURED,
        provider: 'simulated',
        providerPaymentId: 'pay_sim_trig_1',
        providerOrderId: 'order_sim_trig_1',
      });

      const result = await adminController.triggerPaymentReconcile(
        'pay_trig_1',
        { force: true, notes: 'Operator manual reconcile test' },
        { user: mockAdminUser },
      );

      expect(result).toBeDefined();
      expect(result.paymentId).toBe('pay_trig_1');

      // Verify audit log was written
      const logs = Array.from(auditLogsStore.values());
      const trigLog = logs.find((l) => l.action === 'TRIGGER_PAYMENT_RECONCILE');
      expect(trigLog).toBeDefined();
      expect(trigLog?.metadata?.paymentId).toBe('pay_trig_1');
    });

    it('5.2 should trigger batch reconcile sweep', async () => {
      await mockReconRepo.save({
        id: 'recon_batch_1',
        paymentId: 'pay_b_1',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.PAYMENT_STATE_MISMATCH,
        requiresManualIntervention: true,
        attemptCount: 0,
      });

      await mockPaymentRepo.save({
        id: 'pay_b_1',
        amount: 500,
        currency: 'INR',
        status: PaymentStatus.AUTHORIZED,
        provider: 'simulated',
        providerPaymentId: 'pay_sim_b1',
      });

      const batchResult = await adminController.triggerBatchReconcile(10, { user: mockAdminUser });
      expect(batchResult).toBeDefined();
      expect(batchResult.processed).toBeGreaterThanOrEqual(1);
    });

    it('5.3 should manually resolve a reconciliation record with audit notes', async () => {
      await mockPaymentRepo.save({
        id: 'pay_res_1',
        amount: 700,
        currency: 'INR',
        status: PaymentStatus.AUTHORIZED,
        provider: 'simulated',
      });

      await mockReconRepo.save({
        id: 'recon_res_1',
        paymentId: 'pay_res_1',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.PAYMENT_STATE_MISMATCH,
        requiresManualIntervention: true,
      });

      const resolveResult = await adminController.resolveReconciliation(
        'recon_res_1',
        {
          action: 'MANUAL_RESOLUTION',
          notes: 'Manually verified capture on operator terminal',
        },
        { user: mockAdminUser },
      );

      expect(resolveResult.status).toBe(ReconciliationStatus.RESOLVED);
      expect(resolveResult.requiresManualIntervention).toBe(false);
      expect(resolveResult.sanitizedResolutionReason).toContain('Manually verified capture');

      const logs = Array.from(auditLogsStore.values());
      const resLog = logs.find((l) => l.action === 'RESOLVE_PAYMENT_RECONCILIATION');
      expect(resLog).toBeDefined();
    });

    it('5.4 should route resolve through unified incident endpoint', async () => {
      await mockRecoveryRepo.save({
        id: 'rec_uni_1',
        paymentId: 'pay_uni_1',
        bookingId: 'bk_uni_1',
        failureCategory: FailureCategory.UNKNOWN_PROVIDER_OUTCOME,
        recoveryStatus: RecoveryStatus.REQUIRED,
        requiresManualIntervention: true,
      });

      const res: any = await adminController.resolveUnifiedIncident(
        'rec_uni_1',
        { action: 'RESOLVE', notes: 'Operator resolved via unified incident center' },
        { user: mockAdminUser },
      );

      expect(res.recoveryStatus).toBe(RecoveryStatus.RESOLVED);
      expect(res.requiresManualIntervention).toBe(false);
    });
  });

  describe('6. Strict Validation Enforcement & Anti-Bypass Protections', () => {
    it('6.1 should REJECT invalid payment state transition during manual resolve (CAPTURED -> FAILED)', async () => {
      await mockPaymentRepo.save({
        id: 'pay_val_1',
        status: PaymentStatus.CAPTURED,
        amount: 1000,
        currency: 'INR',
        provider: 'simulated',
      });

      await mockReconRepo.save({
        id: 'recon_val_1',
        paymentId: 'pay_val_1',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.PAYMENT_STATE_MISMATCH,
      });

      await expect(
        adminController.resolveReconciliation(
          'recon_val_1',
          {
            action: 'FORCE_FAIL',
            notes: 'Attempting illegal transition to failed from captured',
            targetPaymentStatus: PaymentStatus.FAILED,
          },
          { user: mockAdminUser },
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('6.2 should REJECT invalid payment state transition during manual resolve (REFUNDED -> CAPTURED)', async () => {
      await mockPaymentRepo.save({
        id: 'pay_val_2',
        status: PaymentStatus.REFUNDED,
        amount: 1000,
        currency: 'INR',
        provider: 'simulated',
      });

      await mockReconRepo.save({
        id: 'recon_val_2',
        paymentId: 'pay_val_2',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.PAYMENT_STATE_MISMATCH,
      });

      await expect(
        adminController.resolveReconciliation(
          'recon_val_2',
          {
            action: 'FORCE_CAPTURE',
            notes: 'Attempting illegal transition to captured from refunded',
            targetPaymentStatus: PaymentStatus.CAPTURED,
          },
          { user: mockAdminUser },
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('6.3 should REJECT invalid booking state transition during manual resolve (CANCELLED -> CONFIRMED)', async () => {
      await mockBookingRepo.save({
        id: 'bk_val_3',
        status: BookingStatus.CANCELLED,
        title: 'Cancelled Show',
        type: BookingType.MOVIE,
        totalPrice: 500,
      });

      await mockPaymentRepo.save({
        id: 'pay_val_3',
        bookingId: 'bk_val_3',
        status: PaymentStatus.REFUNDED,
        amount: 500,
        currency: 'INR',
        provider: 'simulated',
      });

      await mockReconRepo.save({
        id: 'recon_val_3',
        paymentId: 'pay_val_3',
        bookingId: 'bk_val_3',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.BOOKING_STATE_MISMATCH,
      });

      await expect(
        adminController.resolveReconciliation(
          'recon_val_3',
          {
            action: 'FORCE_CONFIRM_BOOKING',
            notes: 'Attempting illegal booking transition to confirmed from cancelled',
            targetBookingStatus: BookingStatus.CONFIRMED,
          },
          { user: mockAdminUser },
        ),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('7. Secret Redaction & Read-Only Safety', () => {
    it('7.1 should NEVER expose secret keys, webhook secrets, or raw private tokens in response DTOs', async () => {
      await mockPaymentRepo.save({
        id: 'pay_sec_1',
        amount: 800,
        currency: 'INR',
        status: PaymentStatus.CAPTURED,
        provider: 'simulated',
        metadata: {
          webhookSecret: 'whsec_secret_key_never_leak',
          internalKey: 'rzp_live_secret_sample',
        },
      });

      await mockReconRepo.save({
        id: 'recon_sec_1',
        paymentId: 'pay_sec_1',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
      });

      const response = await adminController.getReconciliationById('recon_sec_1');
      const jsonString = JSON.stringify(response);

      expect(jsonString).not.toContain('whsec_secret_key_never_leak');
      expect(jsonString).not.toContain('rzp_live_secret_sample');
    });

    it('7.2 should guarantee that GET requests cause ZERO side effects or mutations', async () => {
      await mockReconRepo.save({
        id: 'recon_ro_1',
        paymentId: 'pay_ro_1',
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.AMOUNT_MISMATCH,
        requiresManualIntervention: true,
      });

      const beforeReconCount = reconStore.size;
      const beforePaymentCount = paymentStore.size;
      const beforeAuditCount = auditLogsStore.size;

      // Execute read-only endpoints
      await adminController.getReconciliationDashboard();
      await adminController.getReconciliationSummary();
      await adminController.getReconciliationRecords({});
      await adminController.getReconciliationById('recon_ro_1');
      await adminController.getIncidents({});

      expect(reconStore.size).toBe(beforeReconCount);
      expect(paymentStore.size).toBe(beforePaymentCount);
      expect(auditLogsStore.size).toBe(beforeAuditCount);
    });
  });
});
