import { Test, TestingModule } from '@nestjs/testing';
import { BookingsController } from './modules/bookings/bookings.controller';
import { BookingsService } from './modules/bookings/bookings.service';
import { IdempotencyService } from './modules/bookings/idempotency.service';
import { BookingEntity, BookingStatus, BookingType } from './database/entities/booking.entity';
import { IdempotencyRecordEntity } from './database/entities/idempotency-record.entity';
import { PaymentService } from './modules/payments/payment.service';
import { RazorpayAdapter } from './modules/payments/providers/razorpay.adapter';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { AppController } from './app.controller';

describe('Phase 10 Cloud Staging, Idempotency & E2E Production Flow Tests', () => {
  let controller: BookingsController;
  let service: BookingsService;
  let idempotencyService: IdempotencyService;
  let appController: AppController;

  const mockBookings: BookingEntity[] = [];
  const inMemoryIdempotency: IdempotencyRecordEntity[] = [];

  const mockDataSource = {
    getRepository: jest.fn().mockImplementation((entity) => {
      if (entity === BookingEntity) {
        return {
          find: jest.fn().mockImplementation(({ where }) => {
            return Promise.resolve(
              mockBookings.filter((b) => (!where.userId || b.userId === where.userId) && (!where.status || b.status === where.status)),
            );
          }),
          findOne: jest.fn().mockImplementation(({ where }) => {
            return Promise.resolve(mockBookings.find((b) => b.id === where.id) || null);
          }),
          save: jest.fn().mockImplementation((booking) => {
            const idx = mockBookings.findIndex((b) => b.id === booking.id);
            if (idx >= 0) mockBookings[idx] = booking;
            else mockBookings.push(booking);
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
            if (options?.where?.id === 'non_existent_theatre') return Promise.resolve(null);
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
            return Promise.resolve({
              id: 'hotel_falaknuma',
              name: 'Taj Falaknuma Palace',
              location: 'Engine Bowli, Falaknuma',
              rooms: [{ id: 'room_palace', name: 'Palace Room', pricePerNight: 35000 }],
              addOns: [{ id: 'addon_breakfast', name: 'Royal Breakfast Buffet', price: 2500 }],
            });
          }
          if (entity.name === 'RestaurantEntity' || entity.toString().includes('Restaurant')) {
            return Promise.resolve({
              id: 'rest_jewel',
              name: 'Jewel of Nizam',
              location: 'Masab Tank, Hyderabad',
              coverImageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
            });
          }
          if (entity.name === 'User' || entity.toString().includes('User')) {
            return Promise.resolve({ id: 'usr_staging_001', rewardPoints: 500 });
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
              create: jest.fn().mockImplementation((dto) => ({
                ...dto,
                id: dto.id || `PLZ-${dto.category?.toUpperCase()?.slice(0, 3) || 'GEN'}-${Date.now()}-${Math.floor(Math.random() * 100000)}`,
                createdAt: new Date(),
                updatedAt: new Date(),
              })),
              save: jest.fn().mockImplementation((booking) => {
                mockBookings.push(booking);
                return Promise.resolve(booking);
              }),
            };
          }
          return {
            findOne: jest.fn().mockResolvedValue({ id: 'usr_staging_001', rewardPoints: 500 }),
            save: jest.fn().mockImplementation((item) => Promise.resolve(item)),
          };
        }),
      };
      return callback(mockManager);
    }),
  };

  const mockIdempotencyRepo = {
    findOne: jest.fn().mockImplementation(({ where }) => {
      const rec = inMemoryIdempotency.find((r) => r.key === where.key);
      return Promise.resolve(rec || null);
    }),
    create: jest.fn().mockImplementation((dto) => ({ ...dto, createdAt: new Date() })),
    save: jest.fn().mockImplementation((record) => {
      const idx = inMemoryIdempotency.findIndex((r) => r.key === record.key);
      if (idx >= 0) inMemoryIdempotency[idx] = record;
      else inMemoryIdempotency.push(record);
      return Promise.resolve(record);
    }),
  };

  beforeAll(async () => {
    const razorpayAdapter = new RazorpayAdapter();
    const simulatedAdapter = new SimulatedPaymentAdapter();
    const paymentService = new PaymentService(razorpayAdapter, simulatedAdapter);

    service = new BookingsService(mockDataSource as any, paymentService);
    idempotencyService = new IdempotencyService(mockIdempotencyRepo as any);
    controller = new BookingsController(service, idempotencyService);
    appController = new AppController();
  });

  beforeEach(() => {
    mockBookings.length = 0;
    inMemoryIdempotency.length = 0;
    jest.clearAllMocks();
  });

  // 1. CLIENT REQUEST IDEMPOTENCY
  describe('Client Booking Idempotency (Idempotency-Key Header)', () => {
    it('returns newly created booking on first request with idempotency key', async () => {
      const req = { user: { sub: 'usr_staging_001' } };
      const idempotencyKey = 'idemp_key_req_1001';
      const body = {
        movieId: 'mov_kalki',
        theatreId: 'theatre_prasad',
        showtimeId: 'st_1',
        seatIds: ['F1', 'F2'],
        movieTitle: 'Kalki 2898 AD',
        theatreName: 'Prasads Multiplex IMAX',
        posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1',
        date: '2026-10-01',
        time: '07:30 PM',
        totalPrice: 1, // Malicious client claims 1 INR
      };

      const result = await controller.createMovieBooking(req, idempotencyKey, body);

      expect(result).toBeDefined();
      expect(result.id).toBeDefined();
      expect(result.userId).toBe('usr_staging_001');
      // Server-side calculated price: 2 seats * 450 + 70 convenience + 45 tax = 1015
      expect(result.totalPrice).toBe(1015);
      expect(inMemoryIdempotency.length).toBe(1);
      expect(inMemoryIdempotency[0].key).toBe('usr_staging_001:idemp_key_req_1001');
    });

    it('replays identical booking and does NOT duplicate database record on duplicate client retry', async () => {
      const req = { user: { sub: 'usr_staging_001' } };
      const idempotencyKey = 'idemp_key_retry_2002';
      const body = {
        movieId: 'mov_kalki',
        theatreId: 'theatre_prasad',
        showtimeId: 'st_1',
        seatIds: ['G4'],
        movieTitle: 'Kalki 2898 AD',
        theatreName: 'Prasads Multiplex IMAX',
        posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1',
        date: '2026-10-02',
        time: '07:30 PM',
      };

      // Call 1 (Original request)
      const firstCall = await controller.createMovieBooking(req, idempotencyKey, body);
      expect(mockBookings.length).toBe(1);

      // Call 2 (Client network retry with exact same idempotency key)
      const secondCall = await controller.createMovieBooking(req, idempotencyKey, body);

      // Must return identical cached record
      expect(secondCall.id).toBe(firstCall.id);
      expect(secondCall.totalPrice).toBe(firstCall.totalPrice);

      // Database should NOT have added a second record
      expect(mockBookings.length).toBe(1);
    });

    it('isolates idempotency keys per user so users do not collide or read each others cached data', async () => {
      const sharedKey = 'common_client_generated_uuid_99';

      const reqUserA = { user: { sub: 'usr_alice' } };
      const reqUserB = { user: { sub: 'usr_bob' } };

      const bodyA = {
        movieId: 'mov_kalki',
        theatreId: 'theatre_prasad',
        showtimeId: 'st_1',
        seatIds: ['A1'],
        movieTitle: 'Alice Movie',
        theatreName: 'Prasads Multiplex IMAX',
        posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1',
        date: '2026-10-01',
        time: '07:30 PM',
      };
      const bodyB = {
        movieId: 'mov_kalki',
        theatreId: 'theatre_prasad',
        showtimeId: 'st_1',
        seatIds: ['B1'],
        movieTitle: 'Bob Movie',
        theatreName: 'Prasads Multiplex IMAX',
        posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1',
        date: '2026-10-01',
        time: '07:30 PM',
      };

      const resA = await controller.createMovieBooking(reqUserA, sharedKey, bodyA);
      const resB = await controller.createMovieBooking(reqUserB, sharedKey, bodyB);

      expect(resA.id).not.toBe(resB.id);
      expect(resA.title).toBe('Alice Movie');
      expect(resB.title).toBe('Bob Movie');
      expect(inMemoryIdempotency.length).toBe(2);
      expect(mockBookings.length).toBe(2);
    });

    it('works across different vertical booking types (Dining, Stays, Sports)', async () => {
      const req = { user: { sub: 'usr_staging_001' } };

      // Dining
      const diningRes1 = await controller.createDiningReservation(req, 'idemp_dining_1', {
        restaurantId: 'rest_jewel',
        date: '2026-10-05',
        timeSlot: '20:00',
        partySize: 4,
        seatingPreference: 'Indoor',
        guestName: 'Gopi',
        guestPhone: '+919876543210',
      });
      const diningRes2 = await controller.createDiningReservation(req, 'idemp_dining_1', {
        restaurantId: 'rest_jewel',
        date: '2026-10-05',
        timeSlot: '20:00',
        partySize: 4,
        seatingPreference: 'Indoor',
        guestName: 'Gopi',
        guestPhone: '+919876543210',
      });
      expect(diningRes1.id).toBe(diningRes2.id);

      // Stays
      const stayRes1 = await controller.createStayBooking(req, 'idemp_stay_1', {
        hotelId: 'hotel_falaknuma',
        roomTypeId: 'room_palace',
        checkInDate: '2026-11-01',
        checkOutDate: '2026-11-03',
        nights: 2,
        roomsCount: 1,
        guestsCount: 2,
        primaryGuestName: 'Gopi',
        primaryGuestPhone: '+919876543210',
      });
      const stayRes2 = await controller.createStayBooking(req, 'idemp_stay_1', {
        hotelId: 'hotel_falaknuma',
        roomTypeId: 'room_palace',
        checkInDate: '2026-11-01',
        checkOutDate: '2026-11-03',
        nights: 2,
        roomsCount: 1,
        guestsCount: 2,
        primaryGuestName: 'Gopi',
        primaryGuestPhone: '+919876543210',
      });
      expect(stayRes1.id).toBe(stayRes2.id);
      // 2 nights * 35000 + 12% tax (8400) = 78400
      expect(stayRes1.totalPrice).toBe(78400);
    });
  });

  // 2. SERVER-SIDE PRICING & TAMPER RESISTANCE
  describe('Server-Side Pricing Integrity Across Verticals', () => {
    it('overrides client-submitted sports court booking price with server rate calculation', async () => {
      const req = { user: { sub: 'usr_staging_002' } };
      const res = await controller.createSportsBooking(req, undefined, {
        venueId: 'venue_gachibowli',
        sportName: 'Cricket',
        slotId: 'slot_turf_1',
        date: '2026-10-01',
        playersCount: 10,
        totalPrice: 1, // Malicious client claims 1 INR
      });

      // 1200 slot + 50 convenience = 1250
      expect(res.totalPrice).toBe(1250);
      expect(res.status).toBe(BookingStatus.UPCOMING);
    });

    it('rejects booking when theatre does not exist', async () => {
      const req = { user: { sub: 'usr_staging_002' } };
      await expect(
        controller.createMovieBooking(req, undefined, {
          theatreId: 'non_existent_theatre',
          showtimeId: 'st_1',
          seatIds: ['A1'],
          movieTitle: 'Inception',
          theatreName: 'Fake',
          posterUrl: '',
          date: '2026-10-01',
          time: '12:00',
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // 3. BOOKING CANCELLATION & AUDIT INTEGRITY
  describe('Booking Lifecycle Transitions', () => {
    it('cancels confirmed booking and updates status to CANCELLED', async () => {
      const req = { user: { sub: 'usr_staging_cancel_test' } };
      const booking = await controller.createMovieBooking(req, undefined, {
        theatreId: 'theatre_prasad',
        showtimeId: 'st_1',
        seatIds: ['K10'],
        movieTitle: 'Interstellar',
        theatreName: 'Prasads Multiplex IMAX',
        posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1',
        date: '2026-10-05',
        time: '18:00',
      });

      expect(booking.status).toBe(BookingStatus.UPCOMING);

      const cancelled = await controller.cancel(req, booking.id);
      expect(cancelled.status).toBe(BookingStatus.CANCELLED);
    });

    it('prevents non-owner user from cancelling another users booking', async () => {
      const ownerReq = { user: { sub: 'usr_original_owner' } };
      const maliciousReq = { user: { sub: 'usr_hacker' } };

      const booking = await controller.createMovieBooking(ownerReq, undefined, {
        theatreId: 'theatre_prasad',
        showtimeId: 'st_1',
        seatIds: ['C1'],
        movieTitle: 'Dune Part 2',
        theatreName: 'Prasads Multiplex IMAX',
        posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1',
        date: '2026-10-05',
        time: '20:00',
      });

      await expect(controller.cancel(maliciousReq, booking.id)).rejects.toThrow(ForbiddenException);
    });
  });

  // 4. CLOUD STAGING & HEALTH READINESS
  describe('Cloud Staging & Production Health Readiness', () => {
    it('health check returns 200 with service metadata and uptime', () => {
      const health = appController.healthCheck();
      expect(health.status).toBe('UP');
      expect(health.service).toBe('plaza-backend');
      expect(health.timestamp).toBeDefined();
      expect(typeof health.uptime).toBe('number');
    });
  });
});
