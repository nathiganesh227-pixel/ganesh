import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import {
  PaymentEntity,
  PaymentErrorCode,
  PaymentStatus,
  assertValidPaymentStateTransition,
  isValidPaymentStateTransition,
  toMinorUnits,
} from './database/entities/payment.entity';
import {
  BookingEntity,
  BookingStatus,
  BookingType,
} from './database/entities/booking.entity';
import { User } from './database/entities/user.entity';
import { MovieEntity } from './database/entities/movie.entity';
import { TheatreEntity } from './database/entities/theatre.entity';
import { SportsVenueEntity } from './database/entities/sports-venue.entity';
import { RestaurantEntity } from './database/entities/restaurant.entity';
import { HotelEntity } from './database/entities/hotel.entity';
import { ProductEntity } from './database/entities/product.entity';
import { EventEntity } from './database/entities/event.entity';
import { ActivityEntity } from './database/entities/activity.entity';
import { PaymentConfigService } from './modules/payments/payment-config.service';
import { PaymentService } from './modules/payments/payment.service';
import { PaymentsController } from './modules/payments/payments.controller';
import { WebhooksController } from './modules/payments/webhooks.controller';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { BookingsService } from './modules/bookings/bookings.service';
import { AddQuoteIdToPaymentsTable1790700000000 } from './database/migrations/1790700000000-AddQuoteIdToPaymentsTable';

describe('Phase 25.2 — Payment Order & Server-Side Verification Hardening', () => {
  const TEST_KEY_ID = 'rzp_test_plaza252keyid';
  const TEST_KEY_SECRET = 'secret_test_plaza252_hmac_key_secret';
  const TEST_WEBHOOK_SECRET = 'whsec_test_plaza252_webhook_secret';

  const originalEnv = { ...process.env };

  // In-memory mock stores
  let paymentsStore: Map<string, PaymentEntity>;
  let bookingsStore: Map<string, BookingEntity>;
  let usersStore: Map<string, User>;
  let moviesStore: Map<string, MovieEntity>;
  let theatresStore: Map<string, TheatreEntity>;
  let eventsStore: Map<string, EventEntity>;
  let sportsStore: Map<string, SportsVenueEntity>;
  let staysStore: Map<string, HotelEntity>;
  let productsStore: Map<string, ProductEntity>;
  let activitiesStore: Map<string, ActivityEntity>;
  let restaurantsStore: Map<string, RestaurantEntity>;
  let smsLog: { to: string; message: string }[];

  let paymentRepoMock: any;
  let bookingRepoMock: any;
  let userRepoMock: any;
  let dataSourceMock: any;
  let notificationAdapterMock: any;

  function buildPaymentEnv(overrides: Record<string, string | undefined> = {}) {
    delete process.env.PAYMENT_MODE;
    delete process.env.RAZORPAY_LIVE_ENABLED;
    delete process.env.RAZORPAY_KEY_ID;
    delete process.env.RAZORPAY_KEY_SECRET;
    delete process.env.RAZORPAY_WEBHOOK_SECRET;
    process.env.NODE_ENV = 'test';
    Object.assign(process.env, overrides);
  }

  function signOrderPayment(
    orderId: string,
    paymentId: string,
    secret: string = TEST_KEY_SECRET,
  ): string {
    return crypto
      .createHmac('sha256', secret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');
  }

  function createHarness(envOverrides: Record<string, string | undefined> = {}) {
    buildPaymentEnv(envOverrides);
    const configService = new PaymentConfigService(process.env);

    const razorpayAdapter = new RazorpayAdapter(configService);
    const simulatedAdapter = new SimulatedPaymentAdapter();

    const paymentService = new PaymentService(
      razorpayAdapter,
      simulatedAdapter,
      paymentRepoMock,
      configService,
    );

    const bookingsService = new BookingsService(
      dataSourceMock,
      paymentService,
    );

    const paymentsController = new PaymentsController(
      paymentService,
      razorpayAdapter,
      bookingRepoMock,
      paymentRepoMock,
      userRepoMock,
      { findOne: jest.fn(async ({ where }: any) => eventsStore.get(where.id) || null), save: jest.fn() } as any,
      { findOne: jest.fn(async ({ where }: any) => activitiesStore.get(where.id) || null), save: jest.fn() } as any,
      notificationAdapterMock,
    );

    const webhooksController = new WebhooksController(
      razorpayAdapter,
      bookingRepoMock,
      paymentRepoMock,
      userRepoMock,
      { findOne: jest.fn(async ({ where }: any) => eventsStore.get(where.id) || null), save: jest.fn() } as any,
      { findOne: jest.fn(async ({ where }: any) => activitiesStore.get(where.id) || null), save: jest.fn() } as any,
      notificationAdapterMock,
    );

    return {
      configService,
      razorpayAdapter,
      simulatedAdapter,
      paymentService,
      bookingsService,
      paymentsController,
      webhooksController,
    };
  }

  beforeEach(() => {
    paymentsStore = new Map<string, PaymentEntity>();
    bookingsStore = new Map<string, BookingEntity>();
    usersStore = new Map<string, User>();
    moviesStore = new Map<string, MovieEntity>();
    theatresStore = new Map<string, TheatreEntity>();
    eventsStore = new Map<string, EventEntity>();
    sportsStore = new Map<string, SportsVenueEntity>();
    staysStore = new Map<string, HotelEntity>();
    productsStore = new Map<string, ProductEntity>();
    activitiesStore = new Map<string, ActivityEntity>();
    restaurantsStore = new Map<string, RestaurantEntity>();
    smsLog = [];

    usersStore.set('usr_alice', {
      id: 'usr_alice',
      name: 'Alice Customer',
      email: 'alice@plaza.app',
      phone: '+919876543210',
      avatarUrl: '',
      city: 'Hyderabad',
      rewardPoints: 500,
      tier: 'GOLD',
      role: 'user' as any,
      preferences: {},
      createdAt: new Date(),
    } as any);

    usersStore.set('usr_bob', {
      id: 'usr_bob',
      name: 'Bob Customer',
      email: 'bob@plaza.app',
      phone: '+919876543211',
      avatarUrl: '',
      city: 'Hyderabad',
      rewardPoints: 200,
      tier: 'SILVER',
      role: 'user' as any,
      preferences: {},
      createdAt: new Date(),
    } as any);

    theatresStore.set('t_1', {
      id: 't_1',
      name: 'AMB Cinemas',
      location: 'Gachibowli, Hyderabad',
      distanceKm: 2.5,
      amenities: ['Dolby Atmos'],
      isPublished: true,
      showtimes: [
        {
          id: 'st_1',
          time: '07:30 PM',
          format: 'IMAX 2D',
          language: 'English',
          basePrice: 450,
          totalSeats: 100,
          availableSeats: 80,
          isFillingFast: false,
          isAlmostFull: false,
        },
      ],
    } as any);

    eventsStore.set('ev_1', {
      id: 'ev_1',
      title: 'Sunburn Arena Live',
      category: 'Music',
      posterUrl: 'https://example.com/ev.jpg',
      venue: 'Hitex Exhibition Centre',
      location: 'Hyderabad',
      eventDate: '2026-11-15',
      time: '06:00 PM',
      duration: '4h',
      ageLimit: '18+',
      description: 'Concert',
      isPublished: true,
      ticketTiers: [
        {
          id: 'tier_vip',
          name: 'VIP Phase 1',
          price: 2000,
          description: 'Front row access',
          remainingCount: 50,
          perks: ['Fast Track'],
        },
      ],
      lineup: [],
      faqs: [],
    } as any);

    paymentRepoMock = {
      create: jest.fn((dto: Partial<PaymentEntity>) => ({
        currency: 'INR',
        createdAt: new Date(),
        updatedAt: new Date(),
        ...dto,
      })),
      save: jest.fn(async (entity: PaymentEntity) => {
        entity.updatedAt = new Date();
        paymentsStore.set(entity.id, entity);
        return entity;
      }),
      findOne: jest.fn(async ({ where }: any) => {
        if (!where) return null;
        const conditions = Array.isArray(where) ? where : [where];
        for (const cond of conditions) {
          for (const p of paymentsStore.values()) {
            let match = true;
            for (const [k, v] of Object.entries(cond)) {
              if (v !== undefined && (p as any)[k] !== v) {
                match = false;
                break;
              }
            }
            if (match) return p;
          }
        }
        return null;
      }),
      find: jest.fn(async ({ where }: any) => {
        const results: PaymentEntity[] = [];
        for (const p of paymentsStore.values()) {
          let match = true;
          if (where) {
            for (const [k, v] of Object.entries(where)) {
              if (v !== undefined && (p as any)[k] !== v) {
                match = false;
                break;
              }
            }
          }
          if (match) results.push(p);
        }
        return results;
      }),
    };

    bookingRepoMock = {
      create: jest.fn((dto: Partial<BookingEntity>) => ({
        createdAt: new Date(),
        ...dto,
      })),
      save: jest.fn(async (entity: BookingEntity) => {
        bookingsStore.set(entity.id, entity);
        return entity;
      }),
      findOne: jest.fn(async ({ where }: any) => {
        if (!where) return null;
        if (where.id) {
          const b = bookingsStore.get(where.id);
          if (!b) return null;
          if (where.userId && b.userId !== where.userId) return null;
          return b;
        }
        return null;
      }),
      createQueryBuilder: jest.fn(() => ({
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn(async () => []),
        getOne: jest.fn(async () => null),
      })),
    };

    userRepoMock = {
      findOne: jest.fn(async ({ where }: any) => {
        if (!where?.id) return null;
        return usersStore.get(where.id) || null;
      }),
      save: jest.fn(async (u: User) => {
        usersStore.set(u.id, u);
        return u;
      }),
    };

    const getRepoForClass = (cls: any) => {
      if (cls === BookingEntity) return bookingRepoMock;
      if (cls === PaymentEntity) return paymentRepoMock;
      if (cls === User) return userRepoMock;
      if (cls === TheatreEntity) {
        return { findOne: jest.fn(async ({ where }: any) => theatresStore.get(where.id) || null) };
      }
      if (cls === EventEntity) {
        return { findOne: jest.fn(async ({ where }: any) => eventsStore.get(where.id) || null) };
      }
      if (cls === MovieEntity) {
        return { findOne: jest.fn(async ({ where }: any) => moviesStore.get(where.id) || null) };
      }
      if (cls === SportsVenueEntity) {
        return { findOne: jest.fn(async ({ where }: any) => sportsStore.get(where.id) || null) };
      }
      if (cls === RestaurantEntity) {
        return { findOne: jest.fn(async ({ where }: any) => restaurantsStore.get(where.id) || null) };
      }
      if (cls === HotelEntity) {
        return { findOne: jest.fn(async ({ where }: any) => staysStore.get(where.id) || null) };
      }
      if (cls === ProductEntity) {
        return { findOne: jest.fn(async ({ where }: any) => productsStore.get(where.id) || null) };
      }
      if (cls === ActivityEntity) {
        return { findOne: jest.fn(async ({ where }: any) => activitiesStore.get(where.id) || null) };
      }
      return bookingRepoMock;
    };

    dataSourceMock = {
      getRepository: jest.fn(getRepoForClass),
      transaction: jest.fn(async (cb: any) => {
        const manager = {
          findOne: jest.fn(async (entityCls: any, { where }: any) => {
            if (entityCls === TheatreEntity) return theatresStore.get(where.id) || null;
            if (entityCls === EventEntity) return eventsStore.get(where.id) || null;
            if (entityCls === User) return usersStore.get(where.id) || null;
            return null;
          }),
          save: jest.fn(async (entityOrCls: any, maybeEntity?: any) => {
            const target = maybeEntity || entityOrCls;
            if (target && target.rewardPoints !== undefined && target.id) {
              usersStore.set(target.id, target);
            }
            return target;
          }),
          getRepository: jest.fn(getRepoForClass),
        };
        return cb(manager);
      }),
    };

    notificationAdapterMock = {
      sendSms: jest.fn(async (payload: { to: string; message: string }) => {
        smsLog.push(payload);
      }),
    };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  // =========================================================================
  // SECTION 25: MANDATORY 35-POINT TEST MATRIX
  // =========================================================================
  describe('Section 25 — Mandatory 35-Point Payment & Verification Test Matrix', () => {
    it('Test 1: Valid quote -> payment order created with server canonical amount', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1', 'A2'],
        },
        'usr_alice',
      );

      // 2 * 450 = 900 + 70 convenience + 45 tax = 1015 INR (101500 paise)
      expect(quote.grandTotal).toBe(1015);
      expect(quote.amountInMinorUnits).toBe(101500);

      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });

      expect(order.quoteId).toBe(quote.quoteId);
      expect(order.amount).toBe(1015);
      expect(order.amountInMinorUnits).toBe(101500);
      expect(order.currency).toBe('INR');
      expect(order.status).toBe(PaymentStatus.PENDING);
      expect(order.providerOrderId).toMatch(/^order_/);
      expect(order.keyId).toBe(TEST_KEY_ID);
    });

    it('Test 2: Client sends tampered lower amount -> ignored or rejected; server uses canonical amount', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1', 'A2'],
        },
        'usr_alice',
      );

      // When client passes tampered clientAmount, server rejects with PAYMENT_AMOUNT_MISMATCH
      await expect(
        paymentService.createPaymentOrder({
          quoteId: quote.quoteId,
          userId: 'usr_alice',
          clientAmount: 1, // Tampered ₹1 instead of ₹1015
        }),
      ).rejects.toThrow(
        new RegExp(PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH),
      );

      // And when client passes non-authoritative `amount: 1`, server ignores it and uses canonical ₹1015 (101500 paise)
      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
        amount: 1,
      });
      expect(order.amount).toBe(1015);
      expect(order.amountInMinorUnits).toBe(101500);
    });

    it('Test 3: Client sends tampered higher amount -> ignored or rejected; server uses canonical amount', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1', 'A2'],
        },
        'usr_alice',
      );

      // Rejected when validated via clientAmount
      await expect(
        paymentService.createPaymentOrder({
          quoteId: quote.quoteId,
          userId: 'usr_alice',
          clientAmount: 99999,
        }),
      ).rejects.toThrow(
        new RegExp(PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH),
      );

      // Ignored when passed as non-authoritative `amount`; server uses canonical 1015
      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
        amount: 99999,
      });
      expect(order.amount).toBe(1015);
      expect(order.amountInMinorUnits).toBe(101500);
    });

    it('Test 4: Client sends negative or zero amount for paid booking -> rejected', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );

      await expect(
        paymentService.createPaymentOrder({
          quoteId: quote.quoteId,
          userId: 'usr_alice',
          amount: -500,
        }),
      ).rejects.toThrow(BadRequestException);

      await expect(
        paymentService.createPaymentOrder({
          quoteId: quote.quoteId,
          userId: 'usr_alice',
          amount: 0,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('Test 5: Client sends wrong currency -> rejected with PAYMENT_CURRENCY_MISMATCH', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );

      await expect(
        paymentService.createPaymentOrder({
          quoteId: quote.quoteId,
          userId: 'usr_alice',
          currency: 'USD',
        }),
      ).rejects.toThrow(
        new RegExp(PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH),
      );
    });

    it('Test 6: Missing quoteId -> rejected with QUOTE_NOT_FOUND', async () => {
      const { paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      await expect(
        paymentService.createPaymentOrder({
          quoteId: '',
          userId: 'usr_alice',
        }),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.QUOTE_NOT_FOUND));
    });

    it('Test 7: Non-existent quoteId -> rejected with QUOTE_NOT_FOUND', async () => {
      const { paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      await expect(
        paymentService.createPaymentOrder({
          quoteId: 'QT_DOES_NOT_EXIST_999',
          userId: 'usr_alice',
        }),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.QUOTE_NOT_FOUND));
    });

    it('Test 8: Expired quoteId -> rejected with QUOTE_EXPIRED', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );

      paymentService.expireQuote(quote.quoteId);

      await expect(
        paymentService.createPaymentOrder({
          quoteId: quote.quoteId,
          userId: 'usr_alice',
        }),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.QUOTE_EXPIRED));
    });

    it('Test 9: Cancelled quoteId -> rejected with QUOTE_CANCELLED', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );

      paymentService.cancelQuote(quote.quoteId);

      await expect(
        paymentService.createPaymentOrder({
          quoteId: quote.quoteId,
          userId: 'usr_alice',
        }),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.QUOTE_CANCELLED));
    });

    it('Test 10: Quote owned by User A used by User B -> rejected with QUOTE_NOT_OWNED', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );

      await expect(
        paymentService.createPaymentOrder({
          quoteId: quote.quoteId,
          userId: 'usr_bob', // Different user!
        }),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.QUOTE_NOT_OWNED));
    });

    it('Test 11: Quote already consumed -> rejected with QUOTE_ALREADY_CONSUMED', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );

      paymentService.markQuoteConsumed(
        quote.quoteId,
        'PAY_CONSUMED_1',
        'PLZ-MOV-CONSUMED1',
      );

      await expect(
        paymentService.createPaymentOrder({
          quoteId: quote.quoteId,
          userId: 'usr_alice',
          bookingId: 'PLZ-MOV-DIFFERENT2',
        }),
      ).rejects.toThrow(
        new RegExp(PaymentErrorCode.QUOTE_ALREADY_CONSUMED),
      );
    });

    it('Test 12: Duplicate order creation for same valid quote -> returns existing compatible pending order without duplicate provider order', async () => {
      const { bookingsService, paymentService, razorpayAdapter } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const createOrderSpy = jest.spyOn(razorpayAdapter, 'createOrder');

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1', 'A2'],
        },
        'usr_alice',
      );

      const firstOrder = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });
      expect(firstOrder.idempotentReplay).toBe(false);

      const secondOrder = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });

      expect(secondOrder.idempotentReplay).toBe(true);
      expect(secondOrder.paymentId).toBe(firstOrder.paymentId);
      expect(secondOrder.providerOrderId).toBe(firstOrder.providerOrderId);
      expect(secondOrder.amountInMinorUnits).toBe(firstOrder.amountInMinorUnits);
      expect(createOrderSpy).toHaveBeenCalledTimes(1);
    });

    it('Test 13: Valid Razorpay test signature -> verifies true', () => {
      const { razorpayAdapter } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const orderId = 'order_test_valid_13';
      const paymentId = 'pay_test_valid_13';
      const signature = signOrderPayment(orderId, paymentId, TEST_KEY_SECRET);

      expect(
        razorpayAdapter.verifySignature(orderId, paymentId, signature),
      ).toBe(true);
    });

    it('Test 14: Invalid signature -> rejected with INVALID_PAYMENT_SIGNATURE', async () => {
      const { bookingsService, paymentService, paymentsController } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );

      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });

      const wrongSig = 'a'.repeat(64);
      await expect(
        paymentsController.verifyPayment(
          {
            bookingId: order.bookingId,
            razorpayOrderId: order.providerOrderId,
            razorpayPaymentId: 'pay_test_14',
            razorpaySignature: wrongSig,
          },
          { user: { id: 'usr_alice' } },
        ),
      ).rejects.toThrow(
        new RegExp(PaymentErrorCode.INVALID_PAYMENT_SIGNATURE),
      );

      // Payment must NOT be marked CAPTURED
      const storedPayment = paymentsStore.get(order.paymentId);
      expect(storedPayment?.status).toBe(PaymentStatus.PENDING);
    });

    it('Test 15: Truncated signature -> rejected', () => {
      const { razorpayAdapter } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const orderId = 'order_test_15';
      const paymentId = 'pay_test_15';
      const fullSig = signOrderPayment(orderId, paymentId, TEST_KEY_SECRET);
      const truncated = fullSig.slice(0, 32);

      expect(
        razorpayAdapter.verifySignature(orderId, paymentId, truncated),
      ).toBe(false);
    });

    it('Test 16: Wrong length signature -> rejected', () => {
      const { razorpayAdapter } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const orderId = 'order_test_16';
      const paymentId = 'pay_test_16';
      const fullSig = signOrderPayment(orderId, paymentId, TEST_KEY_SECRET);

      expect(
        razorpayAdapter.verifySignature(orderId, paymentId, fullSig + 'ab'),
      ).toBe(false);
      expect(razorpayAdapter.verifySignature(orderId, paymentId, '')).toBe(
        false,
      );
    });

    it('Test 17: Non-hex signature -> rejected', () => {
      const { razorpayAdapter } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const nonHex64 = 'z'.repeat(64);
      expect(
        razorpayAdapter.verifySignature('order_17', 'pay_17', nonHex64),
      ).toBe(false);
    });

    it('Test 18: Signature generated with wrong secret -> rejected', () => {
      const { razorpayAdapter } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const sigWithWrongSecret = signOrderPayment(
        'order_18',
        'pay_18',
        'wrong_secret_key_999',
      );
      expect(
        razorpayAdapter.verifySignature('order_18', 'pay_18', sigWithWrongSecret),
      ).toBe(false);
    });

    it('Test 19: Signature generated for different order_id -> rejected', () => {
      const { razorpayAdapter } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const sigForOrderA = signOrderPayment(
        'order_A',
        'pay_19',
        TEST_KEY_SECRET,
      );
      expect(
        razorpayAdapter.verifySignature('order_B', 'pay_19', sigForOrderA),
      ).toBe(false);
    });

    it('Test 20: Signature generated for different payment_id -> rejected', () => {
      const { razorpayAdapter } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const sigForPayA = signOrderPayment(
        'order_20',
        'pay_A',
        TEST_KEY_SECRET,
      );
      expect(
        razorpayAdapter.verifySignature('order_20', 'pay_B', sigForPayA),
      ).toBe(false);
    });

    it('Test 21: Verified signature with mismatched providerOrderId -> rejected with PAYMENT_ORDER_MISMATCH', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote1 = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );
      const order1 = await paymentService.createPaymentOrder({
        quoteId: quote1.quoteId,
        userId: 'usr_alice',
        bookingId: 'PLZ-MOV-ORDER1',
      });

      const otherOrderId = 'order_foreign_other_999';
      const paymentId = 'pay_valid_for_foreign_999';
      const validSigForOtherOrder = signOrderPayment(
        otherOrderId,
        paymentId,
        TEST_KEY_SECRET,
      );

      await expect(
        paymentService.verifyPayment({
          bookingId: order1.bookingId,
          orderId: otherOrderId, // Mismatched order ID for booking PLZ-MOV-ORDER1
          paymentId,
          signature: validSigForOtherOrder,
          userId: 'usr_alice',
        }),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.PAYMENT_ORDER_MISMATCH));
    });

    it('Test 22: Verified signature with mismatched amount -> rejected with PAYMENT_AMOUNT_MISMATCH', async () => {
      const { bookingsService, paymentService, razorpayAdapter } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1', 'A2'], // ₹1015 = 101500 paise
        },
        'usr_alice',
      );

      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });

      const paymentId = 'pay_underpaid_22';
      // Provider reports only 100 paise (₹1) instead of 101500 paise (₹1015)
      razorpayAdapter.registerProviderPayment({
        paymentId,
        orderId: order.providerOrderId,
        amount: 1,
        amountInMinorUnits: 100,
        currency: 'INR',
        status: 'captured',
        captured: true,
      });

      const sig = signOrderPayment(
        order.providerOrderId,
        paymentId,
        TEST_KEY_SECRET,
      );

      await expect(
        paymentService.verifyPayment({
          bookingId: order.bookingId,
          orderId: order.providerOrderId,
          paymentId,
          signature: sig,
          userId: 'usr_alice',
        }),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH));
    });

    it('Test 23: Verified signature with mismatched currency -> rejected with PAYMENT_CURRENCY_MISMATCH', async () => {
      const { bookingsService, paymentService, razorpayAdapter } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'], // ₹543 = 54300 paise
        },
        'usr_alice',
      );

      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });

      const paymentId = 'pay_wrong_currency_23';
      razorpayAdapter.registerProviderPayment({
        paymentId,
        orderId: order.providerOrderId,
        amount: 543,
        amountInMinorUnits: 54300,
        currency: 'USD', // Wrong currency!
        status: 'captured',
        captured: true,
      });

      const sig = signOrderPayment(
        order.providerOrderId,
        paymentId,
        TEST_KEY_SECRET,
      );

      await expect(
        paymentService.verifyPayment({
          bookingId: order.bookingId,
          orderId: order.providerOrderId,
          paymentId,
          signature: sig,
          userId: 'usr_alice',
        }),
      ).rejects.toThrow(
        new RegExp(PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH),
      );
    });

    it('Test 24: Payment owned by User A verified by User B -> rejected with PAYMENT_NOT_OWNED', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );

      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });

      const paymentId = 'pay_alice_24';
      const sig = signOrderPayment(
        order.providerOrderId,
        paymentId,
        TEST_KEY_SECRET,
      );

      await expect(
        paymentService.verifyPayment({
          bookingId: order.bookingId,
          orderId: order.providerOrderId,
          paymentId,
          signature: sig,
          userId: 'usr_bob', // Bob trying to verify Alice's payment
        }),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.PAYMENT_NOT_OWNED));
    });

    it('Test 25: Payment for Booking A verified against Booking B -> rejected with PAYMENT_BOOKING_MISMATCH', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quoteA = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );
      const orderA = await paymentService.createPaymentOrder({
        quoteId: quoteA.quoteId,
        userId: 'usr_alice',
        bookingId: 'PLZ-MOV-BOOKING-A',
      });

      const paymentId = 'pay_for_booking_A_25';
      const sig = signOrderPayment(
        orderA.providerOrderId,
        paymentId,
        TEST_KEY_SECRET,
      );

      await expect(
        paymentService.verifyPayment({
          bookingId: 'PLZ-MOV-BOOKING-B', // Different booking ID!
          orderId: orderA.providerOrderId,
          paymentId,
          signature: sig,
          userId: 'usr_alice',
        }),
      ).rejects.toThrow(
        new RegExp(PaymentErrorCode.PAYMENT_BOOKING_MISMATCH),
      );
    });

    it('Test 26 & 27: Valid verification transitions payment PENDING -> CAPTURED and booking PENDING -> UPCOMING/CONFIRMED', async () => {
      const { bookingsService, paymentsController } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['B1', 'B2'],
        },
        'usr_alice',
      );

      const booking = await bookingsService.createMovieBooking({
        userId: 'usr_alice',
        movieId: 'm_1',
        theatreId: 't_1',
        showtimeId: 'st_1',
        seatIds: ['B1', 'B2'],
        movieTitle: 'Kalki 2898 AD',
        theatreName: 'AMB Cinemas',
        posterUrl: 'https://example.com/kalki.jpg',
        date: '2026-10-15',
        time: '07:30 PM',
        quoteId: quote.quoteId,
      });

      // Set booking to PENDING to verify transition PENDING -> UPCOMING
      booking.status = BookingStatus.PENDING;
      booking.metadata = {
        ...booking.metadata,
        rewardAwarded: false,
      };
      await bookingRepoMock.save(booking);

      const paymentRecord = Array.from(paymentsStore.values()).find(
        (p) => p.bookingId === booking.id,
      )!;
      expect(paymentRecord.status).toBe(PaymentStatus.PENDING);

      const paymentId = 'pay_verified_26_27';
      const sig = signOrderPayment(
        paymentRecord.providerOrderId!,
        paymentId,
        TEST_KEY_SECRET,
      );

      const res = await paymentsController.verifyPayment(
        {
          bookingId: booking.id,
          razorpayOrderId: paymentRecord.providerOrderId!,
          razorpayPaymentId: paymentId,
          razorpaySignature: sig,
          quoteId: quote.quoteId,
        },
        { user: { id: 'usr_alice' } },
      );

      expect(res.success).toBe(true);
      expect(res.status).toBe(PaymentStatus.CAPTURED);
      expect(res.booking.status).toBe(BookingStatus.UPCOMING);

      const updatedPayment = paymentsStore.get(paymentRecord.id)!;
      expect(updatedPayment.status).toBe(PaymentStatus.CAPTURED);
      expect(updatedPayment.providerPaymentId).toBe(paymentId);

      const updatedBooking = bookingsStore.get(booking.id)!;
      expect(updatedBooking.status).toBe(BookingStatus.UPCOMING);
      expect(updatedBooking.metadata.paymentVerified).toBe(true);
    });

    it('Test 28: Duplicate verification on already CAPTURED payment -> idempotent success, no duplicate booking/reward/notification', async () => {
      const { bookingsService, paymentsController } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['C1', 'C2'],
        },
        'usr_alice',
      );

      const booking = await bookingsService.createMovieBooking({
        userId: 'usr_alice',
        movieId: 'm_1',
        theatreId: 't_1',
        showtimeId: 'st_1',
        seatIds: ['C1', 'C2'],
        movieTitle: 'Kalki 2898 AD',
        theatreName: 'AMB Cinemas',
        posterUrl: 'https://example.com/kalki.jpg',
        date: '2026-10-15',
        time: '07:30 PM',
        quoteId: quote.quoteId,
      });

      booking.status = BookingStatus.PENDING;
      booking.metadata = { ...booking.metadata, rewardAwarded: false };
      await bookingRepoMock.save(booking);

      const paymentRecord = Array.from(paymentsStore.values()).find(
        (p) => p.bookingId === booking.id,
      )!;
      const paymentId = 'pay_idemp_28';
      const sig = signOrderPayment(
        paymentRecord.providerOrderId!,
        paymentId,
        TEST_KEY_SECRET,
      );

      const pointsBefore = usersStore.get('usr_alice')!.rewardPoints;

      // 1st verification
      const firstVerify = await paymentsController.verifyPayment(
        {
          bookingId: booking.id,
          razorpayOrderId: paymentRecord.providerOrderId!,
          razorpayPaymentId: paymentId,
          razorpaySignature: sig,
        },
        { user: { id: 'usr_alice' } },
      );
      expect(firstVerify.success).toBe(true);
      expect(firstVerify.idempotentReplay).toBeUndefined();

      const pointsAfterFirst = usersStore.get('usr_alice')!.rewardPoints;
      expect(pointsAfterFirst).toBeGreaterThan(pointsBefore);
      expect(smsLog.length).toBe(1);

      // 2nd verification (duplicate replay with same paymentId)
      const secondVerify = await paymentsController.verifyPayment(
        {
          bookingId: booking.id,
          razorpayOrderId: paymentRecord.providerOrderId!,
          razorpayPaymentId: paymentId,
          razorpaySignature: sig,
        },
        { user: { id: 'usr_alice' } },
      );
      expect(secondVerify.success).toBe(true);
      expect(secondVerify.idempotentReplay).toBe(true);

      // Reward points and SMS count MUST NOT increase on duplicate replay
      expect(usersStore.get('usr_alice')!.rewardPoints).toBe(pointsAfterFirst);
      expect(smsLog.length).toBe(1);
    });

    it('Test 29: Verification attempted on FAILED payment -> rejected with INVALID_PAYMENT_STATE_TRANSITION', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['D1'],
        },
        'usr_alice',
      );

      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });

      await paymentService.markPaymentFailed(
        order.bookingId,
        'Customer cancelled',
      );

      const paymentId = 'pay_after_fail_29';
      const sig = signOrderPayment(
        order.providerOrderId,
        paymentId,
        TEST_KEY_SECRET,
      );

      await expect(
        paymentService.verifyPayment({
          bookingId: order.bookingId,
          orderId: order.providerOrderId,
          paymentId,
          signature: sig,
          userId: 'usr_alice',
        }),
      ).rejects.toThrow(
        new RegExp(PaymentErrorCode.INVALID_PAYMENT_STATE_TRANSITION),
      );
    });

    it('Test 30: Verification attempted on REFUNDED payment -> rejected with INVALID_PAYMENT_STATE_TRANSITION', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['E1'],
        },
        'usr_alice',
      );

      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });

      const paymentId = 'pay_to_refund_30';
      const sig = signOrderPayment(
        order.providerOrderId,
        paymentId,
        TEST_KEY_SECRET,
      );

      await paymentService.verifyPayment({
        bookingId: order.bookingId,
        orderId: order.providerOrderId,
        paymentId,
        signature: sig,
        userId: 'usr_alice',
      });

      await paymentService.processRefund(order.bookingId, order.amount);
      const refundedRecord = paymentsStore.get(order.paymentId)!;
      expect(refundedRecord.status).toBe(PaymentStatus.REFUNDED);

      // Attempt re-verification on REFUNDED payment
      await expect(
        paymentService.verifyPayment({
          bookingId: order.bookingId,
          orderId: order.providerOrderId,
          paymentId,
          signature: sig,
          userId: 'usr_alice',
        }),
      ).rejects.toThrow(
        new RegExp(PaymentErrorCode.INVALID_PAYMENT_STATE_TRANSITION),
      );
    });

    it('Test 31: Booking completion attempted without verified payment -> rejected with PAYMENT_NOT_VERIFIED', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['F1'],
        },
        'usr_alice',
      );

      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });

      await expect(
        paymentService.assertBookingPaymentVerified(
          order.bookingId,
          'usr_alice',
        ),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.PAYMENT_NOT_VERIFIED));
    });

    it('Test 32: Simulated mode order creation + verification works with PAYMENT_MODE=SIMULATED', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      const quote = await bookingsService.calculateQuote(
        'event',
        {
          eventId: 'ev_1',
          tierId: 'tier_vip',
          ticketCount: 2, // 2 * 2000 = 4000 + 200 fee = 4200 INR (420000 paise)
        },
        'usr_alice',
      );

      expect(quote.grandTotal).toBe(4200);
      expect(quote.amountInMinorUnits).toBe(420000);

      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });

      expect(order.paymentMode).toBe('SIMULATED');
      expect(order.providerOrderId).toMatch(/^order_sim_/);
      expect(order.amountInMinorUnits).toBe(420000);

      const simPaymentId = 'pay_sim_test_32';
      const simSignature = signOrderPayment(
        order.providerOrderId,
        simPaymentId,
        'simulated_key_secret',
      );

      const verifyRes = await paymentService.verifyPayment({
        bookingId: order.bookingId,
        orderId: order.providerOrderId,
        paymentId: simPaymentId,
        signature: simSignature,
        userId: 'usr_alice',
      });

      expect(verifyRes.success).toBe(true);
      expect(verifyRes.payment?.status).toBe(PaymentStatus.CAPTURED);
    });

    it('Test 33: Razorpay mode with RAZORPAY_LIVE_ENABLED=false blocks live order creation with RAZORPAY_LIVE_DISABLED', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'false',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );

      await expect(
        paymentService.createPaymentOrder({
          quoteId: quote.quoteId,
          userId: 'usr_alice',
        }),
      ).rejects.toThrow(new RegExp(PaymentErrorCode.RAZORPAY_LIVE_DISABLED));
    });

    it('Test 34: Razorpay mode with rzp_test_ keys in test context works with mock/stub provider', async () => {
      const { bookingsService, paymentService } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );

      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });

      expect(order.paymentMode).toBe('RAZORPAY');
      expect(order.keyId).toBe(TEST_KEY_ID);

      const paymentId = 'pay_test_34';
      const sig = signOrderPayment(
        order.providerOrderId,
        paymentId,
        TEST_KEY_SECRET,
      );

      const verified = await paymentService.verifyPayment({
        bookingId: order.bookingId,
        orderId: order.providerOrderId,
        paymentId,
        signature: sig,
        userId: 'usr_alice',
      });

      expect(verified.success).toBe(true);
      expect(verified.payment?.status).toBe(PaymentStatus.CAPTURED);
    });

    it('Test 35: No secret appears in API responses or logs', async () => {
      const { bookingsService, paymentService, configService } = createHarness({
        PAYMENT_MODE: 'RAZORPAY',
        RAZORPAY_LIVE_ENABLED: 'true',
        RAZORPAY_KEY_ID: TEST_KEY_ID,
        RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
        RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
      });

      const quote = await bookingsService.calculateQuote(
        'movie',
        {
          theatreId: 't_1',
          showtimeId: 'st_1',
          seatIds: ['A1'],
        },
        'usr_alice',
      );

      const order = await paymentService.createPaymentOrder({
        quoteId: quote.quoteId,
        userId: 'usr_alice',
      });

      const serialized = JSON.stringify({
        quote,
        order,
        safeConfig: paymentService.getSafeConfigSummary(),
        evalSummary: configService.getSafeSummary(),
      });

      expect(serialized).not.toContain(TEST_KEY_SECRET);
      expect(serialized).not.toContain(TEST_WEBHOOK_SECRET);
      expect(serialized).not.toContain('keySecret');
      expect(serialized).not.toContain('webhookSecret');
    });
  });

  // =========================================================================
  // SECTION 26: STATE MACHINE TRANSITION TESTS
  // =========================================================================
  describe('Section 26 — Canonical Payment State Machine Transitions', () => {
    const allowedTransitions: [PaymentStatus, PaymentStatus][] = [
      [PaymentStatus.CREATED, PaymentStatus.PENDING],
      [PaymentStatus.PENDING, PaymentStatus.AUTHORIZED],
      [PaymentStatus.PENDING, PaymentStatus.CAPTURED],
      [PaymentStatus.AUTHORIZED, PaymentStatus.CAPTURED],
      [PaymentStatus.CAPTURED, PaymentStatus.REFUND_PENDING],
      [PaymentStatus.REFUND_PENDING, PaymentStatus.REFUNDED],
    ];

    it.each(allowedTransitions)(
      'allows valid transition %s -> %s',
      (from, to) => {
        expect(isValidPaymentStateTransition(from, to)).toBe(true);
        expect(() => assertValidPaymentStateTransition(from, to)).not.toThrow();
      },
    );

    const forbiddenTransitions: [PaymentStatus, PaymentStatus][] = [
      [PaymentStatus.FAILED, PaymentStatus.CAPTURED],
      [PaymentStatus.FAILED, PaymentStatus.AUTHORIZED],
      [PaymentStatus.REFUNDED, PaymentStatus.CAPTURED],
      [PaymentStatus.REFUNDED, PaymentStatus.AUTHORIZED],
      [PaymentStatus.CAPTURED, PaymentStatus.FAILED],
      [PaymentStatus.CREATED, PaymentStatus.REFUNDED],
      [PaymentStatus.CREATED, PaymentStatus.CAPTURED],
    ];

    it.each(forbiddenTransitions)(
      'rejects forbidden transition %s -> %s',
      (from, to) => {
        expect(isValidPaymentStateTransition(from, to)).toBe(false);
        expect(() => assertValidPaymentStateTransition(from, to)).toThrow(
          /INVALID_PAYMENT_STATE_TRANSITION/,
        );
      },
    );
  });

  // =========================================================================
  // ADDITIONAL HARDENING: Quote Snapshot Tampering, Order Reassignment & Migration
  // =========================================================================
  describe('Quote Tampering, Provider ID Immutability & Migration', () => {
    it('detects tampered quote snapshot (subtotal + convenienceFee + taxes - discount != grandTotal)', () => {
      const { paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      const quoteRecord = paymentService.registerQuote({
        quoteId: 'QT_TAMPER_1',
        userId: 'usr_alice',
        type: 'movie',
        vertical: 'movies',
        subtotal: 900,
        convenienceFee: 70,
        fees: 70,
        taxes: 45,
        tax: 45,
        discount: 0,
        total: 1015,
        grandTotal: 1015,
        currency: 'INR',
        expiresAt: new Date(Date.now() + 600000).toISOString(),
      });

      // Mutate internal subtotal so snapshot integrity breaks
      quoteRecord.quote.subtotal = 500;

      expect(() =>
        paymentService.validateCanonicalQuote('QT_TAMPER_1', {
          userId: 'usr_alice',
        }),
      ).toThrow(new RegExp(PaymentErrorCode.QUOTE_TAMPERED));
    });

    it('prevents reassigning providerOrderId or providerPaymentId once bound', () => {
      const { paymentService } = createHarness({
        PAYMENT_MODE: 'SIMULATED',
        RAZORPAY_LIVE_ENABLED: 'false',
      });

      const record: PaymentEntity = {
        id: 'PAY_IMMUT_1',
        bookingId: 'BK_1',
        userId: 'usr_alice',
        amount: 500,
        currency: 'INR',
        provider: 'razorpay',
        paymentMethod: 'UPI_FAST',
        providerOrderId: 'order_original_1',
        providerPaymentId: 'pay_original_1',
        status: PaymentStatus.CAPTURED,
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      expect(() =>
        paymentService.assignProviderOrderId(record, 'order_different_2'),
      ).toThrow(new RegExp(PaymentErrorCode.PAYMENT_ORDER_MISMATCH));

      expect(() =>
        paymentService.assignProviderPaymentId(record, 'pay_different_2'),
      ).toThrow(new RegExp(PaymentErrorCode.PAYMENT_ID_MISMATCH));
    });

    it('converts major INR amounts to integer minor units (paise) accurately', () => {
      expect(toMinorUnits(499)).toBe(49900);
      expect(toMinorUnits(1015.5)).toBe(101550);
      expect(toMinorUnits(0)).toBe(0);
    });

    it('AddQuoteIdToPaymentsTable1790700000000 migration adds quoteId column and indices cleanly', async () => {
      const migration = new AddQuoteIdToPaymentsTable1790700000000();
      const executedSql: string[] = [];
      const mockQueryRunner: any = {
        query: jest.fn(async (sql: string) => {
          executedSql.push(sql);
        }),
      };

      await migration.up(mockQueryRunner);
      expect(
        executedSql.some((s) =>
          s.includes('ADD COLUMN IF NOT EXISTS "quoteId"'),
        ),
      ).toBe(true);
      expect(
        executedSql.some((s) => s.includes('IDX_payments_quoteId')),
      ).toBe(true);

      await migration.down(mockQueryRunner);
      expect(
        executedSql.some((s) => s.includes('DROP COLUMN IF EXISTS "quoteId"')),
      ).toBe(true);
    });

    it('scans repository source files to verify zero hardcoded live keys or secrets', () => {
      const srcDir = path.resolve(__dirname);
      const filesToScan: string[] = [];

      function walk(dir: string) {
        for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
          const full = path.join(dir, entry.name);
          if (entry.isDirectory()) {
            walk(full);
          } else if (
            entry.isFile() &&
            entry.name.endsWith('.ts') &&
            !entry.name.endsWith('.spec.ts')
          ) {
            filesToScan.push(full);
          }
        }
      }

      walk(srcDir);
      expect(filesToScan.length).toBeGreaterThan(20);

      for (const file of filesToScan) {
        const content = fs.readFileSync(file, 'utf8');
        expect(content).not.toMatch(/rzp_live_[A-Za-z0-9]{8,}/);
      }
    });
  });
});
