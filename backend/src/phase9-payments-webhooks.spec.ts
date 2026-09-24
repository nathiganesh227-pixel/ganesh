import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { WebhooksController } from './modules/payments/webhooks.controller';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { PaymentService } from './modules/payments/payment.service';
import { TwilioSmsAdapter } from './modules/notifications/providers/twilio-sms.adapter';
import { WebhookEventEntity } from './database/entities/webhook-event.entity';
import { BookingEntity, BookingStatus } from './database/entities/booking.entity';
import { UnauthorizedException } from '@nestjs/common';
import * as crypto from 'crypto';

describe('Phase 9 Payment Provider Adapters & Webhook Security Tests', () => {
  let webhooksController: WebhooksController;
  let razorpayAdapter: RazorpayAdapter;
  let simulatedAdapter: SimulatedPaymentAdapter;
  let paymentService: PaymentService;
  let twilioAdapter: TwilioSmsAdapter;

  const mockWebhookEvents: WebhookEventEntity[] = [];
  const mockBookings: BookingEntity[] = [];

  const secret = 'whsec_test_plaza2026';

  beforeAll(async () => {
    process.env.RAZORPAY_WEBHOOK_SECRET = secret;
    process.env.RAZORPAY_KEY_SECRET = 'secret_test_plaza2026';

    razorpayAdapter = new RazorpayAdapter();
    simulatedAdapter = new SimulatedPaymentAdapter();
    paymentService = new PaymentService(razorpayAdapter, simulatedAdapter);
    twilioAdapter = new TwilioSmsAdapter();

    const mockWebhookRepo = {
      findOne: jest.fn().mockImplementation(({ where }) => {
        return Promise.resolve(mockWebhookEvents.find((e) => e.id === where.id) || null);
      }),
      create: jest.fn().mockImplementation((dto) => ({ ...dto })),
      save: jest.fn().mockImplementation((event) => {
        mockWebhookEvents.push(event);
        return Promise.resolve(event);
      }),
    };

    const mockBookingRepo = {
      findOne: jest.fn().mockImplementation(({ where }) => {
        return Promise.resolve(mockBookings.find((b) => b.id === where.id) || null);
      }),
      save: jest.fn().mockImplementation((booking) => {
        const idx = mockBookings.findIndex((b) => b.id === booking.id);
        if (idx >= 0) mockBookings[idx] = booking;
        else mockBookings.push(booking);
        return Promise.resolve(booking);
      }),
      createQueryBuilder: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockImplementation(async () => {
          return mockBookings.find((b) => b.metadata?.payment?.paymentId) || null;
        }),
      }),
    };

    webhooksController = new WebhooksController(
      razorpayAdapter,
      mockWebhookRepo as any,
      mockBookingRepo as any,
      twilioAdapter,
    );
  });

  beforeEach(() => {
    mockWebhookEvents.length = 0;
    mockBookings.length = 0;
  });

  // 1. PAYMENT PROVIDER ADAPTERS
  describe('Payment Provider Adapters', () => {
    it('RazorpayAdapter creates order with correct amount in paise', async () => {
      const order = await razorpayAdapter.createOrder({
        bookingId: 'PLZ-MOV-100',
        amount: 450,
      });

      expect(order.orderId).toBeDefined();
      expect(order.provider).toBe('razorpay');
      expect(order.raw.amount).toBe(45000); // 450 * 100 paise
      expect(order.raw.currency).toBe('INR');
    });

    it('RazorpayAdapter verifies valid HMAC-SHA256 signature and rejects tampered ones', () => {
      const payload = JSON.stringify({ event: 'payment.captured', id: 'evt_1' });
      const validSignature = crypto.createHmac('sha256', secret).update(payload).digest('hex');

      expect(razorpayAdapter.verifyWebhookSignature(payload, validSignature)).toBe(true);
      expect(razorpayAdapter.verifyWebhookSignature(payload, 'invalid_signature_12345')).toBe(false);
      expect(razorpayAdapter.verifyWebhookSignature('{"tampered":true}', validSignature)).toBe(false);
    });

    it('RazorpayAdapter verifies checkout completion signature', () => {
      const orderId = 'order_abc123';
      const paymentId = 'pay_xyz789';
      const keySecret = 'secret_test_plaza2026';
      const expectedSignature = crypto
        .createHmac('sha256', keySecret)
        .update(`${orderId}|${paymentId}`)
        .digest('hex');

      const isValid = razorpayAdapter.verifyPaymentSignature({
        orderId,
        paymentId,
        signature: expectedSignature,
      });

      expect(isValid).toBe(true);
    });

    it('SimulatedPaymentAdapter creates instantly settled orders and processes refunds', async () => {
      const order = await simulatedAdapter.createOrder({
        bookingId: 'PLZ-DIN-200',
        amount: 1200,
      });
      expect(order.status).toBe('PAID');
      expect(order.provider).toBe('simulated');

      const refund = await simulatedAdapter.refund({
        paymentId: 'pay_sim_123',
        amount: 1200,
      });
      expect(refund.status).toBe('REFUNDED');
      expect(refund.amount).toBe(1200);
    });

    it('TwilioSmsAdapter dispatches confirmation SMS', async () => {
      const result = await twilioAdapter.sendSms({
        to: '+919876543210',
        message: 'Your booking is confirmed',
      });
      expect(result.success).toBe(true);
      expect(result.messageId.startsWith('SM_')).toBe(true);
    });
  });

  // 2. WEBHOOK SECURITY & IDEMPOTENCY
  describe('Webhook Security & Idempotency Enforcement', () => {
    it('rejects webhooks with missing signature header (401 Unauthorized)', async () => {
      await expect(
        webhooksController.handleRazorpayWebhook('', { event: 'order.paid' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects webhooks with forged signature (401 Unauthorized)', async () => {
      const body = { event: 'order.paid', id: 'evt_forged' };
      await expect(
        webhooksController.handleRazorpayWebhook('bad_forged_sig', body),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('processes genuine order.paid webhook and transitions booking to UPCOMING', async () => {
      // Seed pending booking
      const booking: BookingEntity = {
        id: 'PLZ-MOV-777',
        userId: 'usr_userA',
        type: 'movie' as any,
        title: 'Kalki 2898 AD',
        subtitle: 'Prasads IMAX',
        imageUrl: 'https://example.com/poster.jpg',
        date: '2026-10-10',
        time: '08:00 PM',
        location: 'Hyderabad',
        status: BookingStatus.PENDING,
        totalPrice: 1015,
        qrCodeData: 'QR-777',
        metadata: {},
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      mockBookings.push(booking);

      const payload = {
        id: 'evt_order_paid_101',
        event: 'order.paid',
        payload: {
          order: { entity: { id: 'order_101', receipt: 'PLZ-MOV-777' } },
          payment: { entity: { id: 'pay_rzp_999', amount: 101500 } },
        },
      };

      const raw = JSON.stringify(payload);
      const signature = crypto.createHmac('sha256', secret).update(raw).digest('hex');

      const response = await webhooksController.handleRazorpayWebhook(signature, payload);
      expect(response.success).toBe(true);
      expect(response.eventId).toBe('evt_order_paid_101');

      // Booking status should now be UPCOMING/CONFIRMED with payment metadata
      expect(booking.status).toBe(BookingStatus.UPCOMING);
      expect(booking.metadata.payment.paymentId).toBe('pay_rzp_999');
      expect(booking.metadata.payment.amount).toBe(1015);
      expect(booking.metadata.payment.provider).toBe('razorpay');
    });

    it('enforces idempotency and ignores replayed webhook events', async () => {
      const payload = {
        id: 'evt_duplicate_replay_500',
        event: 'order.paid',
        payload: {
          order: { entity: { id: 'order_500', receipt: 'PLZ-MOV-777' } },
          payment: { entity: { id: 'pay_500', amount: 50000 } },
        },
      };

      const raw = JSON.stringify(payload);
      const signature = crypto.createHmac('sha256', secret).update(raw).digest('hex');

      // First delivery: processes successfully
      const firstDelivery = await webhooksController.handleRazorpayWebhook(signature, payload);
      expect(firstDelivery.success).toBe(true);

      // Second delivery (Replay attack / duplicate): safely ignored!
      const secondDelivery: any = await webhooksController.handleRazorpayWebhook(signature, payload);
      expect(secondDelivery.status).toBe('ignored');
      expect(secondDelivery.reason).toBe('already_processed');
    });

    it('transitions booking to FAILED upon payment.failed webhook', async () => {
      const booking: BookingEntity = {
        id: 'PLZ-SPT-888',
        userId: 'usr_userA',
        type: 'sports' as any,
        title: 'Box Cricket Arena',
        subtitle: 'Court 1',
        imageUrl: 'https://example.com/sports.jpg',
        date: '2026-10-12',
        time: '06:00 AM',
        location: 'Hyderabad',
        status: BookingStatus.PENDING,
        totalPrice: 1250,
        qrCodeData: 'QR-888',
        metadata: {},
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      mockBookings.push(booking);

      const payload = {
        id: 'evt_pay_failed_404',
        event: 'payment.failed',
        payload: {
          payment: {
            entity: {
              id: 'pay_fail_111',
              notes: { bookingId: 'PLZ-SPT-888' },
              error_description: 'Card declined by issuing bank',
            },
          },
        },
      };

      const raw = JSON.stringify(payload);
      const signature = crypto.createHmac('sha256', secret).update(raw).digest('hex');

      const response = await webhooksController.handleRazorpayWebhook(signature, payload);
      expect(response.success).toBe(true);
      expect(booking.status).toBe(BookingStatus.FAILED);
      expect(booking.metadata.failureReason).toBe('Card declined by issuing bank');
    });
  });
});
