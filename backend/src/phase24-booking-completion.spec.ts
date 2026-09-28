import {
  BadRequestException,
  ConflictException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BookingsService } from './modules/bookings/bookings.service';
import { BookingsController } from './modules/bookings/bookings.controller';
import { PaymentService } from './modules/payments/payment.service';
import { SimulatedPaymentAdapter } from './modules/payments/providers/simulated-payment.adapter';
import {
  BookingEntity,
  BookingStatus,
  BookingType,
} from './database/entities/booking.entity';
import { SeatLockEntity } from './database/entities/seat-lock.entity';
import { User, UserRole } from './database/entities/user.entity';
import { EventEntity } from './database/entities/event.entity';
import { ActivityEntity } from './database/entities/activity.entity';
import { HotelEntity } from './database/entities/hotel.entity';
import { ProductEntity } from './database/entities/product.entity';
import { SportsVenueEntity } from './database/entities/sports-venue.entity';
import { TheatreEntity } from './database/entities/theatre.entity';
import { RestaurantEntity } from './database/entities/restaurant.entity';
import { PartnersService } from './modules/partners/partners.service';
import { PartnerEntity, PartnerStatus, PartnerType } from './database/entities/partner.entity';
import { PartnerUserEntity } from './database/entities/partner-user.entity';
import { PartnerBusinessEntity, BusinessStatus } from './database/entities/partner-business.entity';

describe('Phase 24 — Real Booking & Order Completion Tests', () => {
  let bookingsService: BookingsService;
  let bookingsController: BookingsController;
  let partnersService: PartnersService;
  let simulatedPaymentAdapter: SimulatedPaymentAdapter;
  let paymentService: PaymentService;

  // In-memory data store for tests
  let bookingsDb: BookingEntity[];
  let usersDb: Map<string, User>;
  let eventsDb: Map<string, EventEntity>;
  let activitiesDb: Map<string, ActivityEntity>;
  let hotelsDb: Map<string, HotelEntity>;
  let productsDb: Map<string, ProductEntity>;
  let theatresDb: Map<string, TheatreEntity>;
  let sportsDb: Map<string, SportsVenueEntity>;
  let restaurantsDb: Map<string, RestaurantEntity>;
  let partnersDb: Map<string, PartnerEntity>;
  let partnerUsersDb: Map<string, PartnerUserEntity>;
  let partnerBusinessesDb: Map<string, PartnerBusinessEntity>;

  let mockDataSource: any;

  beforeEach(() => {
    bookingsDb = [];
    usersDb = new Map();
    eventsDb = new Map();
    activitiesDb = new Map();
    hotelsDb = new Map();
    productsDb = new Map();
    theatresDb = new Map();
    sportsDb = new Map();
    restaurantsDb = new Map();
    partnersDb = new Map();
    partnerUsersDb = new Map();
    partnerBusinessesDb = new Map();

    // Populate baseline users
    usersDb.set('usr_customer_1', {
      id: 'usr_customer_1',
      fullName: 'Alice Customer',
      email: 'alice@example.com',
      phoneNumber: '+919876543210',
      role: UserRole.USER,
      rewardPoints: 500,
      createdAt: new Date(),
      updatedAt: new Date(),
    } as unknown as User);

    usersDb.set('usr_customer_2', {
      id: 'usr_customer_2',
      fullName: 'Bob Customer',
      email: 'bob@example.com',
      phoneNumber: '+919876543211',
      role: UserRole.USER,
      rewardPoints: 100,
      createdAt: new Date(),
      updatedAt: new Date(),
    } as unknown as User);

    // Populate baseline vertical catalog entities
    theatresDb.set('th_prasad', {
      id: 'th_prasad',
      name: 'Prasads Multiplex IMAX',
      location: 'Necklace Road, Hyderabad',
      showtimes: [
        { id: 'st_101', format: 'IMAX 3D', basePrice: 450 },
      ],
    } as any);

    restaurantsDb.set('rest_paradise', {
      id: 'rest_paradise',
      name: 'Paradise Biryani',
      location: 'Secunderabad',
      coverImageUrl: 'https://images.unsplash.com/photo-paradise',
    } as any);

    eventsDb.set('evt_rock_fest', {
      id: 'evt_rock_fest',
      title: 'Hyderabad Rock Festival 2026',
      venue: 'Gachibowli Stadium',
      location: 'Gachibowli',
      eventDate: '2026-11-20',
      isPublished: true,
      ticketTiers: [
        { id: 'tier_vip', name: 'VIP Pass', price: 2999, remainingCount: 1 },
      ],
    } as any);

    activitiesDb.set('act_karting', {
      id: 'act_karting',
      title: 'Championship Go-Karting',
      location: 'Airport Road',
      isPublished: true,
      packages: [
        { id: 'pkg_pro', name: '10 Laps Pro Kart', pricePerPerson: 1200 },
      ],
      timeSlots: [
        { time: '10:00 AM - 11:00 AM', availableSlots: 1, isFillingFast: false },
      ],
    } as any);

    hotelsDb.set('htl_palace', {
      id: 'htl_palace',
      name: 'Taj Falaknuma Palace',
      location: 'Falaknuma, Hyderabad',
      isPublished: true,
      rooms: [
        {
          id: 'room_royal',
          name: 'Royal Heritage Suite',
          pricePerNight: 25000,
          isAvailable: true,
          availableRooms: 1,
        },
      ],
    } as any);

    productsDb.set('prd_smartwatch', {
      id: 'prd_smartwatch',
      name: 'Noise Pro Series 5',
      price: 3499,
      inStock: true,
      stock: 1,
      storeName: 'PLAZA Electronics',
      storeLocation: 'Hyderabad',
      variants: [
        { id: 'var_black', name: 'Midnight Black', priceDelta: 0, inStock: true, stock: 1 },
      ],
    } as any);

    sportsDb.set('spt_arena', {
      id: 'spt_arena',
      name: 'Smash Turf Arena',
      location: 'Madhapur',
      slots: [
        { id: 'slot_turf_1', courtName: 'Box Cricket A', time: '07:00 PM - 08:00 PM', price: 1500 },
      ],
    } as any);

    // Baseline partner setup
    partnersDb.set('part_a', {
      id: 'part_a',
      legalName: 'Apex Hospitality Pvt Ltd',
      tradeName: 'Apex Sports',
      status: PartnerStatus.APPROVED,
      partnerType: PartnerType.SPORTS_VENUE,
    } as any);

    partnerBusinessesDb.set('biz_a', {
      id: 'biz_a',
      partnerId: 'part_a',
      name: 'Smash Turf Arena',
      status: BusinessStatus.APPROVED,
    } as any);

    partnerUsersDb.set('pusr_a', {
      id: 'pusr_a',
      partnerId: 'part_a',
      userId: 'usr_partner_a',
      role: 'ADMIN',
    } as any);

    // Mock query builder for bookings
    const createMockBookingQueryBuilder = () => {
      let filterFn = (b: BookingEntity) => true;
      let andFilterFn = (b: BookingEntity) => true;

      const qb: any = {
        where: jest.fn().mockImplementation((condition: string, params: any) => {
          if (condition.includes("b.metadata->>'theatreId'")) {
            filterFn = (b: BookingEntity) =>
              b.metadata?.theatreId === params.tId;
          } else if (condition.includes("b.metadata->>'restaurantId'")) {
            filterFn = (b: BookingEntity) =>
              b.metadata?.restaurantId === params.rId;
          } else if (condition.includes("b.metadata->>'venueId'")) {
            filterFn = (b: BookingEntity) =>
              b.metadata?.venueId === params.vId;
          }
          return qb;
        }),
        andWhere: jest.fn().mockImplementation((condition: string, params: any) => {
          const prevAnd = andFilterFn;
          if (condition.includes("b.metadata->>'showtimeId'")) {
            andFilterFn = (b: BookingEntity) =>
              prevAnd(b) && b.metadata?.showtimeId === params.stId;
          } else if (condition.includes('b.date = :date')) {
            andFilterFn = (b: BookingEntity) =>
              prevAnd(b) && b.date === params.date;
          } else if (condition.includes('b.time = :time')) {
            andFilterFn = (b: BookingEntity) =>
              prevAnd(b) && b.time === params.time;
          } else if (condition.includes("b.metadata->>'slotId'")) {
            andFilterFn = (b: BookingEntity) =>
              prevAnd(b) && b.metadata?.slotId === (params.sId || params.slId);
          } else if (condition.includes('b.status !=')) {
            andFilterFn = (b: BookingEntity) =>
              prevAnd(b) && b.status !== params.cancelled && b.status !== params.failed;
          }
          return qb;
        }),
        getMany: jest.fn().mockImplementation(async () => {
          return bookingsDb.filter((b) => filterFn(b) && andFilterFn(b));
        }),
        getOne: jest.fn().mockImplementation(async () => {
          return bookingsDb.find((b) => filterFn(b) && andFilterFn(b)) || null;
        }),
      };
      return qb;
    };

    const mockBookingRepo: any = {
      createQueryBuilder: jest.fn().mockImplementation(createMockBookingQueryBuilder),
      create: jest.fn().mockImplementation((dto) => ({
        ...dto,
        id: dto.id || `PLZ-${dto.category?.toUpperCase()?.slice(0, 3) || 'GEN'}-${Date.now()}-${Math.floor(Math.random() * 10000)}`,
        createdAt: new Date(),
        updatedAt: new Date(),
      })),
      save: jest.fn().mockImplementation((b: BookingEntity) => {
        const existingIdx = bookingsDb.findIndex((x) => x.id === b.id);
        if (existingIdx >= 0) {
          bookingsDb[existingIdx] = b;
        } else {
          bookingsDb.push(b);
        }
        return Promise.resolve(b);
      }),
      findOne: jest.fn().mockImplementation(({ where }) => {
        const id = where?.id;
        const partnerId = where?.partnerId;
        const b = bookingsDb.find((item) => {
          if (id && item.id !== id) return false;
          if (partnerId && item.partnerId !== partnerId) return false;
          return true;
        });
        return Promise.resolve(b || null);
      }),
    };

    const mockPaymentRepo: any = {
      create: jest.fn().mockImplementation((dto) => ({ ...dto, id: dto.id || `PAY_${Date.now()}` })),
      save: jest.fn().mockImplementation((p) => Promise.resolve(p)),
      findOne: jest.fn().mockResolvedValue(null),
    };

    const mockEntityManager: any = {
      getRepository: jest.fn().mockImplementation((entity) => {
        if (entity === BookingEntity) return mockBookingRepo;
        if (entity === User) {
          return {
            findOne: jest.fn().mockImplementation(({ where }) => Promise.resolve(usersDb.get(where.id) || null)),
            save: jest.fn().mockImplementation((u) => {
              usersDb.set(u.id, u);
              return Promise.resolve(u);
            }),
          };
        }
        if (entity === TheatreEntity) {
          return {
            findOne: jest.fn().mockImplementation(({ where }) => Promise.resolve(theatresDb.get(where.id) || null)),
          };
        }
        if (entity === RestaurantEntity) {
          return {
            findOne: jest.fn().mockImplementation(({ where }) => Promise.resolve(restaurantsDb.get(where.id) || null)),
          };
        }
        if (entity === EventEntity) {
          return {
            findOne: jest.fn().mockImplementation(({ where }) => Promise.resolve(eventsDb.get(where.id) || null)),
            save: jest.fn().mockImplementation((e) => {
              eventsDb.set(e.id, e);
              return Promise.resolve(e);
            }),
          };
        }
        if (entity === ActivityEntity) {
          return {
            findOne: jest.fn().mockImplementation(({ where }) => Promise.resolve(activitiesDb.get(where.id) || null)),
            save: jest.fn().mockImplementation((a) => {
              activitiesDb.set(a.id, a);
              return Promise.resolve(a);
            }),
          };
        }
        if (entity === HotelEntity) {
          return {
            findOne: jest.fn().mockImplementation(({ where }) => Promise.resolve(hotelsDb.get(where.id) || null)),
            save: jest.fn().mockImplementation((h) => {
              hotelsDb.set(h.id, h);
              return Promise.resolve(h);
            }),
          };
        }
        if (entity === ProductEntity) {
          return {
            findOne: jest.fn().mockImplementation(({ where }) => Promise.resolve(productsDb.get(where.id) || null)),
            save: jest.fn().mockImplementation((p) => {
              productsDb.set(p.id, p);
              return Promise.resolve(p);
            }),
          };
        }
        if (entity === SportsVenueEntity) {
          return {
            findOne: jest.fn().mockImplementation(({ where }) => Promise.resolve(sportsDb.get(where.id) || null)),
          };
        }
        return {
          findOne: jest.fn().mockResolvedValue(null),
          save: jest.fn().mockImplementation((x) => Promise.resolve(x)),
        };
      }),
      findOne: jest.fn().mockImplementation((entity, options) => {
        const repo = mockEntityManager.getRepository(entity);
        return repo ? repo.findOne(options) : Promise.resolve(null);
      }),
      save: jest.fn().mockImplementation((entityOrTarget, maybeEntity) => {
        const item = maybeEntity || entityOrTarget;
        if (item.id && productsDb.has(item.id)) productsDb.set(item.id, item);
        if (item.id && hotelsDb.has(item.id)) hotelsDb.set(item.id, item);
        return Promise.resolve(item);
      }),
    };

    mockDataSource = {
      getRepository: jest.fn().mockImplementation((entity) => mockEntityManager.getRepository(entity)),
      transaction: jest.fn().mockImplementation(async (callback) => callback(mockEntityManager)),
    };

    simulatedPaymentAdapter = new SimulatedPaymentAdapter();
    paymentService = new PaymentService(
      simulatedPaymentAdapter as any,
      simulatedPaymentAdapter,
      mockPaymentRepo,
    );
    // Mock refund processing
    jest.spyOn(paymentService, 'processRefund').mockResolvedValue({
      success: true,
      refundId: 'rfnd_sim_phase24',
      status: 'REFUNDED' as any,
      amount: 1000,
    } as any);

    bookingsService = new BookingsService(mockDataSource, paymentService);
    bookingsController = new BookingsController(bookingsService, {} as any);

    // Setup mock PartnersService
    const mockPartnerRepo: any = {
      findOne: jest.fn().mockImplementation(({ where }) => Promise.resolve(partnersDb.get(where.id) || null)),
    };
    partnersService = new PartnersService(
      mockPartnerRepo,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      mockBookingRepo,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
      {} as any,
    );
    // Mock audit log for partners
    (partnersService as any).recordAudit = jest.fn().mockResolvedValue(undefined);
  });

  // =========================================================================
  // SECTION 1: SEAT LOCKING ENGINE
  // =========================================================================
  describe('1. Movie Seat Locking Engine', () => {
    it('successfully acquires a temporary seat lock for a user with TTL', async () => {
      const lockRes = await bookingsService.lockSeats({
        theatreId: 'th_prasad',
        showtimeId: 'st_101',
        seatIds: ['E12', 'E13'],
        userId: 'usr_customer_1',
        ttlSeconds: 600,
      });

      expect(lockRes.success).toBe(true);
      expect(lockRes.lockId).toBeDefined();
      expect(lockRes.seatIds).toEqual(['E12', 'E13']);
      expect(lockRes.expiresAt).toBeDefined();
    });

    it('rejects another user attempting to lock the same seat (409 Conflict)', async () => {
      await bookingsService.lockSeats({
        theatreId: 'th_prasad',
        showtimeId: 'st_101',
        seatIds: ['E12'],
        userId: 'usr_customer_1',
      });

      await expect(
        bookingsService.lockSeats({
          theatreId: 'th_prasad',
          showtimeId: 'st_101',
          seatIds: ['E12', 'E14'],
          userId: 'usr_customer_2',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('allows the original user to renew or re-lock their seats', async () => {
      await bookingsService.lockSeats({
        theatreId: 'th_prasad',
        showtimeId: 'st_101',
        seatIds: ['E12'],
        userId: 'usr_customer_1',
      });

      const renewRes = await bookingsService.lockSeats({
        theatreId: 'th_prasad',
        showtimeId: 'st_101',
        seatIds: ['E12'],
        userId: 'usr_customer_1',
      });

      expect(renewRes.success).toBe(true);
    });

    it('explicitly releases seat lock so another user can acquire it', async () => {
      await bookingsService.lockSeats({
        theatreId: 'th_prasad',
        showtimeId: 'st_101',
        seatIds: ['E12'],
        userId: 'usr_customer_1',
      });

      await bookingsService.releaseSeatLock({
        theatreId: 'th_prasad',
        showtimeId: 'st_101',
        seatIds: ['E12'],
        userId: 'usr_customer_1',
      });

      const lockResUser2 = await bookingsService.lockSeats({
        theatreId: 'th_prasad',
        showtimeId: 'st_101',
        seatIds: ['E12'],
        userId: 'usr_customer_2',
      });

      expect(lockResUser2.success).toBe(true);
    });

    it('prevents user from releasing seats locked by someone else', async () => {
      await bookingsService.lockSeats({
        theatreId: 'th_prasad',
        showtimeId: 'st_101',
        seatIds: ['E12'],
        userId: 'usr_customer_1',
      });

      const releaseRes = await bookingsService.releaseSeatLock({
        theatreId: 'th_prasad',
        showtimeId: 'st_101',
        seatIds: ['E12'],
        userId: 'usr_customer_2',
      });

      expect(releaseRes.releasedCount).toBe(0);
    });
  });

  // =========================================================================
  // SECTION 2: SERVER-AUTHORITATIVE QUOTE ENGINE & TAMPER RESISTANCE
  // =========================================================================
  describe('2. Canonical Server-Authoritative Quote Engine', () => {
    it('calculates a canonical quote with quoteId, 15m TTL, breakdown and totals', async () => {
      const quote = await bookingsService.calculateQuote('movie', {
        basePrice: 450,
        ticketCount: 2,
        addOns: [{ id: 'popcorn', name: 'Large Popcorn', price: 250 }],
      });

      expect(quote.quoteId).toBeDefined();
      expect(quote.type).toBe('movie');
      expect(quote.subtotal).toBe(1150); // 450*2 + 250
      expect(quote.fees).toBe(70); // convenienceFee 70
      expect(quote.tax).toBe(58); // 5% of 1150
      expect(quote.grandTotal).toBe(1278);
      expect(quote.expiresAt).toBeDefined();
    });

    it('rejects booking if quoteId is expired or not found', async () => {
      await expect(
        bookingsService.createMovieBooking({
          theatreId: 'th_prasad',
          showtimeId: 'st_101',
          seatIds: ['E12'],
          date: '2026-10-15',
          time: '07:00 PM',
          movieTitle: 'Kalki 2898 AD',
          totalAmount: 500,
          quoteId: 'invalid_quote_id',
          userId: 'usr_customer_1',
        } as any),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects booking if client total does not match quote total (anti-tamper)', async () => {
      const quote = await bookingsService.calculateQuote('movie', {
        basePrice: 450,
        ticketCount: 1,
      });

      // User locked seat first
      await bookingsService.lockSeats({
        theatreId: 'th_prasad',
        showtimeId: 'st_101',
        seatIds: ['E12'],
        userId: 'usr_customer_1',
      });

      // Tamper: quote grandTotal is ~566, client sends 10
      await expect(
        bookingsService.createMovieBooking({
          theatreId: 'th_prasad',
          showtimeId: 'st_101',
          seatIds: ['E12'],
          date: '2026-10-15',
          time: '07:00 PM',
          movieTitle: 'Kalki 2898 AD',
          totalAmount: 10,
          quoteId: quote.quoteId,
          userId: 'usr_customer_1',
        } as any),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // =========================================================================
  // SECTION 3: 7 VERTICAL BOOKINGS & CONCURRENCY CONFLICT REJECTIONS
  // =========================================================================
  describe('3. All 7 Vertical Bookings & Concurrency Handling', () => {
    // 3.1 MOVIES
    it('Vertical 1: Movie booking converts seat lock into permanent UPCOMING booking', async () => {
      await bookingsService.lockSeats({
        theatreId: 'th_prasad',
        showtimeId: 'st_101',
        seatIds: ['E12'],
        userId: 'usr_customer_1',
      });

      const quote = await bookingsService.calculateQuote('movie', {
        basePrice: 450,
        ticketCount: 1,
      });

      const booking = await bookingsService.createMovieBooking({
        theatreId: 'th_prasad',
        showtimeId: 'st_101',
        seatIds: ['E12'],
        date: '2026-10-15',
        time: '07:00 PM',
        movieTitle: 'Kalki 2898 AD',
        totalAmount: quote.grandTotal,
        quoteId: quote.quoteId,
        userId: 'usr_customer_1',
      } as any);

      expect(booking.status).toBe(BookingStatus.UPCOMING);
      expect(booking.type).toBe(BookingType.MOVIE);
      expect(booking.qrCodeData).toBeDefined();
      expect(booking.metadata.seatLockConsumed).toBe(true);

      // Now another user cannot lock or book the same seat permanently
      await expect(
        bookingsService.lockSeats({
          theatreId: 'th_prasad',
          showtimeId: 'st_101',
          seatIds: ['E12'],
          userId: 'usr_customer_2',
        }),
      ).rejects.toThrow(ConflictException);
    });

    // 3.2 DINING
    it('Vertical 2: Dining reservation is complimentary ₹0 and rejects duplicate time slot', async () => {
      const reservation = await bookingsService.createDiningReservation({
        restaurantId: 'rest_paradise',
        date: '2026-10-16',
        time: '08:00 PM',
        partySize: 4,
        guestName: 'Alice Customer',
        guestPhone: '+919876543210',
        userId: 'usr_customer_1',
      } as any);

      expect(reservation.status).toBe(BookingStatus.UPCOMING);
      expect(reservation.totalPrice).toBe(0);
      expect(reservation.metadata.isComplimentary).toBe(true);

      // Duplicate reservation attempt by same customer at same time
      await expect(
        bookingsService.createDiningReservation({
          restaurantId: 'rest_paradise',
          date: '2026-10-16',
          time: '08:00 PM',
          partySize: 2,
          guestName: 'Alice Customer',
          guestPhone: '+919876543210',
          userId: 'usr_customer_1',
        } as any),
      ).rejects.toThrow(ConflictException);
    });

    // 3.3 SPORTS
    it('Vertical 3: Sports booking handles Pay-at-Venue and rejects slot conflict', async () => {
      const sportsBooking = await bookingsService.createSportsBooking({
        venueId: 'spt_arena',
        courtId: 'court_1',
        slotId: 'slot_turf_1',
        date: '2026-10-17',
        time: '07:00 PM - 08:00 PM',
        totalAmount: 1500,
        paymentMethod: 'PAY_AT_VENUE',
        userId: 'usr_customer_1',
      } as any);

      expect(sportsBooking.status).toBe(BookingStatus.UPCOMING);
      expect(sportsBooking.metadata.paymentMethod).toBe('PAY_AT_VENUE');
      expect(sportsBooking.metadata.paymentStatus).toBe('PENDING');

      // Duplicate concurrent booking on the same court and slot
      await expect(
        bookingsService.createSportsBooking({
          venueId: 'spt_arena',
          courtId: 'court_1',
          slotId: 'slot_turf_1',
          date: '2026-10-17',
          time: '07:00 PM - 08:00 PM',
          totalAmount: 1500,
          userId: 'usr_customer_2',
        } as any),
      ).rejects.toThrow(ConflictException);
    });

    // 3.4 EVENTS
    it('Vertical 4: Events booking atomically decrements remaining tickets and rejects when exhausted', async () => {
      const event = eventsDb.get('evt_rock_fest')!;
      expect(event.ticketTiers[0].remainingCount).toBe(1);

      const quote = await bookingsService.calculateQuote('event', {
        basePrice: 2999,
        ticketCount: 1,
      });

      // User 1 books the only remaining ticket
      const b1 = await bookingsService.createEventBooking({
        eventId: 'evt_rock_fest',
        tierId: 'tier_vip',
        ticketCount: 1,
        totalAmount: quote.grandTotal,
        quoteId: quote.quoteId,
        userId: 'usr_customer_1',
      } as any);

      expect(b1.status).toBe(BookingStatus.UPCOMING);
      expect(event.ticketTiers[0].remainingCount).toBe(0);

      // Concurrent User 2 attempts to book the exhausted tier
      const quote2 = await bookingsService.calculateQuote('event', {
        basePrice: 2999,
        ticketCount: 1,
      });

      await expect(
        bookingsService.createEventBooking({
          eventId: 'evt_rock_fest',
          tierId: 'tier_vip',
          ticketCount: 1,
          totalAmount: quote2.grandTotal,
          quoteId: quote2.quoteId,
          userId: 'usr_customer_2',
        } as any),
      ).rejects.toThrow(ConflictException);
    });

    // 3.5 ACTIVITIES
    it('Vertical 5: Activity booking decrements slot capacity and rejects when exhausted', async () => {
      const act = activitiesDb.get('act_karting')!;
      expect(act.timeSlots[0].availableSlots).toBe(1);

      const b1 = await bookingsService.createActivityBooking({
        activityId: 'act_karting',
        packageId: 'pkg_pro',
        timeSlot: '10:00 AM - 11:00 AM',
        date: '2026-10-18',
        numberOfPeople: 1,
        totalAmount: 1200,
        userId: 'usr_customer_1',
      } as any);

      expect(b1.status).toBe(BookingStatus.UPCOMING);
      expect(act.timeSlots[0].availableSlots).toBe(0);

      // Concurrent User 2 attempts to book the filled slot
      await expect(
        bookingsService.createActivityBooking({
          activityId: 'act_karting',
          packageId: 'pkg_pro',
          timeSlot: '10:00 AM - 11:00 AM',
          date: '2026-10-18',
          numberOfPeople: 1,
          totalAmount: 1200,
          userId: 'usr_customer_2',
        } as any),
      ).rejects.toThrow(ConflictException);
    });

    // 3.6 STAYS
    it('Vertical 6: Stays booking validates dates, deducts room inventory, and rejects exhaustion', async () => {
      // Invalid date range validation
      await expect(
        bookingsService.createStayBooking({
          hotelId: 'htl_palace',
          roomId: 'room_royal',
          checkIn: '2026-11-10',
          checkOut: '2026-11-09', // Checkout before checkin
          roomsCount: 1,
          guestName: 'Alice',
          guestEmail: 'alice@example.com',
          guestPhone: '+919876543210',
          totalAmount: 25000,
          userId: 'usr_customer_1',
        } as any),
      ).rejects.toThrow(BadRequestException);

      const hotel = hotelsDb.get('htl_palace')!;
      expect(hotel.rooms[0].availableRooms).toBe(1);

      const b1 = await bookingsService.createStayBooking({
        hotelId: 'htl_palace',
        roomId: 'room_royal',
        checkIn: '2026-11-10',
        checkOut: '2026-11-12', // 2 nights
        roomsCount: 1,
        guestName: 'Alice',
        guestEmail: 'alice@example.com',
        guestPhone: '+919876543210',
        totalAmount: 59000,
        userId: 'usr_customer_1',
      } as any);

      expect(b1.status).toBe(BookingStatus.UPCOMING);
      expect(hotel.rooms[0].availableRooms).toBe(0);
      expect(hotel.rooms[0].isAvailable).toBe(false);

      // Concurrent User 2 attempts to book the exhausted room
      await expect(
        bookingsService.createStayBooking({
          hotelId: 'htl_palace',
          roomId: 'room_royal',
          checkIn: '2026-11-10',
          checkOut: '2026-11-12',
          roomsCount: 1,
          guestName: 'Bob',
          guestEmail: 'bob@example.com',
          guestPhone: '+919876543211',
          totalAmount: 59000,
          userId: 'usr_customer_2',
        } as any),
      ).rejects.toThrow(ConflictException);
    });

    // 3.7 SHOPPING
    it('Vertical 7: Shopping order decrements stock atomically and rejects when insufficient stock', async () => {
      const prod = productsDb.get('prd_smartwatch')!;
      expect(prod.variants[0].stock).toBe(1);

      const o1 = await bookingsService.createShoppingOrder({
        items: [
          { productId: 'prd_smartwatch', variantId: 'var_black', quantity: 1 },
        ],
        shippingAddress: {
          fullName: 'Alice Customer',
          street: '123 High Street',
          city: 'Hyderabad',
          postalCode: '500081',
          phoneNumber: '+919876543210',
        },
        totalAmount: 3703,
        userId: 'usr_customer_1',
      } as any);

      expect(o1.status).toBe(BookingStatus.UPCOMING);
      expect(prod.variants[0].stock).toBe(0);
      expect(prod.variants[0].inStock).toBe(false);

      // Concurrent User 2 attempts to order out-of-stock variant
      await expect(
        bookingsService.createShoppingOrder({
          items: [
            { productId: 'prd_smartwatch', variantId: 'var_black', quantity: 1 },
          ],
          shippingAddress: {
            fullName: 'Bob Customer',
            street: '456 Low Street',
            city: 'Hyderabad',
            postalCode: '500081',
            phoneNumber: '+919876543211',
          },
          totalAmount: 3703,
          userId: 'usr_customer_2',
        } as any),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // =========================================================================
  // SECTION 4: DIGITAL PASS & QR CODE VERIFICATION
  // =========================================================================
  describe('4. Digital Pass & QR Code Verification', () => {
    it('successfully verifies a valid digital pass QR code', async () => {
      const reservation = await bookingsService.createDiningReservation({
        restaurantId: 'rest_paradise',
        date: '2026-10-20',
        time: '07:30 PM',
        partySize: 2,
        guestName: 'Alice Customer',
        guestPhone: '+919876543210',
        userId: 'usr_customer_1',
      } as any);

      const verification = await bookingsService.verifyPass(reservation.id, reservation.qrCodeData);
      expect(verification.valid).toBe(true);
      expect(verification.isUsable).toBe(true);
      expect(verification.status).toBe(BookingStatus.UPCOMING);
      expect(verification.bookingId).toBe(reservation.id);
      expect(verification.title).toBe(reservation.title);
    });

    it('rejects verification if QR code data is tampered or mismatched', async () => {
      const reservation = await bookingsService.createDiningReservation({
        restaurantId: 'rest_paradise',
        date: '2026-10-21',
        time: '07:30 PM',
        partySize: 2,
        guestName: 'Alice Customer',
        guestPhone: '+919876543210',
        userId: 'usr_customer_1',
      } as any);

      await expect(
        bookingsService.verifyPass(reservation.id, 'tampered_qr_code_signature'),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects pass verification if booking is cancelled', async () => {
      const reservation = await bookingsService.createDiningReservation({
        restaurantId: 'rest_paradise',
        date: '2026-10-22',
        time: '07:30 PM',
        partySize: 2,
        guestName: 'Alice Customer',
        guestPhone: '+919876543210',
        userId: 'usr_customer_1',
      } as any);

      await bookingsService.cancel(reservation.id, 'usr_customer_1');

      const verification = await bookingsService.verifyPass(reservation.id, reservation.qrCodeData);
      expect(verification.valid).toBe(false);
      expect(verification.status).toBe(BookingStatus.CANCELLED);
    });
  });

  // =========================================================================
  // SECTION 5: CANCELLATION, INVENTORY RESTORATION, REFUND & REWARD REVERSAL
  // =========================================================================
  describe('5. Cancellation, Inventory Restoration, Refund & Reward Reversal', () => {
    it('restores event ticket tier inventory and triggers refund upon cancellation', async () => {
      const event = eventsDb.get('evt_rock_fest')!;
      event.ticketTiers[0].remainingCount = 5;

      const booking = await bookingsService.createEventBooking({
        eventId: 'evt_rock_fest',
        tierId: 'tier_vip',
        ticketCount: 2,
        totalAmount: 6000,
        userId: 'usr_customer_1',
      } as any);

      expect(event.ticketTiers[0].remainingCount).toBe(3);

      // Simulate reward awarded
      booking.metadata.rewardAwarded = true;
      booking.metadata.rewardPoints = 300;

      const cancelledBooking = await bookingsService.cancel(booking.id, 'usr_customer_1');
      expect(cancelledBooking.status).toBe(BookingStatus.CANCELLED);
      // Inventory restored
      expect(event.ticketTiers[0].remainingCount).toBe(5);
      // Refund triggered
      expect(cancelledBooking.metadata.refundProcessed).toBe(true);
      expect(cancelledBooking.metadata.refundId).toBe('rfnd_sim_phase24');
      // Reward reversed
      expect(cancelledBooking.metadata.rewardPointsReversed).toBe(true);
    });

    it('restores activity time slots capacity upon cancellation', async () => {
      const act = activitiesDb.get('act_karting')!;
      act.timeSlots[0].availableSlots = 4;

      const booking = await bookingsService.createActivityBooking({
        activityId: 'act_karting',
        packageId: 'pkg_pro',
        timeSlot: '10:00 AM - 11:00 AM',
        date: '2026-10-18',
        numberOfPeople: 2,
        totalAmount: 2400,
        userId: 'usr_customer_1',
      } as any);

      expect(act.timeSlots[0].availableSlots).toBe(2);

      await bookingsService.cancel(booking.id, 'usr_customer_1');
      expect(act.timeSlots[0].availableSlots).toBe(4);
    });

    it('restores stays room inventory upon cancellation', async () => {
      const hotel = hotelsDb.get('htl_palace')!;
      hotel.rooms[0].availableRooms = 3;
      hotel.rooms[0].isAvailable = true;

      const booking = await bookingsService.createStayBooking({
        hotelId: 'htl_palace',
        roomId: 'room_royal',
        checkIn: '2026-11-10',
        checkOut: '2026-11-12',
        roomsCount: 2,
        guestName: 'Alice',
        guestEmail: 'alice@example.com',
        guestPhone: '+919876543210',
        totalAmount: 50000,
        userId: 'usr_customer_1',
      } as any);

      expect(hotel.rooms[0].availableRooms).toBe(1);

      await bookingsService.cancel(booking.id, 'usr_customer_1');
      expect(hotel.rooms[0].availableRooms).toBe(3);
    });
  });

  // =========================================================================
  // SECTION 6: PARTNER CHECK-IN TENANT ISOLATION
  // =========================================================================
  describe('6. Partner Check-In Tenant Isolation', () => {
    it('allows a partner to check in their own booking transitioning it to COMPLETED', async () => {
      const sportsBooking = await bookingsService.createSportsBooking({
        venueId: 'spt_arena',
        courtId: 'court_1',
        slotId: 'slot_turf_1',
        date: '2026-10-17',
        time: '07:00 PM - 08:00 PM',
        totalAmount: 1500,
        paymentMethod: 'PAY_AT_VENUE',
        userId: 'usr_customer_1',
      } as any);

      // Tag booking to partner A
      sportsBooking.partnerId = 'part_a';
      sportsBooking.businessId = 'biz_a';

      const checkinResult = await partnersService.checkInCustomer('part_a', sportsBooking.id, {
        id: 'usr_partner_a',
        email: 'partner@example.com',
        role: 'ADMIN',
      });
      expect(checkinResult.success).toBe(true);
      expect(sportsBooking.status).toBe(BookingStatus.COMPLETED);
    });

    it('strictly forbids a partner from checking in a booking belonging to another partner', async () => {
      const sportsBooking = await bookingsService.createSportsBooking({
        venueId: 'spt_arena',
        courtId: 'court_1',
        slotId: 'slot_turf_1',
        date: '2026-10-17',
        time: '07:00 PM - 08:00 PM',
        totalAmount: 1500,
        paymentMethod: 'PAY_AT_VENUE',
        userId: 'usr_customer_1',
      } as any);

      // Tag booking to Partner A
      sportsBooking.partnerId = 'part_a';
      sportsBooking.businessId = 'biz_a';

      // Partner B attempts to check in Partner A's booking
      await expect(
        partnersService.checkInCustomer('part_b_intruder', sportsBooking.id, {
          id: 'usr_partner_b',
          email: 'partnerB@example.com',
          role: 'ADMIN',
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
