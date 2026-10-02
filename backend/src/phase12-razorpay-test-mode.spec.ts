import * as crypto from 'crypto';
import {
  BadRequestException,
  UnauthorizedException,
  BadGatewayException,
  ForbiddenException,
} from '@nestjs/common';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { PaymentConfigService, PaymentMode, PaymentConfigStatus } from './modules/payments/payment-config.service';
import { PaymentService } from './modules/payments/payment.service';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { PaymentStatus, toMinorUnits } from './database/entities/payment.entity';
import { WebhooksController } from './modules/payments/webhooks.controller';
import { WebhookEventEntity } from './database/entities/webhook-event.entity';
import { BookingEntity, BookingStatus, BookingType } from './database/entities/booking.entity';

describe('Phase 12 — Razorpay Test Mode Architecture Suite', () => {
  const TEST_KEY_ID = 'rzp_test_1234567890abcdef';
  const TEST_KEY_SECRET = 'test_secret_abcdef1234567890';
  const TEST_WEBHOOK_SECRET = 'test_webhook_secret_99887766';

  let configService: PaymentConfigService;
  let razorpayAdapter: RazorpayAdapter;
  let simulatedAdapter: SimulatedPaymentAdapter;
  let paymentService: PaymentService;

  beforeEach(() => {
    configService = new PaymentConfigService({
      NODE_ENV: 'test',
      PAYMENT_MODE: 'RAZORPAY',
      RAZORPAY_LIVE_ENABLED: 'true',
      RAZORPAY_KEY_ID: TEST_KEY_ID,
      RAZORPAY_KEY_SECRET: TEST_KEY_SECRET,
      RAZORPAY_WEBHOOK_SECRET: TEST_WEBHOOK_SECRET,
    });
    razorpayAdapter = new RazorpayAdapter(configService);
    simulatedAdapter = new SimulatedPaymentAdapter();
    paymentService = new PaymentService(
      razorpayAdapter,
      simulatedAdapter,
      undefined,
      configService,
    );
  });

  // ---------------------------------------------------------------------------
  // 1. ORDER CREATION & AMOUNT VALIDATION
  // ---------------------------------------------------------------------------
  describe('1. Razorpay Order Creation & Strict Amount Validation', () => {
    it('1.1 should create a valid order with server-authoritative amount in minor units and INR currency', async () => {
      const order = await razorpayAdapter.createOrder({
        bookingId: 'BK_TEST_001',
        amount: 10.0, // ₹10.00
        currency: 'INR',
        receipt: 'rec_bk_001',
        notes: { userId: 'usr_test_1', type: 'movie' },
      });

      expect(order.orderId).toBeDefined();
      expect(order.amount).toBe(10.0);
      expect(order.amountInMinorUnits).toBe(1000); // 1000 paise
      expect(order.currency).toBe('INR');
      expect(order.provider).toBe('razorpay');
      expect(order.keyId).toBe(TEST_KEY_ID);
      expect(order.status).toBe('CREATED');
    });

    it('1.2 should strictly reject order creation when amount is less than 100 paise (< ₹1.00)', async () => {
      await expect(
        razorpayAdapter.createOrder({
          bookingId: 'BK_TEST_INVALID',
          amount: 0.5, // 50 paise (< 100 paise)
          currency: 'INR',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('1.3 should strictly reject non-INR currencies', async () => {
      await expect(
        razorpayAdapter.createOrder({
          bookingId: 'BK_TEST_USD',
          amount: 100,
          currency: 'USD',
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. SIGNATURE VERIFICATION (PAYMENT & WEBHOOK)
  // ---------------------------------------------------------------------------
  describe('2. Cryptographic Signature Verification', () => {
    it('2.1 should successfully verify valid checkout HMAC-SHA256 signature', () => {
      const orderId = 'order_test_12345';
      const paymentId = 'pay_test_67890';
      const payload = `${orderId}|${paymentId}`;
      const validSignature = crypto
        .createHmac('sha256', TEST_KEY_SECRET)
        .update(payload)
        .digest('hex');

      const isValid = razorpayAdapter.verifyPaymentSignature({
        orderId,
        paymentId,
        signature: validSignature,
      });

      expect(isValid).toBe(true);
    });

    it('2.2 should reject tampered or invalid payment signature', () => {
      const orderId = 'order_test_12345';
      const paymentId = 'pay_test_67890';
      const tamperedSignature = crypto
        .createHmac('sha256', 'wrong_secret')
        .update(`${orderId}|${paymentId}`)
        .digest('hex');

      const isValid = razorpayAdapter.verifyPaymentSignature({
        orderId,
        paymentId,
        signature: tamperedSignature,
      });

      expect(isValid).toBe(false);
    });

    it('2.3 should reject signature verification with missing or empty parameters', () => {
      expect(
        razorpayAdapter.verifyPaymentSignature({
          orderId: '',
          paymentId: 'pay_test_1',
          signature: 'abcd',
        }),
      ).toBe(false);

      expect(
        razorpayAdapter.verifyPaymentSignature({
          orderId: 'order_test_1',
          paymentId: '',
          signature: 'abcd',
        }),
      ).toBe(false);

      expect(
        razorpayAdapter.verifyPaymentSignature({
          orderId: 'order_test_1',
          paymentId: 'pay_test_1',
          signature: '',
        }),
      ).toBe(false);
    });

    it('2.4 should successfully verify valid webhook HMAC-SHA256 signature with raw body', () => {
      const rawPayload = JSON.stringify({
        event: 'order.paid',
        payload: { payment: { entity: { id: 'pay_test_001', amount: 50000 } } },
      });
      const validSignature = crypto
        .createHmac('sha256', TEST_WEBHOOK_SECRET)
        .update(rawPayload)
        .digest('hex');

      const isValid = razorpayAdapter.verifyWebhookSignature(rawPayload, validSignature);
      expect(isValid).toBe(true);
    });

    it('2.5 should reject invalid webhook signature', () => {
      const rawPayload = JSON.stringify({ event: 'order.paid' });
      const invalidSignature = '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

      const isValid = razorpayAdapter.verifyWebhookSignature(rawPayload, invalidSignature);
      expect(isValid).toBe(false);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. CANONICAL PRICING & QUOTE INTEGRITY
  // ---------------------------------------------------------------------------
  describe('3. Server-Authoritative Pricing & Quote Integration', () => {
    it('3.1 should create order strictly using server quote amount and reject client tampering', async () => {
      paymentService.registerQuote(
        {
          quoteId: 'QUO_TEST_999',
          type: 'event',
          vertical: 'events',
          subtotal: 500,
          discount: 50,
          taxes: 45,
          tax: 45,
          convenienceFee: 20,
          fees: 20,
          total: 515,
          grandTotal: 515,
          currency: 'INR',
          expiresAt: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
        },
        { userId: 'usr_test_1', bookingId: 'BK_EVT_999' },
      );

      // Normal order creation without client tampering
      const orderSession = await paymentService.createPaymentOrder({
        quoteId: 'QUO_TEST_999',
        bookingId: 'BK_EVT_999',
        userId: 'usr_test_1',
      });

      expect(orderSession.amount).toBe(515); // Server authoritative ₹515
      expect(orderSession.amountInMinorUnits).toBe(51500); // 51500 paise
      expect(orderSession.provider).toBe('razorpay');
      expect(orderSession.keyId).toBe(TEST_KEY_ID);
      // Secrets must never appear in order response
      expect((orderSession as any).keySecret).toBeUndefined();
      expect((orderSession as any).secret).toBeUndefined();

      // Malicious client attempting to tamper with total is rejected
      await expect(
        paymentService.createPaymentOrder({
          quoteId: 'QUO_TEST_999',
          bookingId: 'BK_EVT_999',
          userId: 'usr_test_1',
          clientAmount: 1.0, // Tampered amount
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. SECRETS SANITIZATION
  // ---------------------------------------------------------------------------
  describe('4. Secrets Protection & Security Invariants', () => {
    it('4.1 should never expose RAZORPAY_KEY_SECRET in config summaries or responses', () => {
      const summary = configService.getSafeSummary();
      expect(summary.paymentMode).toBe(PaymentMode.RAZORPAY);
      expect(summary.razorpayLiveEnabled).toBe(true);
      expect(summary.razorpayConfigured).toBe(true);
      expect(summary.paymentConfigStatus).toBe(PaymentConfigStatus.RAZORPAY_READY);
      expect((summary as any).keySecret).toBeUndefined();
      expect((summary as any).razorpayKeySecret).toBeUndefined();
      expect((summary as any).webhookSecret).toBeUndefined();
    });
  });

  // ---------------------------------------------------------------------------
  // 5. WEBHOOK PROCESSING & DEDUPLICATION
  // ---------------------------------------------------------------------------
  describe('5. Webhook Handling & Deduplication', () => {
    let webhookController: WebhooksController;
    let webhookEvents: Map<string, WebhookEventEntity>;
    let bookings: Map<string, BookingEntity>;

    beforeEach(() => {
      webhookEvents = new Map();
      bookings = new Map();

      const mockWebhookRepo: any = {
        create: jest.fn((e) => ({ ...e })),
        save: jest.fn(async (e) => {
          webhookEvents.set(e.id, e);
          return e;
        }),
        findOne: jest.fn(async ({ where }) => {
          if (where.id) return webhookEvents.get(where.id) || null;
          return null;
        }),
      };

      const mockBookingRepo: any = {
        findOne: jest.fn(async ({ where }) => {
          if (where.id) return bookings.get(where.id) || null;
          return null;
        }),
        save: jest.fn(async (b) => {
          bookings.set(b.id, b);
          return b;
        }),
      };

      const mockNotificationAdapter: any = {
        sendSms: jest.fn(async () => true),
      };

      webhookController = new WebhooksController(
        razorpayAdapter,
        mockWebhookRepo,
        mockBookingRepo,
        mockNotificationAdapter,
      );
    });

    it('5.1 should process order.paid webhook event and confirm booking', async () => {
      const booking = {
        id: 'PLZ-WH-001',
        userId: 'usr_test_1',
        status: BookingStatus.PENDING,
        title: 'Standup Comedy Night',
        totalPrice: 499,
        type: BookingType.EVENT,
      } as BookingEntity;
      bookings.set(booking.id, booking);

      const payload = {
        id: 'evt_test_001',
        event: 'order.paid',
        payload: {
          order: {
            entity: {
              id: 'order_test_wh_1',
              receipt: 'PLZ-WH-001',
              amount: 49900,
              currency: 'INR',
              status: 'paid',
            },
          },
          payment: {
            entity: {
              id: 'pay_test_wh_1',
              order_id: 'order_test_wh_1',
              amount: 49900,
              currency: 'INR',
              status: 'captured',
            },
          },
        },
      };

      const rawBody = JSON.stringify(payload);
      const signature = crypto
        .createHmac('sha256', TEST_WEBHOOK_SECRET)
        .update(rawBody)
        .digest('hex');

      const result = await webhookController.handleRazorpayWebhook(
        signature,
        payload,
        { rawBody },
      );

      expect(result.status).toBe('processed');
      const finalStatus = bookings.get('PLZ-WH-001')?.status;
      expect([BookingStatus.CONFIRMED, BookingStatus.UPCOMING]).toContain(finalStatus);
    });

    it('5.2 should deduplicate replayed webhook events idempotently with zero duplicate side effects', async () => {
      const existingEvent: WebhookEventEntity = {
        id: 'evt_test_duplicate',
        provider: 'razorpay',
        eventType: 'order.paid',
        payload: {},
        status: 'PROCESSED',
        currency: 'INR',
        receivedAt: new Date(),
        updatedAt: new Date(),
      };
      webhookEvents.set(existingEvent.id, existingEvent);

      const payload = {
        id: 'evt_test_duplicate',
        event: 'order.paid',
      };
      const rawBody = JSON.stringify(payload);
      const signature = crypto
        .createHmac('sha256', TEST_WEBHOOK_SECRET)
        .update(rawBody)
        .digest('hex');

      const result = await webhookController.handleRazorpayWebhook(
        signature,
        payload,
        { rawBody },
      );

      expect(result.status).toBe('ignored');
      expect(result.reason).toBe('already_processed');
    });
  });
});
