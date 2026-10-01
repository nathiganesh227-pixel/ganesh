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
  toMinorUnits,
} from './database/entities/payment.entity';
import {
  PaymentRecoveryEntity,
  FailureCategory,
  RecoveryStatus,
} from './database/entities/payment-recovery.entity';
import { IdempotencyRecordEntity } from './database/entities/idempotency-record.entity';
import { BookingEntity, BookingStatus, BookingType } from './database/entities/booking.entity';
import { User, UserRole } from './database/entities/user.entity';
import { EventEntity } from './database/entities/event.entity';
import { ActivityEntity } from './database/entities/activity.entity';
import { ProductEntity } from './database/entities/product.entity';
import { RestaurantEntity } from './database/entities/restaurant.entity';
import { AuditLogEntity } from './database/entities/audit-log.entity';
import { PaymentRecoveryService } from './modules/payments/payment-recovery.service';
import { IdempotencyService } from './modules/bookings/idempotency.service';
import { PaymentService } from './modules/payments/payment.service';
import { PaymentConfigService, PaymentMode } from './modules/payments/payment-config.service';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { PaymentsController } from './modules/payments/payments.controller';
import { AdminService } from './modules/admin/admin.service';
import { AdminController } from './modules/admin/admin.controller';
import { TwilioSmsAdapter } from './modules/notifications/providers/twilio-sms.adapter';
import { CreatePaymentRecoveryTable1791000000000 } from './database/migrations/1791000000000-CreatePaymentRecoveryTable';

const TEST_KEY_ID = 'rzp_test_1234567890ABCD';
const TEST_KEY_SECRET = 'simulated_key_secret';

function signOrderPayment(orderId: string, paymentId: string, secret = TEST_KEY_SECRET): string {
  return crypto
    .createHmac('sha256', secret)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');
}

describe('PLAZA Phase 25.5 — Payment Failure & Recovery State Machine', () => {
  let recoveryStore: Map<string, PaymentRecoveryEntity>;
  let idempotencyStore: Map<string, IdempotencyRecordEntity>;
  let paymentsStore: Map<string, PaymentEntity>;
  let bookingsStore: Map<string, BookingEntity>;
  let usersStore: Map<string, User>;
  let eventsStore: Map<string, EventEntity>;
  let activitiesStore: Map<string, ActivityEntity>;
  let productsStore: Map<string, ProductEntity>;
  let restaurantsStore: Map<string, RestaurantEntity>;
  let auditLogsStore: Map<string, AuditLogEntity>;
  let smsLog: Array<{ to: string; message: string }>;

  let mockRecoveryRepo: any;
  let mockIdempRepo: any;
  let mockPaymentRepo: any;
  let mockBookingRepo: any;
  let mockUserRepo: any;
  let mockEventRepo: any;
  let mockActivityRepo: any;
  let mockProductRepo: any;
  let mockRestaurantRepo: any;
  let mockAuditLogRepo: any;
  let mockDataSource: any;

  let recoveryService: PaymentRecoveryService;
  let idempotencyService: IdempotencyService;
  let paymentConfigService: PaymentConfigService;
  let simulatedAdapter: SimulatedPaymentAdapter;
  let razorpayAdapter: RazorpayAdapter;
  let paymentService: PaymentService;
  let smsAdapter: TwilioSmsAdapter;
  let paymentsController: PaymentsController;
  let adminService: AdminService;
  let adminController: AdminController;

  beforeEach(() => {
    recoveryStore = new Map();
    idempotencyStore = new Map();
    paymentsStore = new Map();
    bookingsStore = new Map();
    usersStore = new Map();
    eventsStore = new Map();
    activitiesStore = new Map();
    productsStore = new Map();
    restaurantsStore = new Map();
    auditLogsStore = new Map();
    smsLog = [];

    // Seed test users
    usersStore.set('usr_customer1', {
      id: 'usr_customer1',
      email: 'customer1@plaza.test',
      role: UserRole.USER,
      rewardPoints: 100,
    } as any);

    usersStore.set('usr_admin1', {
      id: 'usr_admin1',
      email: 'admin@plaza.test',
      role: UserRole.ADMIN,
      rewardPoints: 0,
    } as any);

    // Mock Recovery Repo
    mockRecoveryRepo = {
      create: jest.fn((data: any) => ({ ...data })),
      save: jest.fn(async (entity: any) => {
        const id = entity.id || `recov_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
        const record = {
          ...entity,
          id,
          createdAt: entity.createdAt || new Date(),
          updatedAt: new Date(),
        };
        recoveryStore.set(id, record);
        return record;
      }),
      findOne: jest.fn(async (options: any) => {
        if (options?.where?.id) return recoveryStore.get(options.where.id) || null;
        if (options?.where?.paymentId) {
          for (const r of recoveryStore.values()) {
            if (r.paymentId === options.where.paymentId) return r;
          }
        }
        return null;
      }),
      find: jest.fn(async (options?: any) => {
        let results = Array.from(recoveryStore.values());
        if (options?.where?.recoveryStatus) {
          results = results.filter((r) => r.recoveryStatus === options.where.recoveryStatus);
        }
        if (options?.where?.failureCategory) {
          results = results.filter((r) => r.failureCategory === options.where.failureCategory);
        }
        return results;
      }),
      findAndCount: jest.fn(async (options?: any) => {
        const results = Array.from(recoveryStore.values());
        return [results, results.length];
      }),
    };

    // Mock Idempotency Repo
    mockIdempRepo = {
      create: jest.fn((data: any) => ({ ...data })),
      save: jest.fn(async (entity: any) => {
        const id = entity.id || `idemp_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
        const record = {
          ...entity,
          id,
          createdAt: entity.createdAt || new Date(),
          updatedAt: new Date(),
        };
        const key = record.key || record.idempotencyKey;
        idempotencyStore.set(key, record);
        if (record.idempotencyKey) {
          idempotencyStore.set(record.idempotencyKey, record);
        }
        return record;
      }),
      findOne: jest.fn(async (options: any) => {
        if (options?.where?.key) {
          return idempotencyStore.get(options.where.key) || null;
        }
        if (options?.where?.idempotencyKey) {
          return idempotencyStore.get(options.where.idempotencyKey) || null;
        }
        return null;
      }),
    };

    // Mock Payment Repo
    mockPaymentRepo = {
      create: jest.fn((data: any) => ({ ...data })),
      save: jest.fn(async (entity: any) => {
        const id = entity.id || `pay_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
        const record = {
          ...entity,
          id,
          createdAt: entity.createdAt || new Date(),
          updatedAt: new Date(),
        };
        paymentsStore.set(id, record);
        return record;
      }),
      findOne: jest.fn(async (options: any) => {
        if (options?.where?.id) return paymentsStore.get(options.where.id) || null;
        if (options?.where?.bookingId) {
          for (const p of paymentsStore.values()) {
            if (p.bookingId === options.where.bookingId) return p;
          }
        }
        if (options?.where?.providerOrderId) {
          for (const p of paymentsStore.values()) {
            if (p.providerOrderId === options.where.providerOrderId) return p;
          }
        }
        if (options?.where?.providerPaymentId) {
          for (const p of paymentsStore.values()) {
            if (p.providerPaymentId === options.where.providerPaymentId) return p;
          }
        }
        return null;
      }),
      find: jest.fn(async () => Array.from(paymentsStore.values())),
    };

    // Mock Booking Repo
    mockBookingRepo = {
      findOne: jest.fn(async (options: any) => {
        if (options?.where?.id) return bookingsStore.get(options.where.id) || null;
        return null;
      }),
      save: jest.fn(async (entity: any) => {
        const id = entity.id || `bk_${Date.now()}`;
        const record = { ...entity, id, updatedAt: new Date() };
        bookingsStore.set(id, record);
        return record;
      }),
      find: jest.fn(async () => Array.from(bookingsStore.values())),
      count: jest.fn(async () => bookingsStore.size),
    };

    // Mock User Repo
    mockUserRepo = {
      findOne: jest.fn(async (options: any) => {
        if (options?.where?.id) return usersStore.get(options.where.id) || null;
        return null;
      }),
      save: jest.fn(async (entity: any) => {
        usersStore.set(entity.id, { ...entity, updatedAt: new Date() });
        return entity;
      }),
      count: jest.fn(async () => usersStore.size),
    };

    // Mock Audit Log Repo
    mockAuditLogRepo = {
      save: jest.fn(async (entity: any) => {
        const id = entity.id || `aud_${Date.now()}`;
        auditLogsStore.set(id, { ...entity, id, createdAt: new Date() });
        return entity;
      }),
      find: jest.fn(async () => Array.from(auditLogsStore.values())),
      count: jest.fn(async () => auditLogsStore.size),
    };

    mockDataSource = {
      transaction: jest.fn(async (cb: any) => {
        const em = {
          save: jest.fn(async (ent: any) => {
            if (ent.idempotencyKey) return mockIdempRepo.save(ent);
            if (ent.status && ent.amount) return mockPaymentRepo.save(ent);
            if (ent.bookingNumber || ent.totalPrice) return mockBookingRepo.save(ent);
            return ent;
          }),
          findOne: jest.fn(async (cls: any, opts: any) => {
            if (cls === IdempotencyRecordEntity || opts?.where?.idempotencyKey) {
              return mockIdempRepo.findOne(opts);
            }
            if (cls === PaymentEntity || opts?.where?.id) {
              return mockPaymentRepo.findOne(opts);
            }
            if (cls === BookingEntity) {
              return mockBookingRepo.findOne(opts);
            }
            return null;
          }),
        };
        return cb(em);
      }),
    };

    recoveryService = new PaymentRecoveryService(mockRecoveryRepo);
    idempotencyService = new IdempotencyService(mockIdempRepo);
    paymentConfigService = new PaymentConfigService({
      PAYMENT_MODE: PaymentMode.SIMULATED,
      RAZORPAY_LIVE_ENABLED: 'false',
      RAZORPAY_KEY_ID: TEST_KEY_ID,
      RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
    });
    simulatedAdapter = new SimulatedPaymentAdapter();
    razorpayAdapter = new RazorpayAdapter(paymentConfigService);

    paymentService = new PaymentService(
      razorpayAdapter,
      simulatedAdapter,
      mockPaymentRepo,
      paymentConfigService,
      idempotencyService,
      recoveryService,
    );

    smsAdapter = {
      sendSms: jest.fn(async (options: any) => {
        const to = options?.to || options;
        const message = options?.message || '';
        smsLog.push({ to, message });
        return { messageSid: `SM_${Date.now()}`, status: 'sent', provider: 'twilio' };
      }),
    } as any;

    paymentsController = new PaymentsController(
      paymentService,
      razorpayAdapter,
      mockBookingRepo,
      mockPaymentRepo,
      mockUserRepo,
      mockEventRepo,
      mockActivityRepo,
      smsAdapter,
      idempotencyService,
      recoveryService,
    );

    adminService = new AdminService(
      mockUserRepo,
      {} as any,
      {} as any,
      mockRestaurantRepo,
      mockEventRepo,
      mockActivityRepo,
      mockProductRepo,
      {} as any,
      {} as any,
      mockBookingRepo,
      mockAuditLogRepo,
      {} as any,
      {} as any,
      mockPaymentRepo,
      {} as any,
      {} as any,
      paymentService,
      mockRecoveryRepo,
      recoveryService,
    );

    adminController = new AdminController(adminService);
  });

  // Helper to register valid active quote
  function registerQuote(quoteId: string, bookingId: string, userId = 'usr_customer1', total = 1000) {
    return paymentService.registerQuote(
      {
        quoteId,
        bookingId,
        userId,
        type: 'movie',
        vertical: 'movie',
        subtotal: total,
        discount: 0,
        taxes: 0,
        tax: 0,
        convenienceFee: 0,
        fees: 0,
        total,
        grandTotal: total,
        currency: 'INR',
        expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
      } as any,
      { userId, bookingId },
    );
  }

  // =========================================================================
  // SUITE 1: Failure Classification and Categorization (13 categories)
  // =========================================================================
  describe('Suite 1: Failure Classification and Sanitization', () => {
    it('1.1 should correctly classify validation errors as VALIDATION_FAILURE', () => {
      const err = new BadRequestException('Amount mismatch between quote and capture');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.VALIDATION_FAILURE);
    });

    it('1.2 should correctly classify authorization / signature errors as AUTHORIZATION_FAILURE', () => {
      const err = new UnauthorizedException('Invalid payment signature HMAC');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.AUTHORIZATION_FAILURE);
    });

    it('1.3 should correctly classify card / bank declines as PROVIDER_DECLINED', () => {
      const err = new Error('BAD_REQUEST_ERROR: Payment was declined by issuing bank');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.PROVIDER_DECLINED);
    });

    it('1.4 should correctly classify gateway timeouts as PROVIDER_TIMEOUT', () => {
      const err = new Error('Gateway timeout: ETIMEDOUT contacting razorpay API');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.PROVIDER_TIMEOUT);
    });

    it('1.5 should correctly classify service unavailable as PROVIDER_UNAVAILABLE', () => {
      const err = new ServiceUnavailableException('Payment gateway maintenance');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.PROVIDER_UNAVAILABLE);
    });

    it('1.6 should correctly classify network socket drops as NETWORK_ERROR', () => {
      const err = new Error('Socket closed unexpectedly: ECONNRESET');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.NETWORK_ERROR);
    });

    it('1.7 should correctly classify database errors as DATABASE_FAILURE', () => {
      const err = new Error('QueryFailedError: deadlock detected in transaction');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.DATABASE_FAILURE);
    });

    it('1.8 should correctly classify booking execution failures as BOOKING_CONFIRMATION_FAILURE', () => {
      const err = new Error('Failed to update booking status to UPCOMING');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.BOOKING_CONFIRMATION_FAILURE);
    });

    it('1.9 should correctly classify inventory exhaustion as INVENTORY_FAILURE', () => {
      const err = new Error('Show time slot capacity exhausted / sold out');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.INVENTORY_FAILURE);
    });

    it('1.10 should correctly classify rewards failure as REWARD_FAILURE', () => {
      const err = new Error('Failed to award loyalty reward points to user account');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.REWARD_FAILURE);
    });

    it('1.11 should correctly classify SMS notification failures as NOTIFICATION_FAILURE', () => {
      const err = new Error('Twilio delivery failed: phone number unreachable');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.NOTIFICATION_FAILURE);
    });

    it('1.12 should correctly classify refund failures as REFUND_FAILURE', () => {
      const err = new Error('Refund failed: payment has already been fully refunded');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.REFUND_FAILURE);
    });

    it('1.13 should classify unknown or unhandled errors as UNKNOWN_PROVIDER_OUTCOME', () => {
      const err = new Error('Unexpected internal anomaly 0x89');
      expect(recoveryService.classifyError(err)).toBe(FailureCategory.UNKNOWN_PROVIDER_OUTCOME);
    });

    it('1.14 isUnknownOutcome should identify uncertain categories requiring reconciliation', () => {
      expect(recoveryService.isUnknownOutcome(FailureCategory.PROVIDER_TIMEOUT)).toBe(true);
      expect(recoveryService.isUnknownOutcome(FailureCategory.PROVIDER_UNAVAILABLE)).toBe(true);
      expect(recoveryService.isUnknownOutcome(FailureCategory.NETWORK_ERROR)).toBe(true);
      expect(recoveryService.isUnknownOutcome(FailureCategory.UNKNOWN_PROVIDER_OUTCOME)).toBe(true);
      expect(recoveryService.isUnknownOutcome(FailureCategory.VALIDATION_FAILURE)).toBe(false);
      expect(recoveryService.isUnknownOutcome(FailureCategory.AUTHORIZATION_FAILURE)).toBe(false);
      expect(recoveryService.isUnknownOutcome(FailureCategory.PROVIDER_DECLINED)).toBe(false);
    });

    it('1.15 sanitizeReason should scrub API keys, secrets, JWT tokens, and connection strings', () => {
      const sensitive = 'Failed at key=rzp_live_abc1234567890 secret=super_secret_val with token=eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.doNotLeak';
      const clean = recoveryService.sanitizeReason(sensitive);
      expect(clean).not.toContain('rzp_live_abc1234567890');
      expect(clean).not.toContain('super_secret_val');
      expect(clean).not.toContain('eyJhbGci');
      expect(clean).toContain('[REDACTED]');
    });
  });

  // =========================================================================
  // SUITE 2: Payment Creation Failures & Recovery
  // =========================================================================
  describe('Suite 2: Payment Creation Failures & Recovery', () => {
    it('2.1 definitive provider rejection during order creation records failure incident and marks payment FAILED', async () => {
      registerQuote('quo_fail_1', 'bk_order_fail_1', 'usr_customer1', 500);

      jest.spyOn(simulatedAdapter, 'createOrder').mockRejectedValueOnce(
        new BadRequestException('Invalid customer email or currency not supported'),
      );

      await expect(
        paymentService.createPaymentOrder({
          quoteId: 'quo_fail_1',
          bookingId: 'bk_order_fail_1',
          userId: 'usr_customer1',
        }),
      ).rejects.toThrow(BadRequestException);

      const incidents = Array.from(recoveryStore.values());
      expect(incidents.length).toBeGreaterThanOrEqual(1);
      expect(incidents[0].failureCategory).toBe(FailureCategory.VALIDATION_FAILURE);
      expect(incidents[0].recoveryStatus).toBe(RecoveryStatus.REQUIRED);
    });

    it('2.2 provider timeout during order creation records PROVIDER_TIMEOUT incident and leaves state safely retriable', async () => {
      registerQuote('quo_timeout_1', 'bk_order_timeout_1', 'usr_customer1', 1500);

      jest.spyOn(simulatedAdapter, 'createOrder').mockRejectedValueOnce(
        new Error('Gateway timeout ETIMEDOUT on order creation'),
      );

      await expect(
        paymentService.createPaymentOrder({
          quoteId: 'quo_timeout_1',
          bookingId: 'bk_order_timeout_1',
          userId: 'usr_customer1',
        }),
      ).rejects.toThrow();

      const incidents = Array.from(recoveryStore.values());
      expect(incidents.some((i) => i.failureCategory === FailureCategory.PROVIDER_TIMEOUT)).toBe(true);
    });

    it('2.3 network socket error during order creation records NETWORK_ERROR incident', async () => {
      registerQuote('quo_net_1', 'bk_order_net_1', 'usr_customer1', 2500);

      jest.spyOn(simulatedAdapter, 'createOrder').mockRejectedValueOnce(
        new Error('ECONNRESET connection reset by peer'),
      );

      await expect(
        paymentService.createPaymentOrder({
          quoteId: 'quo_net_1',
          bookingId: 'bk_order_net_1',
          userId: 'usr_customer1',
        }),
      ).rejects.toThrow();

      const incidents = Array.from(recoveryStore.values());
      expect(incidents.some((i) => i.failureCategory === FailureCategory.NETWORK_ERROR)).toBe(true);
    });

    it('2.4 retrying payment creation with same idempotency key after successful creation returns cached order', async () => {
      registerQuote('quo_idemp_1', 'bk_idemp_create_1', 'usr_customer1', 750);

      const res1 = await paymentService.createPaymentOrder({
        quoteId: 'quo_idemp_1',
        bookingId: 'bk_idemp_create_1',
        userId: 'usr_customer1',
        idempotencyKey: 'idem_key_create_100',
      });

      const res2 = await paymentService.createPaymentOrder({
        quoteId: 'quo_idemp_1',
        bookingId: 'bk_idemp_create_1',
        userId: 'usr_customer1',
        idempotencyKey: 'idem_key_create_100',
      });

      expect(res1.orderId).toBe(res2.orderId);
      expect(res1.amount).toBe(res2.amount);
    });

    it('2.5 retrying payment creation with same idempotency key but conflicting payload is rejected with 409', async () => {
      registerQuote('quo_idemp_2', 'bk_idemp_create_2', 'usr_customer1', 1000);
      registerQuote('quo_idemp_alt', 'bk_idemp_create_2', 'usr_customer1', 2000);

      await paymentService.createPaymentOrder({
        quoteId: 'quo_idemp_2',
        bookingId: 'bk_idemp_create_2',
        userId: 'usr_customer1',
        idempotencyKey: 'idem_key_conflict_100',
      });

      await expect(
        paymentService.createPaymentOrder({
          quoteId: 'quo_idemp_alt',
          bookingId: 'bk_idemp_create_2',
          userId: 'usr_customer1',
          idempotencyKey: 'idem_key_conflict_100',
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  // =========================================================================
  // SUITE 3: Payment Verification Failures & Unknown Outcome Protection
  // =========================================================================
  describe('Suite 3: Payment Verification Failures & Unknown Outcome Protection', () => {
    let orderId: string;
    let paymentId: string;
    let bookingId: string;
    let quoteId: string;

    beforeEach(async () => {
      bookingId = 'bk_verify_suite_1';
      quoteId = 'quo_verify_suite_1';
      bookingsStore.set(bookingId, {
        id: bookingId,
        userId: 'usr_customer1',
        totalPrice: 1200,
        status: BookingStatus.PENDING,
        title: 'VIP Lounge Experience',
      } as any);

      registerQuote(quoteId, bookingId, 'usr_customer1', 1200);

      const orderRes = await paymentService.createPaymentOrder({
        quoteId,
        bookingId,
        userId: 'usr_customer1',
      });
      orderId = orderRes.orderId;
      paymentId = `pay_${Date.now()}_test`;
    });

    it('3.1 invalid signature triggers AUTHORIZATION_FAILURE and marks payment FAILED', async () => {
      const invalidSig = 'deadbeef0000111122223333444455556666777788889999aaaabbbbccccdddd';

      const verifyRes = await paymentService.verifyPayment({
        bookingId,
        orderId,
        paymentId,
        signature: invalidSig,
        quoteId,
        userId: 'usr_customer1',
        amount: 1200,
        currency: 'INR',
      });
      expect(verifyRes.success).toBe(false);

      await expect(
        paymentsController.verifyPayment(
          {
            bookingId,
            razorpayOrderId: orderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: invalidSig,
            quoteId,
            amount: 1200,
            currency: 'INR',
          },
          { user: { id: 'usr_customer1', email: 'customer1@plaza.test' } } as any,
        ),
      ).rejects.toThrow(UnauthorizedException);

      const incidents = Array.from(recoveryStore.values());
      expect(incidents.some((i) => i.failureCategory === FailureCategory.AUTHORIZATION_FAILURE)).toBe(true);
    });

    it('3.2 amount mismatch triggers VALIDATION_FAILURE and marks payment FAILED', async () => {
      const validSig = signOrderPayment(orderId, paymentId);

      await expect(
        paymentService.verifyPayment({
          bookingId,
          orderId,
          paymentId,
          signature: validSig,
          quoteId,
          userId: 'usr_customer1',
          amount: 999, // Expected 1200
          currency: 'INR',
        }),
      ).rejects.toThrow(BadRequestException);

      const payment = await mockPaymentRepo.findOne({ where: { providerOrderId: orderId } });
      expect(payment.status).toBe(PaymentStatus.FAILED);
      expect(payment.failureReason).toBe(PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH);
    });

    it('3.3 currency mismatch triggers VALIDATION_FAILURE and marks payment FAILED', async () => {
      const validSig = signOrderPayment(orderId, paymentId);

      await expect(
        paymentService.verifyPayment({
          bookingId,
          orderId,
          paymentId,
          signature: validSig,
          quoteId,
          userId: 'usr_customer1',
          amount: 1200,
          currency: 'USD', // Expected INR
        }),
      ).rejects.toThrow(BadRequestException);

      const payment = await mockPaymentRepo.findOne({ where: { providerOrderId: orderId } });
      expect(payment.status).toBe(PaymentStatus.FAILED);
      expect(payment.failureReason).toBe(PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH);
    });

    it('3.4 provider decline during fetch details triggers PROVIDER_DECLINED and marks payment FAILED', async () => {
      const validSig = signOrderPayment(orderId, paymentId);
      jest.spyOn(simulatedAdapter, 'fetchPaymentDetails').mockResolvedValueOnce({
        paymentId,
        orderId,
        amount: 1200,
        amountInMinorUnits: 120000,
        currency: 'INR',
        status: 'failed',
        captured: false,
      });

      await expect(
        paymentService.verifyPayment({
          bookingId,
          orderId,
          paymentId,
          signature: validSig,
          quoteId,
          userId: 'usr_customer1',
          amount: 1200,
          currency: 'INR',
        }),
      ).rejects.toThrow(BadRequestException);

      const payment = await mockPaymentRepo.findOne({ where: { providerOrderId: orderId } });
      expect(payment.status).toBe(PaymentStatus.FAILED);
    });

    it('3.5 provider timeout during fetchPaymentDetails preserves PENDING status and creates UNKNOWN_PROVIDER_OUTCOME incident', async () => {
      const validSig = signOrderPayment(orderId, paymentId);
      jest.spyOn(simulatedAdapter, 'fetchPaymentDetails').mockRejectedValueOnce(
        new Error('Gateway timeout ETIMEDOUT during payment status fetch'),
      );

      await expect(
        paymentService.verifyPayment({
          bookingId,
          orderId,
          paymentId,
          signature: validSig,
          quoteId,
          userId: 'usr_customer1',
          amount: 1200,
          currency: 'INR',
        }),
      ).rejects.toThrow(ServiceUnavailableException);

      const payment = await mockPaymentRepo.findOne({ where: { providerOrderId: orderId } });
      // CRITICAL RECOVERY INVARIANT: Do NOT mark payment FAILED on provider timeout!
      expect(payment.status).toBe(PaymentStatus.PENDING);

      const incidents = Array.from(recoveryStore.values());
      expect(incidents.some((i) => i.recoveryStatus === RecoveryStatus.REQUIRED)).toBe(true);
    });

    it('3.6 network socket drop during fetchPaymentDetails preserves PENDING status and creates REQUIRED incident', async () => {
      const validSig = signOrderPayment(orderId, paymentId);
      jest.spyOn(simulatedAdapter, 'fetchPaymentDetails').mockRejectedValueOnce(
        new Error('ECONNRESET connection reset by peer'),
      );

      await expect(
        paymentService.verifyPayment({
          bookingId,
          orderId,
          paymentId,
          signature: validSig,
          quoteId,
          userId: 'usr_customer1',
          amount: 1200,
          currency: 'INR',
        }),
      ).rejects.toThrow(ServiceUnavailableException);

      const payment = await mockPaymentRepo.findOne({ where: { providerOrderId: orderId } });
      expect(payment.status).toBe(PaymentStatus.PENDING);
    });

    it('3.7 verified payment cannot be demoted from CAPTURED to FAILED by subsequent failed verification', async () => {
      const validSig = signOrderPayment(orderId, paymentId);

      // 1. First verification succeeds
      const res = await paymentService.verifyPayment({
        bookingId,
        orderId,
        paymentId,
        signature: validSig,
        quoteId,
        userId: 'usr_customer1',
        amount: 1200,
        currency: 'INR',
      });
      expect(res.success).toBe(true);

      // 2. State transition validator must block CAPTURED -> FAILED
      const paymentBefore = await mockPaymentRepo.findOne({ where: { providerOrderId: orderId } });
      expect(paymentBefore.status).toBe(PaymentStatus.CAPTURED);

      expect(() => {
        assertValidPaymentStateTransition(PaymentStatus.CAPTURED, PaymentStatus.FAILED);
      }).toThrow();
    });
  });

  // =========================================================================
  // SUITE 4: Booking Failures with Captured Payment & Non-Fatal Side Effects
  // =========================================================================
  describe('Suite 4: Booking Confirmation & Non-Fatal Side Effect Isolation', () => {
    let orderId: string;
    let paymentId: string;
    let bookingId: string;
    let quoteId: string;

    beforeEach(async () => {
      bookingId = 'bk_side_effect_1';
      quoteId = 'quo_side_effect_1';
      bookingsStore.set(bookingId, {
        id: bookingId,
        userId: 'usr_customer1',
        totalPrice: 2000,
        status: BookingStatus.PENDING,
        title: 'Skyline Dining Table',
        type: BookingType.DINING,
        metadata: { restaurantId: 'rest_1' },
      } as any);

      registerQuote(quoteId, bookingId, 'usr_customer1', 2000);

      const orderRes = await paymentService.createPaymentOrder({
        quoteId,
        bookingId,
        userId: 'usr_customer1',
      });
      orderId = orderRes.orderId;
      paymentId = `pay_${Date.now()}_side`;
    });

    it('4.1 reward point delivery failure does NOT abort captured payment or confirmed booking', async () => {
      const validSig = signOrderPayment(orderId, paymentId);

      jest.spyOn(mockUserRepo, 'save').mockRejectedValueOnce(
        new Error('Database deadlock on reward points increment'),
      );

      const res = await paymentsController.verifyPayment(
        {
          bookingId,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: validSig,
          quoteId,
          amount: 2000,
          currency: 'INR',
        },
        { user: { id: 'usr_customer1', email: 'customer1@plaza.test' } } as any,
      );

      expect(res.status).toBe(PaymentStatus.CAPTURED);
      const booking = await mockBookingRepo.findOne({ where: { id: bookingId } });
      expect(booking.status).toBe(BookingStatus.UPCOMING);

      const incidents = Array.from(recoveryStore.values());
      expect(incidents.some((i) => i.failureCategory === FailureCategory.REWARD_FAILURE)).toBe(true);
    });

    it('4.2 SMS delivery failure does NOT abort captured payment or confirmed booking', async () => {
      const validSig = signOrderPayment(orderId, paymentId);

      jest.spyOn(smsAdapter, 'sendSms').mockRejectedValueOnce(
        new Error('Twilio provider error 500: network timeout'),
      );

      const res = await paymentsController.verifyPayment(
        {
          bookingId,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: validSig,
          quoteId,
          amount: 2000,
          currency: 'INR',
        },
        { user: { id: 'usr_customer1', email: 'customer1@plaza.test' } } as any,
      );

      expect(res.status).toBe(PaymentStatus.CAPTURED);
      const booking = await mockBookingRepo.findOne({ where: { id: bookingId } });
      expect(booking.status).toBe(BookingStatus.UPCOMING);

      const incidents = Array.from(recoveryStore.values());
      expect(incidents.some((i) => i.failureCategory === FailureCategory.NOTIFICATION_FAILURE)).toBe(true);
    });

    it('4.3 booking update failure after payment capture preserves CAPTURED payment and records BOOKING_CONFIRMATION_FAILURE', async () => {
      const validSig = signOrderPayment(orderId, paymentId);

      jest.spyOn(mockBookingRepo, 'save').mockRejectedValueOnce(
        new Error('Database disk full: cannot save booking'),
      );

      await expect(
        paymentsController.verifyPayment(
          {
            bookingId,
            razorpayOrderId: orderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: validSig,
            quoteId,
            amount: 2000,
            currency: 'INR',
          },
          { user: { id: 'usr_customer1', email: 'customer1@plaza.test' } } as any,
        ),
      ).rejects.toThrow();

      const payment = await mockPaymentRepo.findOne({ where: { providerOrderId: orderId } });
      expect(payment.status).toBe(PaymentStatus.CAPTURED);

      const incidents = Array.from(recoveryStore.values());
      expect(
        incidents.some((i) => i.failureCategory === FailureCategory.BOOKING_CONFIRMATION_FAILURE),
      ).toBe(true);
    });
  });

  // =========================================================================
  // SUITE 5: Refund Failures & Timeout Handling
  // =========================================================================
  describe('Suite 5: Refund Failures & Timeout Handling', () => {
    let paymentId: string;
    let bookingId: string;

    beforeEach(async () => {
      bookingId = 'bk_refund_suite_1';
      bookingsStore.set(bookingId, {
        id: bookingId,
        userId: 'usr_customer1',
        totalPrice: 3000,
        status: BookingStatus.UPCOMING,
        title: 'Luxury Spa Suite',
      } as any);

      paymentId = `pay_captured_${Date.now()}`;
      paymentsStore.set(paymentId, {
        id: paymentId,
        bookingId,
        userId: 'usr_customer1',
        amount: 3000,
        currency: 'INR',
        status: PaymentStatus.CAPTURED,
        providerOrderId: `order_${Date.now()}`,
        providerPaymentId: `rzp_pay_${Date.now()}`,
        refundAmount: 0,
      } as any);
    });

    it('5.1 successful refund transitions payment to REFUNDED and booking to CANCELLED', async () => {
      const res = await adminService.refundBooking(
        bookingId,
        { reason: 'Customer requested cancellation' },
        { id: 'usr_admin1', email: 'admin@plaza.test' },
      );

      expect(res.success).toBe(true);
      const payment = await mockPaymentRepo.findOne({ where: { id: paymentId } });
      expect(payment.status).toBe(PaymentStatus.REFUNDED);
      expect(payment.refundAmount).toBe(3000);

      const booking = await mockBookingRepo.findOne({ where: { id: bookingId } });
      expect(booking.status).toBe(BookingStatus.CANCELLED);
    });

    it('5.2 definitive provider refund decline records REFUND_FAILURE and preserves payment CAPTURED', async () => {
      jest.spyOn(simulatedAdapter, 'refund').mockRejectedValueOnce(
        new BadRequestException('Refund rejected: card expired / chargeback active'),
      );

      await expect(
        adminService.refundBooking(
          bookingId,
          { reason: 'Cancellation attempt' },
          { id: 'usr_admin1', email: 'admin@plaza.test' },
        ),
      ).rejects.toThrow(BadRequestException);

      const payment = await mockPaymentRepo.findOne({ where: { id: paymentId } });
      expect(payment.status).toBe(PaymentStatus.CAPTURED);

      const incidents = Array.from(recoveryStore.values());
      expect(incidents.some((i) => i.failureCategory === FailureCategory.REFUND_FAILURE)).toBe(true);
    });

    it('5.3 provider timeout during refund transitions payment to REFUND_PENDING and records PROVIDER_TIMEOUT', async () => {
      jest.spyOn(simulatedAdapter, 'refund').mockRejectedValueOnce(
        new Error('Gateway timeout ETIMEDOUT on refund dispatch'),
      );

      await expect(
        adminService.refundBooking(
          bookingId,
          { reason: 'Cancellation attempt' },
          { id: 'usr_admin1', email: 'admin@plaza.test' },
        ),
      ).rejects.toThrow();

      const payment = await mockPaymentRepo.findOne({ where: { id: paymentId } });
      // Must NOT be marked REFUNDED or FAILED!
      expect(payment.status).toBe(PaymentStatus.REFUND_PENDING);

      const incidents = Array.from(recoveryStore.values());
      expect(incidents.some((i) => i.failureCategory === FailureCategory.PROVIDER_TIMEOUT)).toBe(true);
    });

    it('5.4 network error during refund transitions payment to REFUND_PENDING and records NETWORK_ERROR', async () => {
      jest.spyOn(simulatedAdapter, 'refund').mockRejectedValueOnce(
        new Error('ECONNRESET connection reset by peer during refund'),
      );

      await expect(
        adminService.refundBooking(
          bookingId,
          { reason: 'Cancellation attempt' },
          { id: 'usr_admin1', email: 'admin@plaza.test' },
        ),
      ).rejects.toThrow();

      const payment = await mockPaymentRepo.findOne({ where: { id: paymentId } });
      expect(payment.status).toBe(PaymentStatus.REFUND_PENDING);
    });
  });

  // =========================================================================
  // SUITE 6: Admin Recovery Visibility & Manual Intervention
  // =========================================================================
  describe('Suite 6: Admin Recovery Management & Resolution', () => {
    it('6.1 admin can list and filter recovery incidents', async () => {
      await recoveryService.recordIncident({
        resourceType: 'payment',
        resourceId: 'pay_rec_1',
        paymentId: 'pay_rec_1',
        bookingId: 'bk_rec_1',
        failureCategory: FailureCategory.PROVIDER_TIMEOUT,
        safeFailureReason: 'Gateway timeout during verification',
      });

      await recoveryService.recordIncident({
        resourceType: 'booking',
        resourceId: 'bk_rec_2',
        bookingId: 'bk_rec_2',
        failureCategory: FailureCategory.BOOKING_CONFIRMATION_FAILURE,
        safeFailureReason: 'Database error saving booking',
      });

      const listRes = await adminController.getRecoveryIncidents({
        status: RecoveryStatus.REQUIRED,
      });

      expect(listRes.total).toBe(2);
      expect(listRes.incidents.length).toBe(2);
    });

    it('6.2 admin can get incident by ID and resolve it with notes and audit record', async () => {
      const incident = await recoveryService.recordIncident({
        resourceType: 'payment',
        resourceId: 'pay_rec_solve_1',
        paymentId: 'pay_rec_solve_1',
        bookingId: 'bk_rec_solve_1',
        failureCategory: FailureCategory.UNKNOWN_PROVIDER_OUTCOME,
        safeFailureReason: 'Provider unreachable during capture check',
      });

      const detail = await adminController.getRecoveryIncidentById(incident.id);
      expect(detail.id).toBe(incident.id);
      expect(detail.recoveryStatus).toBe(RecoveryStatus.REQUIRED);

      const resolveRes = await adminController.resolveRecoveryIncident(
        incident.id,
        { notes: 'Manually verified capture on Razorpay portal; ticket issued' },
        { user: { id: 'usr_admin1', email: 'admin@plaza.test' } },
      );

      expect(resolveRes.recoveryStatus).toBe(RecoveryStatus.RESOLVED);
      expect(resolveRes.resolutionNotes).toContain('Manually verified capture');

      const logs = Array.from(auditLogsStore.values());
      expect(logs.some((l) => l.action === 'RESOLVE_RECOVERY_INCIDENT')).toBe(true);
    });
  });

  // =========================================================================
  // SUITE 7: State Machine Integrity & State Transitions
  // =========================================================================
  describe('Suite 7: Payment State Machine Integrity', () => {
    it('7.1 valid transitions succeed', () => {
      expect(() => assertValidPaymentStateTransition(PaymentStatus.PENDING, PaymentStatus.CAPTURED)).not.toThrow();
      expect(() => assertValidPaymentStateTransition(PaymentStatus.PENDING, PaymentStatus.FAILED)).not.toThrow();
      expect(() => assertValidPaymentStateTransition(PaymentStatus.CAPTURED, PaymentStatus.REFUND_PENDING)).not.toThrow();
      expect(() => assertValidPaymentStateTransition(PaymentStatus.CAPTURED, PaymentStatus.REFUNDED)).not.toThrow();
      expect(() => assertValidPaymentStateTransition(PaymentStatus.REFUND_PENDING, PaymentStatus.REFUNDED)).not.toThrow();
      expect(() => assertValidPaymentStateTransition(PaymentStatus.REFUND_PENDING, PaymentStatus.CAPTURED)).not.toThrow();
    });

    it('7.2 illegal transitions are strictly blocked', () => {
      // Cannot move CAPTURED to FAILED
      expect(() => assertValidPaymentStateTransition(PaymentStatus.CAPTURED, PaymentStatus.FAILED)).toThrow(BadRequestException);
      // Cannot move REFUNDED to CAPTURED
      expect(() => assertValidPaymentStateTransition(PaymentStatus.REFUNDED, PaymentStatus.CAPTURED)).toThrow(BadRequestException);
      // Cannot move FAILED to CAPTURED directly
      expect(() => assertValidPaymentStateTransition(PaymentStatus.FAILED, PaymentStatus.CAPTURED)).toThrow(BadRequestException);
      // Cannot move REFUNDED to PENDING
      expect(() => assertValidPaymentStateTransition(PaymentStatus.REFUNDED, PaymentStatus.PENDING)).toThrow(BadRequestException);
    });

    it('7.3 toMinorUnits handles float rounding safely', () => {
      expect(toMinorUnits(10.5)).toBe(1050);
      expect(toMinorUnits(199.99)).toBe(19999);
      expect(toMinorUnits(0)).toBe(0);
      expect(toMinorUnits(100)).toBe(10000);
    });
  });

  // =========================================================================
  // SUITE 8: Production Safety & Migration Verifications
  // =========================================================================
  describe('Suite 8: Production Safety & Reversible Migration', () => {
    it('8.1 production environment strictly enforces SIMULATED payment mode and false live activation', () => {
      const config = paymentConfigService.evaluate();
      expect(config.summary.paymentMode).toBe(PaymentMode.SIMULATED);
      expect(config.summary.razorpayLiveEnabled).toBe(false);
      expect(config.summary.liveOperationsAllowed).toBe(false);
    });

    it('8.2 migration creates table and indices and drops cleanly on rollback', async () => {
      const migration = new CreatePaymentRecoveryTable1791000000000();
      let createdTable: any = null;
      let createdIndices: any[] = [];
      let droppedTableName: string | null = null;

      const mockQueryRunner = {
        createTable: jest.fn(async (t: any) => {
          createdTable = t;
        }),
        createIndices: jest.fn(async (tName: string, indices: any[]) => {
          createdIndices = indices;
        }),
        dropTable: jest.fn(async (tName: string) => {
          droppedTableName = tName;
        }),
      } as any;

      await migration.up(mockQueryRunner);
      expect(createdTable).toBeDefined();
      expect(createdTable.name).toBe('payment_recovery_records');
      expect(createdIndices.length).toBe(5);

      await migration.down(mockQueryRunner);
      expect(droppedTableName).toBe('payment_recovery_records');
    });
  });
});
