import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UnauthorizedException, BadRequestException, NotFoundException } from '@nestjs/common';
import * as crypto from 'crypto';
import { BookingsService } from './modules/bookings/bookings.service';
import { BookingsController } from './modules/bookings/bookings.controller';
import { PaymentsController } from './modules/payments/payments.controller';
import { WebhooksController } from './modules/payments/webhooks.controller';
import { PaymentService } from './modules/payments/payment.service';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { TwilioSmsAdapter } from './modules/notifications/providers/twilio-sms.adapter';
import { BookingEntity, BookingStatus, BookingType } from './database/entities/booking.entity';
import { PaymentEntity, PaymentStatus } from './database/entities/payment.entity';
import { WebhookEventEntity } from './database/entities/webhook-event.entity';
import { User } from './database/entities/user.entity';
import { TheatreEntity } from './database/entities/theatre.entity';
import { EventEntity } from './database/entities/event.entity';
import { ActivityEntity } from './database/entities/activity.entity';
import { ProductEntity } from './database/entities/product.entity';
import { HotelEntity } from './database/entities/hotel.entity';
import { SportsVenueEntity } from './database/entities/sports-venue.entity';

describe('Phase 20 Payments & Booking Hardening Tests', () => {
  let bookingsService: BookingsService;
  let bookingsController: BookingsController;
  let paymentsController: PaymentsController;
  let webhooksController: WebhooksController;
  let paymentService: PaymentService;
  let razorpayAdapter: RazorpayAdapter;
  let simulatedAdapter: SimulatedPaymentAdapter;

  const mockKeySecret = 'test_rzp_key_secret_2026';
  const mockWebhookSecret = 'test_whsec_2026';

  const mockBookings: BookingEntity[] = [];
  const mockPayments: PaymentEntity[] = [];
  const mockWebhookEvents: WebhookEventEntity[] = [];
  const mockUsers: User[] = [
    {
      id: 'usr_test_1',
      email: 'user1@plaza.local',
      passwordHash: 'hash',
      name: 'Test Customer',
      role: 'user',
      city: 'Hyderabad',
      rewardPoints: 500,
      createdAt: new Date(),
      updatedAt: new Date(),
    } as User,
  ];

  const mockEvents: EventEntity[] = [
    {
      id: 'evt_rock_fest',
      title: 'Hyderabad Rock Fest',
      category: 'Music',
      eventDate: '2026-11-20',
      time: '07:00 PM',
      venue: 'Gachibowli Stadium',
      location: 'Hyderabad',
      price: 999,
      ticketTiers: [
        { id: 'tier_vip', name: 'VIP Pass', price: 2500, remainingCount: 10, totalCount: 50 },
        { id: 'tier_ga', name: 'General Admission', price: 999, remainingCount: 100, totalCount: 200 },
      ],
      isPublished: true,
    } as any,
  ];

  const mockActivities: ActivityEntity[] = [
    {
      id: 'act_go_karting',
      title: 'Pro Go-Karting 500cc',
      category: 'Adventures',
      startingPrice: 1200,
      packages: [
        { id: 'pkg_pro', name: 'Pro 10 Laps', pricePerPerson: 1500, duration: '20 mins', highlights: [] },
      ],
      addOns: [
        { id: 'addon_gopro', name: 'GoPro Helmet Cam', price: 300, description: '4K video footage' },
      ],
      timeSlots: [
        { time: '04:00 PM', availableSlots: 8, isFillingFast: false },
      ],
      isPublished: true,
    } as any,
  ];

  const mockHotels: HotelEntity[] = [
    {
      id: 'hotel_taj_falaknuma',
      name: 'Taj Falaknuma Palace',
      rooms: [
        { id: 'room_palace_suite', name: 'Palace Suite', pricePerNight: 35000, maxGuests: 2, isAvailable: true } as any,
      ],
      addOns: [
        { id: 'addon_airport_transfer', name: 'Luxury Airport Transfer', price: 3500, description: 'Rolls Royce transfer' },
      ],
      isPublished: true,
    } as any,
  ];

  const mockTheatres: TheatreEntity[] = [
    {
      id: 'theatre_prasad',
      name: 'Prasads Multiplex',
      location: 'Hyderabad',
      showtimes: [
        { id: 'st_imax_1', time: '07:30 PM', format: 'IMAX 3D', basePrice: 450 },
      ],
      isPublished: true,
    } as any,
  ];

  const mockSportsVenues: SportsVenueEntity[] = [
    {
      id: 'venue_squad_turf',
      name: 'Gachibowli Box Arena',
      slots: [
        { id: 'slot_8pm', startTime: '08:00 PM', endTime: '09:00 PM', price: 1200, isAvailable: true },
      ],
      addOns: [
        { id: 'addon_cricket_kit', name: 'SG Pro Kit', price: 200, description: 'Bat and pads' },
      ],
      isPublished: true,
    } as any,
  ];

  const mockProducts: ProductEntity[] = [
    {
      id: 'prod_hoodie',
      name: 'Plaza Stealth Hoodie',
      price: 2499,
      variants: [
        { id: 'var_xl', name: 'XL Black', priceDelta: 200, inStock: true },
      ],
      inStock: true,
      isPublished: true,
    } as any,
  ];

  beforeAll(async () => {
    process.env.RAZORPAY_KEY_SECRET = mockKeySecret;
    process.env.RAZORPAY_WEBHOOK_SECRET = mockWebhookSecret;

    razorpayAdapter = new RazorpayAdapter();
    simulatedAdapter = new SimulatedPaymentAdapter();

    const mockPaymentRepo = {
      create: jest.fn().mockImplementation((dto) => ({ ...dto })),
      save: jest.fn().mockImplementation((p) => {
        const idx = mockPayments.findIndex((x) => x.id === p.id);
        if (idx >= 0) mockPayments[idx] = p;
        else mockPayments.push(p);
        return Promise.resolve(p);
      }),
      findOne: jest.fn().mockImplementation(({ where }) => {
        if (Array.isArray(where)) {
          for (const cond of where) {
            const found = mockPayments.find((p) =>
              (cond.bookingId && p.bookingId === cond.bookingId) ||
              (cond.providerOrderId && p.providerOrderId === cond.providerOrderId) ||
              (cond.providerPaymentId && p.providerPaymentId === cond.providerPaymentId) ||
              (cond.id && p.id === cond.id),
            );
            if (found) return Promise.resolve(found);
          }
          return Promise.resolve(null);
        }
        return Promise.resolve(
          mockPayments.find((p) =>
            (where.id && p.id === where.id) ||
            (where.bookingId && p.bookingId === where.bookingId) ||
            (where.providerOrderId && p.providerOrderId === where.providerOrderId) ||
            (where.providerPaymentId && p.providerPaymentId === where.providerPaymentId),
          ) || null,
        );
      }),
    };

    const mockBookingRepo = {
      create: jest.fn().mockImplementation((dto) => ({ ...dto })),
      save: jest.fn().mockImplementation((b) => {
        const idx = mockBookings.findIndex((x) => x.id === b.id);
        if (idx >= 0) mockBookings[idx] = b;
        else mockBookings.push(b);
        return Promise.resolve(b);
      }),
      findOne: jest.fn().mockImplementation(({ where }) => {
        return Promise.resolve(mockBookings.find((b) => b.id === where.id) || null);
      }),
      createQueryBuilder: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
        getOne: jest.fn().mockImplementation(async () => {
          return mockBookings.find((b) => b.metadata?.payment?.paymentId) || null;
        }),
      }),
    };

    const mockUserRepo = {
      findOne: jest.fn().mockImplementation(({ where }) => {
        return Promise.resolve(mockUsers.find((u) => u.id === where.id) || null);
      }),
      save: jest.fn().mockImplementation((u) => Promise.resolve(u)),
    };

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

    const mockEventRepo = {
      findOne: jest.fn().mockImplementation(({ where }) => {
        return Promise.resolve(mockEvents.find((e) => e.id === where.id) || null);
      }),
      save: jest.fn().mockImplementation((e) => Promise.resolve(e)),
    };

    const mockActivityRepo = {
      findOne: jest.fn().mockImplementation(({ where }) => {
        return Promise.resolve(mockActivities.find((a) => a.id === where.id) || null);
      }),
      save: jest.fn().mockImplementation((a) => Promise.resolve(a)),
    };

    const mockDataSource = {
      getRepository: jest.fn().mockImplementation((entity) => {
        if (entity === BookingEntity) return mockBookingRepo;
        if (entity === PaymentEntity) return mockPaymentRepo;
        if (entity === User) return mockUserRepo;
        if (entity === EventEntity) return mockEventRepo;
        if (entity === ActivityEntity) return mockActivityRepo;
        if (entity === HotelEntity) {
          return { findOne: jest.fn().mockImplementation(({ where }) => mockHotels.find((h) => h.id === where.id)) };
        }
        if (entity === TheatreEntity) {
          return { findOne: jest.fn().mockImplementation(({ where }) => mockTheatres.find((t) => t.id === where.id)) };
        }
        if (entity === SportsVenueEntity) {
          return { findOne: jest.fn().mockImplementation(({ where }) => mockSportsVenues.find((s) => s.id === where.id)) };
        }
        if (entity === ProductEntity) {
          return { findOne: jest.fn().mockImplementation(({ where }) => mockProducts.find((p) => p.id === where.id)) };
        }
        return mockBookingRepo;
      }),
      transaction: jest.fn().mockImplementation(async (cb) => {
        const mockManager = {
          getRepository: (entity: any) => mockDataSource.getRepository(entity),
          findOne: (entity: any, opts: any) => mockDataSource.getRepository(entity).findOne(opts),
          save: (entity: any, val: any) => val ? mockDataSource.getRepository(entity).save(val) : mockDataSource.getRepository(entity).save(entity),
        };
        return cb(mockManager);
      }),
    };

    paymentService = new PaymentService(razorpayAdapter, simulatedAdapter, mockPaymentRepo as any);
    bookingsService = new BookingsService(mockDataSource as any, paymentService);

    const mockIdempotencyService = {
      get: jest.fn().mockResolvedValue(null),
      save: jest.fn().mockResolvedValue(true),
    };

    bookingsController = new BookingsController(bookingsService, mockIdempotencyService as any);

    const twilioAdapter = new TwilioSmsAdapter();

    paymentsController = new PaymentsController(
      paymentService,
      razorpayAdapter,
      mockBookingRepo as any,
      mockPaymentRepo as any,
      mockUserRepo as any,
      mockEventRepo as any,
      mockActivityRepo as any,
      twilioAdapter,
    );

    webhooksController = new WebhooksController(
      razorpayAdapter,
      mockWebhookRepo as any,
      mockBookingRepo as any,
      twilioAdapter,
      mockPaymentRepo as any,
      mockUserRepo as any,
      mockEventRepo as any,
      mockActivityRepo as any,
    );
  });

  beforeEach(() => {
    mockBookings.length = 0;
    mockPayments.length = 0;
    mockWebhookEvents.length = 0;
    mockUsers[0].rewardPoints = 500;
    mockEvents[0].ticketTiers[0].remainingCount = 10;
    mockActivities[0].timeSlots[0].availableSlots = 8;
  });

  // 1. QUOTE API ACROSS ALL 7 VERTICALS
  describe('Quote API Calculation Across All 7 Verticals', () => {
    it('calculates Movie quote: basePrice * seats + 70 convenience + 5% tax', async () => {
      const quote = await bookingsController.calculateQuote({
        type: 'movie',
        theatreId: 'theatre_prasad',
        showtimeId: 'st_imax_1',
        seatIds: ['E1', 'E2'],
      });

      // 450 * 2 = 900 subtotal, 70 convenience, round(900 * 0.05) = 45 tax => 1015 grandTotal
      expect(quote.type).toBe('movie');
      expect(quote.subtotal).toBe(900);
      expect(quote.convenienceFee).toBe(70);
      expect(quote.taxes).toBe(45);
      expect(quote.grandTotal).toBe(1015);
      expect(quote.currency).toBe('INR');
    });

    it('calculates Dining quote as complimentary (0 INR)', async () => {
      const quote = await bookingsController.calculateQuote({
        type: 'dining',
        restaurantId: 'rest_jewel',
        guestsCount: 4,
      });

      expect(quote.type).toBe('dining');
      expect(quote.subtotal).toBe(0);
      expect(quote.grandTotal).toBe(0);
      expect(quote.breakdown.pricingModel).toBe('COMPLIMENTARY');
    });

    it('calculates Event quote: tier.price * tickets + 5% convenience', async () => {
      const quote = await bookingsController.calculateQuote({
        type: 'event',
        eventId: 'evt_rock_fest',
        tierId: 'tier_vip',
        ticketCount: 2,
      });

      // 2500 * 2 = 5000 subtotal, 5% convenience = 250 => 5250 grandTotal
      expect(quote.type).toBe('event');
      expect(quote.subtotal).toBe(5000);
      expect(quote.convenienceFee).toBe(250);
      expect(quote.grandTotal).toBe(5250);
    });

    it('calculates Activity quote: (pkgPrice * people) + addOns + 18% tax', async () => {
      const quote = await bookingsController.calculateQuote({
        type: 'activity',
        activityId: 'act_go_karting',
        packageId: 'pkg_pro',
        numberOfPeople: 2,
        addOnIds: ['addon_gopro'],
      });

      // (1500 * 2) + 300 = 3300 subtotal, 18% tax = 594 => 3894 grandTotal
      expect(quote.type).toBe('activity');
      expect(quote.subtotal).toBe(3300);
      expect(quote.taxes).toBe(594);
      expect(quote.grandTotal).toBe(3894);
    });

    it('calculates Shopping quote: items + 29 platform fee + 5% GST', async () => {
      const quote = await bookingsController.calculateQuote({
        type: 'shopping',
        items: [
          { productId: 'prod_hoodie', variantId: 'var_xl', quantity: 2 },
        ],
      });

      // Unit price = 2499 + 200 = 2699 * 2 = 5398 subtotal, 29 platform fee, 5% GST = 270 => 5697 grandTotal
      expect(quote.type).toBe('shopping');
      expect(quote.subtotal).toBe(5398);
      expect(quote.convenienceFee).toBe(29);
      expect(quote.taxes).toBe(270);
      expect(quote.grandTotal).toBe(5697);
    });

    it('calculates Stay quote: (room * nights * rooms + addOns) + 12% GST', async () => {
      const quote = await bookingsController.calculateQuote({
        type: 'stay',
        hotelId: 'hotel_taj_falaknuma',
        roomTypeId: 'room_palace_suite',
        nights: 2,
        roomsCount: 1,
        addOnIds: ['addon_airport_transfer'],
      });

      // (35000 * 2 * 1) + 3500 = 73500 subtotal, 12% GST = 8820 => 82320 grandTotal
      expect(quote.type).toBe('stay');
      expect(quote.subtotal).toBe(73500);
      expect(quote.taxes).toBe(8820);
      expect(quote.grandTotal).toBe(82320);
    });

    it('calculates Sports quote: courtPrice + addOns + 50 convenience', async () => {
      const quote = await bookingsController.calculateQuote({
        type: 'sports',
        venueId: 'venue_squad_turf',
        slotId: 'slot_8pm',
        addOnIds: ['addon_cricket_kit'],
      });

      // 1200 + 200 = 1400 subtotal, 50 convenience => 1450 grandTotal
      expect(quote.type).toBe('sports');
      expect(quote.subtotal).toBe(1400);
      expect(quote.convenienceFee).toBe(50);
      expect(quote.grandTotal).toBe(1450);
    });
  });

  // 2. CRYPTOGRAPHIC SIGNATURE VERIFICATION
  describe('Cryptographic Signature Verification (POST /payments/verify)', () => {
    it('rejects verification if HMAC signature does not match secret (401 Unauthorized)', async () => {
      const booking = mockBookings.push({
        id: 'PLZ-MOV-V1',
        userId: 'usr_test_1',
        type: BookingType.MOVIE,
        title: 'Kalki 2898 AD',
        subtitle: 'IMAX',
        imageUrl: 'url',
        date: '2026-10-10',
        location: 'Hyderabad',
        status: BookingStatus.PENDING,
        totalPrice: 1015,
        qrCodeData: 'QR-1',
        metadata: {},
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any);

      await expect(
        paymentsController.verifyPayment({
          bookingId: 'PLZ-MOV-V1',
          razorpayOrderId: 'order_123',
          razorpayPaymentId: 'pay_999',
          razorpaySignature: 'invalid_forged_sig',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('verifies authentic HMAC-SHA256 signature, transitions payment to CAPTURED, and awards rewards idempotently', async () => {
      const booking: BookingEntity = {
        id: 'PLZ-MOV-V2',
        userId: 'usr_test_1',
        type: BookingType.MOVIE,
        title: 'Kalki 2898 AD',
        subtitle: 'IMAX',
        imageUrl: 'url',
        date: '2026-10-10',
        location: 'Hyderabad',
        status: BookingStatus.PENDING,
        totalPrice: 1015,
        qrCodeData: 'QR-2',
        metadata: {},
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any;
      mockBookings.push(booking);

      const orderId = 'order_valid_777';
      const paymentId = 'pay_valid_888';
      const validSig = crypto
        .createHmac('sha256', mockKeySecret)
        .update(`${orderId}|${paymentId}`)
        .digest('hex');

      const initialPoints = mockUsers[0].rewardPoints;

      // First verification call
      const res = await paymentsController.verifyPayment({
        bookingId: 'PLZ-MOV-V2',
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: validSig,
      });

      expect(res.success).toBe(true);
      expect(res.status).toBe(PaymentStatus.CAPTURED);
      expect(res.booking.status).toBe(BookingStatus.UPCOMING);
      expect(res.booking.metadata.paymentVerified).toBe(true);

      // Points awarded: 10% of 1015 = 102 points
      const expectedPoints = initialPoints + Math.round(1015 * 0.1);
      expect(mockUsers[0].rewardPoints).toBe(expectedPoints);

      // Second replay verification call (Idempotency check)
      await paymentsController.verifyPayment({
        bookingId: 'PLZ-MOV-V2',
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: validSig,
      });

      // Reward points MUST NOT be doubled
      expect(mockUsers[0].rewardPoints).toBe(expectedPoints);
    });
  });

  // 3. PAYMENT FAILURE & INVENTORY RESTORATION
  describe('Payment Failure & Inventory Restoration (POST /payments/failed)', () => {
    it('transitions booking and payment to FAILED and restores event tier tickets', async () => {
      const booking: BookingEntity = {
        id: 'PLZ-EVT-FAIL-1',
        userId: 'usr_test_1',
        type: BookingType.EVENT,
        title: 'Hyderabad Rock Fest',
        subtitle: '2x VIP Pass',
        imageUrl: 'url',
        date: '2026-11-20',
        location: 'Hyderabad',
        status: BookingStatus.PENDING,
        totalPrice: 5250,
        qrCodeData: 'QR-EVT-F1',
        metadata: {
          eventId: 'evt_rock_fest',
          tierId: 'tier_vip',
          ticketCount: 2,
        },
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any;
      mockBookings.push(booking);

      // Simulating tickets were decremented
      mockEvents[0].ticketTiers[0].remainingCount = 8;

      const res = await paymentsController.handlePaymentFailure({
        bookingId: 'PLZ-EVT-FAIL-1',
        reason: 'Bank authorization declined',
      });

      expect(res.success).toBe(true);
      expect(res.status).toBe(BookingStatus.FAILED);
      expect(booking.status).toBe(BookingStatus.FAILED);
      // Tickets restored from 8 back to 10
      expect(mockEvents[0].ticketTiers[0].remainingCount).toBe(10);
    });
  });

  // 4. CANCELLATION, REFUND & REWARD REVERSAL
  describe('Booking Cancellation & Reward Reversal (DELETE /bookings/:id)', () => {
    it('cancels booking, executes refund, restores activity slots, and reverses reward points', async () => {
      const booking: BookingEntity = {
        id: 'PLZ-ACT-CANCEL-1',
        userId: 'usr_test_1',
        type: BookingType.ACTIVITY,
        title: 'Pro Go-Karting',
        subtitle: '2 people',
        imageUrl: 'url',
        date: '2026-10-15',
        location: 'Hyderabad',
        status: BookingStatus.UPCOMING,
        totalPrice: 3894,
        qrCodeData: 'QR-ACT-C1',
        metadata: {
          activityId: 'act_go_karting',
          timeSlot: '04:00 PM',
          numberOfPeople: 2,
          rewardAwarded: true,
          rewardPoints: 195, // 5% of 3894
          payment: {
            paymentId: 'pay_kart_999',
            amount: 3894,
            status: 'COMPLETED',
          },
        },
        createdAt: new Date(),
        updatedAt: new Date(),
      } as any;
      mockBookings.push(booking);

      // Activity slots decremented to 6
      mockActivities[0].timeSlots[0].availableSlots = 6;
      // User has 500 + 195 = 695 points
      mockUsers[0].rewardPoints = 695;

      const cancelled = await bookingsService.cancel('PLZ-ACT-CANCEL-1', 'usr_test_1');

      expect(cancelled.status).toBe(BookingStatus.CANCELLED);
      expect(cancelled.metadata.refund).toBeDefined();
      expect(cancelled.metadata.refund.amount).toBe(3894);
      // Activity spots restored from 6 to 8
      expect(mockActivities[0].timeSlots[0].availableSlots).toBe(8);
      // User points reversed by 195 back to 500
      expect(mockUsers[0].rewardPoints).toBe(500);
      expect(cancelled.metadata.rewardAwarded).toBe(false);
      expect(cancelled.metadata.rewardPointsReversed).toBe(true);
    });
  });
});
