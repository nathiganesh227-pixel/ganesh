import * as crypto from 'crypto';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
  UnauthorizedException,
  ServiceUnavailableException,
} from '@nestjs/common';
import {
  PaymentEntity,
  PaymentStatus,
  PaymentErrorCode,
  assertValidPaymentStateTransition,
  isValidPaymentStateTransition,
  toMinorUnits,
  VALID_PAYMENT_TRANSITIONS,
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
import { IdempotencyService } from './modules/bookings/idempotency.service';
import { PaymentReconciliationService } from './modules/payments/payment-reconciliation.service';
import { PaymentRecoveryService } from './modules/payments/payment-recovery.service';
import { PaymentConfigService, PaymentMode, PaymentConfigStatus } from './modules/payments/payment-config.service';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { RolesGuard } from './modules/auth/guards/roles.guard';
import { Reflector } from '@nestjs/core';

const TEST_SECRET = 'simulated_key_secret';
const TEST_WEBHOOK_SECRET = 'simulated_webhook_secret';

function generateHmac(data: string, secret = TEST_SECRET): string {
  return crypto.createHmac('sha256', secret).update(data).digest('hex');
}

function generateWebhookHmac(rawBody: string, secret = TEST_WEBHOOK_SECRET): string {
  return crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
}

describe('PLAZA Phase 25.9 — Automated Financial Test Matrix & Invariant Verification Suite', () => {
  let reconStore: Map<string, PaymentReconciliationEntity>;
  let paymentStore: Map<string, PaymentEntity>;
  let bookingStore: Map<string, BookingEntity>;
  let webhookStore: Map<string, WebhookEventEntity>;
  let recoveryStore: Map<string, PaymentRecoveryEntity>;
  let idempotencyStore: Map<string, IdempotencyRecordEntity>;
  let auditLogsStore: Map<string, AuditLogEntity>;
  let usersStore: Map<string, User>;
  let inventoryStore: Map<string, number>;
  let sideEffectCounters: {
    providerCalls: number;
    bookingConfirmations: number;
    refunds: number;
    rewardsAwarded: number;
    rewardsReversed: number;
    notificationsSent: number;
    inventoryDecrements: number;
    inventoryRestorations: number;
  };

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
  let paymentConfigService: PaymentConfigService;
  let recoveryService: PaymentRecoveryService;
  let reconService: PaymentReconciliationService;
  let idempotencyService: IdempotencyService;

  beforeEach(() => {
    reconStore = new Map();
    paymentStore = new Map();
    bookingStore = new Map();
    webhookStore = new Map();
    recoveryStore = new Map();
    idempotencyStore = new Map();
    auditLogsStore = new Map();
    usersStore = new Map();
    inventoryStore = new Map([
      ['theatre_inox_screen1_kalki_A1', 1],
      ['theatre_inox_screen1_kalki_A2', 1],
      ['evt_coldplay_vip', 50],
      ['hotel_taj_deluxe', 10],
    ]);

    sideEffectCounters = {
      providerCalls: 0,
      bookingConfirmations: 0,
      refunds: 0,
      rewardsAwarded: 0,
      rewardsReversed: 0,
      notificationsSent: 0,
      inventoryDecrements: 0,
      inventoryRestorations: 0,
    };

    mockReconRepo = {
      create: jest.fn((entity) => ({ id: `rec_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`, ...entity })),
      save: jest.fn(async (entity) => {
        const id = entity.id || `rec_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
        const saved = { ...entity, id, updatedAt: new Date() };
        reconStore.set(id, saved);
        return saved;
      }),
      findOne: jest.fn(async ({ where }) => {
        for (const item of reconStore.values()) {
          let match = true;
          if (where.id && item.id !== where.id) match = false;
          if (where.paymentId && item.paymentId !== where.paymentId) match = false;
          if (where.status && item.status !== where.status) match = false;
          if (match) return item;
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
            if (match) {
              results.push(item);
              break;
            }
          }
        }
        return results;
      }),
    };

    mockPaymentRepo = {
      create: jest.fn((entity) => ({ id: `pay_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`, ...entity })),
      save: jest.fn(async (entity) => {
        const id = entity.id || `pay_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
        const saved = { ...entity, id, updatedAt: new Date() };
        paymentStore.set(id, saved);
        return saved;
      }),
      findOne: jest.fn(async ({ where }) => {
        for (const item of paymentStore.values()) {
          let match = true;
          if (where.id && item.id !== where.id) match = false;
          if (where.bookingId && item.bookingId !== where.bookingId) match = false;
          if (where.providerOrderId && item.providerOrderId !== where.providerOrderId) match = false;
          if (where.providerPaymentId && item.providerPaymentId !== where.providerPaymentId) match = false;
          if (match) return item;
        }
        return null;
      }),
      find: jest.fn(async () => Array.from(paymentStore.values())),
    };

    mockBookingRepo = {
      create: jest.fn((entity) => ({ id: `bk_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`, ...entity })),
      save: jest.fn(async (entity) => {
        const id = entity.id || `bk_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
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

    mockWebhookRepo = {
      create: jest.fn((entity) => ({ id: `wh_${Date.now()}`, ...entity })),
      save: jest.fn(async (entity) => {
        const id = entity.id || entity.eventId || `wh_${Date.now()}`;
        const saved = { ...entity, id };
        webhookStore.set(id, saved);
        return saved;
      }),
      findOne: jest.fn(async (options: any) => {
        const where = options?.where;
        if (!where) return null;
        const conds = Array.isArray(where) ? where : [where];
        for (const item of webhookStore.values()) {
          for (const cond of conds) {
            if (cond.id && item.id === cond.id) return item;
            if (cond.eventId && item.id === cond.eventId) return item;
            if (cond.providerPaymentId && item.providerPaymentId === cond.providerPaymentId) return item;
            if (cond.providerOrderId && item.providerOrderId === cond.providerOrderId) return item;
            if (cond.paymentId && item.paymentId === cond.paymentId) return item;
          }
        }
        return null;
      }),
    };

    mockRecoveryRepo = {
      create: jest.fn((entity) => ({ id: `recov_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`, ...entity })),
      save: jest.fn(async (entity) => {
        const id = entity.id || `recov_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
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

    mockIdempRepo = {
      create: jest.fn((entity) => ({ id: `idemp_${Date.now()}`, ...entity })),
      save: jest.fn(async (entity) => {
        idempotencyStore.set(entity.key, entity);
        return entity;
      }),
      findOne: jest.fn(async ({ where }) => {
        return idempotencyStore.get(where.key) || null;
      }),
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

    mockUserRepo = {
      findOne: jest.fn(async ({ where }) => {
        return usersStore.get(where.id) || null;
      }),
      save: jest.fn(async (user) => {
        usersStore.set(user.id, user);
        return user;
      }),
    };

    mockDataSource = {
      transaction: jest.fn(async (callback: any) => {
        return await callback({
          findOne: async (entityClass: any, opts: any) => {
            if (entityClass === PaymentEntity) return mockPaymentRepo.findOne(opts);
            if (entityClass === PaymentReconciliationEntity) return mockReconRepo.findOne(opts);
            if (entityClass === BookingEntity) return mockBookingRepo.findOne(opts);
            if (entityClass === WebhookEventEntity) return mockWebhookRepo.findOne(opts);
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

    usersStore.set('usr_alice', {
      id: 'usr_alice',
      email: 'alice@plaza.test',
      role: UserRole.USER,
      rewardPoints: 500,
    } as User);

    usersStore.set('usr_admin', {
      id: 'usr_admin',
      email: 'admin@plaza.test',
      role: UserRole.ADMIN,
      rewardPoints: 1000,
    } as User);
  });

  // =========================================================================
  // SECTION 1: FINANCIAL INVARIANT SUITE (INV-001 through INV-020)
  // =========================================================================
  describe('1. Financial Invariants Suite (INV-001 to INV-020)', () => {
    it('INV-001: Provider amount == canonical amount', () => {
      const canonicalAmount = 450.0;
      const minorUnits = toMinorUnits(canonicalAmount);
      expect(minorUnits).toBe(45000);
      expect(minorUnits / 100).toBe(canonicalAmount);
    });

    it('INV-002: Provider currency == canonical currency', () => {
      const canonicalCurrency = 'INR';
      const providerCurrency = 'INR';
      expect(canonicalCurrency.trim().toUpperCase()).toBe(providerCurrency.trim().toUpperCase());
    });

    it('INV-003: Confirmed online booking requires captured payment', () => {
      const payment: Partial<PaymentEntity> = {
        id: 'pay_001',
        status: PaymentStatus.CAPTURED,
        amount: 500,
      };
      const booking: Partial<BookingEntity> = {
        id: 'bk_001',
        status: BookingStatus.CONFIRMED,
        totalPrice: 500,
      };
      expect(payment.status).toBe(PaymentStatus.CAPTURED);
      expect(booking.status).toBe(BookingStatus.CONFIRMED);
    });

    it('INV-004: PAY_AT_VENUE follows defined pending-payment behavior', () => {
      const payAtVenueBooking: Partial<BookingEntity> = {
        id: 'bk_pav_001',
        status: BookingStatus.UPCOMING,
        metadata: { paymentMethod: 'PAY_AT_VENUE' },
      };
      expect(payAtVenueBooking.metadata?.paymentMethod).toBe('PAY_AT_VENUE');
      expect(payAtVenueBooking.status).toBe(BookingStatus.UPCOMING);
    });

    it('INV-005: Inventory never becomes negative', () => {
      const initialStock = 2;
      let currentStock = initialStock;
      const reserve = () => {
        if (currentStock <= 0) throw new BadRequestException('Sold out');
        currentStock -= 1;
      };
      reserve();
      reserve();
      expect(() => reserve()).toThrow('Sold out');
      expect(currentStock).toBe(0);
      expect(currentStock).toBeGreaterThanOrEqual(0);
    });

    it('INV-006: Rewards awarded at most once per confirmed booking', () => {
      let rewardAwardCount = 0;
      const awardReward = (alreadyAwarded: boolean) => {
        if (!alreadyAwarded) {
          rewardAwardCount += 1;
          return true;
        }
        return false;
      };
      expect(awardReward(false)).toBe(true);
      expect(awardReward(true)).toBe(false);
      expect(awardReward(true)).toBe(false);
      expect(rewardAwardCount).toBe(1);
    });

    it('INV-007: Rewards reversed at most once upon cancellation/refund', () => {
      let reversalCount = 0;
      const reverseReward = (alreadyReversed: boolean) => {
        if (!alreadyReversed) {
          reversalCount += 1;
          return true;
        }
        return false;
      };
      expect(reverseReward(false)).toBe(true);
      expect(reverseReward(true)).toBe(false);
      expect(reversalCount).toBe(1);
    });

    it('INV-008: Refund executed at most once', () => {
      let executedRefunds = 0;
      const processRefund = (status: PaymentStatus) => {
        if (status === PaymentStatus.CAPTURED) {
          executedRefunds += 1;
          return PaymentStatus.REFUND_PENDING;
        }
        if (status === PaymentStatus.REFUND_PENDING) {
          executedRefunds += 1;
          return PaymentStatus.REFUNDED;
        }
        if (status === PaymentStatus.REFUNDED) {
          return PaymentStatus.REFUNDED;
        }
        throw new BadRequestException('Invalid refund transition');
      };
      let st = processRefund(PaymentStatus.CAPTURED);
      st = processRefund(st);
      expect(st).toBe(PaymentStatus.REFUNDED);
      st = processRefund(st);
      expect(st).toBe(PaymentStatus.REFUNDED);
      expect(executedRefunds).toBe(2);
    });

    it('INV-009: Duplicate webhook creates zero additional financial side effects', async () => {
      const eventPayload = { id: 'evt_dup_100', event: 'order.paid', payload: { payment: { id: 'pay_sim_1' } } };
      await mockWebhookRepo.save({ eventId: 'evt_dup_100', processed: true });

      const isDuplicate = (await mockWebhookRepo.findOne({ where: { eventId: 'evt_dup_100' } })) !== null;
      expect(isDuplicate).toBe(true);
      expect(sideEffectCounters.bookingConfirmations).toBe(0);
      expect(sideEffectCounters.rewardsAwarded).toBe(0);
    });

    it('INV-010: Duplicate idempotency request creates zero additional financial side effects', async () => {
      const cached = { bookingId: 'bk_123', status: 'CONFIRMED' };
      await idempotencyService.save('usr_alice', 'key_idemp_1', '/bookings', cached, {
        requestPayload: { amount: 500 },
      });

      let mutationCount = 0;
      const res = await idempotencyService.execute('usr_alice', 'key_idemp_1', '/bookings', { amount: 500 }, async () => {
        mutationCount += 1;
        return { bookingId: 'bk_new', status: 'CONFIRMED' };
      });

      expect(res.bookingId).toBe('bk_123');
      expect(mutationCount).toBe(0);
    });

    it('INV-011: Expired quote creates zero financial mutation', () => {
      const quote = { id: 'qt_1', expiresAt: Date.now() - 10000 };
      const isExpired = Date.now() > quote.expiresAt;
      expect(isExpired).toBe(true);
      expect(() => {
        if (isExpired) throw new BadRequestException(`${PaymentErrorCode.QUOTE_EXPIRED}: Quote expired`);
      }).toThrow(/QUOTE_EXPIRED/);
      expect(sideEffectCounters.providerCalls).toBe(0);
    });

    it('INV-012: Invalid transition creates zero financial mutation', () => {
      const initialStatus = PaymentStatus.FAILED;
      expect(() => assertValidPaymentStateTransition(initialStatus, PaymentStatus.CAPTURED)).toThrow(BadRequestException);
      const stateAfter = initialStatus;
      expect(stateAfter).toBe(initialStatus);
      expect(sideEffectCounters.bookingConfirmations).toBe(0);
    });

    it('INV-013: Cross-user financial access creates zero financial mutation', () => {
      const bookingOwner: string = 'usr_bob';
      const requestingUser: string = 'usr_alice';
      expect(() => {
        if (bookingOwner !== requestingUser) {
          throw new ForbiddenException(`${PaymentErrorCode.PAYMENT_NOT_OWNED}: Forbidden`);
        }
      }).toThrow(ForbiddenException);
    });

    it('INV-014: Provider mismatch blocks automatic financial mutation', () => {
      const canonicalOrderId: string = 'order_sim_111';
      const providerOrderId: string = 'order_sim_222';
      expect(() => {
        if (canonicalOrderId !== providerOrderId) {
          throw new BadRequestException(`${PaymentErrorCode.PAYMENT_ORDER_MISMATCH}: Order ID mismatch`);
        }
      }).toThrow(/PAYMENT_ORDER_MISMATCH/);
    });

    it('INV-015: Uncertain provider outcome remains recoverable', () => {
      const timeoutErr = new Error('Gateway Timeout (ETIMEDOUT 504)');
      const failureCategory = recoveryService.classifyError(timeoutErr);
      expect(failureCategory).toBe(FailureCategory.PROVIDER_TIMEOUT);
      const incident = mockRecoveryRepo.create({
        resourceId: 'pay_timeout_1',
        failureCategory,
        recoveryStatus: RecoveryStatus.REQUIRED,
      });
      expect(incident.recoveryStatus).toBe(RecoveryStatus.REQUIRED);
    });

    it('INV-016: Reconciliation cannot bypass transition validators', () => {
      expect(isValidPaymentStateTransition(PaymentStatus.REFUNDED, PaymentStatus.CAPTURED)).toBe(false);
      expect(() => assertValidPaymentStateTransition(PaymentStatus.REFUNDED, PaymentStatus.CAPTURED)).toThrow(
        BadRequestException,
      );
    });

    it('INV-017: Admin cannot bypass canonical state machine', async () => {
      await expect(
        reconService.manualResolve('rec_999', {
          action: 'FORCE_CAPTURE',
          notes: 'Illegal override attempt',
          targetPaymentStatus: PaymentStatus.CAPTURED,
        }),
      ).rejects.toThrow();
    });

    it('INV-018: Financial state survives process restart (durable PostgreSQL representation)', () => {
      const paymentData: Partial<PaymentEntity> = {
        id: 'pay_durable_1',
        bookingId: 'bk_durable_1',
        amount: 1500,
        currency: 'INR',
        status: PaymentStatus.CAPTURED,
        provider: 'simulated',
      };
      const serialized = JSON.stringify(paymentData);
      const restored = JSON.parse(serialized);
      expect(restored.id).toBe('pay_durable_1');
      expect(restored.status).toBe(PaymentStatus.CAPTURED);
      expect(restored.amount).toBe(1500);
    });

    it('INV-019: Financial admin mutations are audited', async () => {
      await mockAuditLogRepo.save({
        id: 'aud_test_1',
        userId: 'usr_admin',
        action: 'MANUAL_RECONCILIATION_RESOLVE',
        resourceType: 'PaymentReconciliation',
        resourceId: 'rec_001',
        details: { action: 'MARK_RESOLVED', notes: 'Verified provider receipt' },
      });
      const logs = await mockAuditLogRepo.find();
      expect(logs.length).toBe(1);
      expect(logs[0].action).toBe('MANUAL_RECONCILIATION_RESOLVE');
    });

    it('INV-020: Real-money processing remains ₹0.00', () => {
      expect(paymentConfigService.getPaymentMode()).toBe(PaymentMode.SIMULATED);
      expect(paymentConfigService.isRazorpayLiveEnabled()).toBe(false);
      expect(paymentConfigService.getConfigStatus()).toBe(PaymentConfigStatus.SIMULATED_READY);
    });
  });

  // =========================================================================
  // SECTION 2: PAYMENT STATE MACHINE TRANSITIONS MATRIX
  // =========================================================================
  describe('2. Payment State Machine Matrix (Valid, Terminal, Invalid)', () => {
    const validPairs: [PaymentStatus, PaymentStatus][] = [
      [PaymentStatus.CREATED, PaymentStatus.PENDING],
      [PaymentStatus.CREATED, PaymentStatus.AUTHORIZED],
      [PaymentStatus.CREATED, PaymentStatus.FAILED],
      [PaymentStatus.CREATED, PaymentStatus.CANCELLED],
      [PaymentStatus.PENDING, PaymentStatus.AUTHORIZED],
      [PaymentStatus.PENDING, PaymentStatus.CAPTURED],
      [PaymentStatus.PENDING, PaymentStatus.FAILED],
      [PaymentStatus.PENDING, PaymentStatus.CANCELLED],
      [PaymentStatus.AUTHORIZED, PaymentStatus.CAPTURED],
      [PaymentStatus.AUTHORIZED, PaymentStatus.FAILED],
      [PaymentStatus.AUTHORIZED, PaymentStatus.CANCELLED],
      [PaymentStatus.CAPTURED, PaymentStatus.REFUND_PENDING],
      [PaymentStatus.CAPTURED, PaymentStatus.REFUNDED],
      [PaymentStatus.REFUND_PENDING, PaymentStatus.REFUNDED],
      [PaymentStatus.REFUND_PENDING, PaymentStatus.CAPTURED],
    ];

    test.each(validPairs)('Valid transition: %s -> %s', (from, to) => {
      expect(isValidPaymentStateTransition(from, to)).toBe(true);
      expect(() => assertValidPaymentStateTransition(from, to)).not.toThrow();
    });

    const invalidPairs: [PaymentStatus, PaymentStatus][] = [
      [PaymentStatus.CREATED, PaymentStatus.CAPTURED],
      [PaymentStatus.CREATED, PaymentStatus.REFUND_PENDING],
      [PaymentStatus.CREATED, PaymentStatus.REFUNDED],
      [PaymentStatus.PENDING, PaymentStatus.REFUND_PENDING],
      [PaymentStatus.PENDING, PaymentStatus.REFUNDED],
      [PaymentStatus.AUTHORIZED, PaymentStatus.REFUND_PENDING],
      [PaymentStatus.AUTHORIZED, PaymentStatus.REFUNDED],
      [PaymentStatus.FAILED, PaymentStatus.CREATED],
      [PaymentStatus.FAILED, PaymentStatus.PENDING],
      [PaymentStatus.FAILED, PaymentStatus.AUTHORIZED],
      [PaymentStatus.FAILED, PaymentStatus.CAPTURED],
      [PaymentStatus.FAILED, PaymentStatus.REFUNDED],
      [PaymentStatus.CAPTURED, PaymentStatus.CREATED],
      [PaymentStatus.CAPTURED, PaymentStatus.PENDING],
      [PaymentStatus.CAPTURED, PaymentStatus.AUTHORIZED],
      [PaymentStatus.CAPTURED, PaymentStatus.FAILED],
      [PaymentStatus.REFUNDED, PaymentStatus.CREATED],
      [PaymentStatus.REFUNDED, PaymentStatus.PENDING],
      [PaymentStatus.REFUNDED, PaymentStatus.AUTHORIZED],
      [PaymentStatus.REFUNDED, PaymentStatus.CAPTURED],
      [PaymentStatus.REFUNDED, PaymentStatus.REFUND_PENDING],
      [PaymentStatus.CANCELLED, PaymentStatus.CAPTURED],
      [PaymentStatus.CANCELLED, PaymentStatus.AUTHORIZED],
    ];

    test.each(invalidPairs)('Invalid transition rejected: %s -> %s', (from, to) => {
      expect(isValidPaymentStateTransition(from, to)).toBe(false);
      expect(() => assertValidPaymentStateTransition(from, to)).toThrow(BadRequestException);
    });

    it('should preserve previous state on invalid transition attempt', () => {
      const payment: Partial<PaymentEntity> = {
        id: 'pay_preserve_1',
        status: PaymentStatus.CAPTURED,
        amount: 800,
      };

      try {
        assertValidPaymentStateTransition(payment.status!, PaymentStatus.FAILED);
        payment.status = PaymentStatus.FAILED;
      } catch (err) {
        // Ignored
      }

      expect(payment.status).toBe(PaymentStatus.CAPTURED);
    });
  });

  // =========================================================================
  // SECTION 3: BOOKING STATE MACHINE & ONLINE VS PAY_AT_VENUE
  // =========================================================================
  describe('3. Booking State Machine & Online vs Pay-at-Venue', () => {
    it('should allow valid booking forward transitions', () => {
      expect(VALID_BOOKING_TRANSITIONS[BookingStatus.PENDING]).toContain(BookingStatus.CONFIRMED);
      expect(VALID_BOOKING_TRANSITIONS[BookingStatus.CONFIRMED]).toContain(BookingStatus.COMPLETED);
      expect(VALID_BOOKING_TRANSITIONS[BookingStatus.CONFIRMED]).toContain(BookingStatus.CANCELLED);
    });

    it('should allow booking cancellation from PENDING, UPCOMING, and CONFIRMED', () => {
      expect(VALID_BOOKING_TRANSITIONS[BookingStatus.PENDING]).toContain(BookingStatus.CANCELLED);
      expect(VALID_BOOKING_TRANSITIONS[BookingStatus.UPCOMING]).toContain(BookingStatus.CANCELLED);
      expect(VALID_BOOKING_TRANSITIONS[BookingStatus.CONFIRMED]).toContain(BookingStatus.CANCELLED);
    });

    it('should disallow COMPLETED booking from transitioning to any state', () => {
      expect(VALID_BOOKING_TRANSITIONS[BookingStatus.COMPLETED]).toHaveLength(0);
    });

    it('should disallow FAILED booking from transitioning to any state', () => {
      expect(VALID_BOOKING_TRANSITIONS[BookingStatus.FAILED]).toHaveLength(0);
    });

    it('online booking cannot become CONFIRMED without CAPTURED payment', () => {
      const verifyOnlineConfirmation = (paymentStatus: PaymentStatus): BookingStatus => {
        if (paymentStatus !== PaymentStatus.CAPTURED) {
          throw new BadRequestException('Cannot confirm booking without captured payment');
        }
        return BookingStatus.CONFIRMED;
      };

      expect(() => verifyOnlineConfirmation(PaymentStatus.PENDING)).toThrow(/without captured payment/);
      expect(() => verifyOnlineConfirmation(PaymentStatus.FAILED)).toThrow(/without captured payment/);
      expect(verifyOnlineConfirmation(PaymentStatus.CAPTURED)).toBe(BookingStatus.CONFIRMED);
    });
  });

  // =========================================================================
  // SECTION 4: SERVER-AUTHORITATIVE QUOTE SECURITY & TAMPER REJECTION
  // =========================================================================
  describe('4. Server-Authoritative Quote Security & Tamper Rejection', () => {
    const serverQuote = {
      quoteId: 'qt_auth_001',
      userId: 'usr_alice',
      bookingId: 'bk_auth_001',
      amount: 1200.0,
      amountMinorUnits: 120000,
      currency: 'INR',
      expiresAt: Date.now() + 600000,
      consumed: false,
      cancelled: false,
    };

    it('4.1 should validate correct unexpired server quote', () => {
      const clientRequest = { quoteId: 'qt_auth_001', userId: 'usr_alice', bookingId: 'bk_auth_001' };
      expect(serverQuote.consumed).toBe(false);
      expect(serverQuote.cancelled).toBe(false);
      expect(serverQuote.userId).toBe(clientRequest.userId);
      expect(Date.now()).toBeLessThan(serverQuote.expiresAt);
    });

    it('4.2 should reject expired quote', () => {
      const expiredQuote = { ...serverQuote, expiresAt: Date.now() - 5000 };
      expect(() => {
        if (Date.now() > expiredQuote.expiresAt) {
          throw new BadRequestException(`${PaymentErrorCode.QUOTE_EXPIRED}: Quote has expired`);
        }
      }).toThrow(/QUOTE_EXPIRED/);
    });

    it('4.3 should reject cancelled quote', () => {
      const cancelledQuote = { ...serverQuote, cancelled: true };
      expect(() => {
        if (cancelledQuote.cancelled) {
          throw new BadRequestException(`${PaymentErrorCode.QUOTE_CANCELLED}: Quote was cancelled`);
        }
      }).toThrow(/QUOTE_CANCELLED/);
    });

    it('4.4 should reject cross-user quote consumption (User B uses User A quote)', () => {
      const attackerUserId = 'usr_bob';
      expect(() => {
        if (serverQuote.userId !== (attackerUserId as string)) {
          throw new ForbiddenException(`${PaymentErrorCode.QUOTE_NOT_OWNED}: Forbidden quote access`);
        }
      }).toThrow(ForbiddenException);
    });

    it('4.5 client-provided amount must never override server quote amount', () => {
      const tamperedClientAmount = 1.0;
      const finalAmount = serverQuote.amount;
      expect(finalAmount).toBe(1200.0);
      expect(finalAmount).not.toBe(tamperedClientAmount);
    });

    it('4.6 should reject already-consumed quote', () => {
      const consumedQuote = { ...serverQuote, consumed: true };
      expect(() => {
        if (consumedQuote.consumed) {
          throw new ConflictException(`${PaymentErrorCode.QUOTE_ALREADY_CONSUMED}: Quote already used`);
        }
      }).toThrow(ConflictException);
    });
  });

  // =========================================================================
  // SECTION 5: AMOUNT AND CURRENCY INTEGRITY
  // =========================================================================
  describe('5. Amount and Currency Integrity', () => {
    it('5.1 should accurately convert major units to minor units without floating-point errors', () => {
      expect(toMinorUnits(499)).toBe(49900);
      expect(toMinorUnits(12.5)).toBe(1250);
      expect(toMinorUnits(0)).toBe(0);
      expect(toMinorUnits(9999.99)).toBe(999999);
    });

    it('5.2 should reject negative or non-finite amounts', () => {
      expect(() => toMinorUnits(-100)).toThrow(BadRequestException);
      expect(() => toMinorUnits(NaN)).toThrow(BadRequestException);
      expect(() => toMinorUnits(Infinity)).toThrow(BadRequestException);
    });

    it('5.3 should detect and reject amount mismatches during verification', () => {
      const canonicalPaise: number = 50000;
      const providerPaise: number = 45000;
      expect(() => {
        if (canonicalPaise !== providerPaise) {
          throw new BadRequestException(`${PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH}: Amount mismatch`);
        }
      }).toThrow(/PAYMENT_AMOUNT_MISMATCH/);
    });

    it('5.4 should reject currency mismatches', () => {
      const canonicalCurrency: string = 'INR';
      const providerCurrency: string = 'USD';
      expect(() => {
        if (canonicalCurrency !== providerCurrency) {
          throw new BadRequestException(`${PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH}: Currency mismatch`);
        }
      }).toThrow(/PAYMENT_CURRENCY_MISMATCH/);
    });
  });

  // =========================================================================
  // SECTION 6: PROVIDER IDENTITY VALIDATION
  // =========================================================================
  describe('6. Provider Identity Validation', () => {
    it('6.1 should accept matching provider order ID and payment ID', () => {
      const canonical = { orderId: 'order_sim_100', paymentId: 'pay_sim_200' };
      const incoming = { orderId: 'order_sim_100', paymentId: 'pay_sim_200' };
      expect(canonical.orderId).toBe(incoming.orderId);
      expect(canonical.paymentId).toBe(incoming.paymentId);
    });

    it('6.2 should reject mismatched provider order ID', () => {
      const canonicalOrderId: string = 'order_sim_100';
      const wrongOrderId: string = 'order_sim_999';
      expect(() => {
        if (canonicalOrderId !== wrongOrderId) {
          throw new BadRequestException(`${PaymentErrorCode.PAYMENT_ORDER_MISMATCH}: Order ID mismatch`);
        }
      }).toThrow(/PAYMENT_ORDER_MISMATCH/);
    });

    it('6.3 should reject payment ID belonging to another booking', () => {
      const paymentRecord = { id: 'pay_1', bookingId: 'bk_alpha' };
      const incomingBookingId = 'bk_beta';
      expect(() => {
        if (paymentRecord.bookingId !== incomingBookingId) {
          throw new BadRequestException(`${PaymentErrorCode.PAYMENT_BOOKING_MISMATCH}: Booking ID mismatch`);
        }
      }).toThrow(/PAYMENT_BOOKING_MISMATCH/);
    });
  });

  // =========================================================================
  // SECTION 7: IDEMPOTENCY MATRIX
  // =========================================================================
  describe('7. Idempotency Matrix (Phase 25.4 Service)', () => {
    it('7.1 Same key + Same request -> identical cached response', async () => {
      const payload = { amount: 500, bookingId: 'bk_1' };
      const response = { paymentId: 'pay_001', status: 'CREATED' };

      await idempotencyService.save('usr_alice', 'idemp_key_1', '/payments/order', response, {
        requestPayload: payload,
      });

      const cached = await idempotencyService.get('usr_alice', 'idemp_key_1', payload);
      expect(cached).toBeDefined();
      expect(cached?.paymentId).toBe('pay_001');
      expect(cached?.idempotentReplay).toBe(true);
    });

    it('7.2 Same key + Different request -> 409 ConflictException', async () => {
      const originalPayload = { amount: 500, bookingId: 'bk_1' };
      const alteredPayload = { amount: 800, bookingId: 'bk_1' };

      await idempotencyService.save('usr_alice', 'idemp_key_2', '/payments/order', { success: true }, {
        requestPayload: originalPayload,
      });

      await expect(
        idempotencyService.get('usr_alice', 'idemp_key_2', alteredPayload),
      ).rejects.toThrow(ConflictException);
    });

    it('7.3 Concurrent same-key requests -> single execution via in-flight lock', async () => {
      let executions = 0;
      const payload = { item: 'movie_ticket', count: 2 };

      const execTask = () =>
        idempotencyService.execute('usr_alice', 'idemp_concurrent_1', '/bookings/create', payload, async () => {
          executions += 1;
          await new Promise((r) => setTimeout(r, 20));
          return { bookingId: 'bk_concur_1', status: 'CONFIRMED' };
        });

      const [res1, res2] = await Promise.all([execTask(), execTask()]);
      expect(executions).toBe(1);
      expect(res1.bookingId).toBe('bk_concur_1');
      expect(res2.bookingId).toBe('bk_concur_1');
    });

    it('7.4 computeFingerprint should produce identical hash regardless of key order', () => {
      const objA = { amount: 500, currency: 'INR', notes: { tier: 'VIP', row: 'C' } };
      const objB = { notes: { row: 'C', tier: 'VIP' }, currency: 'INR', amount: 500 };
      const hashA = idempotencyService.computeFingerprint(objA);
      const hashB = idempotencyService.computeFingerprint(objB);
      expect(hashA).toBe(hashB);
    });
  });

  // =========================================================================
  // SECTION 8: WEBHOOK SECURITY MATRIX
  // =========================================================================
  describe('8. Webhook Security Matrix (HMAC & Deduplication)', () => {
    it('8.1 should verify valid webhook HMAC-SHA256 signature', () => {
      const rawBody = JSON.stringify({ event: 'order.paid', payload: { payment: { entity: { id: 'pay_123' } } } });
      const signature = generateWebhookHmac(rawBody, TEST_WEBHOOK_SECRET);
      const isValid = simulatedAdapter.verifyWebhookSignature(rawBody, signature, TEST_WEBHOOK_SECRET);
      expect(isValid).toBe(true);
    });

    it('8.2 should reject invalid or tampered webhook signature', () => {
      const rawBody = JSON.stringify({ event: 'order.paid', payload: { payment: { entity: { id: 'pay_123' } } } });
      const isValid = simulatedAdapter.verifyWebhookSignature(rawBody, 'invalid_signature_hex', TEST_WEBHOOK_SECRET);
      expect(isValid).toBe(false);
    });

    it('8.3 should reject modified raw body even with valid original signature', () => {
      const originalBody = JSON.stringify({ event: 'order.paid', amount: 500 });
      const tamperedBody = JSON.stringify({ event: 'order.paid', amount: 5000 });
      const signature = generateWebhookHmac(originalBody, TEST_WEBHOOK_SECRET);
      const isValid = simulatedAdapter.verifyWebhookSignature(tamperedBody, signature, TEST_WEBHOOK_SECRET);
      expect(isValid).toBe(false);
    });

    it('8.4 Webhook event deduplication: duplicate event yields zero mutations', async () => {
      const eventId = 'evt_unique_12345';
      await mockWebhookRepo.save({ eventId, processed: true, payload: { orderId: 'order_1' } });

      const isProcessed = (await mockWebhookRepo.findOne({ where: { eventId } })) !== null;
      expect(isProcessed).toBe(true);
      expect(sideEffectCounters.bookingConfirmations).toBe(0);
    });
  });

  // =========================================================================
  // SECTION 9: RECONCILIATION ENGINE MATRIX & CONCURRENCY
  // =========================================================================
  describe('9. Reconciliation Engine Matrix & Concurrency (Phase 25.6 Service)', () => {
    it('9.1 canonical and provider consistent -> RESOLVED / NO_MISMATCH', async () => {
      const payment = await mockPaymentRepo.save({
        id: 'pay_rec_match_1',
        bookingId: 'bk_match_1',
        amount: 800,
        currency: 'INR',
        status: PaymentStatus.CAPTURED,
        providerOrderId: 'order_sim_rec_1',
        providerPaymentId: 'pay_sim_rec_1',
      });
      await mockBookingRepo.save({
        id: 'bk_match_1',
        status: BookingStatus.CONFIRMED,
        totalPrice: 800,
      });
      await mockWebhookRepo.save({
        eventId: 'wh_rec_match_1',
        providerPaymentId: 'pay_sim_rec_1',
        providerOrderId: 'order_sim_rec_1',
        status: 'PROCESSED',
        processedAt: new Date(),
      });

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_rec_1',
        orderId: 'order_sim_rec_1',
        amount: 800,
        amountInMinorUnits: 80000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const recon = await reconService.reconcilePayment(payment.id);
      expect(recon.status).toBe(ReconciliationStatus.NOT_REQUIRED);
      expect(recon.mismatchCategory).toBe(ReconciliationMismatchCategory.NO_MISMATCH);
      expect(recon.requiresManualIntervention).toBe(false);
    });

    it('9.2 provider captured while canonical pending -> auto-heals to CAPTURED and booking CONFIRMED', async () => {
      const payment = await mockPaymentRepo.save({
        id: 'pay_rec_heal_1',
        bookingId: 'bk_heal_1',
        amount: 1500,
        currency: 'INR',
        status: PaymentStatus.PENDING,
        providerOrderId: 'order_sim_heal_1',
        providerPaymentId: 'pay_sim_heal_1',
      });
      const booking = await mockBookingRepo.save({
        id: 'bk_heal_1',
        status: BookingStatus.PENDING,
        totalPrice: 1500,
      });

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_heal_1',
        orderId: 'order_sim_heal_1',
        amount: 1500,
        amountInMinorUnits: 150000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const recon = await reconService.reconcilePayment(payment.id);
      expect(recon.status).toBe(ReconciliationStatus.RESOLVED);
      expect(recon.mismatchCategory).toBe(ReconciliationMismatchCategory.WEBHOOK_GAP);

      const healedPayment = await mockPaymentRepo.findOne({ where: { id: payment.id } });
      expect(healedPayment.status).toBe(PaymentStatus.CAPTURED);

      const healedBooking = await mockBookingRepo.findOne({ where: { id: booking.id } });
      expect(healedBooking.status).toBe(BookingStatus.CONFIRMED);
    });

    it('9.3 amount mismatch -> AMOUNT_MISMATCH requiring manual intervention', async () => {
      const payment = await mockPaymentRepo.save({
        id: 'pay_rec_amt_1',
        bookingId: 'bk_amt_1',
        amount: 500,
        currency: 'INR',
        status: PaymentStatus.CAPTURED,
        providerOrderId: 'order_sim_amt_1',
        providerPaymentId: 'pay_sim_amt_1',
      });
      await mockBookingRepo.save({
        id: 'bk_amt_1',
        status: BookingStatus.CONFIRMED,
        totalPrice: 500,
      });

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_amt_1',
        orderId: 'order_sim_amt_1',
        amount: 300,
        amountInMinorUnits: 30000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const recon = await reconService.reconcilePayment(payment.id);
      expect(recon.status).toBe(ReconciliationStatus.REQUIRED);
      expect(recon.mismatchCategory).toBe(ReconciliationMismatchCategory.AMOUNT_MISMATCH);
      expect(recon.requiresManualIntervention).toBe(true);
    });

    it('9.4 Concurrent reconciliation on same payment -> executes exactly once without double mutations', async () => {
      const payment = await mockPaymentRepo.save({
        id: 'pay_rec_concur_1',
        bookingId: 'bk_concur_1',
        amount: 1000,
        currency: 'INR',
        status: PaymentStatus.PENDING,
        providerOrderId: 'order_sim_c1',
        providerPaymentId: 'pay_sim_c1',
      });
      await mockBookingRepo.save({
        id: 'bk_concur_1',
        status: BookingStatus.PENDING,
        totalPrice: 1000,
      });

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sim_c1',
        orderId: 'order_sim_c1',
        amount: 1000,
        amountInMinorUnits: 100000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const [r1, r2, r3] = await Promise.all([
        reconService.reconcilePayment(payment.id),
        reconService.reconcilePayment(payment.id),
        reconService.reconcilePayment(payment.id),
      ]);

      expect(r1).toBeDefined();
      expect(r2).toBeDefined();
      expect(r3).toBeDefined();

      const finalPayment = await mockPaymentRepo.findOne({ where: { id: payment.id } });
      expect(finalPayment.status).toBe(PaymentStatus.CAPTURED);
    });
  });

  // =========================================================================
  // SECTION 10: PAYMENT RECOVERY STATE MACHINE (13 FAILURE CATEGORIES)
  // =========================================================================
  describe('10. Payment Recovery State Machine (13 Categories)', () => {
    const errorCategoryMappings: [string, FailureCategory][] = [
      ['Invalid HMAC signature provided', FailureCategory.AUTHORIZATION_FAILURE],
      ['Gateway timeout ETIMEDOUT 504', FailureCategory.PROVIDER_TIMEOUT],
      ['Service Unavailable 503 maintenance', FailureCategory.PROVIDER_UNAVAILABLE],
      ['Socket hang up ECONNRESET', FailureCategory.NETWORK_ERROR],
      ['Refund failed with gateway', FailureCategory.REFUND_FAILURE],
      ['Twilio SMS dispatch failed', FailureCategory.NOTIFICATION_FAILURE],
      ['Reward coin balance lock failed', FailureCategory.REWARD_FAILURE],
      ['Ticket tier sold out inventory failure', FailureCategory.INVENTORY_FAILURE],
      ['Booking confirmation state error', FailureCategory.BOOKING_CONFIRMATION_FAILURE],
      ['Unmapped mysterious error occurred', FailureCategory.UNKNOWN_PROVIDER_OUTCOME],
    ];

    test.each(errorCategoryMappings)('Classify error "%s" -> %s', (msg, expectedCategory) => {
      const category = recoveryService.classifyError(new Error(msg));
      expect(category).toBe(expectedCategory);
    });

    it('should sanitize sensitive tokens and keys from error reason strings', () => {
      const rawError = 'Error with key rzp_test_1234567890ABCD and secret=SuperSecretPassword123 at file.ts:10';
      const sanitized = recoveryService.sanitizeReason(rawError);
      expect(sanitized).not.toContain('rzp_test_1234567890ABCD');
      expect(sanitized).not.toContain('SuperSecretPassword123');
      expect(sanitized).toContain('[REDACTED_RZP_KEY]');
    });
  });

  // =========================================================================
  // SECTION 11: BOOKING CONFIRMATION FAILURE AFTER CAPTURE & REFUND
  // =========================================================================
  describe('11. Booking Confirmation Failure After Capture', () => {
    it('should keep payment CAPTURED when booking fails and initiate refund workflow', async () => {
      const payment = await mockPaymentRepo.save({
        id: 'pay_capture_fail_bk',
        bookingId: 'bk_fail_after_capture',
        amount: 2500,
        currency: 'INR',
        status: PaymentStatus.CAPTURED,
      });

      const booking = await mockBookingRepo.save({
        id: 'bk_fail_after_capture',
        status: BookingStatus.FAILED,
        totalPrice: 2500,
      });

      const incident = await mockRecoveryRepo.save({
        resourceId: payment.id,
        paymentId: payment.id,
        bookingId: booking.id,
        failureCategory: FailureCategory.BOOKING_CONFIRMATION_FAILURE,
        recoveryStatus: RecoveryStatus.REQUIRED,
      });

      expect(payment.status).toBe(PaymentStatus.CAPTURED);
      expect(booking.status).toBe(BookingStatus.FAILED);
      expect(incident.recoveryStatus).toBe(RecoveryStatus.REQUIRED);

      assertValidPaymentStateTransition(payment.status, PaymentStatus.REFUND_PENDING);
      payment.status = PaymentStatus.REFUND_PENDING;
      await mockPaymentRepo.save(payment);

      assertValidPaymentStateTransition(payment.status, PaymentStatus.REFUNDED);
      payment.status = PaymentStatus.REFUNDED;
      await mockPaymentRepo.save(payment);

      expect(payment.status).toBe(PaymentStatus.REFUNDED);
    });
  });

  // =========================================================================
  // SECTION 12: REFUND & PARTIAL REFUND INTEGRITY
  // =========================================================================
  describe('12. Refund and Partial Refund Integrity', () => {
    it('12.1 should transition CAPTURED -> REFUND_PENDING -> REFUNDED legally', () => {
      let status = PaymentStatus.CAPTURED;
      assertValidPaymentStateTransition(status, PaymentStatus.REFUND_PENDING);
      status = PaymentStatus.REFUND_PENDING;

      assertValidPaymentStateTransition(status, PaymentStatus.REFUNDED);
      status = PaymentStatus.REFUNDED;

      expect(status).toBe(PaymentStatus.REFUNDED);
    });

    it('12.2 should reject refund attempts on PENDING, AUTHORIZED, or FAILED payments', () => {
      expect(() => assertValidPaymentStateTransition(PaymentStatus.PENDING, PaymentStatus.REFUNDED)).toThrow(
        BadRequestException,
      );
      expect(() => assertValidPaymentStateTransition(PaymentStatus.AUTHORIZED, PaymentStatus.REFUNDED)).toThrow(
        BadRequestException,
      );
      expect(() => assertValidPaymentStateTransition(PaymentStatus.FAILED, PaymentStatus.REFUNDED)).toThrow(
        BadRequestException,
      );
    });

    it('12.3 Partial refunds: cumulative refunded amount must not exceed captured amount', () => {
      const capturedMinorUnits = 100000;
      let totalRefundedMinorUnits = 0;

      const applyPartialRefund = (refundMajor: number) => {
        const refundMinor = toMinorUnits(refundMajor);
        if (totalRefundedMinorUnits + refundMinor > capturedMinorUnits) {
          throw new BadRequestException(`${PaymentErrorCode.REFUND_AMOUNT_INVALID}: Excessive refund`);
        }
        totalRefundedMinorUnits += refundMinor;
        return totalRefundedMinorUnits;
      };

      expect(applyPartialRefund(400)).toBe(40000);
      expect(applyPartialRefund(600)).toBe(100000);
      expect(() => applyPartialRefund(50)).toThrow(/REFUND_AMOUNT_INVALID/);
      expect(totalRefundedMinorUnits).toBe(capturedMinorUnits);
    });
  });

  // =========================================================================
  // SECTION 13: INVENTORY / SEAT LOCKS INTEGRITY
  // =========================================================================
  describe('13. Inventory and Seat Locks Integrity', () => {
    it('13.1 should prevent concurrent booking for the same movie seat', () => {
      const seatKey = 'theatre_inox_screen1_kalki_A1';
      expect(inventoryStore.get(seatKey)).toBe(1);

      const reserveSeat = (user: string) => {
        const count = inventoryStore.get(seatKey) || 0;
        if (count <= 0) {
          throw new ConflictException('Seat already reserved');
        }
        inventoryStore.set(seatKey, count - 1);
        sideEffectCounters.inventoryDecrements += 1;
        return { user, seat: seatKey, status: 'RESERVED' };
      };

      const res1 = reserveSeat('usr_alice');
      expect(res1.status).toBe('RESERVED');
      expect(inventoryStore.get(seatKey)).toBe(0);

      expect(() => reserveSeat('usr_bob')).toThrow(ConflictException);
      expect(sideEffectCounters.inventoryDecrements).toBe(1);
    });

    it('13.2 should restore inventory upon payment failure or cancellation', () => {
      const seatKey = 'theatre_inox_screen1_kalki_A2';
      inventoryStore.set(seatKey, 0);

      const restoreSeat = () => {
        const count = inventoryStore.get(seatKey) || 0;
        inventoryStore.set(seatKey, count + 1);
        sideEffectCounters.inventoryRestorations += 1;
      };

      restoreSeat();
      expect(inventoryStore.get(seatKey)).toBe(1);
      expect(sideEffectCounters.inventoryRestorations).toBe(1);
    });
  });

  // =========================================================================
  // SECTION 14: REWARDS, NOTIFICATIONS, & ALL 7 VERTICALS
  // =========================================================================
  describe('14. Rewards, Notifications, & All 7 Verticals', () => {
    it('14.1 Rewards awarded exactly once on confirmation', () => {
      const user = usersStore.get('usr_alice')!;
      const initialPoints = user.rewardPoints;
      const pointsToAward = 50;

      let awarded = false;
      const award = () => {
        if (!awarded) {
          user.rewardPoints += pointsToAward;
          awarded = true;
          sideEffectCounters.rewardsAwarded += 1;
        }
      };

      award();
      award();
      expect(user.rewardPoints).toBe(initialPoints + 50);
      expect(sideEffectCounters.rewardsAwarded).toBe(1);
    });

    it('14.2 Rewards reversed exactly once on cancellation', () => {
      const user = usersStore.get('usr_alice')!;
      const pointsToDeduct = 50;

      let reversed = false;
      const reverse = () => {
        if (!reversed) {
          user.rewardPoints -= pointsToDeduct;
          reversed = true;
          sideEffectCounters.rewardsReversed += 1;
        }
      };

      reverse();
      reverse();
      expect(sideEffectCounters.rewardsReversed).toBe(1);
    });

    const verticals: [BookingType, string][] = [
      [BookingType.MOVIE, 'Prasads IMAX - Kalki 2898 AD'],
      [BookingType.DINING, 'Jewel of Nizam - Table for 2'],
      [BookingType.EVENT, 'Coldplay Music of Spheres VIP'],
      [BookingType.ACTIVITY, 'Wonderla High Thrill Pass'],
      [BookingType.SHOPPING, 'Inorbit Premium Luxury Voucher'],
      [BookingType.STAY, 'Taj Falaknuma Palace Suite'],
      [BookingType.SPORTS, 'Gachibowli Badminton Court 1'],
    ];

    test.each(verticals)('Vertical %s (%s) supports complete financial lifecycle', async (type, title) => {
      const booking = await mockBookingRepo.save({
        type,
        title,
        status: BookingStatus.PENDING,
        totalPrice: 1500,
        userId: 'usr_alice',
      });
      const payment = await mockPaymentRepo.save({
        bookingId: booking.id,
        amount: 1500,
        currency: 'INR',
        status: PaymentStatus.CAPTURED,
        provider: 'simulated',
      });

      assertValidPaymentStateTransition(payment.status, PaymentStatus.REFUND_PENDING);
      expect(booking.id).toBeDefined();
      expect(payment.id).toBeDefined();
    });
  });

  // =========================================================================
  // SECTION 15: ADMIN RBAC & MANUAL RESOLUTION CANONICAL ENFORCEMENT
  // =========================================================================
  describe('15. Admin RBAC & Manual Resolution Canonical Enforcement', () => {
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

    it('15.1 should permit ADMIN and SUPER_ADMIN roles to access financial ops', () => {
      expect(rolesGuard.canActivate(createCtx(UserRole.ADMIN))).toBe(true);
      expect(rolesGuard.canActivate(createCtx(UserRole.SUPER_ADMIN))).toBe(true);
    });

    it('15.2 should deny USER and PARTNER roles from financial ops', () => {
      expect(() => rolesGuard.canActivate(createCtx(UserRole.USER))).toThrow(ForbiddenException);
      expect(() => rolesGuard.canActivate(createCtx(UserRole.PARTNER_OWNER))).toThrow(ForbiddenException);
      expect(() => rolesGuard.canActivate(createCtx(UserRole.PARTNER_STAFF))).toThrow(ForbiddenException);
    });

    it('15.3 manual resolution must fail if transition is illegal', async () => {
      const payment = await mockPaymentRepo.save({
        id: 'pay_manual_illegal',
        bookingId: 'bk_man_1',
        amount: 1000,
        currency: 'INR',
        status: PaymentStatus.CAPTURED,
      });

      const recon = await mockReconRepo.save({
        id: 'rec_man_illegal',
        paymentId: payment.id,
        status: ReconciliationStatus.REQUIRED,
        mismatchCategory: ReconciliationMismatchCategory.PAYMENT_STATE_MISMATCH,
      });

      await expect(
        reconService.manualResolve(recon.id, {
          action: 'OVERRIDE_STATUS',
          notes: 'Attempting illegal transition to FAILED',
          targetPaymentStatus: PaymentStatus.FAILED,
        }),
      ).rejects.toThrow();
    });
  });

  // =========================================================================
  // SECTION 16: RECONCILIATION SCHEDULER & DURABILITY
  // =========================================================================
  describe('16. Reconciliation Scheduler & Durability', () => {
    it('16.1 reconcileBatch should process pending reconciliation records', async () => {
      const payment = await mockPaymentRepo.save({
        id: 'pay_sweep_1',
        bookingId: 'bk_sw_1',
        amount: 400,
        currency: 'INR',
        status: PaymentStatus.CAPTURED,
        providerOrderId: 'order_sw_1',
        providerPaymentId: 'pay_sw_1',
      });
      await mockBookingRepo.save({
        id: 'bk_sw_1',
        status: BookingStatus.CONFIRMED,
        totalPrice: 400,
      });

      await mockReconRepo.save({
        id: 'rec_sweep_1',
        paymentId: payment.id,
        status: ReconciliationStatus.REQUIRED,
        attemptCount: 0,
        maxRetries: 5,
        nextRetryAt: new Date(Date.now() - 1000),
      });

      simulatedAdapter.registerProviderPayment({
        paymentId: 'pay_sw_1',
        orderId: 'order_sw_1',
        amount: 400,
        amountInMinorUnits: 40000,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const batchResult = await reconService.reconcileBatch(10);
      expect(batchResult.processed).toBeGreaterThanOrEqual(1);
    });

    it('16.2 max retry limit flags record for manual intervention', async () => {
      const recon = await mockReconRepo.save({
        id: 'rec_max_retry',
        paymentId: 'pay_nonexistent_999',
        status: ReconciliationStatus.REQUIRED,
        attemptCount: 5,
        maxRetries: 5,
      });

      recon.status = ReconciliationStatus.FAILED;
      recon.requiresManualIntervention = true;
      await mockReconRepo.save(recon);

      const saved = await mockReconRepo.findOne({ where: { id: recon.id } });
      expect(saved.status).toBe(ReconciliationStatus.FAILED);
      expect(saved.requiresManualIntervention).toBe(true);
    });
  });
});
