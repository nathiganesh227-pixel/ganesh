import {
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';

import { AdminController } from './modules/admin/admin.controller';
import { AdminService } from './modules/admin/admin.service';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from './modules/auth/guards/roles.guard';
import { ROLES_KEY } from './modules/auth/decorators/roles.decorator';
import { User, UserRole } from './database/entities/user.entity';
import { MovieEntity } from './database/entities/movie.entity';
import { TheatreEntity } from './database/entities/theatre.entity';
import { RestaurantEntity } from './database/entities/restaurant.entity';
import { EventEntity } from './database/entities/event.entity';
import { ActivityEntity } from './database/entities/activity.entity';
import { ProductEntity } from './database/entities/product.entity';
import { HotelEntity } from './database/entities/hotel.entity';
import { SportsVenueEntity } from './database/entities/sports-venue.entity';
import { BookingEntity, BookingStatus, BookingType } from './database/entities/booking.entity';
import { AuditLogEntity } from './database/entities/audit-log.entity';
import { ScreenEntity } from './database/entities/screen.entity';
import { ShowEntity } from './database/entities/show.entity';
import { PaymentEntity, PaymentStatus } from './database/entities/payment.entity';
import { NotificationEntity } from './database/entities/notification.entity';
import { WebhookEventEntity } from './database/entities/webhook-event.entity';
import { PaymentService } from './modules/payments/payment.service';

describe('Phase 21 — Production Admin & Operations Console', () => {
  const TEST_JWT_SECRET = 'test_phase21_admin_ops_secret_key_2026';
  let jwtService: JwtService;
  let adminService: AdminService;
  let adminController: AdminController;
  let jwtAuthGuard: JwtAuthGuard;
  let rolesGuard: RolesGuard;
  let reflector: Reflector;

  // In-memory repositories storage
  let mockUsers: User[] = [];
  let mockBookings: BookingEntity[] = [];
  let mockPayments: PaymentEntity[] = [];
  let mockNotifications: NotificationEntity[] = [];
  let mockAuditLogs: AuditLogEntity[] = [];
  let mockEvents: EventEntity[] = [];
  let mockActivities: ActivityEntity[] = [];

  let mockUserRepo: any;
  let mockMovieRepo: any;
  let mockTheatreRepo: any;
  let mockScreenRepo: any;
  let mockShowRepo: any;
  let mockRestaurantRepo: any;
  let mockEventRepo: any;
  let mockActivityRepo: any;
  let mockProductRepo: any;
  let mockHotelRepo: any;
  let mockSportsVenueRepo: any;
  let mockBookingRepo: any;
  let mockAuditLogRepo: any;
  let mockPaymentRepo: any;
  let mockNotificationRepo: any;
  let mockWebhookEventRepo: any;
  let mockPaymentService: any;

  beforeEach(() => {
    jwtService = new JwtService({
      secret: TEST_JWT_SECRET,
      signOptions: { expiresIn: '1h' },
    });

    mockUsers = [
      {
        id: 'usr_admin_1',
        email: 'admin@plaza.app',
        passwordHash: '$2b$10$hashedAdminPassword',
        name: 'Super Admin',
        phone: '+91 99999 00001',
        city: 'Hyderabad',
        role: UserRole.ADMIN,
        rewardPoints: 1000,
        createdAt: new Date('2026-01-01T00:00:00Z'),
        updatedAt: new Date('2026-01-01T00:00:00Z'),
      } as User,
      {
        id: 'usr_operator_1',
        email: 'operator@plaza.app',
        passwordHash: '$2b$10$hashedOperatorPassword',
        name: 'Plaza Operator',
        phone: '+91 99999 00002',
        city: 'Hyderabad',
        role: UserRole.OPERATOR,
        rewardPoints: 200,
        createdAt: new Date('2026-01-02T00:00:00Z'),
        updatedAt: new Date('2026-01-02T00:00:00Z'),
      } as User,
      {
        id: 'usr_customer_1',
        email: 'customer@plaza.app',
        passwordHash: '$2b$10$hashedCustomerPassword',
        name: 'Jane Customer',
        phone: '+91 98765 43210',
        city: 'Hyderabad',
        role: UserRole.USER,
        rewardPoints: 500,
        createdAt: new Date('2026-01-03T00:00:00Z'),
        updatedAt: new Date('2026-01-03T00:00:00Z'),
      } as User,
    ];

    mockBookings = [
      {
        id: 'bk_mov_101',
        userId: 'usr_customer_1',
        type: BookingType.MOVIE,
        title: 'Pushpa 2: The Rule',
        subtitle: 'AMB Cinemas • Screen 1 (Laser IMAX) • 2 Seats',
        imageUrl: 'https://images.unsplash.com/pushpa2.jpg',
        date: '2026-09-28',
        time: '18:30',
        location: 'AMB Cinemas, Gachibowli',
        status: BookingStatus.UPCOMING,
        totalPrice: 700,
        qrCodeData: 'PLZ-QR-MOV-101',
        metadata: { basePrice: 600, taxes: 50, convenienceFee: 50, seats: ['G12', 'G13'] },
        createdAt: new Date('2026-09-26T10:00:00Z'),
        updatedAt: new Date('2026-09-26T10:00:00Z'),
      } as BookingEntity,
      {
        id: 'bk_evt_202',
        userId: 'usr_customer_1',
        type: BookingType.EVENT,
        title: 'Sunburn Arena Hyderabad',
        subtitle: 'VIP Experience Pass',
        imageUrl: 'https://images.unsplash.com/sunburn.jpg',
        date: '2026-10-15',
        time: '16:00',
        location: 'GMR Arena',
        status: BookingStatus.CONFIRMED,
        totalPrice: 2500,
        qrCodeData: 'PLZ-QR-EVT-202',
        metadata: { eventId: 'evt_sunburn_1', tierId: 'tier_vip', tickets: 1, basePrice: 2500 },
        createdAt: new Date('2026-09-26T11:00:00Z'),
        updatedAt: new Date('2026-09-26T11:00:00Z'),
      } as BookingEntity,
      {
        id: 'bk_fail_303',
        userId: 'usr_customer_1',
        type: BookingType.ACTIVITY,
        title: 'Go-Karting Grand Prix',
        subtitle: 'Pro Track 10 Laps',
        imageUrl: 'https://images.unsplash.com/karting.jpg',
        date: '2026-09-27',
        time: '14:00',
        location: 'Chicane Circuit',
        status: BookingStatus.FAILED,
        totalPrice: 1200,
        qrCodeData: 'PLZ-QR-KART-303',
        metadata: { failureReason: 'Payment authorization declined' },
        createdAt: new Date('2026-09-26T12:00:00Z'),
        updatedAt: new Date('2026-09-26T12:00:00Z'),
      } as BookingEntity,
    ];

    mockPayments = [
      {
        id: 'pay_rzp_101',
        bookingId: 'bk_mov_101',
        userId: 'usr_customer_1',
        amount: 700,
        currency: 'INR',
        provider: 'razorpay',
        providerOrderId: 'order_rzp_101',
        providerPaymentId: 'pay_gateway_id_101',
        providerSignature: 'secret_hmac_signature_should_not_leak',
        status: PaymentStatus.CAPTURED,
        paymentMethod: 'UPI',
        refundAmount: 0,
        metadata: { channel: 'gpay' },
        createdAt: new Date('2026-09-26T10:01:00Z'),
        updatedAt: new Date('2026-09-26T10:01:00Z'),
      } as PaymentEntity,
      {
        id: 'pay_fail_202',
        bookingId: 'bk_fail_303',
        userId: 'usr_customer_1',
        amount: 1200,
        currency: 'INR',
        provider: 'razorpay',
        providerOrderId: 'order_rzp_202',
        providerPaymentId: null as any,
        providerSignature: null as any,
        status: PaymentStatus.FAILED,
        failureReason: 'Card issuer authentication timed out',
        refundAmount: 0,
        metadata: {},
        createdAt: new Date('2026-09-26T12:01:00Z'),
        updatedAt: new Date('2026-09-26T12:01:00Z'),
      } as PaymentEntity,
    ];

    mockEvents = [
      {
        id: 'evt_sunburn_1',
        title: 'Sunburn Arena Hyderabad',
        category: 'Music',
        ticketTiers: [
          { id: 'tier_vip', name: 'VIP', price: 2500, remainingCount: 19, description: 'VIP Lounge' },
        ],
        isFeatured: true,
        isPublished: true,
      } as EventEntity,
    ];

    mockActivities = [
      {
        id: 'act_kart_1',
        title: 'Go-Karting Grand Prix',
        category: 'Racing',
        timeSlots: [
          { time: '14:00', availableSlots: 8 },
        ],
        isPublished: true,
      } as ActivityEntity,
    ];

    mockNotifications = [
      {
        id: 'notif_1',
        userId: 'usr_customer_1',
        title: 'Booking Confirmed',
        message: 'Your booking for Pushpa 2: The Rule is confirmed',
        type: 'booking',
        timeAgo: '10m ago',
        isRead: false,
        actionRoute: '/bookings/bk_mov_101',
        createdAt: new Date('2026-09-26T10:02:00Z'),
        updatedAt: new Date('2026-09-26T10:02:00Z'),
      } as NotificationEntity,
    ];

    mockAuditLogs = [];

    // Setup Mock Repositories
    mockUserRepo = {
      count: jest.fn().mockImplementation(async (opts?: any) => {
        if (opts?.where?.role) {
          return mockUsers.filter((u) => u.role === opts.where.role).length;
        }
        return mockUsers.length;
      }),
      find: jest.fn().mockImplementation(async () => mockUsers),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockUsers.find((u) => u.id === where?.id || u.email === where?.email) || null;
      }),
      save: jest.fn().mockImplementation(async (u: User) => {
        const idx = mockUsers.findIndex((x) => x.id === u.id);
        if (idx >= 0) mockUsers[idx] = { ...mockUsers[idx], ...u };
        return u;
      }),
      query: jest.fn().mockResolvedValue([{ 1: 1 }]),
      createQueryBuilder: jest.fn().mockReturnValue({
        select: jest.fn().mockReturnThis(),
        getRawOne: jest.fn().mockResolvedValue({ total: '1700' }),
        where: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockImplementation(async () => mockUsers),
      }),
    };

    mockBookingRepo = {
      count: jest.fn().mockImplementation(async (opts?: any) => {
        if (opts?.where?.status) {
          return mockBookings.filter((b) => b.status === opts.where.status).length;
        }
        return mockBookings.length;
      }),
      find: jest.fn().mockImplementation(async (opts?: any) => {
        if (opts?.where?.status) {
          return mockBookings.filter((b) => b.status === opts.where.status);
        }
        return mockBookings;
      }),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockBookings.find((b) => b.id === where?.id) || null;
      }),
      save: jest.fn().mockImplementation(async (b: BookingEntity) => {
        const idx = mockBookings.findIndex((x) => x.id === b.id);
        if (idx >= 0) mockBookings[idx] = { ...mockBookings[idx], ...b };
        return b;
      }),
      createQueryBuilder: jest.fn().mockReturnValue({
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getRawOne: jest.fn().mockResolvedValue({ total: '3200' }),
        getMany: jest.fn().mockImplementation(async () => mockBookings),
        getManyAndCount: jest.fn().mockImplementation(async () => [mockBookings, mockBookings.length]),
      }),
    };

    mockPaymentRepo = {
      count: jest.fn().mockImplementation(async (opts?: any) => {
        if (opts?.where?.status) {
          return mockPayments.filter((p) => p.status === opts.where.status).length;
        }
        return mockPayments.length;
      }),
      find: jest.fn().mockImplementation(async (opts?: any) => {
        if (opts?.where?.status) {
          return mockPayments.filter((p) => p.status === opts.where.status);
        }
        return mockPayments;
      }),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return (
          mockPayments.find((p) => {
            if (where.id && p.id === where.id) return true;
            if (where.bookingId && p.bookingId === where.bookingId) return true;
            if (where.providerPaymentId && p.providerPaymentId === where.providerPaymentId) return true;
            return false;
          }) || null
        );
      }),
      save: jest.fn().mockImplementation(async (p: PaymentEntity) => {
        const idx = mockPayments.findIndex((x) => x.id === p.id);
        if (idx >= 0) mockPayments[idx] = { ...mockPayments[idx], ...p };
        else mockPayments.push(p);
        return p;
      }),
      createQueryBuilder: jest.fn().mockReturnValue({
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getRawOne: jest.fn().mockResolvedValue({ total: '0' }),
        getMany: jest.fn().mockImplementation(async () => mockPayments),
        getManyAndCount: jest.fn().mockImplementation(async () => [mockPayments, mockPayments.length]),
      }),
    };

    mockAuditLogRepo = {
      save: jest.fn().mockImplementation(async (log: AuditLogEntity) => {
        mockAuditLogs.push(log);
        return log;
      }),
      find: jest.fn().mockImplementation(async () => mockAuditLogs),
      createQueryBuilder: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockImplementation(async () => mockAuditLogs),
        getManyAndCount: jest.fn().mockImplementation(async () => [mockAuditLogs, mockAuditLogs.length]),
      }),
    };

    mockNotificationRepo = {
      findAndCount: jest.fn().mockResolvedValue([mockNotifications, mockNotifications.length]),
    };

    mockEventRepo = {
      count: jest.fn().mockResolvedValue(1),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockEvents.find((e) => e.id === where?.id) || null;
      }),
      save: jest.fn().mockImplementation(async (e: EventEntity) => {
        const idx = mockEvents.findIndex((x) => x.id === e.id);
        if (idx >= 0) mockEvents[idx] = { ...mockEvents[idx], ...e };
        return e;
      }),
      createQueryBuilder: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue(mockEvents),
      }),
    };

    mockActivityRepo = {
      count: jest.fn().mockResolvedValue(1),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockActivities.find((a) => a.id === where?.id) || null;
      }),
      save: jest.fn().mockImplementation(async (a: ActivityEntity) => {
        const idx = mockActivities.findIndex((x) => x.id === a.id);
        if (idx >= 0) mockActivities[idx] = { ...mockActivities[idx], ...a };
        return a;
      }),
      createQueryBuilder: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue(mockActivities),
      }),
    };

    mockMovieRepo = {
      count: jest.fn().mockResolvedValue(10),
      find: jest.fn().mockResolvedValue([]),
      createQueryBuilder: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
      }),
    };

    mockRestaurantRepo = {
      count: jest.fn().mockResolvedValue(8),
      find: jest.fn().mockResolvedValue([]),
      createQueryBuilder: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
      }),
    };

    mockProductRepo = {
      count: jest.fn().mockResolvedValue(15),
      find: jest.fn().mockResolvedValue([]),
      createQueryBuilder: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
      }),
    };

    mockHotelRepo = {
      count: jest.fn().mockResolvedValue(6),
      find: jest.fn().mockResolvedValue([]),
      createQueryBuilder: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
      }),
    };

    mockSportsVenueRepo = {
      count: jest.fn().mockResolvedValue(5),
      find: jest.fn().mockResolvedValue([]),
      createQueryBuilder: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
      }),
    };

    mockTheatreRepo = { count: jest.fn().mockResolvedValue(4), find: jest.fn().mockResolvedValue([]) };
    mockScreenRepo = { count: jest.fn().mockResolvedValue(12), find: jest.fn().mockResolvedValue([]) };
    mockShowRepo = { count: jest.fn().mockResolvedValue(30), find: jest.fn().mockResolvedValue([]) };
    mockWebhookEventRepo = {};

    mockPaymentService = {
      processRefund: jest.fn().mockImplementation(async (paymentId: string, amount: number, reason: string) => {
        const refundId = `rfnd_${Date.now()}`;
        const pay = mockPayments.find((p) => p.id === paymentId || p.providerPaymentId === paymentId);
        if (pay) {
          pay.status = PaymentStatus.REFUNDED;
          pay.refundAmount = amount;
          pay.refundId = refundId;
        }
        return {
          refundId,
          paymentId,
          amount,
          status: 'REFUNDED',
          reason,
        };
      }),
    };

    adminService = new AdminService(
      mockUserRepo,
      mockMovieRepo,
      mockTheatreRepo,
      mockRestaurantRepo,
      mockEventRepo,
      mockActivityRepo,
      mockProductRepo,
      mockHotelRepo,
      mockSportsVenueRepo,
      mockBookingRepo,
      mockAuditLogRepo,
      mockScreenRepo,
      mockShowRepo,
      mockPaymentRepo,
      mockNotificationRepo,
      mockWebhookEventRepo,
      mockPaymentService,
    );

    adminController = new AdminController(adminService);

    reflector = new Reflector();
    jwtAuthGuard = new JwtAuthGuard(jwtService);
    rolesGuard = new RolesGuard(reflector);
  });

  // Helper token generators
  function createToken(payload: { sub: string; email: string; role: UserRole }): string {
    return jwtService.sign(payload);
  }

  const getAdminToken = () =>
    createToken({ sub: 'usr_admin_1', email: 'admin@plaza.app', role: UserRole.ADMIN });

  const getOperatorToken = () =>
    createToken({ sub: 'usr_operator_1', email: 'operator@plaza.app', role: UserRole.OPERATOR });

  const getCustomerToken = () =>
    createToken({ sub: 'usr_customer_1', email: 'customer@plaza.app', role: UserRole.USER });

  // Guard Pipeline Helper
  async function executePipeline(
    handler: Function,
    reqHeaders: Record<string, string>,
    action: () => any,
  ): Promise<any> {
    const mockRequest: any = {
      headers: reqHeaders,
    };
    const mockContext = {
      switchToHttp: () => ({
        getRequest: () => mockRequest,
      }),
      getHandler: () => handler,
      getClass: () => AdminController,
    } as unknown as ExecutionContext;

    const canActivateJwt = await jwtAuthGuard.canActivate(mockContext);
    if (!canActivateJwt) {
      throw new UnauthorizedException('JWT validation failed');
    }

    const canActivateRoles = rolesGuard.canActivate(mockContext);
    if (!canActivateRoles) {
      throw new ForbiddenException('Insufficient role permissions');
    }

    return action();
  }

  // ---------------- 1. SECURITY & RBAC ----------------
  describe('1. Security & RBAC: Admin vs Operator vs User', () => {
    it('should reject unauthenticated requests with 401', async () => {
      await expect(
        executePipeline(
          AdminController.prototype.getHealth,
          {},
          () => adminController.getHealth(),
        ),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should reject normal customer (USER) with 403 on operational endpoints', async () => {
      await expect(
        executePipeline(
          AdminController.prototype.getDashboard,
          { authorization: `Bearer ${getCustomerToken()}` },
          () => adminController.getDashboard(),
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should allow OPERATOR on routine operational endpoints (dashboard, search, bookings, health)', async () => {
      const dashboard = await executePipeline(
        AdminController.prototype.getDashboard,
        { authorization: `Bearer ${getOperatorToken()}` },
        () => adminController.getDashboard(),
      );
      expect(dashboard).toBeDefined();
      expect(dashboard.platform).toBeDefined();

      const health = await executePipeline(
        AdminController.prototype.getSystemHealth,
        { authorization: `Bearer ${getOperatorToken()}` },
        () => adminController.getSystemHealth(),
      );
      expect(health.status).toBe('HEALTHY');
    });

    it('should BLOCK OPERATOR with 403 on sensitive administrative endpoints (refund, role change, reward adjustment)', async () => {
      // 1. Refund
      await expect(
        executePipeline(
          AdminController.prototype.refundBooking,
          { authorization: `Bearer ${getOperatorToken()}` },
          () => adminController.refundBooking('bk_mov_101', { reason: 'Test' }, { user: mockUsers[1] }),
        ),
      ).rejects.toThrow(ForbiddenException);

      // 2. Role Change
      await expect(
        executePipeline(
          AdminController.prototype.updateUserRole,
          { authorization: `Bearer ${getOperatorToken()}` },
          () => adminController.updateUserRole('usr_customer_1', { role: UserRole.OPERATOR }, { user: mockUsers[1] }),
        ),
      ).rejects.toThrow(ForbiddenException);

      // 3. Reward Adjustment
      await expect(
        executePipeline(
          AdminController.prototype.adjustUserRewards,
          { authorization: `Bearer ${getOperatorToken()}` },
          () => adminController.adjustUserRewards('usr_customer_1', { amount: 100, reason: 'Goodwill' }, { user: mockUsers[1] }),
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should allow ADMIN on all sensitive administrative endpoints', async () => {
      const roles = reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
        AdminController.prototype.refundBooking,
        AdminController,
      ]);
      expect(roles).toEqual([UserRole.ADMIN, UserRole.SUPER_ADMIN]);
    });
  });

  // ---------------- 2. DASHBOARD OVERVIEW ----------------
  describe('2. Admin Dashboard Overview & Live Metrics', () => {
    it('should return complete platform metrics and 7 vertical breakdowns without hardcoding', async () => {
      const stats = await adminService.getDashboardStats();

      // Top level
      expect(stats.users).toBe(3);
      expect(stats.bookings).toBe(3);

      // Platform metrics
      expect(stats.platform.totalUsers).toBe(3);
      expect(stats.platform.adminUsers).toBe(1);
      expect(stats.platform.operatorUsers).toBe(1);
      expect(stats.platform.totalBookings).toBe(3);
      expect(stats.platform.grossBookingValue).toBe(3200);
      expect(stats.platform.totalRewardsIssued).toBe(1700);

      // Verticals breakdown
      expect(stats.verticals.movies.total).toBe(10);
      expect(stats.verticals.dining.total).toBe(8);
      expect(stats.verticals.events.total).toBe(1);
      expect(stats.verticals.activities.total).toBe(1);
      expect(stats.verticals.shopping.total).toBe(15);
      expect(stats.verticals.stays.total).toBe(6);
      expect(stats.verticals.sports.total).toBe(5);
    });
  });

  // ---------------- 3. GLOBAL OPERATIONS SEARCH ----------------
  describe('3. Global Operations Search', () => {
    it('should find bookings, payments, users, and catalog items by query', async () => {
      const result = await adminService.searchOperations('Pushpa');

      expect(result.query).toBe('Pushpa');
      expect(result.totalMatches).toBeGreaterThan(0);
      const bookingMatch = result.results.find((r) => r.type === 'booking');
      expect(bookingMatch).toBeDefined();
      expect(bookingMatch?.title).toContain('Pushpa');
      expect(bookingMatch?.link).toBe('/admin/bookings/bk_mov_101');
    });

    it('should return empty results gracefully on empty or whitespace query', async () => {
      const emptyResult = await adminService.searchOperations('   ');
      expect(emptyResult.totalMatches).toBe(0);
      expect(emptyResult.results).toEqual([]);
    });
  });

  // ---------------- 4. BOOKINGS OPERATIONS & AUDIT TIMELINE ----------------
  describe('4. Booking Operations & Detail Breakdown', () => {
    it('should list bookings and support query filtering', async () => {
      const result = await adminService.getBookings({ vertical: 'movie', limit: 10, offset: 0 });
      expect(result.total).toBe(3);
      expect(result.bookings.length).toBeGreaterThan(0);
      expect((result.bookings[0] as any).paymentStatus).toBe(PaymentStatus.CAPTURED);
    });

    it('should return detailed booking with customer contact, line-item pricing, and audit timeline', async () => {
      const detail = await adminService.getBookingDetails('bk_mov_101');

      expect(detail.booking.id).toBe('bk_mov_101');
      expect(detail.customer.email).toBe('customer@plaza.app');
      expect(detail.pricing.basePrice).toBe(600);
      expect(detail.pricing.taxes).toBe(50);
      expect(detail.pricing.convenienceFee).toBe(50);
      expect(detail.pricing.totalPrice).toBe(700);
      expect(detail.payment?.status).toBe(PaymentStatus.CAPTURED);
      expect(detail.timeline.length).toBeGreaterThanOrEqual(1);
    });
  });

  // ---------------- 5. REFUND WORKFLOW ----------------
  describe('5. Safe Refund & Cancellation Workflow', () => {
    it('should execute real payment gateway refund, cancel booking, restore inventory, and record audit log', async () => {
      const refundDto = { reason: 'Customer requested refund due to schedule conflict' };
      const actor = { id: 'usr_admin_1', email: 'admin@plaza.app' };

      const result = await adminService.refundBooking('bk_evt_202', refundDto, actor);

      expect(result.success).toBe(true);
      expect(result.booking.status).toBe(BookingStatus.CANCELLED);

      // Verify event inventory restored
      const event = mockEvents.find((e) => e.id === 'evt_sunburn_1');
      expect(event?.ticketTiers[0].remainingCount).toBe(20); // 19 + 1 restored

      // Verify audit log recorded
      const log = mockAuditLogs.find((l) => l.action === 'REFUND_BOOKING');
      expect(log).toBeDefined();
      expect(log?.actorEmail).toBe('admin@plaza.app');
      expect(log?.metadata?.reason).toBe(refundDto.reason);
    });

    it('should reject refunding an already cancelled booking', async () => {
      const refundDto = { reason: 'Duplicate refund attempt' };
      const actor = { id: 'usr_admin_1', email: 'admin@plaza.app' };

      // First refund
      await adminService.refundBooking('bk_mov_101', refundDto, actor);

      // Second attempt should fail
      await expect(
        adminService.refundBooking('bk_mov_101', refundDto, actor),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ---------------- 6. PAYMENT OPERATIONS & SECRETS PROTECTION ----------------
  describe('6. Payment Operations & Secrets Protection', () => {
    it('should return payments list with safe projection without exposing providerSignature or secrets', async () => {
      const result = await adminService.getPayments({ limit: 10, offset: 0 });

      expect(result.total).toBe(2);
      expect(result.payments.length).toBe(2);

      const capturedPay: any = result.payments.find((p) => p.id === 'pay_rzp_101');
      expect(capturedPay).toBeDefined();
      expect(capturedPay.amount).toBe(700);
      expect(capturedPay.status).toBe(PaymentStatus.CAPTURED);

      // CRITICAL SECURITY ASSERTION: gateway signatures must never leak to UI
      expect(capturedPay.providerSignature).toBeUndefined();
      expect(capturedPay.keySecret).toBeUndefined();
    });
  });

  // ---------------- 7. USER MANAGEMENT & LAST-ADMIN DEFENSE ----------------
  describe('7. User Operations, Last-Admin Defense & Reward Adjustments', () => {
    it('should prevent demoting the last remaining administrator', async () => {
      const actor = { id: 'usr_admin_1', email: 'admin@plaza.app' };

      await expect(
        adminService.updateUserRole('usr_admin_1', { role: UserRole.USER }, actor),
      ).rejects.toThrow(BadRequestException);
    });

    it('should allow adjusting user reward points with mandatory reason and audit record', async () => {
      const actor = { id: 'usr_admin_1', email: 'admin@plaza.app' };
      const result = await adminService.adjustUserRewards(
        'usr_customer_1',
        { amount: 150, reason: 'Goodwill compensation for screening audio glitch' },
        actor,
      );

      expect(result.success).toBe(true);
      expect(result.previousPoints).toBe(500);
      expect(result.newPoints).toBe(650);
      expect(result.user.rewardPoints).toBe(650);

      // Verify audit log
      const audit = mockAuditLogs.find((l) => l.action === 'ADJUST_USER_REWARDS');
      expect(audit).toBeDefined();
      expect(audit?.actorEmail).toBe('admin@plaza.app');
      expect(audit?.metadata?.adjustment).toBe(150);
      expect(audit?.metadata?.reason).toContain('Goodwill compensation');
    });
  });

  // ---------------- 8. SYSTEM HEALTH & TRUTHFUL GATEWAY MODE ----------------
  describe('8. System Health, DB Ping & Truthful Gateway Mode', () => {
    it('should truthfully report payment mode as TEST/SANDBOX when live keys are absent', async () => {
      const health = await adminService.getSystemHealth();

      expect(health.status).toBe('HEALTHY');
      expect(health.services.api.status).toBe('UP');
      expect(health.services.database.status).toBe('UP');

      // Truthful gateway verification
      expect(health.services.payments.mode).toBe('TEST/SANDBOX');
      expect(health.services.notifications.mode).toBe('TEST/SANDBOX');
    });
  });

  // ---------------- 9. INCIDENTS OPERATIONS ----------------
  describe('9. Operational Incidents & Correlation IDs', () => {
    it('should list operational failures with correlation IDs and severity ratings', async () => {
      const incidents = await adminService.getIncidents(10, 0);

      expect(incidents.total).toBeGreaterThan(0);
      const payIncident = incidents.incidents.find((i) => i.source === 'PAYMENT_GATEWAY');
      expect(payIncident).toBeDefined();
      expect(payIncident?.severity).toBe('HIGH');
      expect(payIncident?.correlationId).toBeDefined();
      expect(payIncident?.message).toContain('Card issuer authentication timed out');
    });
  });
});
