import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';
import {
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import {
  PaymentEntity,
  PaymentErrorCode,
  PaymentStatus,
  toMinorUnits,
} from './database/entities/payment.entity';
import {
  BookingEntity,
  BookingStatus,
  BookingType,
} from './database/entities/booking.entity';
import { User, UserRole } from './database/entities/user.entity';
import { EventEntity } from './database/entities/event.entity';
import { ActivityEntity } from './database/entities/activity.entity';
import { WebhookEventEntity } from './database/entities/webhook-event.entity';
import { PaymentConfigService } from './modules/payments/payment-config.service';
import { WebhooksController } from './modules/payments/webhooks.controller';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { AdminService } from './modules/admin/admin.service';
import { AdminController } from './modules/admin/admin.controller';
import { EnhanceWebhookEventsTable1790800000000 } from './database/migrations/1790800000000-EnhanceWebhookEventsTable';

describe('Phase 25.3 — Razorpay Webhook Verification & Replay Protection Hardening', () => {
  const TEST_KEY_ID = 'rzp_test_plaza253keyid';
  const TEST_KEY_SECRET = 'secret_test_plaza253_hmac_key_secret';
  const TEST_WEBHOOK_SECRET = 'whsec_test_plaza253_webhook_secret';

  const originalEnv = { ...process.env };

  let webhookEventsStore: Map<string, WebhookEventEntity>;
  let paymentsStore: Map<string, PaymentEntity>;
  let bookingsStore: Map<string, BookingEntity>;
  let usersStore: Map<string, User>;
  let eventsStore: Map<string, EventEntity>;
  let activitiesStore: Map<string, ActivityEntity>;

  let mockWebhookRepo: any;
  let mockPaymentRepo: any;
  let mockBookingRepo: any;
  let mockUserRepo: any;
  let mockEventRepo: any;
  let mockActivityRepo: any;
  let mockSmsAdapter: any;

  let configService: PaymentConfigService;
  let razorpayAdapter: RazorpayAdapter;
  let webhooksController: WebhooksController;
  let adminService: AdminService;
  let adminController: AdminController;

  function calculateHmacSignature(payload: string, secret: string): string {
    return crypto.createHmac('sha256', secret).update(payload).digest('hex');
  }

  function createBooking(overrides: Partial<BookingEntity> = {}): BookingEntity {
    return {
      id: overrides.id || `bk_${Date.now()}`,
      userId: overrides.userId || 'usr_1',
      title: overrides.title || 'Sample Booking',
      subtitle: overrides.subtitle || 'Subtitle',
      imageUrl: overrides.imageUrl || 'https://img.plaza.app/item.png',
      type: overrides.type || BookingType.MOVIE,
      date: overrides.date || '2026-10-15',
      time: overrides.time || '19:00',
      totalPrice: overrides.totalPrice !== undefined ? overrides.totalPrice : 500,
      status: overrides.status || BookingStatus.PENDING,
      metadata: overrides.metadata || {},
      createdAt: overrides.createdAt || new Date(),
      updatedAt: overrides.updatedAt || new Date(),
    } as BookingEntity;
  }

  function createUser(overrides: Partial<User> = {}): User {
    return {
      id: overrides.id || `usr_${Date.now()}`,
      email: overrides.email || 'user@plaza.app',
      name: overrides.name || 'Test User',
      passwordHash: overrides.passwordHash || 'hash',
      role: overrides.role || UserRole.USER,
      rewardPoints: overrides.rewardPoints !== undefined ? overrides.rewardPoints : 0,
      createdAt: overrides.createdAt || new Date(),
      updatedAt: overrides.updatedAt || new Date(),
    } as User;
  }

  function createPayment(overrides: Partial<PaymentEntity> = {}): PaymentEntity {
    return {
      id: overrides.id || `pay_${Date.now()}`,
      bookingId: overrides.bookingId || 'bk_1',
      userId: overrides.userId || 'usr_1',
      amount: overrides.amount !== undefined ? overrides.amount : 500,
      currency: overrides.currency || 'INR',
      provider: overrides.provider || 'razorpay',
      status: overrides.status || PaymentStatus.PENDING,
      providerOrderId: overrides.providerOrderId,
      providerPaymentId: overrides.providerPaymentId,
      createdAt: overrides.createdAt || new Date(),
      updatedAt: overrides.updatedAt || new Date(),
    } as PaymentEntity;
  }

  function createEvent(overrides: any = {}): EventEntity {
    return {
      id: overrides.id || 'evt_music_fest',
      title: overrides.title || 'Summer Music Fest',
      category: overrides.category || 'Concert',
      venue: overrides.venue || 'Plaza Arena',
      date: overrides.date || '2026-11-01',
      time: overrides.time || '18:00',
      price: overrides.price !== undefined ? overrides.price : 1500,
      ticketTiers: overrides.ticketTiers || [
        { id: 'tier_vip', name: 'VIP', description: 'VIP', price: 2500, remainingCount: 10 },
      ],
      isPublished: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    } as any;
  }

  function createActivity(overrides: any = {}): ActivityEntity {
    return {
      id: overrides.id || 'act_paintball',
      title: overrides.title || overrides.name || 'Paintball Arena',
      category: overrides.category || 'Action',
      duration: overrides.duration || '1 hour',
      price: overrides.price !== undefined ? overrides.price : 800,
      timeSlots: overrides.timeSlots || [
        { time: '14:00', availableSlots: 4, isFillingFast: false },
      ],
      isPublished: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    } as any;
  }

  beforeEach(() => {
    process.env.PAYMENT_MODE = 'SIMULATED';
    process.env.RAZORPAY_LIVE_ENABLED = 'false';
    process.env.RAZORPAY_KEY_ID = TEST_KEY_ID;
    process.env.RAZORPAY_KEY_SECRET = TEST_KEY_SECRET;
    process.env.RAZORPAY_WEBHOOK_SECRET = TEST_WEBHOOK_SECRET;

    webhookEventsStore = new Map<string, WebhookEventEntity>();
    paymentsStore = new Map<string, PaymentEntity>();
    bookingsStore = new Map<string, BookingEntity>();
    usersStore = new Map<string, User>();
    eventsStore = new Map<string, EventEntity>();
    activitiesStore = new Map<string, ActivityEntity>();

    mockWebhookRepo = {
      create: jest.fn((dto) => ({
        ...dto,
        receivedAt: new Date(),
        updatedAt: new Date(),
      })),
      save: jest.fn(async (entity) => {
        webhookEventsStore.set(entity.id, { ...entity });
        return entity;
      }),
      findOne: jest.fn(async ({ where }) => {
        if (where.id) return webhookEventsStore.get(where.id) || null;
        return null;
      }),
      find: jest.fn(async (options?: any) => {
        return Array.from(webhookEventsStore.values());
      }),
    };

    mockPaymentRepo = {
      create: jest.fn((dto) => ({ ...dto, createdAt: new Date(), updatedAt: new Date() })),
      save: jest.fn(async (entity) => {
        paymentsStore.set(entity.id, { ...entity });
        return entity;
      }),
      findOne: jest.fn(async ({ where }) => {
        const conditions = Array.isArray(where) ? where : [where];
        for (const cond of conditions) {
          for (const p of paymentsStore.values()) {
            let match = true;
            if (cond.id && p.id !== cond.id) match = false;
            if (cond.bookingId && p.bookingId !== cond.bookingId) match = false;
            if (cond.providerOrderId && p.providerOrderId !== cond.providerOrderId) match = false;
            if (cond.providerPaymentId && p.providerPaymentId !== cond.providerPaymentId) match = false;
            if (match) return p;
          }
        }
        return null;
      }),
      find: jest.fn(async () => Array.from(paymentsStore.values())),
    };

    mockBookingRepo = {
      save: jest.fn(async (entity) => {
        bookingsStore.set(entity.id, { ...entity });
        return entity;
      }),
      findOne: jest.fn(async ({ where }) => {
        if (where.id) return bookingsStore.get(where.id) || null;
        return null;
      }),
      find: jest.fn(async () => Array.from(bookingsStore.values())),
    };

    mockUserRepo = {
      save: jest.fn(async (entity) => {
        usersStore.set(entity.id, { ...entity });
        return entity;
      }),
      findOne: jest.fn(async ({ where }) => {
        if (where.id) return usersStore.get(where.id) || null;
        return null;
      }),
      count: jest.fn(async () => usersStore.size),
    };

    mockEventRepo = {
      save: jest.fn(async (entity) => {
        eventsStore.set(entity.id, { ...entity });
        return entity;
      }),
      findOne: jest.fn(async ({ where }) => {
        if (where.id) return eventsStore.get(where.id) || null;
        return null;
      }),
      count: jest.fn(async () => eventsStore.size),
    };

    mockActivityRepo = {
      save: jest.fn(async (entity) => {
        activitiesStore.set(entity.id, { ...entity });
        return entity;
      }),
      findOne: jest.fn(async ({ where }) => {
        if (where.id) return activitiesStore.get(where.id) || null;
        return null;
      }),
      count: jest.fn(async () => activitiesStore.size),
    };

    mockSmsAdapter = {
      sendSms: jest.fn(async () => ({ success: true, messageId: 'sms_123' })),
    };

    configService = new PaymentConfigService();
    razorpayAdapter = new RazorpayAdapter(configService);

    webhooksController = new WebhooksController(
      razorpayAdapter,
      mockWebhookRepo,
      mockBookingRepo,
      mockSmsAdapter,
      mockPaymentRepo,
      mockUserRepo,
      mockEventRepo,
      mockActivityRepo,
    );

    adminService = new AdminService(
      mockUserRepo,
      { count: jest.fn(async () => 0) } as any,
      { count: jest.fn(async () => 0) } as any,
      { count: jest.fn(async () => 0) } as any,
      mockEventRepo,
      mockActivityRepo,
      { count: jest.fn(async () => 0) } as any,
      { count: jest.fn(async () => 0) } as any,
      { count: jest.fn(async () => 0) } as any,
      mockBookingRepo,
      { save: jest.fn(), find: jest.fn() } as any,
      { count: jest.fn(async () => 0) } as any,
      { count: jest.fn(async () => 0) } as any,
      mockPaymentRepo,
      undefined,
      mockWebhookRepo,
    );

    adminController = new AdminController(adminService);
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  // ==========================================
  // 1. WEBHOOK SIGNATURE VERIFICATION (1-8)
  // ==========================================
  describe('1. Webhook Signature Verification', () => {
    it('1. should throw 401 Unauthorized when x-razorpay-signature header is missing', async () => {
      const payload = JSON.stringify({ event: 'payment.captured', id: 'evt_1' });
      await expect(
        webhooksController.handleRazorpayWebhook('', payload as any),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('2. should throw 401 Unauthorized when signature is invalid or forged', async () => {
      const payload = JSON.stringify({ event: 'payment.captured', id: 'evt_2' });
      await expect(
        webhooksController.handleRazorpayWebhook('invalid_signature_hex_xyz', payload as any),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('3. should verify valid HMAC-SHA256 signature calculated with webhook secret', async () => {
      const payloadObj = { event: 'payment.captured', id: 'evt_valid_1', payload: {} };
      const rawPayload = JSON.stringify(payloadObj);
      const validSignature = calculateHmacSignature(rawPayload, TEST_WEBHOOK_SECRET);

      const result = await webhooksController.handleRazorpayWebhook(validSignature, payloadObj);
      expect(result.success).toBe(true);
      expect(result.eventId).toBe('evt_valid_1');
    });

    it('4. should use raw body Buffer without JSON re-serialization drift if present on req', async () => {
      const rawString = '{"id":"evt_raw_1","event":"order.paid","payload":{}}';
      const rawBuffer = Buffer.from(rawString, 'utf8');
      const validSignature = calculateHmacSignature(rawString, TEST_WEBHOOK_SECRET);

      const reqMock = { rawBody: rawBuffer };
      const result = await webhooksController.handleRazorpayWebhook(
        validSignature,
        JSON.parse(rawString),
        reqMock,
      );
      expect(result.success).toBe(true);
      expect(result.eventId).toBe('evt_raw_1');
    });

    it('5. should reject payload if raw body content was modified after signature calculation (tampering)', async () => {
      const originalPayload = '{"id":"evt_tampered","amount":500}';
      const signature = calculateHmacSignature(originalPayload, TEST_WEBHOOK_SECRET);

      const modifiedPayload = '{"id":"evt_tampered","amount":50000}';
      await expect(
        webhooksController.handleRazorpayWebhook(signature, JSON.parse(modifiedPayload)),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('6. should reject webhook if webhook secret is not configured or blank', () => {
      const customConfig = new PaymentConfigService();
      jest.spyOn(customConfig, 'getRazorpayWebhookSecret').mockReturnValue('');
      const customAdapter = new RazorpayAdapter(customConfig);

      const isValid = customAdapter.verifyWebhookSignature('payload', 'sig');
      expect(isValid).toBe(false);
    });

    it('7. should accept valid signature matching RAZORPAY_WEBHOOK_SECRET via RazorpayAdapter', () => {
      const payload = '{"test":123}';
      const sig = calculateHmacSignature(payload, TEST_WEBHOOK_SECRET);
      expect(razorpayAdapter.verifyWebhookSignature(payload, sig)).toBe(true);
    });

    it('8. should reject signature computed with wrong secret key', () => {
      const payload = '{"test":123}';
      const wrongSig = calculateHmacSignature(payload, 'wrong_webhook_secret_value');
      expect(razorpayAdapter.verifyWebhookSignature(payload, wrongSig)).toBe(false);
    });
  });

  // ==========================================
  // 2. DEDUPLICATION & REPLAY PROTECTION (9-14)
  // ==========================================
  describe('2. Deduplication & Replay Protection', () => {
    it('9. should process first delivery of payment.captured event successfully', async () => {
      const booking = createBooking({
        id: 'bk_dedup_1',
        totalPrice: 400,
        status: BookingStatus.PENDING,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_dedup_first',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_rzp_first_1',
              amount: 40000,
              currency: 'INR',
              notes: { bookingId: 'bk_dedup_1' },
            },
          },
        },
      };

      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.success).toBe(true);
      expect(res.status).toBe('processed');

      const savedEvt = webhookEventsStore.get('evt_dedup_first');
      expect(savedEvt).toBeDefined();
      expect(savedEvt?.status).toBe('PROCESSED');
    });

    it('10. should ignore immediate replay of already processed event ID idempotently', async () => {
      webhookEventsStore.set('evt_replayed_1', {
        id: 'evt_replayed_1',
        provider: 'razorpay',
        eventType: 'payment.captured',
        status: 'PROCESSED',
        payload: {},
        currency: 'INR',
        receivedAt: new Date(),
        updatedAt: new Date(),
      });

      const payloadObj = {
        id: 'evt_replayed_1',
        event: 'payment.captured',
        payload: { payment: { entity: { id: 'pay_replayed' } } },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.success).toBe(true);
      expect(res.status).toBe('ignored');
      expect(res.reason).toBe('already_processed');
      expect(res.idempotentReplay).toBe(true);
    });

    it('11. should NOT award rewards points twice on duplicate delivery', async () => {
      const user = createUser({ id: 'usr_rew_1', rewardPoints: 50 });
      usersStore.set(user.id, user);

      const booking = createBooking({
        id: 'bk_rew_1',
        userId: 'usr_rew_1',
        type: BookingType.MOVIE,
        totalPrice: 500,
        status: BookingStatus.PENDING,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_rew_unique_1',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_rew_1',
              amount: 50000,
              currency: 'INR',
              notes: { bookingId: 'bk_rew_1' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      // Movie 10% of 500 = 50 pts => total 100
      expect(usersStore.get('usr_rew_1')?.rewardPoints).toBe(100);

      // Duplicate delivery with same event ID
      const dupRes = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(dupRes.status).toBe('ignored');
      expect(usersStore.get('usr_rew_1')?.rewardPoints).toBe(100); // untouched
    });

    it('12. should NOT dispatch duplicate SMS notifications on duplicate delivery', async () => {
      const booking = createBooking({
        id: 'bk_sms_1',
        userId: 'usr_sms_1',
        type: BookingType.EVENT,
        totalPrice: 1000,
        status: BookingStatus.PENDING,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_sms_unique_1',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_sms_1',
              amount: 100000,
              currency: 'INR',
              notes: { bookingId: 'bk_sms_1' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(mockSmsAdapter.sendSms).toHaveBeenCalledTimes(1);

      await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(mockSmsAdapter.sendSms).toHaveBeenCalledTimes(1); // not called again
    });

    it('13. should handle in-flight concurrent delivery with status PROCESSING safely', async () => {
      webhookEventsStore.set('evt_inflight_1', {
        id: 'evt_inflight_1',
        provider: 'razorpay',
        eventType: 'payment.captured',
        status: 'PROCESSING',
        payload: {},
        currency: 'INR',
        receivedAt: new Date(),
        updatedAt: new Date(),
      });

      const payloadObj = { id: 'evt_inflight_1', event: 'payment.captured' };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.status).toBe('ignored');
      expect(res.reason).toBe('already_processing');
    });

    it('14. should safely record event as FAILED when handler throws', async () => {
      const payloadObj = {
        id: 'evt_fail_rec',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_fail',
              amount: 50000,
              currency: 'USD', // Currency mismatch triggers error
              notes: { bookingId: 'bk_nonexistent_throw' },
            },
          },
        },
      };

      const payment = createPayment({
        id: 'pay_db_1',
        bookingId: 'bk_nonexistent_throw',
        amount: 500,
        currency: 'INR',
        status: PaymentStatus.PENDING,
      });
      paymentsStore.set(payment.id, payment);

      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await expect(webhooksController.handleRazorpayWebhook(sig, payloadObj)).rejects.toThrow(
        BadRequestException,
      );

      const savedEvt = webhookEventsStore.get('evt_fail_rec');
      expect(savedEvt?.status).toBe('FAILED');
      expect(savedEvt?.failureReason).toBeDefined();
    });
  });

  // ==========================================
  // 3. IDENTITY & ASSOCIATION VALIDATION (15-20)
  // ==========================================
  describe('3. Identity & Association Validation', () => {
    it('15. should match booking and payment by notes.bookingId', async () => {
      const booking = createBooking({
        id: 'bk_match_notes',
        type: BookingType.DINING,
        totalPrice: 800,
        status: BookingStatus.PENDING,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_notes_match',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_match_notes',
              amount: 80000,
              currency: 'INR',
              notes: { bookingId: 'bk_match_notes' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.success).toBe(true);
      expect(bookingsStore.get('bk_match_notes')?.status).toBe(BookingStatus.UPCOMING);
    });

    it('16. should match booking and payment by order.entity.receipt', async () => {
      const booking = createBooking({
        id: 'bk_match_receipt',
        type: BookingType.ACTIVITY,
        totalPrice: 1500,
        status: BookingStatus.PENDING,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_receipt_match',
        event: 'order.paid',
        payload: {
          order: {
            entity: {
              id: 'order_rzp_rcpt_1',
              amount: 150000,
              currency: 'INR',
              receipt: 'bk_match_receipt',
            },
          },
          payment: {
            entity: {
              id: 'pay_rcpt_1',
              amount: 150000,
              currency: 'INR',
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.success).toBe(true);
      expect(bookingsStore.get('bk_match_receipt')?.status).toBe(BookingStatus.UPCOMING);
    });

    it('17. should reject webhook if providerOrderId conflicts with database payment record', async () => {
      const payment = createPayment({
        id: 'pay_order_conflict',
        bookingId: 'bk_ord_1',
        amount: 300,
        currency: 'INR',
        providerOrderId: 'order_canonical_correct',
        status: PaymentStatus.PENDING,
      });
      paymentsStore.set(payment.id, payment);

      const payloadObj = {
        id: 'evt_ord_mismatch',
        event: 'payment.captured',
        payload: {
          order: {
            entity: {
              id: 'order_forged_different',
              amount: 30000,
              currency: 'INR',
              notes: { bookingId: 'bk_ord_1' },
            },
          },
          payment: {
            entity: {
              id: 'pay_rzp_1',
              amount: 30000,
              currency: 'INR',
              order_id: 'order_forged_different',
              notes: { bookingId: 'bk_ord_1' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await expect(webhooksController.handleRazorpayWebhook(sig, payloadObj)).rejects.toThrow(
        BadRequestException,
      );
      await expect(webhooksController.handleRazorpayWebhook(sig, payloadObj)).rejects.toThrow(
        new RegExp(PaymentErrorCode.PAYMENT_ORDER_MISMATCH),
      );
    });

    it('18. should reject attempt to overwrite providerPaymentId on already CAPTURED payment', async () => {
      const payment = createPayment({
        id: 'pay_already_cap',
        bookingId: 'bk_cap_1',
        amount: 250,
        currency: 'INR',
        providerOrderId: 'order_1',
        providerPaymentId: 'pay_first_legit_id',
        status: PaymentStatus.CAPTURED,
      });
      paymentsStore.set(payment.id, payment);

      const payloadObj = {
        id: 'evt_overwrite_payid',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_second_conflicting_id',
              amount: 25000,
              currency: 'INR',
              notes: { bookingId: 'bk_cap_1' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await expect(webhooksController.handleRazorpayWebhook(sig, payloadObj)).rejects.toThrow(
        new RegExp(PaymentErrorCode.PAYMENT_ID_MISMATCH),
      );
    });

    it('19. should allow identical providerPaymentId duplicate webhook without error', async () => {
      const payment = createPayment({
        id: 'pay_same_id',
        bookingId: 'bk_same_1',
        amount: 250,
        currency: 'INR',
        providerOrderId: 'order_1',
        providerPaymentId: 'pay_exact_same_id',
        status: PaymentStatus.CAPTURED,
      });
      paymentsStore.set(payment.id, payment);

      const payloadObj = {
        id: 'evt_same_payid_delivery',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_exact_same_id',
              amount: 25000,
              currency: 'INR',
              notes: { bookingId: 'bk_same_1' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.success).toBe(true);
    });

    it('20. should gracefully skip processing when webhook has no identifiable booking or order', async () => {
      const payloadObj = {
        id: 'evt_unlinked',
        event: 'payment.captured',
        payload: {},
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.success).toBe(true);
    });
  });

  // ==========================================
  // 4. FINANCIAL AMOUNT & CURRENCY VALIDATION (21-25)
  // ==========================================
  describe('4. Financial Amount & Currency Validation', () => {
    it('21. should reject payment.captured when amount in minor units does not match canonical payment amount', async () => {
      const payment = createPayment({
        id: 'pay_amt_test',
        bookingId: 'bk_amt_1',
        amount: 999, // ₹999 = 99900 paise
        currency: 'INR',
        status: PaymentStatus.PENDING,
      });
      paymentsStore.set(payment.id, payment);

      const payloadObj = {
        id: 'evt_amt_mismatch',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_amt_test',
              amount: 50000, // 50000 paise != 99900 paise
              currency: 'INR',
              notes: { bookingId: 'bk_amt_1' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await expect(webhooksController.handleRazorpayWebhook(sig, payloadObj)).rejects.toThrow(
        new RegExp(PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH),
      );
    });

    it('22. should reject payment.captured when currency does not match INR', async () => {
      const payment = createPayment({
        id: 'pay_curr_test',
        bookingId: 'bk_curr_1',
        amount: 500,
        currency: 'INR',
        status: PaymentStatus.PENDING,
      });
      paymentsStore.set(payment.id, payment);

      const payloadObj = {
        id: 'evt_curr_mismatch',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_curr_test',
              amount: 50000,
              currency: 'EUR',
              notes: { bookingId: 'bk_curr_1' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await expect(webhooksController.handleRazorpayWebhook(sig, payloadObj)).rejects.toThrow(
        new RegExp(PaymentErrorCode.PAYMENT_CURRENCY_MISMATCH),
      );
    });

    it('23. should accurately validate fractional rupees using integer minor units (paise)', () => {
      expect(toMinorUnits(499.5)).toBe(49950);
      expect(toMinorUnits(10.05)).toBe(1005);
      expect(toMinorUnits(0.99)).toBe(99);
      expect(() => toMinorUnits(-50)).toThrow(BadRequestException);
    });

    it('24. should match exact integer minor units for high-value transactions', async () => {
      const payment = createPayment({
        id: 'pay_high_val',
        bookingId: 'bk_high_1',
        amount: 50000, // ₹50,000 = 5000000 paise
        currency: 'INR',
        status: PaymentStatus.PENDING,
      });
      paymentsStore.set(payment.id, payment);

      const payloadObj = {
        id: 'evt_high_val_ok',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_high_val',
              amount: 5000000,
              currency: 'INR',
              notes: { bookingId: 'bk_high_1' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.success).toBe(true);
      expect(paymentsStore.get('pay_high_val')?.status).toBe(PaymentStatus.CAPTURED);
    });

    it('25. should validate booking totalPrice minor units if payment entity was not present', async () => {
      const booking = createBooking({
        id: 'bk_direct_amt_check',
        type: BookingType.ACTIVITY,
        totalPrice: 1200, // ₹1200 => 120000 paise
        status: BookingStatus.PENDING,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_direct_amt_mismatch',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_direct_1',
              amount: 99900, // Mismatch!
              currency: 'INR',
              notes: { bookingId: 'bk_direct_amt_check' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await expect(webhooksController.handleRazorpayWebhook(sig, payloadObj)).rejects.toThrow(
        new RegExp(PaymentErrorCode.PAYMENT_AMOUNT_MISMATCH),
      );
    });
  });

  // ==========================================
  // 5. STATE MACHINE TRANSITIONS & FAILURES (26-32)
  // ==========================================
  describe('5. State Machine Transitions & Failure Safety', () => {
    it('26. should transition payment CREATED -> PENDING -> CAPTURED on order.paid', async () => {
      const payment = createPayment({
        id: 'pay_sm_created',
        bookingId: 'bk_sm_1',
        amount: 600,
        currency: 'INR',
        providerOrderId: 'order_sm_1',
        status: PaymentStatus.CREATED,
      });
      paymentsStore.set(payment.id, payment);

      const booking = createBooking({
        id: 'bk_sm_1',
        type: BookingType.MOVIE,
        totalPrice: 600,
        status: BookingStatus.PENDING,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_order_paid_trans',
        event: 'order.paid',
        payload: {
          order: {
            entity: {
              id: 'order_sm_1',
              amount: 60000,
              currency: 'INR',
              receipt: 'bk_sm_1',
            },
          },
          payment: {
            entity: {
              id: 'pay_rzp_cap_id',
              amount: 60000,
              currency: 'INR',
              order_id: 'order_sm_1',
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.success).toBe(true);
      expect(paymentsStore.get('pay_sm_created')?.status).toBe(PaymentStatus.CAPTURED);
      expect(bookingsStore.get('bk_sm_1')?.status).toBe(BookingStatus.UPCOMING);
    });

    it('27. should transition PENDING -> FAILED on payment.failed', async () => {
      const payment = createPayment({
        id: 'pay_fail_trans',
        bookingId: 'bk_fail_1',
        amount: 350,
        currency: 'INR',
        status: PaymentStatus.PENDING,
      });
      paymentsStore.set(payment.id, payment);

      const booking = createBooking({
        id: 'bk_fail_1',
        type: BookingType.ACTIVITY,
        totalPrice: 350,
        status: BookingStatus.PENDING,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_pay_failed',
        event: 'payment.failed',
        payload: {
          payment: {
            entity: {
              id: 'pay_fail_trans',
              amount: 35000,
              currency: 'INR',
              error_description: 'Card expired or declined by bank',
              notes: { bookingId: 'bk_fail_1' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.success).toBe(true);
      expect(paymentsStore.get('pay_fail_trans')?.status).toBe(PaymentStatus.FAILED);
      expect(paymentsStore.get('pay_fail_trans')?.failureReason).toBe(
        'Card expired or declined by bank',
      );
      expect(bookingsStore.get('bk_fail_1')?.status).toBe(BookingStatus.FAILED);
    });

    it('28. should NOT regress already CAPTURED payment on payment.failed delivery', async () => {
      const payment = createPayment({
        id: 'pay_already_captured_safe',
        bookingId: 'bk_safe_1',
        amount: 500,
        currency: 'INR',
        providerPaymentId: 'pay_captured_already',
        status: PaymentStatus.CAPTURED,
      });
      paymentsStore.set(payment.id, payment);

      const booking = createBooking({
        id: 'bk_safe_1',
        type: BookingType.EVENT,
        totalPrice: 500,
        status: BookingStatus.UPCOMING,
        metadata: { paymentVerified: true },
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_delayed_fail_after_capture',
        event: 'payment.failed',
        payload: {
          payment: {
            entity: {
              id: 'pay_captured_already',
              notes: { bookingId: 'bk_safe_1' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.success).toBe(true);
      expect(paymentsStore.get('pay_already_captured_safe')?.status).toBe(PaymentStatus.CAPTURED);
      expect(bookingsStore.get('bk_safe_1')?.status).toBe(BookingStatus.UPCOMING);
    });

    it('29. should reject payment.captured on CANCELLED or FAILED booking', async () => {
      const booking = createBooking({
        id: 'bk_cancelled_prior',
        type: BookingType.MOVIE,
        totalPrice: 400,
        status: BookingStatus.CANCELLED,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_cap_on_cancelled',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_late_cap',
              amount: 40000,
              currency: 'INR',
              notes: { bookingId: 'bk_cancelled_prior' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await expect(webhooksController.handleRazorpayWebhook(sig, payloadObj)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('30. should transition CAPTURED -> REFUND_PENDING -> REFUNDED on refund.processed', async () => {
      const payment = createPayment({
        id: 'pay_to_refund',
        bookingId: 'bk_refund_1',
        amount: 750,
        currency: 'INR',
        providerPaymentId: 'pay_rzp_ref_id',
        status: PaymentStatus.CAPTURED,
      });
      paymentsStore.set(payment.id, payment);

      const booking = createBooking({
        id: 'bk_refund_1',
        type: BookingType.DINING,
        totalPrice: 750,
        status: BookingStatus.UPCOMING,
        metadata: {
          payment: { paymentId: 'pay_rzp_ref_id', status: 'COMPLETED' },
        },
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_refund_done',
        event: 'refund.processed',
        payload: {
          refund: {
            entity: {
              id: 'rfnd_rzp_123',
              payment_id: 'pay_rzp_ref_id',
              amount: 75000,
              currency: 'INR',
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.success).toBe(true);
      expect(paymentsStore.get('pay_to_refund')?.status).toBe(PaymentStatus.REFUNDED);
      expect(paymentsStore.get('pay_to_refund')?.refundId).toBe('rfnd_rzp_123');
      expect(paymentsStore.get('pay_to_refund')?.refundAmount).toBe(750);
      expect(bookingsStore.get('bk_refund_1')?.status).toBe(BookingStatus.CANCELLED);
    });

    it('31. should reverse rewards points on refund.processed if previously awarded', async () => {
      const user = createUser({
        id: 'usr_ref_rew',
        rewardPoints: 200,
      });
      usersStore.set(user.id, user);

      const booking = createBooking({
        id: 'bk_ref_rew',
        userId: 'usr_ref_rew',
        type: BookingType.DINING,
        totalPrice: 1000,
        status: BookingStatus.UPCOMING,
        metadata: {
          payment: { paymentId: 'pay_dining_ref_id', status: 'COMPLETED' },
          rewardAwarded: true,
          rewardPoints: 100,
        },
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_ref_rew_rev',
        event: 'refund.processed',
        payload: {
          refund: {
            entity: {
              id: 'rfnd_dining_1',
              payment_id: 'pay_dining_ref_id',
              amount: 100000,
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(usersStore.get('usr_ref_rew')?.rewardPoints).toBe(100); // 200 - 100
      expect(bookingsStore.get('bk_ref_rew')?.metadata.rewardPointsReversed).toBe(true);
    });

    it('32. should handle unhandled event types by recording IGNORED status safely', async () => {
      const payloadObj = {
        id: 'evt_unhandled_dispute',
        event: 'dispute.created',
        payload: { dispute: { id: 'disp_1' } },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(res.success).toBe(true);
      expect(res.status).toBe('ignored');
      expect(webhookEventsStore.get('evt_unhandled_dispute')?.status).toBe('IGNORED');
    });
  });

  // ==========================================
  // 6. SIDE EFFECT IDEMPOTENCY & INVENTORY (33-37)
  // ==========================================
  describe('6. Side Effect Idempotency & Inventory Restoration', () => {
    it('33. should award 10% rewards on MOVIE bookings', async () => {
      const user = createUser({ id: 'usr_mv_1', rewardPoints: 0 });
      usersStore.set(user.id, user);

      const booking = createBooking({
        id: 'bk_mv_calc',
        userId: 'usr_mv_1',
        type: BookingType.MOVIE,
        totalPrice: 450,
        status: BookingStatus.PENDING,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_mv_points',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_mv_1',
              amount: 45000,
              currency: 'INR',
              notes: { bookingId: 'bk_mv_calc' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(usersStore.get('usr_mv_1')?.rewardPoints).toBe(45); // 10% of 450
    });

    it('34. should award flat 100 reward points on DINING bookings', async () => {
      const user = createUser({ id: 'usr_din_1', rewardPoints: 10 });
      usersStore.set(user.id, user);

      const booking = createBooking({
        id: 'bk_din_calc',
        userId: 'usr_din_1',
        type: BookingType.DINING,
        totalPrice: 2000,
        status: BookingStatus.PENDING,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_din_points',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_din_1',
              amount: 200000,
              currency: 'INR',
              notes: { bookingId: 'bk_din_calc' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(usersStore.get('usr_din_1')?.rewardPoints).toBe(110); // 10 + 100
    });

    it('35. should award 5% rewards on other vertical bookings (EVENT/ACTIVITY/STAY)', async () => {
      const user = createUser({ id: 'usr_oth_1', rewardPoints: 0 });
      usersStore.set(user.id, user);

      const booking = createBooking({
        id: 'bk_oth_calc',
        userId: 'usr_oth_1',
        type: BookingType.EVENT,
        totalPrice: 2000,
        status: BookingStatus.PENDING,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_oth_points',
        event: 'payment.captured',
        payload: {
          payment: {
            entity: {
              id: 'pay_oth_1',
              amount: 200000,
              currency: 'INR',
              notes: { bookingId: 'bk_oth_calc' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      expect(usersStore.get('usr_oth_1')?.rewardPoints).toBe(100); // 5% of 2000
    });

    it('36. should restore Event ticket tier inventory on payment.failed', async () => {
      const event = createEvent({
        id: 'evt_music_fest',
        ticketTiers: [
          { id: 'tier_vip', name: 'VIP', description: 'VIP Tier', price: 2500, remainingCount: 10 },
        ],
      });
      eventsStore.set(event.id, event);

      const booking = createBooking({
        id: 'bk_evt_inv',
        type: BookingType.EVENT,
        totalPrice: 5000,
        status: BookingStatus.PENDING,
        metadata: {
          eventId: 'evt_music_fest',
          tierId: 'tier_vip',
          ticketCount: 2,
        },
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_fail_inv_restore',
        event: 'payment.failed',
        payload: {
          payment: {
            entity: {
              id: 'pay_inv_fail',
              amount: 500000,
              currency: 'INR',
              error_description: 'Card Insufficient Funds',
              notes: { bookingId: 'bk_evt_inv' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      const updatedEvent = eventsStore.get('evt_music_fest');
      const tier = updatedEvent?.ticketTiers.find((t: any) => t.id === 'tier_vip');
      expect(tier?.remainingCount).toBe(12); // 10 + 2 restored
    });

    it('37. should restore Activity time slot inventory on payment.failed', async () => {
      const activity = createActivity({
        id: 'act_paintball',
        timeSlots: [
          { time: '14:00', availableSlots: 4, isFillingFast: false },
        ],
      });
      activitiesStore.set(activity.id, activity);

      const booking = createBooking({
        id: 'bk_act_inv',
        type: BookingType.ACTIVITY,
        totalPrice: 1600,
        status: BookingStatus.PENDING,
        metadata: {
          activityId: 'act_paintball',
          timeSlot: '14:00',
          numberOfPeople: 2,
        },
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_fail_act_inv_restore',
        event: 'payment.failed',
        payload: {
          payment: {
            entity: {
              id: 'pay_act_fail',
              amount: 160000,
              currency: 'INR',
              error_description: 'UPI Timeout',
              notes: { bookingId: 'bk_act_inv' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      const updatedAct = activitiesStore.get('act_paintball');
      const slot = updatedAct?.timeSlots.find((s: any) => s.time === '14:00');
      expect(slot?.availableSlots).toBe(6); // 4 + 2 restored
    });
  });

  // ==========================================
  // 7. WEBHOOK AUDIT & ADMIN VISIBILITY (38-41)
  // ==========================================
  describe('7. Webhook Event Ledger & Admin Visibility', () => {
    it('38. should store processed webhook with full metadata, status PROCESSED, and minor units', async () => {
      const booking = createBooking({
        id: 'bk_ledger_1',
        type: BookingType.MOVIE,
        totalPrice: 300,
        status: BookingStatus.PENDING,
      });
      bookingsStore.set(booking.id, booking);

      const payloadObj = {
        id: 'evt_ledger_check',
        event: 'payment.captured',
        payload: {
          order: {
            entity: {
              id: 'order_led_1',
              amount: 30000,
              currency: 'INR',
            },
          },
          payment: {
            entity: {
              id: 'pay_led_1',
              amount: 30000,
              currency: 'INR',
              order_id: 'order_led_1',
              notes: { bookingId: 'bk_ledger_1' },
            },
          },
        },
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      const recorded = webhookEventsStore.get('evt_ledger_check');
      expect(recorded).toBeDefined();
      expect(recorded?.status).toBe('PROCESSED');
      expect(recorded?.providerPaymentId).toBe('pay_led_1');
      expect(recorded?.providerOrderId).toBe('order_led_1');
      expect(recorded?.bookingId).toBe('bk_ledger_1');
      expect(recorded?.amountInMinorUnits).toBe(30000);
      expect(recorded?.amount).toBe(300);
      expect(recorded?.currency).toBe('INR');
      expect(recorded?.processedAt).toBeDefined();
    });

    it('39. should query webhook events via AdminService.getWebhooks with safe projection', async () => {
      webhookEventsStore.set('evt_admin_test_1', {
        id: 'evt_admin_test_1',
        provider: 'razorpay',
        eventType: 'payment.captured',
        status: 'PROCESSED',
        providerPaymentId: 'pay_adm_1',
        providerOrderId: 'order_adm_1',
        bookingId: 'bk_adm_1',
        amount: 500,
        amountInMinorUnits: 50000,
        currency: 'INR',
        payload: { test: true },
        receivedAt: new Date(),
        updatedAt: new Date(),
      });

      const webhooks = await adminService.getWebhooks(10, 0);
      expect(webhooks.length).toBeGreaterThan(0);
      const item = webhooks.find((w) => w.id === 'evt_admin_test_1');
      expect(item).toBeDefined();
      expect(item?.providerPaymentId).toBe('pay_adm_1');
      expect(item?.amountInMinorUnits).toBe(50000);
      expect((item as any).secret).toBeUndefined();
    });

    it('40. should access GET /api/v1/admin/webhooks via AdminController', async () => {
      const res = await adminController.getWebhooks({ limit: 20, offset: 0 });
      expect(Array.isArray(res)).toBe(true);
    });

    it('41. should verify migration 1790800000000 has valid up and down statements', async () => {
      const migration = new EnhanceWebhookEventsTable1790800000000();
      const mockQueryRunner = {
        query: jest.fn(async () => []),
      };

      await migration.up(mockQueryRunner as any);
      expect(mockQueryRunner.query).toHaveBeenCalledWith(
        expect.stringContaining('ALTER TABLE "webhook_events" ADD COLUMN IF NOT EXISTS "status"'),
      );

      await migration.down(mockQueryRunner as any);
      expect(mockQueryRunner.query).toHaveBeenCalledWith(
        expect.stringContaining('ALTER TABLE "webhook_events" DROP COLUMN IF EXISTS "status"'),
      );
    });
  });

  // ==========================================
  // 8. SECURITY & SECRET PROTECTION (42-44)
  // ==========================================
  describe('8. Security & Secret Protection', () => {
    it('42. should ensure paymentMode is SIMULATED and RAZORPAY_LIVE_ENABLED is false in all env configs', () => {
      expect(configService.getPaymentMode()).toBe('SIMULATED');
      expect(configService.isRazorpayLiveEnabled()).toBe(false);

      const renderYamlPath = path.resolve(__dirname, '../../render.yaml');
      if (fs.existsSync(renderYamlPath)) {
        const renderYaml = fs.readFileSync(renderYamlPath, 'utf8');
        expect(renderYaml).toContain('RAZORPAY_LIVE_ENABLED');
        expect(renderYaml).toContain('false');
        expect(renderYaml).toContain('PAYMENT_MODE');
        expect(renderYaml).toContain('SIMULATED');
      }
    });

    it('43. should never leak secrets or private credentials in webhook controller return payloads', async () => {
      const payloadObj = {
        id: 'evt_sec_check',
        event: 'payment.captured',
        payload: {},
      };
      const raw = JSON.stringify(payloadObj);
      const sig = calculateHmacSignature(raw, TEST_WEBHOOK_SECRET);

      const res = await webhooksController.handleRazorpayWebhook(sig, payloadObj);
      const resStr = JSON.stringify(res);
      expect(resStr).not.toContain(TEST_KEY_SECRET);
      expect(resStr).not.toContain(TEST_WEBHOOK_SECRET);
      expect(resStr).not.toContain('rzp_live_');
    });

    it('44. should confirm codebase has zero live Razorpay keys or hardcoded production secrets', () => {
      const filesToCheck = [
        path.resolve(__dirname, 'modules/payments/webhooks.controller.ts'),
        path.resolve(__dirname, 'modules/payments/payment-config.service.ts'),
        path.resolve(__dirname, 'modules/payments/payment.service.ts'),
        path.resolve(__dirname, 'modules/payments/providers/razorpay.adapter.ts'),
        path.resolve(__dirname, 'modules/admin/admin.service.ts'),
        path.resolve(__dirname, 'modules/admin/admin.controller.ts'),
      ];

      for (const file of filesToCheck) {
        if (fs.existsSync(file)) {
          const content = fs.readFileSync(file, 'utf8');
          expect(content).not.toMatch(/rzp_live_[a-zA-Z0-9]{14,}/);
          expect(content).not.toMatch(/['"]rzp_live_/);
        }
      }

      expect(configService.isRazorpayLiveEnabled()).toBe(false);
      expect(configService.getPaymentMode()).toBe('SIMULATED');
    });
  });
});
