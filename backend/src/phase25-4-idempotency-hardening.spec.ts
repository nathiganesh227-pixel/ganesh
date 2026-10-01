import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import {
  PaymentEntity,
  PaymentStatus,
  PaymentErrorCode,
  assertValidPaymentStateTransition,
  toMinorUnits,
} from './database/entities/payment.entity';
import { IdempotencyRecordEntity } from './database/entities/idempotency-record.entity';
import { BookingEntity, BookingStatus, BookingType } from './database/entities/booking.entity';
import { User, UserRole } from './database/entities/user.entity';
import { EventEntity } from './database/entities/event.entity';
import { ActivityEntity } from './database/entities/activity.entity';
import { ProductEntity } from './database/entities/product.entity';
import { RestaurantEntity } from './database/entities/restaurant.entity';
import { IdempotencyService } from './modules/bookings/idempotency.service';
import { PaymentService } from './modules/payments/payment.service';
import { PaymentConfigService, PaymentMode } from './modules/payments/payment-config.service';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { PaymentsController } from './modules/payments/payments.controller';
import { BookingsService } from './modules/bookings/bookings.service';
import { BookingsController } from './modules/bookings/bookings.controller';
import { AdminService } from './modules/admin/admin.service';
import { TwilioSmsAdapter } from './modules/notifications/providers/twilio-sms.adapter';
import { EnhanceIdempotencyRecordsTable1790900000000 } from './database/migrations/1790900000000-EnhanceIdempotencyRecordsTable';

const TEST_KEY_ID = 'rzp_test_1234567890ABCD';
const TEST_KEY_SECRET = 'test_secret_for_signing_9876543210';

function signOrderPayment(orderId: string, paymentId: string, secret = TEST_KEY_SECRET): string {
  return crypto
    .createHmac('sha256', secret)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');
}

describe('PLAZA Phase 25.4 — Payment and Refund Idempotency Hardening', () => {
  let idempotencyStore: Map<string, IdempotencyRecordEntity>;
  let paymentsStore: Map<string, PaymentEntity>;
  let bookingsStore: Map<string, BookingEntity>;
  let usersStore: Map<string, User>;
  let eventsStore: Map<string, EventEntity>;
  let activitiesStore: Map<string, ActivityEntity>;
  let productsStore: Map<string, ProductEntity>;
  let restaurantsStore: Map<string, RestaurantEntity>;
  let smsLog: Array<{ to: string; message: string }>;

  let mockIdempRepo: any;
  let mockPaymentRepo: any;
  let mockBookingRepo: any;
  let mockUserRepo: any;
  let mockEventRepo: any;
  let mockActivityRepo: any;
  let mockProductRepo: any;
  let mockRestaurantRepo: any;
  let mockDataSource: any;

  let idempotencyService: IdempotencyService;
  let paymentConfigService: PaymentConfigService;
  let simulatedAdapter: SimulatedPaymentAdapter;
  let razorpayAdapter: RazorpayAdapter;
  let paymentService: PaymentService;
  let smsAdapter: TwilioSmsAdapter;
  let paymentsController: PaymentsController;
  let bookingsService: BookingsService;
  let bookingsController: BookingsController;
  let adminService: AdminService;

  beforeEach(() => {
    idempotencyStore = new Map();
    paymentsStore = new Map();
    bookingsStore = new Map();
    usersStore = new Map();
    eventsStore = new Map();
    activitiesStore = new Map();
    productsStore = new Map();
    restaurantsStore = new Map();
    smsLog = [];

    // Seed test users
    usersStore.set('usr_alice', {
      id: 'usr_alice',
      email: 'alice@plaza.test',
      role: UserRole.USER,
      rewardPoints: 500,
    } as any);

    usersStore.set('usr_bob', {
      id: 'usr_bob',
      email: 'bob@plaza.test',
      role: UserRole.USER,
      rewardPoints: 200,
    } as any);

    usersStore.set('usr_admin', {
      id: 'usr_admin',
      email: 'admin@plaza.test',
      role: UserRole.ADMIN,
      rewardPoints: 0,
    } as any);

    // Seed restaurant
    restaurantsStore.set('rest_jewel', {
      id: 'rest_jewel',
      name: 'Jewel of Nizam',
      isOpenNow: true,
    } as any);

    // Mock Idempotency Repository
    mockIdempRepo = {
      findOne: jest.fn(async ({ where }: any) => {
        if (where.key) return idempotencyStore.get(where.key) || null;
        if (where.idempotencyKey && where.userId) {
          const key = `${where.userId}:${where.idempotencyKey}`;
          return idempotencyStore.get(key) || null;
        }
        return null;
      }),
      create: jest.fn((dto: any) => ({ ...dto, createdAt: new Date(), updatedAt: new Date() })),
      save: jest.fn(async (entity: IdempotencyRecordEntity) => {
        idempotencyStore.set(entity.key, { ...entity, updatedAt: new Date() });
        return entity;
      }),
      delete: jest.fn(async ({ key }: any) => {
        idempotencyStore.delete(key);
      }),
    };

    // Mock Payment Repository
    mockPaymentRepo = {
      findOne: jest.fn(async ({ where }: any) => {
        if (where.id) return paymentsStore.get(where.id) || null;
        if (where.quoteId) {
          for (const p of paymentsStore.values()) {
            if (p.quoteId === where.quoteId) return p;
          }
        }
        if (where.bookingId) {
          for (const p of paymentsStore.values()) {
            if (p.bookingId === where.bookingId) return p;
          }
        }
        if (where.providerOrderId) {
          for (const p of paymentsStore.values()) {
            if (p.providerOrderId === where.providerOrderId) return p;
          }
        }
        if (where.providerPaymentId) {
          for (const p of paymentsStore.values()) {
            if (p.providerPaymentId === where.providerPaymentId) return p;
          }
        }
        return null;
      }),
      create: jest.fn((dto: any) => ({ ...dto, createdAt: new Date(), updatedAt: new Date() })),
      save: jest.fn(async (entity: PaymentEntity) => {
        paymentsStore.set(entity.id, { ...entity, updatedAt: new Date() });
        return entity;
      }),
      count: jest.fn(async () => paymentsStore.size),
    };

    // Mock Booking Repository
    mockBookingRepo = {
      findOne: jest.fn(async ({ where }: any) => {
        if (where.id) return bookingsStore.get(where.id) || null;
        return null;
      }),
      find: jest.fn(async ({ where }: any) => {
        const results: BookingEntity[] = [];
        for (const b of bookingsStore.values()) {
          if (!where?.userId || b.userId === where.userId) {
            if (!where?.status || b.status === where.status) {
              results.push(b);
            }
          }
        }
        return results;
      }),
      createQueryBuilder: jest.fn(() => ({
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getOne: jest.fn(async () => null),
        getMany: jest.fn(async () => []),
        getCount: jest.fn(async () => 0),
      })),
      create: jest.fn((dto: any) => ({ ...dto, createdAt: new Date(), updatedAt: new Date() })),
      save: jest.fn(async (entity: BookingEntity) => {
        bookingsStore.set(entity.id, { ...entity, updatedAt: new Date() });
        return entity;
      }),
      count: jest.fn(async () => bookingsStore.size),
    };

    // Mock User Repository
    mockUserRepo = {
      findOne: jest.fn(async ({ where }: any) => {
        if (where.id) return usersStore.get(where.id) || null;
        return null;
      }),
      save: jest.fn(async (entity: User) => {
        usersStore.set(entity.id, { ...entity });
        return entity;
      }),
      count: jest.fn(async () => usersStore.size),
    };

    // Mock Event Repository
    mockEventRepo = {
      create: jest.fn((dto: any) => ({ ...dto })),
      findOne: jest.fn(async ({ where }: any) => {
        if (where.id) return eventsStore.get(where.id) || null;
        return null;
      }),
      save: jest.fn(async (entity: EventEntity) => {
        eventsStore.set(entity.id, { ...entity });
        return entity;
      }),
    };

    // Mock Activity Repository
    mockActivityRepo = {
      create: jest.fn((dto: any) => ({ ...dto })),
      findOne: jest.fn(async ({ where }: any) => {
        if (where.id) return activitiesStore.get(where.id) || null;
        return null;
      }),
      save: jest.fn(async (entity: ActivityEntity) => {
        activitiesStore.set(entity.id, { ...entity });
        return entity;
      }),
    };

    // Mock Product Repository
    mockProductRepo = {
      create: jest.fn((dto: any) => ({ ...dto })),
      findOne: jest.fn(async ({ where }: any) => {
        if (where.id) return productsStore.get(where.id) || null;
        return null;
      }),
      save: jest.fn(async (entity: ProductEntity) => {
        productsStore.set(entity.id, { ...entity });
        return entity;
      }),
    };

    // Mock Restaurant Repository
    mockRestaurantRepo = {
      create: jest.fn((dto: any) => ({ ...dto })),
      findOne: jest.fn(async ({ where }: any) => {
        if (where.id) return restaurantsStore.get(where.id) || null;
        return null;
      }),
      save: jest.fn(async (entity: RestaurantEntity) => {
        restaurantsStore.set(entity.id, { ...entity });
        return entity;
      }),
    };

    // Mock DataSource
    mockDataSource = {
      getRepository: jest.fn((entityTarget: any) => {
        if (entityTarget === BookingEntity || entityTarget?.name === 'BookingEntity') return mockBookingRepo;
        if (entityTarget === PaymentEntity || entityTarget?.name === 'PaymentEntity') return mockPaymentRepo;
        if (entityTarget === User || entityTarget?.name === 'User') return mockUserRepo;
        if (entityTarget === EventEntity || entityTarget?.name === 'EventEntity') return mockEventRepo;
        if (entityTarget === ActivityEntity || entityTarget?.name === 'ActivityEntity') return mockActivityRepo;
        if (entityTarget === ProductEntity || entityTarget?.name === 'ProductEntity') return mockProductRepo;
        if (entityTarget === RestaurantEntity || entityTarget?.name === 'RestaurantEntity') return mockRestaurantRepo;
        if (entityTarget === IdempotencyRecordEntity || entityTarget?.name === 'IdempotencyRecordEntity') return mockIdempRepo;
        return null;
      }),
      transaction: jest.fn(async (cb: any) => {
        const manager = {
          getRepository: (target: any) => mockDataSource.getRepository(target),
          findOne: async (target: any, options: any) => mockDataSource.getRepository(target)?.findOne(options),
          save: async (target: any, entity?: any) => {
            if (entity) {
              return mockDataSource.getRepository(target)?.save(entity);
            }
            return mockDataSource.getRepository(target.constructor)?.save(target);
          },
        };
        return cb(manager);
      }),
    };

    // Notification SMS Adapter Mock
    smsAdapter = {
      sendSms: jest.fn(async (options: { to: string; message: string }) => {
        smsLog.push(options);
        return { success: true, messageId: `SM_TEST_${Date.now()}` };
      }),
    } as any;

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
    );

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
    );

    bookingsService = new BookingsService(mockDataSource, paymentService);
    bookingsController = new BookingsController(bookingsService, idempotencyService);
    adminService = new AdminService(
      mockUserRepo,
      {} as any,
      {} as any,
      {} as any,
      mockEventRepo,
      mockActivityRepo,
      mockProductRepo,
      {} as any,
      {} as any,
      mockBookingRepo,
      { create: jest.fn((d) => d), save: jest.fn() } as any,
      {} as any,
      {} as any,
      mockPaymentRepo,
      {} as any,
      {} as any,
      paymentService,
    );
  });

  // =========================================================================
  // Section 1: Core Idempotency Engine & Fingerprinting (Tests 1–6)
  // =========================================================================
  describe('1. Core Idempotency Engine & Request Fingerprinting', () => {
    it('Test 1: Same key + same payload -> returns identical cached response with idempotentReplay: true', async () => {
      const payload = { quoteId: 'QUO_100', bookingId: 'BK_100', paymentMethod: 'UPI' };
      let executionCount = 0;

      const result1 = await idempotencyService.execute(
        'usr_alice',
        'key_test_1',
        '/payments/orders',
        payload,
        async () => {
          executionCount++;
          return { orderId: 'order_100', amount: 500 };
        },
        { operation: 'payment:create' },
      );

      expect(executionCount).toBe(1);
      expect(result1.orderId).toBe('order_100');
      expect((result1 as any).idempotentReplay).toBeUndefined();

      // Repeat with same key and payload
      const result2 = await idempotencyService.execute(
        'usr_alice',
        'key_test_1',
        '/payments/orders',
        payload,
        async () => {
          executionCount++;
          return { orderId: 'order_999', amount: 999 };
        },
        { operation: 'payment:create' },
      );

      expect(executionCount).toBe(1); // Not re-executed
      expect(result2.orderId).toBe('order_100');
      expect((result2 as any).idempotentReplay).toBe(true);
    });

    it('Test 2: Same key + different request payload -> throws 409 ConflictException', async () => {
      const payload1 = { quoteId: 'QUO_A', amount: 100 };
      const payload2 = { quoteId: 'QUO_B', amount: 200 };

      await idempotencyService.save('usr_alice', 'key_conflict_1', '/payments/orders', { orderId: 'order_A' }, {
        requestPayload: payload1,
        operation: 'payment:create',
      });

      await expect(
        idempotencyService.get('usr_alice', 'key_conflict_1', payload2),
      ).rejects.toThrow(ConflictException);
    });

    it('Test 3: Concurrent identical requests -> single canonical operation executed safely', async () => {
      let runCount = 0;
      const work = async () => {
        runCount++;
        return { status: 'OK', ts: 12345 };
      };

      const [resA, resB] = await Promise.all([
        idempotencyService.execute('usr_alice', 'key_concurrent_1', '/test', { item: 'sample' }, work),
        idempotencyService.execute('usr_alice', 'key_concurrent_1', '/test', { item: 'sample' }, work),
      ]);

      expect(resA.status).toBe('OK');
      expect(resB.status).toBe('OK');
      expect(runCount).toBe(1);
    });

    it('Test 4: Different users using the same idempotency key -> isolated namespaces', async () => {
      const payload = { action: 'book' };

      const resUserA = await idempotencyService.execute('usr_alice', 'shared_uuid_999', '/book', payload, async () => {
        return { owner: 'Alice', token: 'TOK_A' };
      });

      const resUserB = await idempotencyService.execute('usr_bob', 'shared_uuid_999', '/book', payload, async () => {
        return { owner: 'Bob', token: 'TOK_B' };
      });

      expect(resUserA.owner).toBe('Alice');
      expect(resUserB.owner).toBe('Bob');
      expect(resUserA.token).not.toBe(resUserB.token);
    });

    it('Test 5: SHA-256 fingerprint generation is deterministic regardless of object key order', () => {
      const obj1 = { z: 1, a: 2, m: { nestedB: 'hello', nestedA: 'world' } };
      const obj2 = { a: 2, m: { nestedA: 'world', nestedB: 'hello' }, z: 1 };

      const hash1 = idempotencyService.computeFingerprint(obj1);
      const hash2 = idempotencyService.computeFingerprint(obj2);

      expect(hash1).toBe(hash2);
      expect(hash1).toHaveLength(64);
    });

    it('Test 6: Safe error handling on failed execution marks record as FAILED without caching false success', async () => {
      const payload = { action: 'fail' };

      await expect(
        idempotencyService.execute('usr_alice', 'key_fail_test', '/test', payload, async () => {
          throw new BadRequestException('Simulated execution failure');
        }),
      ).rejects.toThrow(BadRequestException);

      const record = idempotencyStore.get('usr_alice:key_fail_test');
      expect(record).toBeDefined();
      expect(record?.status).toBe('FAILED');
      expect(record?.failureReason).toBe('Simulated execution failure');
    });
  });

  // =========================================================================
  // Section 2: Payment Order Creation Idempotency (Tests 7–13)
  // =========================================================================
  describe('2. Payment Order Creation Idempotency', () => {
    let testQuote: any;

    beforeEach(() => {
      testQuote = paymentService.registerQuote(
        {
          quoteId: 'QUO_MOV_777',
          type: 'movie',
          vertical: 'movie',
          items: [{ name: 'Kalki 2898 AD', quantity: 1, price: 450 }],
          subtotal: 450,
          discount: 0,
          taxes: 23,
          tax: 23,
          convenienceFee: 70,
          fees: 70,
          rewardsEarned: 54,
          total: 543,
          grandTotal: 543,
          currency: 'INR',
          expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
          breakdown: {},
        } as any,
        { userId: 'usr_alice' },
      );
    });

    it('Test 7: Order creation with idempotency key creates order successfully', async () => {
      const order = await paymentService.createPaymentOrder({
        quoteId: 'QUO_MOV_777',
        bookingId: 'BK_TEST_7',
        userId: 'usr_alice',
        idempotencyKey: 'idemp_order_7',
      });

      expect(order.orderId).toBeDefined();
      expect(order.amount).toBe(543);
      expect(order.amountInMinorUnits).toBe(54300);
      expect(order.idempotentReplay).toBe(false);
    });

    it('Test 8: Order creation replay with same key & payload -> returns cached order without duplicate provider creation', async () => {
      const order1 = await paymentService.createPaymentOrder({
        quoteId: 'QUO_MOV_777',
        bookingId: 'BK_TEST_8',
        userId: 'usr_alice',
        idempotencyKey: 'idemp_order_8',
      });

      const order2 = await paymentService.createPaymentOrder({
        quoteId: 'QUO_MOV_777',
        bookingId: 'BK_TEST_8',
        userId: 'usr_alice',
        idempotencyKey: 'idemp_order_8',
      });

      expect(order2.orderId).toBe(order1.orderId);
      expect(order2.paymentId).toBe(order1.paymentId);
      expect(order2.idempotentReplay).toBe(true);
    });

    it('Test 9: Order creation replay with same key but different bookingId/quoteId -> throws 409 ConflictException', async () => {
      await paymentService.createPaymentOrder({
        quoteId: 'QUO_MOV_777',
        bookingId: 'BK_TEST_9A',
        paymentMethod: 'UPI_FAST',
        userId: 'usr_alice',
        idempotencyKey: 'idemp_order_9',
      });

      await expect(
        paymentService.createPaymentOrder({
          quoteId: 'QUO_MOV_777',
          bookingId: 'BK_TEST_9A',
          paymentMethod: 'NET_BANKING', // Different payment method parameter under same key
          userId: 'usr_alice',
          idempotencyKey: 'idemp_order_9',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('Test 10: Missing idempotency key auto-generates composite key and creates order safely', async () => {
      const order = await paymentService.createPaymentOrder({
        quoteId: 'QUO_MOV_777',
        userId: 'usr_alice',
      });

      expect(order.orderId).toBeDefined();
      expect(order.paymentId).toBeDefined();
    });

    it('Test 11: Duplicate order creation on already CAPTURED payment -> rejected with PAYMENT_ALREADY_CAPTURED', async () => {
      const payment = mockPaymentRepo.create({
        id: 'PAY_CAPTURED_11',
        quoteId: 'QUO_MOV_777',
        bookingId: 'BK_11',
        userId: 'usr_alice',
        amount: 543,
        currency: 'INR',
        provider: 'simulated',
        providerOrderId: 'order_sim_11',
        status: PaymentStatus.CAPTURED,
      });
      paymentsStore.set(payment.id, payment);

      await expect(
        paymentService.createPaymentOrder({
          quoteId: 'QUO_MOV_777',
          userId: 'usr_alice',
          idempotencyKey: 'idemp_order_11',
        }),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.PAYMENT_ALREADY_CAPTURED));
    });

    it('Test 12: Order creation replay returns same minor unit paise value snapshot', async () => {
      const order = await paymentService.createPaymentOrder({
        quoteId: 'QUO_MOV_777',
        userId: 'usr_alice',
        idempotencyKey: 'idemp_order_12',
      });

      expect(order.amountInMinorUnits).toBe(54300);
      expect(order.amount).toBe(543);
    });

    it('Test 13: Order creation replay does not mutate or overwrite existing payment entity', async () => {
      const order1 = await paymentService.createPaymentOrder({
        quoteId: 'QUO_MOV_777',
        userId: 'usr_alice',
        idempotencyKey: 'idemp_order_13',
      });

      const initialRecord = paymentsStore.get(order1.paymentId);
      const initialCreatedAt = initialRecord?.createdAt;

      await paymentService.createPaymentOrder({
        quoteId: 'QUO_MOV_777',
        userId: 'usr_alice',
        idempotencyKey: 'idemp_order_13',
      });

      const afterRecord = paymentsStore.get(order1.paymentId);
      expect(afterRecord?.id).toBe(initialRecord?.id);
      expect(afterRecord?.createdAt).toEqual(initialCreatedAt);
    });
  });

  // =========================================================================
  // Section 3: Payment Verification Idempotency & Replays (Tests 14–19)
  // =========================================================================
  describe('3. Payment Verification Idempotency & Replay Protection', () => {
    let booking: BookingEntity;
    let payment: PaymentEntity;
    let orderId: string;
    let paymentId: string;
    let validSignature: string;

    beforeEach(() => {
      orderId = 'order_test_ver_14';
      paymentId = 'pay_test_ver_14';
      validSignature = signOrderPayment(orderId, paymentId);

      booking = mockBookingRepo.create({
        id: 'BK_VER_14',
        userId: 'usr_alice',
        type: BookingType.MOVIE,
        title: 'Kalki 2898 AD',
        status: BookingStatus.PENDING,
        totalPrice: 543,
        metadata: {},
      });
      bookingsStore.set(booking.id, booking);

      payment = mockPaymentRepo.create({
        id: 'PAY_VER_14',
        bookingId: booking.id,
        userId: 'usr_alice',
        amount: 543,
        currency: 'INR',
        provider: 'razorpay',
        providerOrderId: orderId,
        status: PaymentStatus.PENDING,
        metadata: {},
      });
      paymentsStore.set(payment.id, payment);
    });

    it('Test 14: Initial payment verification with valid signature succeeds', async () => {
      const result = await paymentsController.verifyPayment(
        {
          bookingId: booking.id,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: validSignature,
        },
        { user: { id: 'usr_alice' } },
        'idemp_verify_14',
      );

      expect(result.success).toBe(true);
      expect(result.status).toBe(PaymentStatus.CAPTURED);
      expect((result as any).idempotentReplay).toBeUndefined();
      expect(booking.status).toBe(BookingStatus.UPCOMING);
      expect(payment.status).toBe(PaymentStatus.CAPTURED);
    });

    it('Test 15: Verification replay with same key & payload returns cached verification with idempotentReplay: true', async () => {
      await paymentsController.verifyPayment(
        {
          bookingId: booking.id,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: validSignature,
        },
        { user: { id: 'usr_alice' } },
        'idemp_verify_15',
      );

      const replay = await paymentsController.verifyPayment(
        {
          bookingId: booking.id,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: validSignature,
        },
        { user: { id: 'usr_alice' } },
        'idemp_verify_15',
      );

      expect(replay.success).toBe(true);
      expect(replay.idempotentReplay).toBe(true);
    });

    it('Test 16: Verification replay with same key but different paymentId -> throws 409 ConflictException', async () => {
      await paymentsController.verifyPayment(
        {
          bookingId: booking.id,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: validSignature,
        },
        { user: { id: 'usr_alice' } },
        'idemp_verify_16',
      );

      await expect(
        paymentsController.verifyPayment(
          {
            bookingId: booking.id,
            razorpayOrderId: orderId,
            razorpayPaymentId: 'pay_different_attempt',
            razorpaySignature: validSignature,
          },
          { user: { id: 'usr_alice' } },
          'idemp_verify_16',
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('Test 17: Replay verification on already CAPTURED payment -> idempotent success without double state change', async () => {
      payment.status = PaymentStatus.CAPTURED;
      payment.providerPaymentId = paymentId;
      booking.status = BookingStatus.UPCOMING;
      booking.metadata = { paymentVerified: true, payment: { paymentId, orderId } };

      const result = await paymentsController.verifyPayment(
        {
          bookingId: booking.id,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: validSignature,
        },
        { user: { id: 'usr_alice' } },
      );

      expect(result.success).toBe(true);
      expect(result.idempotentReplay).toBe(true);
    });

    it('Test 18: Replay verification does NOT award duplicate reward points', async () => {
      const pointsBefore = usersStore.get('usr_alice')!.rewardPoints;

      // 1st verification
      await paymentsController.verifyPayment(
        {
          bookingId: booking.id,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: validSignature,
        },
        { user: { id: 'usr_alice' } },
        'idemp_rewards_18',
      );

      const pointsAfterFirst = usersStore.get('usr_alice')!.rewardPoints;
      expect(pointsAfterFirst).toBeGreaterThan(pointsBefore);

      // 2nd verification replay
      await paymentsController.verifyPayment(
        {
          bookingId: booking.id,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: validSignature,
        },
        { user: { id: 'usr_alice' } },
        'idemp_rewards_18',
      );

      const pointsAfterSecond = usersStore.get('usr_alice')!.rewardPoints;
      expect(pointsAfterSecond).toBe(pointsAfterFirst); // No duplicate award!
    });

    it('Test 19: Replay verification does NOT dispatch duplicate SMS notifications', async () => {
      expect(smsLog.length).toBe(0);

      // 1st verification
      await paymentsController.verifyPayment(
        {
          bookingId: booking.id,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: validSignature,
        },
        { user: { id: 'usr_alice' } },
        'idemp_sms_19',
      );
      expect(smsLog.length).toBe(1);

      // 2nd verification replay
      await paymentsController.verifyPayment(
        {
          bookingId: booking.id,
          razorpayOrderId: orderId,
          razorpayPaymentId: paymentId,
          razorpaySignature: validSignature,
        },
        { user: { id: 'usr_alice' } },
        'idemp_sms_19',
      );
      expect(smsLog.length).toBe(1); // No duplicate SMS dispatched!
    });
  });

  // =========================================================================
  // Section 4: Refund Idempotency & Financial Hardening (Tests 20–30)
  // =========================================================================
  describe('4. Refund Idempotency & Financial Hardening', () => {
    let capturedPayment: PaymentEntity;

    beforeEach(() => {
      capturedPayment = mockPaymentRepo.create({
        id: 'PAY_CAPTURED_REF',
        bookingId: 'BK_REF_20',
        userId: 'usr_alice',
        amount: 1000,
        currency: 'INR',
        provider: 'simulated',
        providerOrderId: 'order_sim_ref',
        providerPaymentId: 'pay_sim_ref',
        status: PaymentStatus.CAPTURED,
        refundAmount: 0,
      });
      paymentsStore.set(capturedPayment.id, capturedPayment);
    });

    it('Test 20: Refund processing transitions payment CAPTURED -> REFUND_PENDING -> REFUNDED', async () => {
      const refund = await paymentService.processRefund(
        capturedPayment.id,
        1000,
        'Customer requested refund',
        { idempotencyKey: 'idemp_refund_20' },
      );

      expect(refund.refundId).toBeDefined();
      expect(refund.status).toBe('REFUNDED');
      expect(capturedPayment.status).toBe(PaymentStatus.REFUNDED);
      expect(capturedPayment.refundAmount).toBe(1000);
    });

    it('Test 21: Refund replay with same key returns cached refund with idempotentReplay: true without calling provider', async () => {
      const refund1 = await paymentService.processRefund(
        capturedPayment.id,
        1000,
        'Customer requested refund',
        { idempotencyKey: 'idemp_refund_21' },
      );

      const refund2 = await paymentService.processRefund(
        capturedPayment.id,
        1000,
        'Customer requested refund',
        { idempotencyKey: 'idemp_refund_21' },
      );

      expect(refund2.refundId).toBe(refund1.refundId);
      expect(refund2.idempotentReplay).toBe(true);
    });

    it('Test 22: Refund replay with same key but different amount -> throws 409 ConflictException', async () => {
      await paymentService.processRefund(
        capturedPayment.id,
        500,
        'Partial refund',
        { idempotencyKey: 'idemp_refund_22' },
      );

      await expect(
        paymentService.processRefund(
          capturedPayment.id,
          600, // Different amount
          'Partial refund',
          { idempotencyKey: 'idemp_refund_22' },
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('Test 23: Refund exceeding total payment balance -> rejected with REFUND_AMOUNT_INVALID', async () => {
      await expect(
        paymentService.processRefund(capturedPayment.id, 1500, 'Over refund'),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.REFUND_AMOUNT_INVALID));
    });

    it('Test 24: Refund with negative or zero amount -> rejected with REFUND_AMOUNT_INVALID', async () => {
      await expect(
        paymentService.processRefund(capturedPayment.id, 0, 'Zero refund'),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.REFUND_AMOUNT_INVALID));

      await expect(
        paymentService.processRefund(capturedPayment.id, -100, 'Negative refund'),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.REFUND_AMOUNT_INVALID));
    });

    it('Test 25: Refund on payment in FAILED or PENDING state -> rejected with INVALID_PAYMENT_STATE_TRANSITION', async () => {
      const failedPayment = mockPaymentRepo.create({
        id: 'PAY_FAILED_25',
        amount: 500,
        currency: 'INR',
        provider: 'simulated',
        status: PaymentStatus.FAILED,
      });
      paymentsStore.set(failedPayment.id, failedPayment);

      await expect(
        paymentService.processRefund(failedPayment.id, 500, 'Refund failed payment'),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.INVALID_PAYMENT_STATE_TRANSITION));
    });

    it('Test 26: Multiple partial refunds up to full total amount succeed', async () => {
      const refund1 = await paymentService.processRefund(capturedPayment.id, 400, 'Partial 1', {
        idempotencyKey: 'idemp_partial_1',
      });
      expect(refund1.status).toBe('REFUNDED');
      expect(paymentsStore.get(capturedPayment.id)!.refundAmount).toBe(400);

      const refund2 = await paymentService.processRefund(capturedPayment.id, 600, 'Partial 2', {
        idempotencyKey: 'idemp_partial_2',
      });
      expect(refund2.status).toBe('REFUNDED');
      expect(paymentsStore.get(capturedPayment.id)!.refundAmount).toBe(1000);
    });

    it('Test 27: Excessive partial refund (exceeding remaining balance) -> rejected', async () => {
      await paymentService.processRefund(capturedPayment.id, 700, 'Partial 1', {
        idempotencyKey: 'idemp_partial_27a',
      });

      await expect(
        paymentService.processRefund(capturedPayment.id, 400, 'Partial 2 exceeds by 100', {
          idempotencyKey: 'idemp_partial_27b',
        }),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.REFUND_AMOUNT_INVALID));
    });

    it('Test 28: Refund on already fully REFUNDED payment -> returns existing refund idempotently', async () => {
      await paymentService.processRefund(capturedPayment.id, 1000, 'Full refund', {
        idempotencyKey: 'idemp_full_28',
      });
      expect(paymentsStore.get(capturedPayment.id)!.status).toBe(PaymentStatus.REFUNDED);

      const repeatRefund = await paymentService.processRefund(capturedPayment.id, 1000, 'Full refund', {
        idempotencyKey: 'idemp_full_28',
      });
      expect(repeatRefund.refundId).toBe(paymentsStore.get(capturedPayment.id)!.refundId);
      expect(repeatRefund.idempotentReplay).toBe(true);
    });

    it('Test 29: Admin refund with idempotency -> cancels booking, refunds payment, and does not double-cancel on retry', async () => {
      const booking = mockBookingRepo.create({
        id: 'BK_ADMIN_REF_29',
        userId: 'usr_alice',
        status: BookingStatus.UPCOMING,
        totalPrice: 1000,
      });
      bookingsStore.set(booking.id, booking);
      capturedPayment.bookingId = booking.id;

      const actor = { id: 'usr_admin', email: 'admin@plaza.test' };
      const res1 = await adminService.refundBooking(
        booking.id,
        { reason: 'Customer requested cancellation' },
        actor,
        { idempotencyKey: 'idemp_admin_29' },
      );

      expect(res1.success).toBe(true);
      expect(booking.status).toBe(BookingStatus.CANCELLED);
      expect(capturedPayment.status).toBe(PaymentStatus.REFUNDED);

      // Replay admin refund
      const res2 = await adminService.refundBooking(
        booking.id,
        { reason: 'Customer requested cancellation' },
        actor,
        { idempotencyKey: 'idemp_admin_29' },
      );

      expect(res2.success).toBe(true);
      expect(res2.idempotentReplay).toBe(true);
    });

    it('Test 30: Booking cancellation with idempotency -> refunds payment and returns cancelled booking idempotently', async () => {
      const booking = mockBookingRepo.create({
        id: 'BK_CANCEL_30',
        userId: 'usr_alice',
        status: BookingStatus.UPCOMING,
        totalPrice: 1000,
        metadata: {
          payment: { paymentId: capturedPayment.id },
          rewardAwarded: true,
          rewardPoints: 100,
        },
      });
      bookingsStore.set(booking.id, booking);

      const initialUserPoints = usersStore.get('usr_alice')!.rewardPoints;

      // 1st cancellation
      const cancel1 = await bookingsService.cancel(booking.id, 'usr_alice', {
        idempotencyKey: 'idemp_cancel_30',
      });
      expect(cancel1.status).toBe(BookingStatus.CANCELLED);
      expect(capturedPayment.status).toBe(PaymentStatus.REFUNDED);
      expect(usersStore.get('usr_alice')!.rewardPoints).toBe(initialUserPoints - 100);

      // 2nd cancellation replay
      const cancel2 = await bookingsService.cancel(booking.id, 'usr_alice', {
        idempotencyKey: 'idemp_cancel_30',
      });
      expect(cancel2.status).toBe(BookingStatus.CANCELLED);
      // Points should NOT be subtracted again
      expect(usersStore.get('usr_alice')!.rewardPoints).toBe(initialUserPoints - 100);
    });
  });

  // =========================================================================
  // Section 5: Booking Creation & Lifecycle Idempotency (Tests 31–36)
  // =========================================================================
  describe('5. Booking Creation & Lifecycle Idempotency', () => {
    it('Test 31: Dining reservation creation with idempotency key succeeds', async () => {
      const body = {
        restaurantId: 'rest_jewel',
        date: '2026-10-20',
        timeSlot: '19:00',
        partySize: 4,
      };

      const booking = await bookingsController.createDiningReservation(
        { user: { id: 'usr_alice' } },
        'idemp_dining_31',
        body,
      );

      expect(booking.id).toBeDefined();
      expect(booking.type).toBe(BookingType.DINING);
    });

    it('Test 32: Dining reservation replay with same key returns cached booking', async () => {
      const body = {
        restaurantId: 'rest_jewel',
        date: '2026-10-20',
        timeSlot: '19:00',
        partySize: 4,
      };

      const booking1 = await bookingsController.createDiningReservation(
        { user: { id: 'usr_alice' } },
        'idemp_dining_32',
        body,
      );

      const booking2 = await bookingsController.createDiningReservation(
        { user: { id: 'usr_alice' } },
        'idemp_dining_32',
        body,
      );

      expect(booking2.id).toBe(booking1.id);
      expect((booking2 as any).idempotentReplay).toBe(true);
    });

    it('Test 33: Dining reservation replay with altered payload -> throws 409 ConflictException', async () => {
      const body1 = {
        restaurantId: 'rest_jewel',
        date: '2026-10-20',
        timeSlot: '19:00',
        partySize: 4,
      };
      const body2 = {
        restaurantId: 'rest_jewel',
        date: '2026-10-20',
        timeSlot: '20:00', // Altered time
        partySize: 4,
      };

      await bookingsController.createDiningReservation(
        { user: { id: 'usr_alice' } },
        'idemp_dining_33',
        body1,
      );

      await expect(
        bookingsController.createDiningReservation(
          { user: { id: 'usr_alice' } },
          'idemp_dining_33',
          body2,
        ),
      ).rejects.toThrow(ConflictException);
    });

    it('Test 34: Shopping order idempotency replay does not deduct product inventory twice', async () => {
      const product = mockProductRepo.create({
        id: 'prod_100',
        name: 'Plaza Hoodie',
        price: 1500,
        stock: 10,
        inStock: true,
        isPublished: true,
      });
      productsStore.set(product.id, product);

      const quote = await bookingsService.calculateQuote('shopping', {
        items: [{ productId: 'prod_100', quantity: 2 }],
      }, 'usr_alice');

      const body = {
        items: [{ productId: 'prod_100', quantity: 2 }],
        fulfillmentType: 'DELIVERY',
        quoteId: quote.quoteId,
      };

      // 1st order creation
      const order1 = await bookingsController.createShoppingOrder(
        { user: { id: 'usr_alice' } },
        'idemp_shop_34',
        body,
      );
      expect(order1.id).toBeDefined();
      expect(productsStore.get('prod_100')!.stock).toBe(8); // 10 - 2 = 8

      // 2nd order creation replay
      const order2 = await bookingsController.createShoppingOrder(
        { user: { id: 'usr_alice' } },
        'idemp_shop_34',
        body,
      );
      expect(order2.id).toBe(order1.id);
      expect(productsStore.get('prod_100')!.stock).toBe(8); // Stock remains 8!
    });

    it('Test 35: Event booking idempotency replay does not decrement ticket tier count twice', async () => {
      const event = mockEventRepo.create({
        id: 'evt_concert_1',
        title: 'Sunburn Arena',
        eventDate: '2026-11-01',
        time: '18:00',
        venue: 'Gachibowli Stadium',
        location: 'Hyderabad',
        ticketTiers: [{ id: 'tier_vip', name: 'VIP', price: 2500, remainingCount: 50 }],
      });
      eventsStore.set(event.id, event);

      const quote = await bookingsService.calculateQuote('event', {
        eventId: 'evt_concert_1',
        tierId: 'tier_vip',
        ticketCount: 2,
      }, 'usr_alice');

      const body = {
        eventId: 'evt_concert_1',
        tierId: 'tier_vip',
        ticketCount: 2,
        quoteId: quote.quoteId,
      };

      // 1st booking
      const book1 = await bookingsController.createEventBooking(
        { user: { id: 'usr_alice' } },
        'idemp_evt_35',
        body,
      );
      expect(book1.id).toBeDefined();
      expect(eventsStore.get('evt_concert_1')!.ticketTiers[0].remainingCount).toBe(48); // 50 - 2

      // 2nd booking replay
      const book2 = await bookingsController.createEventBooking(
        { user: { id: 'usr_alice' } },
        'idemp_evt_35',
        body,
      );
      expect(book2.id).toBe(book1.id);
      expect(eventsStore.get('evt_concert_1')!.ticketTiers[0].remainingCount).toBe(48); // Still 48!
    });

    it('Test 36: Activity booking idempotency replay does not deduct available slots twice', async () => {
      const activity = mockActivityRepo.create({
        id: 'act_gokart_1',
        title: 'Go-Karting Pro',
        location: 'Hyderabad',
        isPublished: true,
        packages: [{ id: 'pkg_10laps', name: '10 Laps', pricePerPerson: 800 }],
        timeSlots: [{ time: '16:00', availableSlots: 20, isFillingFast: false }],
      });
      activitiesStore.set(activity.id, activity);

      const quote = await bookingsService.calculateQuote('activity', {
        activityId: 'act_gokart_1',
        packageId: 'pkg_10laps',
        numberOfPeople: 3,
        timeSlot: '16:00',
      }, 'usr_alice');

      const body = {
        activityId: 'act_gokart_1',
        packageId: 'pkg_10laps',
        date: '2026-10-25',
        timeSlot: '16:00',
        numberOfPeople: 3,
        quoteId: quote.quoteId,
      };

      // 1st booking
      const book1 = await bookingsController.createActivityBooking(
        { user: { id: 'usr_alice' } },
        'idemp_act_36',
        body,
      );
      expect(book1.id).toBeDefined();
      expect(activitiesStore.get('act_gokart_1')!.timeSlots[0].availableSlots).toBe(17); // 20 - 3

      // 2nd booking replay
      const book2 = await bookingsController.createActivityBooking(
        { user: { id: 'usr_alice' } },
        'idemp_act_36',
        body,
      );
      expect(book2.id).toBe(book1.id);
      expect(activitiesStore.get('act_gokart_1')!.timeSlots[0].availableSlots).toBe(17); // Still 17!
    });
  });

  // =========================================================================
  // Section 6: Side-Effect Deduplication & Safety Verification (Tests 37–44)
  // =========================================================================
  describe('6. Side-Effect Deduplication & Safety Verification', () => {
    it('Test 37: SMS delivery is dispatched strictly once across multiple verification replays', async () => {
      const orderId = 'order_sms_37';
      const paymentId = 'pay_sms_37';
      const sig = signOrderPayment(orderId, paymentId);

      const b = mockBookingRepo.create({
        id: 'BK_SMS_37',
        userId: 'usr_alice',
        type: BookingType.MOVIE,
        title: 'Kalki 2898 AD',
        status: BookingStatus.PENDING,
        totalPrice: 500,
        metadata: {},
      });
      bookingsStore.set(b.id, b);

      const p = mockPaymentRepo.create({
        id: 'PAY_SMS_37',
        bookingId: b.id,
        userId: 'usr_alice',
        amount: 500,
        currency: 'INR',
        provider: 'razorpay',
        providerOrderId: orderId,
        status: PaymentStatus.PENDING,
      });
      paymentsStore.set(p.id, p);

      for (let i = 0; i < 5; i++) {
        await paymentsController.verifyPayment(
          {
            bookingId: b.id,
            razorpayOrderId: orderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: sig,
          },
          { user: { id: 'usr_alice' } },
          'idemp_sms_37',
        );
      }

      expect(smsLog.length).toBe(1); // Exactly 1 SMS
    });

    it('Test 38: Reward points are credited strictly once across multiple verification replays', async () => {
      const orderId = 'order_rew_38';
      const paymentId = 'pay_rew_38';
      const sig = signOrderPayment(orderId, paymentId);

      const b = mockBookingRepo.create({
        id: 'BK_REW_38',
        userId: 'usr_alice',
        type: BookingType.MOVIE,
        title: 'Kalki 2898 AD',
        status: BookingStatus.PENDING,
        totalPrice: 1000,
        metadata: {},
      });
      bookingsStore.set(b.id, b);

      const p = mockPaymentRepo.create({
        id: 'PAY_REW_38',
        bookingId: b.id,
        userId: 'usr_alice',
        amount: 1000,
        currency: 'INR',
        provider: 'razorpay',
        providerOrderId: orderId,
        status: PaymentStatus.PENDING,
      });
      paymentsStore.set(p.id, p);

      const initialPoints = usersStore.get('usr_alice')!.rewardPoints;

      for (let i = 0; i < 3; i++) {
        await paymentsController.verifyPayment(
          {
            bookingId: b.id,
            razorpayOrderId: orderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: sig,
          },
          { user: { id: 'usr_alice' } },
          'idemp_rew_38',
        );
      }

      // 10% of 1000 = 100 points
      expect(usersStore.get('usr_alice')!.rewardPoints).toBe(initialPoints + 100);
    });

    it('Test 39: Reward points are reversed strictly once across multiple cancellation replays', async () => {
      const b = mockBookingRepo.create({
        id: 'BK_REV_39',
        userId: 'usr_alice',
        status: BookingStatus.UPCOMING,
        totalPrice: 500,
        metadata: {
          rewardAwarded: true,
          rewardPoints: 50,
        },
      });
      bookingsStore.set(b.id, b);

      const pointsBefore = usersStore.get('usr_alice')!.rewardPoints;

      for (let i = 0; i < 3; i++) {
        await bookingsService.cancel(b.id, 'usr_alice', { idempotencyKey: 'idemp_cancel_39' });
      }

      expect(usersStore.get('usr_alice')!.rewardPoints).toBe(pointsBefore - 50);
    });

    it('Test 40: Event ticket count is restored strictly once across cancellation replays', async () => {
      const event = mockEventRepo.create({
        id: 'evt_test_40',
        ticketTiers: [{ id: 'tier_ga', name: 'General', price: 1000, remainingCount: 10 }],
      });
      eventsStore.set(event.id, event);

      const b = mockBookingRepo.create({
        id: 'BK_EVT_40',
        userId: 'usr_alice',
        type: BookingType.EVENT,
        status: BookingStatus.UPCOMING,
        totalPrice: 2000,
        metadata: {
          eventId: 'evt_test_40',
          tierId: 'tier_ga',
          ticketCount: 2,
        },
      });
      bookingsStore.set(b.id, b);

      for (let i = 0; i < 3; i++) {
        await bookingsService.cancel(b.id, 'usr_alice', { idempotencyKey: 'idemp_cancel_40' });
      }

      // Restored 2 tickets once: 10 + 2 = 12
      expect(eventsStore.get('evt_test_40')!.ticketTiers[0].remainingCount).toBe(12);
    });

    it('Test 41: Activity spot count is restored strictly once across cancellation replays', async () => {
      const act = mockActivityRepo.create({
        id: 'act_test_41',
        timeSlots: [{ time: '14:00', availableSlots: 5, isFillingFast: false }],
      });
      activitiesStore.set(act.id, act);

      const b = mockBookingRepo.create({
        id: 'BK_ACT_41',
        userId: 'usr_alice',
        type: BookingType.ACTIVITY,
        status: BookingStatus.UPCOMING,
        totalPrice: 1500,
        metadata: {
          activityId: 'act_test_41',
          timeSlot: '14:00',
          numberOfPeople: 3,
        },
      });
      bookingsStore.set(b.id, b);

      for (let i = 0; i < 3; i++) {
        await bookingsService.cancel(b.id, 'usr_alice', { idempotencyKey: 'idemp_cancel_41' });
      }

      // Restored 3 spots once: 5 + 3 = 8
      expect(activitiesStore.get('act_test_41')!.timeSlots[0].availableSlots).toBe(8);
    });

    it('Test 42: Production Razorpay payments remain disabled (RAZORPAY_LIVE_ENABLED=false)', () => {
      const safeSummary = paymentService.getSafeConfigSummary();
      expect(safeSummary.razorpayLiveEnabled).toBe(false);
      expect(safeSummary.paymentMode).toBe('SIMULATED');
    });

    it('Test 43: No secret or key leaks exist in idempotency records, responses, or error messages', async () => {
      const payload = { quoteId: 'QUO_SECRET_CHECK' };
      const res = await idempotencyService.execute('usr_alice', 'key_leak_check', '/test', payload, async () => {
        return { data: 'safe_data' };
      });

      const resStr = JSON.stringify(res);
      expect(resStr).not.toContain('rzp_live_');
      expect(resStr).not.toContain(TEST_KEY_SECRET);

      const record = idempotencyStore.get('usr_alice:key_leak_check');
      const recStr = JSON.stringify(record);
      expect(recStr).not.toContain('rzp_live_');
      expect(recStr).not.toContain(TEST_KEY_SECRET);
    });

    it('Test 44: Database migration EnhanceIdempotencyRecordsTable1790900000000 is valid and reversible', async () => {
      const migration = new EnhanceIdempotencyRecordsTable1790900000000();
      const queriesRun: string[] = [];
      const queryRunnerMock = {
        query: jest.fn(async (q: string) => {
          queriesRun.push(q);
        }),
      };

      await migration.up(queryRunnerMock as any);
      expect(queriesRun.length).toBeGreaterThan(0);
      expect(queriesRun.some((q) => q.includes('ALTER TABLE') && q.includes('idempotency_records'))).toBe(true);

      const downQueries: string[] = [];
      const downRunnerMock = {
        query: jest.fn(async (q: string) => {
          downQueries.push(q);
        }),
      };
      await migration.down(downRunnerMock as any);
      expect(downQueries.length).toBeGreaterThan(0);
    });
  });

  // =========================================================================
  // Section 7: Payment State Machine Transitions (Tests 45–48)
  // =========================================================================
  describe('7. Payment State Machine Transitions', () => {
    it('Test 45: Valid transitions: CREATED -> PENDING -> CAPTURED -> REFUND_PENDING -> REFUNDED', () => {
      expect(() => assertValidPaymentStateTransition(PaymentStatus.CREATED, PaymentStatus.PENDING)).not.toThrow();
      expect(() => assertValidPaymentStateTransition(PaymentStatus.PENDING, PaymentStatus.CAPTURED)).not.toThrow();
      expect(() => assertValidPaymentStateTransition(PaymentStatus.CAPTURED, PaymentStatus.REFUND_PENDING)).not.toThrow();
      expect(() => assertValidPaymentStateTransition(PaymentStatus.REFUND_PENDING, PaymentStatus.REFUNDED)).not.toThrow();
    });

    it('Test 46: Invalid transitions: FAILED -> CAPTURED, REFUNDED -> CAPTURED are forbidden', () => {
      expect(() => assertValidPaymentStateTransition(PaymentStatus.FAILED, PaymentStatus.CAPTURED)).toThrow(BadRequestException);
      expect(() => assertValidPaymentStateTransition(PaymentStatus.REFUNDED, PaymentStatus.CAPTURED)).toThrow(BadRequestException);
      expect(() => assertValidPaymentStateTransition(PaymentStatus.CREATED, PaymentStatus.REFUNDED)).toThrow(BadRequestException);
    });

    it('Test 47: Valid transitions: PENDING -> AUTHORIZED -> CAPTURED', () => {
      expect(() => assertValidPaymentStateTransition(PaymentStatus.PENDING, PaymentStatus.AUTHORIZED)).not.toThrow();
      expect(() => assertValidPaymentStateTransition(PaymentStatus.AUTHORIZED, PaymentStatus.CAPTURED)).not.toThrow();
    });

    it('Test 48: Source codebase scan verifies zero hardcoded live Razorpay secrets or credentials', () => {
      const backendSrcDir = path.resolve(__dirname, '..', 'src');
      const scanDir = (dir: string): string[] => {
        let results: string[] = [];
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        for (const entry of entries) {
          const fullPath = path.join(dir, entry.name);
          if (entry.isDirectory()) {
            results = results.concat(scanDir(fullPath));
          } else if (entry.name.endsWith('.ts') && !entry.name.endsWith('.spec.ts')) {
            results.push(fullPath);
          }
        }
        return results;
      };

      const tsFiles = scanDir(backendSrcDir);
      for (const file of tsFiles) {
        const content = fs.readFileSync(file, 'utf8');
        expect(content).not.toMatch(/rzp_live_[a-zA-Z0-9]{14,}/);
        expect(content).not.toMatch(/process\.env\.RAZORPAY_LIVE_ENABLED\s*=\s*['"]?true['"]?/);
      }
    });
  });
});
