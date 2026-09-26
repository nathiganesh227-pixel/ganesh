import { Test, TestingModule } from '@nestjs/testing';
import { DataSource } from 'typeorm';
import { BookingsService } from './modules/bookings/bookings.service';
import { PaymentService } from './modules/bookings/payment.service';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { BookingEntity, BookingStatus, BookingType } from './database/entities/booking.entity';
import { ConflictException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PlansService } from './modules/plans/plans.service';
import { PlanEntity } from './database/entities/plan.entity';
import { NotificationsService } from './modules/notifications/notifications.service';
import { NotificationEntity } from './database/entities/notification.entity';
import * as bcrypt from 'bcrypt';
import * as jwt from 'jsonwebtoken';

describe('Phase 8 Production Reliability, Security & Concurrency Verification', () => {
  let bookingsService: BookingsService;
  let paymentService: PaymentService;
  let plansService: PlansService;
  let notificationsService: NotificationsService;

  // Mock Database in-memory storage
  const mockBookings: BookingEntity[] = [];
  const mockPlans: PlanEntity[] = [];
  const mockNotifications: NotificationEntity[] = [];

  const mockDataSource = {
    getRepository: jest.fn().mockImplementation((entity) => {
      if (entity === BookingEntity) {
        return {
          find: jest.fn().mockImplementation(({ where }) => {
            return Promise.resolve(
              mockBookings.filter((b) => (!where.userId || b.userId === where.userId) && (!where.status || b.status === where.status))
            );
          }),
          findOne: jest.fn().mockImplementation(({ where }) => {
            return Promise.resolve(mockBookings.find((b) => b.id === where.id) || null);
          }),
          save: jest.fn().mockImplementation((booking) => {
            const idx = mockBookings.findIndex((b) => b.id === booking.id);
            if (idx >= 0) {
              mockBookings[idx] = booking;
            } else {
              mockBookings.push(booking);
            }
            return Promise.resolve(booking);
          }),
          create: jest.fn().mockImplementation((dto) => ({ ...dto })),
        };
      }
      return {};
    }),
    transaction: jest.fn().mockImplementation(async (callback) => {
      const mockManager = {
        findOne: jest.fn().mockImplementation((entity, options) => {
          if (entity.name === 'TheatreEntity' || entity.toString().includes('Theatre')) {
            return Promise.resolve({
              id: 'theatre_prasad',
              name: 'Prasads Multiplex IMAX',
              location: 'Necklace Road, Hyderabad',
              showtimes: [{ id: 'st_1', format: 'IMAX 3D', basePrice: 450 }],
            });
          }
          if (entity.name === 'SportsVenueEntity' || entity.toString().includes('SportsVenue')) {
            return Promise.resolve({
              id: 'venue_gachibowli',
              name: 'Gachibowli Arena',
              location: 'Gachibowli, Hyderabad',
              slots: [{ id: 'slot_turf_1', courtName: 'Box Turf A', time: '06:00 AM - 07:00 AM', duration: '60 min', price: 1200 }],
              addOns: [{ id: 'addon_floodlights', name: 'Floodlights', price: 200 }],
            });
          }
          if (entity.name === 'EventEntity' || entity.toString().includes('Event')) {
            return Promise.resolve({
              id: 'evt_sunburn',
              title: 'Sunburn Arena Hyderabad',
              eventDate: '2026-10-15',
              time: '05:00 PM',
              venue: 'GMR Arena',
              location: 'Shamshabad',
              ticketTiers: [{ id: 'tier_vip', name: 'VIP Pass', price: 2999, remainingCount: 5 }],
            });
          }
          if (entity.name === 'HotelEntity' || entity.toString().includes('Hotel')) {
            const queryId = (options as any)?.where?.id;
            if (queryId === 'hotel_unpublished') {
              return Promise.resolve({
                id: 'hotel_unpublished',
                name: 'Unpublished Villa',
                isPublished: false,
                rooms: [{ id: 'room_villa', name: 'Private Villa', pricePerNight: 20000, isAvailable: true, maxGuests: 4 }],
              });
            }
            return Promise.resolve({
              id: 'hotel_falaknuma',
              name: 'Taj Falaknuma Palace',
              location: 'Engine Bowli, Falaknuma',
              isPublished: true,
              rooms: [{ id: 'room_palace', name: 'Palace Room', pricePerNight: 35000, isAvailable: true, maxGuests: 2 }],
              addOns: [{ id: 'addon_breakfast', name: 'Royal Breakfast Buffet', price: 2500 }],
            });
          }
          if (entity.name === 'ProductEntity' || entity.toString().includes('Product')) {
            const queryId = (options as any)?.where?.id;
            if (queryId === 'prod_unpublished') {
              return Promise.resolve({
                id: 'prod_unpublished',
                name: 'Secret Sneaker',
                price: 9999,
                isPublished: false,
                inStock: true,
              });
            }
            if (queryId === 'prod_out_of_stock') {
              return Promise.resolve({
                id: 'prod_out_of_stock',
                name: 'Sold Out Boots',
                price: 4999,
                isPublished: true,
                inStock: false,
              });
            }
            return Promise.resolve({
              id: 'prod_zara_jacket',
              name: 'Textured Bomber Jacket',
              price: 5990,
              storeName: 'Zara Flagship',
              storeLocation: 'Inorbit Mall, Madhapur',
              variants: [
                { id: 'var_l', name: 'Size L', priceDelta: 0, inStock: true },
                { id: 'var_s', name: 'Size S', priceDelta: 0, inStock: false },
              ],
            });
          }
          if (entity.name === 'ActivityEntity' || entity.toString().includes('Activity')) {
            return Promise.resolve({
              id: 'act_go_karting',
              title: 'Pro Go-Karting Track',
              location: 'Airport Road, Shamshabad',
              packages: [{ id: 'pkg_twin', name: 'Twin Engine 200cc (12 Laps)', pricePerPerson: 1200 }],
              addOns: [{ id: 'addon_helmet_cam', name: '4K Action Cam Rental', price: 350 }],
            });
          }
          if (entity.name === 'User' || entity.toString().includes('User')) {
            return Promise.resolve({ id: 'usr_userA', rewardPoints: 500 });
          }
          return Promise.resolve(null);
        }),
        save: jest.fn().mockImplementation((item) => Promise.resolve(item)),
        getRepository: jest.fn().mockImplementation((entity) => {
          if (entity === BookingEntity) {
            return {
              createQueryBuilder: jest.fn().mockReturnValue({
                where: jest.fn().mockReturnThis(),
                andWhere: jest.fn().mockReturnThis(),
                getMany: jest.fn().mockImplementation(async () => {
                  return mockBookings.filter((b) => b.status !== BookingStatus.CANCELLED);
                }),
                getOne: jest.fn().mockImplementation(async () => {
                  return mockBookings.find((b) => b.status !== BookingStatus.CANCELLED) || null;
                }),
              }),
              create: jest.fn().mockImplementation((dto) => ({ ...dto })),
              save: jest.fn().mockImplementation((booking) => {
                mockBookings.push(booking);
                return Promise.resolve(booking);
              }),
            };
          }
          if (entity.name === 'ProductEntity' || entity.toString().includes('Product')) {
            return {
              findOne: jest.fn().mockImplementation((options) => {
                const queryId = (options as any)?.where?.id;
                if (queryId === 'prod_unpublished') {
                  return Promise.resolve({
                    id: 'prod_unpublished',
                    name: 'Secret Sneaker',
                    price: 9999,
                    isPublished: false,
                    inStock: true,
                  });
                }
                if (queryId === 'prod_out_of_stock') {
                  return Promise.resolve({
                    id: 'prod_out_of_stock',
                    name: 'Sold Out Boots',
                    price: 4999,
                    isPublished: true,
                    inStock: false,
                  });
                }
                return Promise.resolve({
                  id: 'prod_zara_jacket',
                  name: 'Textured Bomber Jacket',
                  price: 5990,
                  storeName: 'Zara Flagship',
                  storeLocation: 'Inorbit Mall, Madhapur',
                  isPublished: true,
                  inStock: true,
                  variants: [
                    { id: 'var_l', name: 'Size L', priceDelta: 0, inStock: true },
                    { id: 'var_s', name: 'Size S', priceDelta: 0, inStock: false },
                  ],
                });
              }),
            };
          }
          return {
            findOne: jest.fn().mockResolvedValue({ id: 'usr_userA', rewardPoints: 500 }),
            save: jest.fn().mockImplementation((item) => Promise.resolve(item)),
          };
        }),
      };
      return callback(mockManager);
    }),
  };

  beforeAll(async () => {
    const razorpayAdapter = new RazorpayAdapter();
    const simulatedAdapter = new SimulatedPaymentAdapter();
    paymentService = new PaymentService(razorpayAdapter, simulatedAdapter);
    bookingsService = new BookingsService(mockDataSource as any, paymentService);

    const mockPlanRepo = {
      find: jest.fn().mockImplementation(({ where }) => {
        return Promise.resolve(mockPlans.filter((p) => p.userId === where.userId));
      }),
      findOne: jest.fn().mockImplementation(({ where }) => {
        return Promise.resolve(mockPlans.find((p) => p.id === where.id) || null);
      }),
      save: jest.fn().mockImplementation((plan) => {
        mockPlans.push(plan);
        return Promise.resolve(plan);
      }),
      create: jest.fn().mockImplementation((dto) => ({ ...dto })),
    };

    const mockNotificationRepo = {
      find: jest.fn().mockImplementation(({ where }) => {
        return Promise.resolve(mockNotifications.filter((n) => n.userId === where.userId));
      }),
      findOne: jest.fn().mockImplementation(({ where }) => {
        return Promise.resolve(mockNotifications.find((n) => n.id === where.id) || null);
      }),
      save: jest.fn().mockImplementation((notif) => {
        const idx = mockNotifications.findIndex((n) => n.id === notif.id);
        if (idx >= 0) mockNotifications[idx] = notif;
        else mockNotifications.push(notif);
        return Promise.resolve(notif);
      }),
    };

    plansService = new PlansService(mockPlanRepo as any);
    notificationsService = new NotificationsService(mockNotificationRepo as any);
  });

  beforeEach(() => {
    mockBookings.length = 0;
    mockPlans.length = 0;
    mockNotifications.length = 0;
  });

  // 1. CONCURRENCY & COLLISION DEFENSES
  describe('Concurrency & Inventory Lock Defenses', () => {
    it('detects movie seat conflict when overlapping seats requested in the same showtime', async () => {
      // First booking succeeds for seats E12, E13
      await bookingsService.createMovieBooking({
        userId: 'usr_userA',
        movieId: 'mov_devara',
        theatreId: 'theatre_prasad',
        showtimeId: 'st_1',
        seatIds: ['E12', 'E13'],
        movieTitle: 'Devara: Part 1',
        theatreName: 'Prasads Multiplex',
        posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1',
        date: '2026-10-01',
        time: '07:30 PM',
      });

      // Second concurrent booking requesting E13 must throw ConflictException
      await expect(
        bookingsService.createMovieBooking({
          userId: 'usr_userB',
          movieId: 'mov_devara',
          theatreId: 'theatre_prasad',
          showtimeId: 'st_1',
          seatIds: ['E13', 'E14'],
          movieTitle: 'Devara: Part 1',
          theatreName: 'Prasads Multiplex',
          posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1',
          date: '2026-10-01',
          time: '07:30 PM',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('detects sports court double-booking collision for identical date and slot', async () => {
      // First booking locks the turf slot
      await bookingsService.createSportsBooking({
        userId: 'usr_userA',
        venueId: 'venue_gachibowli',
        sportName: 'Cricket',
        slotId: 'slot_turf_1',
        date: '2026-10-05',
        playersCount: 10,
      });

      // Second booking on same date and slot must throw ConflictException
      await expect(
        bookingsService.createSportsBooking({
          userId: 'usr_userB',
          venueId: 'venue_gachibowli',
          sportName: 'Cricket',
          slotId: 'slot_turf_1',
          date: '2026-10-05',
          playersCount: 8,
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('rejects event ticket booking when quantity exceeds remaining ticket inventory', async () => {
      // Event has 5 remaining VIP tickets. Requesting 6 must fail.
      await expect(
        bookingsService.createEventBooking({
          userId: 'usr_userA',
          eventId: 'evt_sunburn',
          tierId: 'tier_vip',
          ticketCount: 6,
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  // 2. SERVER-SIDE PRICE AUTHORITY (PRICE TAMPERING DEFENSE)
  describe('Server-Side Price Authority', () => {
    it('enforces canonical server-side calculation and overrides client price tampering', async () => {
      // Client sends a tampered totalPrice of 1.00 INR for 2 IMAX tickets
      const booking = await bookingsService.createMovieBooking({
        userId: 'usr_userA',
        movieId: 'mov_devara',
        theatreId: 'theatre_prasad',
        showtimeId: 'st_1',
        seatIds: ['A1', 'A2'],
        movieTitle: 'Devara',
        theatreName: 'Prasads Multiplex',
        posterUrl: 'https://example.com/poster.jpg',
        date: '2026-10-01',
        time: '07:30 PM',
        ...({ totalPrice: 1.00 } as any), // Client tampering attempt
      });

      // Server formula: (450 * 2) + 70 convenience + 45 (5% tax) = 1015 INR
      expect(booking.totalPrice).toBe(1015);
      expect(booking.totalPrice).not.toBe(1.00);
      expect(booking.metadata.payment.amount).toBe(1015);
      expect(booking.metadata.payment.status).toBe('COMPLETED');
    });

    it('calculates shopping order grand total server-side with platform fee and GST', async () => {
      const order = await bookingsService.createShoppingOrder({
        userId: 'usr_userA',
        items: [{ productId: 'prod_zara_jacket', quantity: 2 }],
        fulfillmentType: 'Store Pickup',
        ...({ totalPrice: 9.99 } as any), // Client tampering attempt
      });

      // Server formula: (5990 * 2) + 29 platform fee + (11980 * 0.05 = 599 GST) = 12608
      expect(order.totalPrice).toBe(12608);
      expect(order.metadata.payment.amount).toBe(12608);
    });

    it('rejects shopping order with unpublished product', async () => {
      await expect(
        bookingsService.createShoppingOrder({
          userId: 'usr_userA',
          items: [{ productId: 'prod_unpublished', quantity: 1 }],
          fulfillmentType: 'Store Pickup',
        }),
      ).rejects.toThrow('not found or unpublished');
    });

    it('rejects shopping order when product is out of stock', async () => {
      await expect(
        bookingsService.createShoppingOrder({
          userId: 'usr_userA',
          items: [{ productId: 'prod_out_of_stock', quantity: 1 }],
          fulfillmentType: 'Store Pickup',
        }),
      ).rejects.toThrow('is out of stock');
    });

    it('rejects shopping order when selected variant is out of stock', async () => {
      await expect(
        bookingsService.createShoppingOrder({
          userId: 'usr_userA',
          items: [{ productId: 'prod_zara_jacket', variantId: 'var_s', quantity: 1 }],
          fulfillmentType: 'Store Pickup',
        }),
      ).rejects.toThrow('is out of stock');
    });

    it('calculates stay booking grand total server-side and overrides client price tampering', async () => {
      const booking = await bookingsService.createStayBooking({
        userId: 'usr_userA',
        hotelId: 'hotel_falaknuma',
        roomTypeId: 'room_palace',
        checkInDate: '2026-10-01',
        checkOutDate: '2026-10-03',
        nights: 2,
        guestsCount: 2,
        roomsCount: 1,
        addOnIds: ['addon_breakfast'],
        ...({ totalPrice: 10.0 } as any), // Client tampering attempt
      });

      // 35000 * 2 nights * 1 room = 70000 + 2500 add-on = 72500 + 12% GST (8700) = 81200
      expect(booking.totalPrice).toBe(81200);
      expect(booking.metadata.payment.amount).toBe(81200);
      expect(booking.metadata.payment.status).toBe('COMPLETED');
    });

    it('rejects stay booking when hotel is unpublished', async () => {
      await expect(
        bookingsService.createStayBooking({
          userId: 'usr_userA',
          hotelId: 'hotel_unpublished',
          roomTypeId: 'room_villa',
          checkInDate: '2026-10-01',
          checkOutDate: '2026-10-03',
          nights: 2,
          guestsCount: 2,
          roomsCount: 1,
        }),
      ).rejects.toThrow('not found or unpublished');
    });

    it('rejects stay booking when check-out date is not after check-in date', async () => {
      await expect(
        bookingsService.createStayBooking({
          userId: 'usr_userA',
          hotelId: 'hotel_falaknuma',
          roomTypeId: 'room_palace',
          checkInDate: '2026-10-05',
          checkOutDate: '2026-10-02',
          nights: 1,
          guestsCount: 2,
          roomsCount: 1,
        }),
      ).rejects.toThrow('Check-out date must be after check-in date');
    });

    it('rejects stay booking when guest count exceeds room capacity', async () => {
      await expect(
        bookingsService.createStayBooking({
          userId: 'usr_userA',
          hotelId: 'hotel_falaknuma',
          roomTypeId: 'room_palace',
          checkInDate: '2026-10-01',
          checkOutDate: '2026-10-03',
          nights: 2,
          guestsCount: 5, // Room capacity is 2
          roomsCount: 1,
        }),
      ).rejects.toThrow('allows maximum of 2 guests');
    });
  });

  // 3. BOOKING STATE MACHINE & PAYMENT INTEGRATION
  describe('Booking State Machine & Payment Lifecycle', () => {
    it('transitions booking from UPCOMING to CANCELLED and processes simulated refund', async () => {
      // 1. Create booking
      const booking = await bookingsService.createMovieBooking({
        userId: 'usr_userA',
        movieId: 'mov_devara',
        theatreId: 'theatre_prasad',
        showtimeId: 'st_1',
        seatIds: ['B5'],
        movieTitle: 'Devara',
        theatreName: 'Prasads Multiplex',
        posterUrl: 'https://example.com/poster.jpg',
        date: '2026-10-01',
        time: '07:30 PM',
      });

      expect(booking.status).toBe(BookingStatus.UPCOMING);
      expect(booking.metadata.payment.paymentId).toBeDefined();

      // 2. Cancel booking by authorized owner
      const cancelled = await bookingsService.cancel(booking.id, 'usr_userA');
      expect(cancelled.status).toBe(BookingStatus.CANCELLED);
      expect(cancelled.metadata.refund).toBeDefined();
      expect(cancelled.metadata.refund.status).toBe('REFUNDED');
      expect(cancelled.metadata.refund.amount).toBe(booking.totalPrice);

      // 3. Re-cancelling must fail with BadRequestException
      await expect(bookingsService.cancel(booking.id, 'usr_userA')).rejects.toThrow(BadRequestException);
    });
  });

  // 4. AUTHORIZATION & DATA ISOLATION (USER A vs USER B)
  describe('Strict User Authorization & Multi-Tenant Data Isolation', () => {
    it('prevents User B from viewing User A booking (403 Forbidden)', async () => {
      const bookingA = await bookingsService.createMovieBooking({
        userId: 'usr_userA',
        movieId: 'mov_devara',
        theatreId: 'theatre_prasad',
        showtimeId: 'st_1',
        seatIds: ['C1'],
        movieTitle: 'Devara',
        theatreName: 'Prasads Multiplex',
        posterUrl: 'https://example.com/poster.jpg',
        date: '2026-10-01',
        time: '07:30 PM',
      });

      // User A can view their own booking
      const fetchedA = await bookingsService.findOne(bookingA.id, 'usr_userA');
      expect(fetchedA.id).toBe(bookingA.id);

      // User B attempting to view User A's booking must throw ForbiddenException
      await expect(bookingsService.findOne(bookingA.id, 'usr_userB')).rejects.toThrow(ForbiddenException);
    });

    it('prevents User B from cancelling User A booking (403 Forbidden)', async () => {
      const bookingA = await bookingsService.createMovieBooking({
        userId: 'usr_userA',
        movieId: 'mov_devara',
        theatreId: 'theatre_prasad',
        showtimeId: 'st_1',
        seatIds: ['C2'],
        movieTitle: 'Devara',
        theatreName: 'Prasads Multiplex',
        posterUrl: 'https://example.com/poster.jpg',
        date: '2026-10-01',
        time: '07:30 PM',
      });

      // User B attempting to cancel User A's booking must throw ForbiddenException
      await expect(bookingsService.cancel(bookingA.id, 'usr_userB')).rejects.toThrow(ForbiddenException);

      // Booking status must still be UPCOMING
      const stillActive = await bookingsService.findOne(bookingA.id, 'usr_userA');
      expect(stillActive.status).toBe(BookingStatus.UPCOMING);
    });

    it('prevents User B from viewing User A plan details (403 Forbidden)', async () => {
      const planA = await plansService.create({
        id: 'plan_123',
        userId: 'usr_userA',
        title: 'Friday Night Movie & Dinner',
        date: '2026-10-02',
      });

      // User A can access
      const fetchedA = await plansService.findOne(planA.id, 'usr_userA');
      expect(fetchedA.id).toBe('plan_123');

      // User B must be denied
      await expect(plansService.findOne(planA.id, 'usr_userB')).rejects.toThrow(ForbiddenException);
    });

    it('prevents User B from modifying User A notifications (403 Forbidden)', async () => {
      const notifA: NotificationEntity = {
        id: 'notif_456',
        userId: 'usr_userA',
        title: 'Ticket Confirmed',
        message: 'Your ticket is ready',
        type: 'booking',
        timeAgo: 'Just now',
        actionRoute: '/bookings',
        isRead: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      mockNotifications.push(notifA);

      // User B cannot mark User A notification as read
      await expect(notificationsService.markAsRead('notif_456', 'usr_userB')).rejects.toThrow(ForbiddenException);

      // User A can mark their own notification as read
      const updated = await notificationsService.markAsRead('notif_456', 'usr_userA');
      expect(updated.isRead).toBe(true);
    });
  });

  // 5. SECURITY & AUTHENTICATION TOKENS
  describe('Authentication Cryptography & JWT Security', () => {
    it('verifies bcrypt password salting, hashing, and signature validation', async () => {
      const rawPassword = 'StrongProductionPassword2026!';
      const salt = await bcrypt.genSalt(10);
      const hash = await bcrypt.hash(rawPassword, salt);

      expect(hash).not.toBe(rawPassword);
      expect(await bcrypt.compare(rawPassword, hash)).toBe(true);
      expect(await bcrypt.compare('WrongPassword', hash)).toBe(false);
    });

    it('verifies signed JWT claims with user ID and rejection of tampered tokens', () => {
      const secret = 'plaza_super_secret_jwt_key_2026';
      const token = jwt.sign(
        { sub: 'usr_userA', email: 'userA@plaza.app', role: 'user' },
        secret,
        { expiresIn: '1h' },
      );

      const decoded: any = jwt.verify(token, secret);
      expect(decoded.sub).toBe('usr_userA');
      expect(decoded.email).toBe('userA@plaza.app');

      // Tampered token must fail verification
      const tampered = token.slice(0, -5) + 'ABCDE';
      expect(() => jwt.verify(tampered, secret)).toThrow();
    });
  });
});
