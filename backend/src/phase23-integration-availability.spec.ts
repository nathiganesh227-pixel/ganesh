import {
  NotFoundException,
  ConflictException,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';

import { IntegrationsModule } from './modules/integrations/integrations.module';
import { IntegrationsService } from './modules/integrations/integrations.service';
import { ProviderRegistryService } from './modules/integrations/registry/provider-registry.service';
import { AdminIntegrationsController } from './modules/integrations/admin-integrations.controller';

import { PartnerIntegrationAdapter } from './modules/integrations/adapters/partner.adapter';
import { AdminCuratedAdapter } from './modules/integrations/adapters/admin.adapter';
import { MovieProviderAdapter } from './modules/integrations/adapters/movie-provider.adapter';
import { DiningProviderAdapter } from './modules/integrations/adapters/dining-provider.adapter';
import { EventProviderAdapter } from './modules/integrations/adapters/event-provider.adapter';
import { ActivityProviderAdapter } from './modules/integrations/adapters/activity-provider.adapter';
import { StayProviderAdapter } from './modules/integrations/adapters/stay-provider.adapter';
import { SportsProviderAdapter } from './modules/integrations/adapters/sports-provider.adapter';
import { ShoppingProviderAdapter } from './modules/integrations/adapters/shopping-provider.adapter';

import {
  IntegrationProviderType,
  IntegrationStatus,
  AvailabilityStatus,
  AvailabilityFreshness,
} from './modules/integrations/dto/integration.dto';

import {
  IntegrationMappingEntity,
  SyncStatus,
} from './database/entities/integration-mapping.entity';
import {
  IntegrationSyncRunEntity,
  SyncRunStatus,
} from './database/entities/integration-sync-run.entity';
import { BookingEntity, BookingStatus, BookingType } from './database/entities/booking.entity';

import { PartnersService } from './modules/partners/partners.service';
import { PartnersController } from './modules/partners/partners.controller';
import { PartnerTenantGuard } from './modules/partners/guards/partner-tenant.guard';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from './modules/auth/guards/roles.guard';
import { ROLES_KEY } from './modules/auth/decorators/roles.decorator';
import { User, UserRole } from './database/entities/user.entity';
import { PartnerEntity, PartnerStatus, PartnerType } from './database/entities/partner.entity';
import { PartnerUserEntity } from './database/entities/partner-user.entity';
import { PartnerBusinessEntity, BusinessStatus } from './database/entities/partner-business.entity';
import { RestaurantEntity } from './database/entities/restaurant.entity';
import { EventEntity } from './database/entities/event.entity';
import { ActivityEntity } from './database/entities/activity.entity';
import { HotelEntity } from './database/entities/hotel.entity';
import { SportsVenueEntity } from './database/entities/sports-venue.entity';

describe('Phase 23 — Real Data & Availability Integration Layer', () => {
  const TEST_JWT_SECRET = 'test_phase23_secret_key_2026';
  let jwtService: JwtService;
  let integrationsService: IntegrationsService;
  let providerRegistry: ProviderRegistryService;
  let adminIntegrationsController: AdminIntegrationsController;
  let partnersService: PartnersService;
  let partnersController: PartnersController;
  let partnerTenantGuard: PartnerTenantGuard;
  let jwtAuthGuard: JwtAuthGuard;
  let rolesGuard: RolesGuard;
  let reflector: Reflector;

  // In-memory repositories
  let mockMappings: IntegrationMappingEntity[] = [];
  let mockSyncRuns: IntegrationSyncRunEntity[] = [];
  let mockBookings: BookingEntity[] = [];
  let mockPartners: PartnerEntity[] = [];
  let mockPartnerUsers: PartnerUserEntity[] = [];
  let mockPartnerBusinesses: PartnerBusinessEntity[] = [];
  let mockRestaurants: RestaurantEntity[] = [];
  let mockEvents: EventEntity[] = [];
  let mockActivities: ActivityEntity[] = [];
  let mockHotels: HotelEntity[] = [];
  let mockSportsVenues: SportsVenueEntity[] = [];

  // Mock repos
  let mockMappingRepo: any;
  let mockSyncRunRepo: any;
  let mockBookingRepo: any;
  let mockPartnerRepo: any;
  let mockPartnerUserRepo: any;
  let mockPartnerBusinessRepo: any;
  let mockRestaurantRepo: any;
  let mockEventRepo: any;
  let mockActivityRepo: any;
  let mockHotelRepo: any;
  let mockSportsVenueRepo: any;

  // Adapters
  let partnerAdapter: PartnerIntegrationAdapter;
  let adminAdapter: AdminCuratedAdapter;
  let movieAdapter: MovieProviderAdapter;
  let diningAdapter: DiningProviderAdapter;
  let eventAdapter: EventProviderAdapter;
  let activityAdapter: ActivityProviderAdapter;
  let stayAdapter: StayProviderAdapter;
  let sportsAdapter: SportsProviderAdapter;
  let shoppingAdapter: ShoppingProviderAdapter;

  beforeEach(() => {
    jwtService = new JwtService({
      secret: TEST_JWT_SECRET,
      signOptions: { expiresIn: '1h' },
    });
    reflector = new Reflector();
    jwtAuthGuard = new JwtAuthGuard(jwtService);
    rolesGuard = new RolesGuard(reflector);

    mockMappings = [];
    mockSyncRuns = [];
    mockBookings = [];
    mockPartners = [];
    mockPartnerUsers = [];
    mockPartnerBusinesses = [];
    mockRestaurants = [];
    mockEvents = [];
    mockActivities = [];
    mockHotels = [];
    mockSportsVenues = [];

    mockMappingRepo = {
      findOne: jest.fn(async ({ where }: any) => {
        return mockMappings.find((m) => {
          if (where.id && m.id !== where.id) return false;
          if (where.provider && m.provider !== where.provider) return false;
          if (where.providerEntityId && m.providerEntityId !== where.providerEntityId) return false;
          if (where.plazaEntityId && m.plazaEntityId !== where.plazaEntityId) return false;
          return true;
        }) || null;
      }),
      create: jest.fn((dto: any) => ({ ...dto })),
      save: jest.fn(async (entity: any) => {
        const idx = mockMappings.findIndex((m) => m.id === entity.id);
        if (idx >= 0) {
          mockMappings[idx] = { ...mockMappings[idx], ...entity };
          return mockMappings[idx];
        }
        mockMappings.push(entity);
        return entity;
      }),
      createQueryBuilder: jest.fn(() => ({
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn(async () => [mockMappings, mockMappings.length]),
      })),
    };

    mockSyncRunRepo = {
      findOne: jest.fn(async ({ where }: any) => {
        return mockSyncRuns.find((r) => {
          if (where.provider && r.provider !== where.provider) return false;
          return true;
        }) || null;
      }),
      find: jest.fn(async () => [...mockSyncRuns]),
      create: jest.fn((dto: any) => ({ ...dto })),
      save: jest.fn(async (entity: any) => {
        const idx = mockSyncRuns.findIndex((r) => r.id === entity.id);
        if (idx >= 0) {
          mockSyncRuns[idx] = { ...mockSyncRuns[idx], ...entity };
          return mockSyncRuns[idx];
        }
        mockSyncRuns.push(entity);
        return entity;
      }),
      createQueryBuilder: jest.fn(() => ({
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn(async () => [mockSyncRuns, mockSyncRuns.length]),
      })),
    };

    mockBookingRepo = {
      findOne: jest.fn(async ({ where }: any) => {
        return mockBookings.find((b) => b.id === where.id) || null;
      }),
    };

    mockPartnerRepo = {
      findOne: jest.fn(async ({ where }: any) => {
        return mockPartners.find((p) => p.id === where.id) || null;
      }),
      save: jest.fn(async (p: any) => {
        const idx = mockPartners.findIndex((item) => item.id === p.id);
        if (idx >= 0) {
          mockPartners[idx] = { ...mockPartners[idx], ...p };
          return mockPartners[idx];
        }
        mockPartners.push(p);
        return p;
      }),
    };

    mockPartnerUserRepo = {
      findOne: jest.fn(async ({ where }: any) => {
        return mockPartnerUsers.find(
          (pu) =>
            pu.partnerId === where.partnerId &&
            pu.userId === where.userId &&
            (where.isActive === undefined || pu.isActive === where.isActive),
        ) || null;
      }),
      save: jest.fn(async (pu: any) => {
        mockPartnerUsers.push(pu);
        return pu;
      }),
    };

    mockPartnerBusinessRepo = {
      findOne: jest.fn(async ({ where }: any) => {
        return mockPartnerBusinesses.find(
          (b) => b.id === where.id && (!where.partnerId || b.partnerId === where.partnerId),
        ) || null;
      }),
      save: jest.fn(async (b: any) => {
        const idx = mockPartnerBusinesses.findIndex((item) => item.id === b.id);
        if (idx >= 0) {
          mockPartnerBusinesses[idx] = { ...mockPartnerBusinesses[idx], ...b };
          return mockPartnerBusinesses[idx];
        }
        mockPartnerBusinesses.push(b);
        return b;
      }),
    };

    mockRestaurantRepo = {
      update: jest.fn(async (id: string, partial: any) => {
        const r = mockRestaurants.find((item) => item.id === id);
        if (r) Object.assign(r, partial);
      }),
      save: jest.fn(async (r: any) => {
        mockRestaurants.push(r);
        return r;
      }),
      findOne: jest.fn(async ({ where }: any) => {
        return mockRestaurants.find((r) => r.id === where.id) || null;
      }),
    };

    mockEventRepo = {
      update: jest.fn(async (id: string, partial: any) => {
        const e = mockEvents.find((item) => item.id === id);
        if (e) Object.assign(e, partial);
      }),
      save: jest.fn(async (e: any) => {
        mockEvents.push(e);
        return e;
      }),
    };

    mockActivityRepo = {
      update: jest.fn(async (id: string, partial: any) => {
        const a = mockActivities.find((item) => item.id === id);
        if (a) Object.assign(a, partial);
      }),
      save: jest.fn(async (a: any) => {
        mockActivities.push(a);
        return a;
      }),
    };

    mockHotelRepo = {
      update: jest.fn(async (id: string, partial: any) => {
        const h = mockHotels.find((item) => item.id === id);
        if (h) Object.assign(h, partial);
      }),
      save: jest.fn(async (h: any) => {
        mockHotels.push(h);
        return h;
      }),
    };

    mockSportsVenueRepo = {
      update: jest.fn(async (id: string, partial: any) => {
        const s = mockSportsVenues.find((item) => item.id === id);
        if (s) Object.assign(s, partial);
      }),
      save: jest.fn(async (s: any) => {
        mockSportsVenues.push(s);
        return s;
      }),
    };

    // Instantiate adapters
    partnerAdapter = new PartnerIntegrationAdapter();
    adminAdapter = new AdminCuratedAdapter();
    movieAdapter = new MovieProviderAdapter();
    diningAdapter = new DiningProviderAdapter();
    eventAdapter = new EventProviderAdapter();
    activityAdapter = new ActivityProviderAdapter();
    stayAdapter = new StayProviderAdapter();
    sportsAdapter = new SportsProviderAdapter();
    shoppingAdapter = new ShoppingProviderAdapter();

    providerRegistry = new ProviderRegistryService(
      partnerAdapter,
      adminAdapter,
      movieAdapter,
      diningAdapter,
      eventAdapter,
      activityAdapter,
      stayAdapter,
      sportsAdapter,
      shoppingAdapter,
    );

    integrationsService = new IntegrationsService(
      mockMappingRepo,
      mockSyncRunRepo,
      mockBookingRepo,
      providerRegistry,
    );

    adminIntegrationsController = new AdminIntegrationsController(integrationsService);

    partnerTenantGuard = new PartnerTenantGuard(mockPartnerUserRepo);

    partnersService = new PartnersService(
      mockPartnerRepo,
      mockPartnerUserRepo,
      mockPartnerBusinessRepo,
      {} as any, // doc repo
      {} as any, // approval repo
      {} as any, // inv repo
      {} as any, // payout repo
      { create: jest.fn((dto) => dto), save: jest.fn() } as any, // audit repo
      {} as any, // user repo
      mockBookingRepo,
      mockRestaurantRepo,
      mockEventRepo,
      mockActivityRepo,
      mockHotelRepo,
      mockSportsVenueRepo,
    );

    partnersController = new PartnersController(partnersService);
  });

  // ----------------------------------------------------
  // PART 1: INTEGRATION CORE & PROVIDER REGISTRY
  // ----------------------------------------------------
  describe('1. Integration Core & Provider Registry', () => {
    it('should register all 9 vertical and internal provider adapters', () => {
      const adapters = providerRegistry.getAllAdapters();
      expect(adapters.length).toBe(9);
      expect(adapters.map((a) => a.providerId)).toEqual(
        expect.arrayContaining([
          'INTERNAL_PARTNER',
          'ADMIN_CURATED',
          'EXTERNAL_MOVIE_AGGREGATOR',
          'EXTERNAL_DINING_AGGREGATOR',
          'EXTERNAL_EVENT_TICKETING',
          'EXTERNAL_ACTIVITY_OPERATOR',
          'EXTERNAL_HOTEL_CHANNEL',
          'EXTERNAL_SPORTS_FACILITY',
          'EXTERNAL_RETAIL_ERP',
        ]),
      );
    });

    it('should truthfully report unconfigured and disabled status for external providers without credentials', () => {
      const summaries = providerRegistry.getProviderSummaries();
      const movieProvider = summaries.find((p) => p.providerId === 'EXTERNAL_MOVIE_AGGREGATOR');
      expect(movieProvider).toBeDefined();
      expect(movieProvider?.isConfigured).toBe(false);
      expect(movieProvider?.isEnabled).toBe(false);
      expect(movieProvider?.status).toBe(IntegrationStatus.DISABLED);

      const internalPartner = summaries.find((p) => p.providerId === 'INTERNAL_PARTNER');
      expect(internalPartner?.isConfigured).toBe(true);
      expect(internalPartner?.isEnabled).toBe(true);
      expect(internalPartner?.status).toBe(IntegrationStatus.ACTIVE);
    });

    it('should never expose API keys or secrets in provider summaries or health checks', async () => {
      const health = await integrationsService.getHealth();
      expect(health.status).toBe('HEALTHY');
      expect(JSON.stringify(health)).not.toContain('API_KEY');
      expect(JSON.stringify(health)).not.toContain('SECRET');
      expect(JSON.stringify(health)).not.toContain('password');
    });

    it('should enforce mapping idempotency and prevent duplicate mappings for the same external ID', async () => {
      const m1 = await integrationsService.createOrUpdateMapping({
        provider: 'EXTERNAL_HOTEL_CHANNEL',
        providerEntityId: 'ext_hotel_taj_101',
        plazaEntityId: 'stay_taj_falaknuma',
        vertical: 'stay',
      });

      expect(mockMappings.length).toBe(1);
      expect(m1.plazaEntityId).toBe('stay_taj_falaknuma');

      // Update mapping with new metadata
      const m2 = await integrationsService.createOrUpdateMapping({
        provider: 'EXTERNAL_HOTEL_CHANNEL',
        providerEntityId: 'ext_hotel_taj_101',
        plazaEntityId: 'stay_taj_falaknuma',
        vertical: 'stay',
        metadata: { roomTypesCount: 5 },
      });

      // Still 1 mapping in DB, updated idempotently
      expect(mockMappings.length).toBe(1);
      expect(m2.metadata?.roomTypesCount).toBe(5);
    });
  });

  // ----------------------------------------------------
  // PART 2: TRUTHFUL AVAILABILITY & FRESHNESS LIFECYCLE
  // ----------------------------------------------------
  describe('2. Truthful Availability & Freshness Lifecycle', () => {
    it('should evaluate availability as UNKNOWN when provider is disabled or unconfigured', async () => {
      const availability = await integrationsService.evaluateAvailability(
        'EXTERNAL_MOVIE_AGGREGATOR',
        'ext_show_999',
      );
      expect(availability.status).toBe(AvailabilityStatus.UNKNOWN);
      expect(availability.freshness).toBe(AvailabilityFreshness.UNKNOWN);
      expect(availability.source).toBe(IntegrationProviderType.EXTERNAL);
    });

    it('should calculate freshness accurately based on timestamp age and TTL', () => {
      const freshTimestamp = new Date(Date.now() - 3 * 60 * 1000); // 3 minutes ago
      expect(integrationsService.calculateFreshness(freshTimestamp, 15)).toBe(
        AvailabilityFreshness.FRESH,
      );

      const staleTimestamp = new Date(Date.now() - 30 * 60 * 1000); // 30 minutes ago
      expect(integrationsService.calculateFreshness(staleTimestamp, 15)).toBe(
        AvailabilityFreshness.STALE,
      );

      expect(integrationsService.calculateFreshness(null)).toBe(AvailabilityFreshness.UNKNOWN);
      expect(integrationsService.calculateFreshness('invalid-date')).toBe(
        AvailabilityFreshness.UNKNOWN,
      );
    });

    it('should normalize shopping stock into truthful availability states (AVAILABLE, LIMITED, SOLD_OUT)', () => {
      const inStockAmple = shoppingAdapter.normalizeStock({
        productId: 'p_1',
        sku: 'SKU_1',
        currentStock: 25,
        inStock: true,
        price: 999,
      });
      expect(inStockAmple.availabilityStatus).toBe(AvailabilityStatus.AVAILABLE);

      const inStockLimited = shoppingAdapter.normalizeStock({
        productId: 'p_2',
        sku: 'SKU_2',
        currentStock: 3,
        inStock: true,
        price: 999,
      });
      expect(inStockLimited.availabilityStatus).toBe(AvailabilityStatus.LIMITED);

      const outOfStock = shoppingAdapter.normalizeStock({
        productId: 'p_3',
        sku: 'SKU_3',
        currentStock: 0,
        inStock: false,
        price: 999,
      });
      expect(outOfStock.availabilityStatus).toBe(AvailabilityStatus.SOLD_OUT);
    });
  });

  // ----------------------------------------------------
  // PART 3: SYNCHRONIZATION EXECUTION & CONCURRENCY
  // ----------------------------------------------------
  describe('3. Synchronization Execution & Concurrency', () => {
    it('should prevent concurrent sync runs for the same provider via activeSyncLocks', async () => {
      // Mock an adapter that takes time
      jest.spyOn(adminAdapter, 'sync').mockImplementation(
        () => new Promise((resolve) => setTimeout(() => resolve({
          recordsRead: 5,
          recordsCreated: 0,
          recordsUpdated: 5,
          recordsSkipped: 0,
          recordsFailed: 0,
        }), 50)),
      );

      const firstSyncPromise = integrationsService.triggerSync('ADMIN_CURATED');
      await expect(
        integrationsService.triggerSync('ADMIN_CURATED'),
      ).rejects.toThrow(ConflictException);

      const firstResult = await firstSyncPromise;
      expect(firstResult.status).toBe(SyncRunStatus.SUCCESS);
      expect(firstResult.recordsUpdated).toBe(5);
    });

    it('should record partial failures and log error summary without throwing fatal server crash', async () => {
      jest.spyOn(diningAdapter, 'sync').mockResolvedValueOnce({
        recordsRead: 10,
        recordsCreated: 8,
        recordsUpdated: 0,
        recordsSkipped: 0,
        recordsFailed: 2,
        errorSummary: '2 restaurants timed out during POS handshake',
      });

      const run = await integrationsService.triggerSync('EXTERNAL_DINING_AGGREGATOR');
      expect(run.status).toBe(SyncRunStatus.PARTIAL);
      expect(run.recordsCreated).toBe(8);
      expect(run.recordsFailed).toBe(2);
      expect(run.errorSummary).toContain('POS handshake');
    });
  });

  // ----------------------------------------------------
  // PART 4: PARTNER OPERATIONAL AVAILABILITY & ISOLATION
  // ----------------------------------------------------
  describe('4. Partner Operational Availability & Tenant Isolation', () => {
    beforeEach(async () => {
      mockPartners.push({
        id: 'prt_olive_101',
        legalName: 'Olive Hospitality Ltd',
        displayName: 'Olive Bistro',
        partnerType: PartnerType.RESTAURANT,
        status: PartnerStatus.APPROVED,
      } as any);

      mockPartnerBusinesses.push({
        id: 'pb_olive_dining',
        partnerId: 'prt_olive_101',
        vertical: 'dining',
        name: 'Olive Bistro Jubilee Hills',
        status: BusinessStatus.APPROVED,
        catalogEntityId: 'rest_olive_cat_1',
      } as any);

      mockRestaurants.push({
        id: 'rest_olive_cat_1',
        name: 'Olive Bistro Jubilee Hills',
        partnerId: 'prt_olive_101',
        businessId: 'pb_olive_dining',
        availabilityStatus: 'AVAILABLE',
        availableSlots: [],
      } as any);

      mockPartnerUsers.push({
        id: 'pu_olive_owner',
        partnerId: 'prt_olive_101',
        userId: 'usr_olive_owner',
        role: UserRole.PARTNER_OWNER,
        isActive: true,
      } as any);
    });

    it('should allow partner owner to update operational slots and availability status', async () => {
      const newSlots = [
        { time: '07:00 PM', tablesLeft: 4, status: 'AVAILABLE' },
        { time: '08:30 PM', tablesLeft: 1, status: 'LIMITED' },
      ];

      const res = await partnersService.updateBusinessAvailability(
        'prt_olive_101',
        'pb_olive_dining',
        { availabilityStatus: AvailabilityStatus.LIMITED, slotsOrTiers: newSlots },
        { sub: 'usr_olive_owner', role: UserRole.PARTNER_OWNER },
      );

      expect(res.success).toBe(true);
      expect(res.availabilityStatus).toBe(AvailabilityStatus.LIMITED);

      // Verify canonical catalog entity was updated
      expect(mockRestaurantRepo.update).toHaveBeenCalledWith(
        'rest_olive_cat_1',
        expect.objectContaining({
          availabilityStatus: AvailabilityStatus.LIMITED,
          source: 'PARTNER',
          availableSlots: newSlots,
        }),
      );
    });

    it('should throw NotFoundException if partner tries to update availability for another partner business', async () => {
      await expect(
        partnersService.updateBusinessAvailability(
          'prt_different_org',
          'pb_olive_dining',
          { availabilityStatus: AvailabilityStatus.AVAILABLE },
          { sub: 'usr_hacker' },
        ),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ----------------------------------------------------
  // PART 5: BOOKING SAFETY & RECONCILIATION GUARD
  // ----------------------------------------------------
  describe('5. Booking Safety & Reconciliation Guard', () => {
    it('should protect confirmed, upcoming, and active customer bookings from external sync overwrite', async () => {
      mockBookings.push({
        id: 'bk_confirmed_customer_1',
        userId: 'usr_customer_1',
        type: BookingType.STAY,
        status: BookingStatus.CONFIRMED,
        title: 'Taj Falaknuma Palace',
        totalPrice: 15000,
        partnerId: 'prt_taj_hotels',
      } as any);

      const check = await integrationsService.verifyBookingIntegrity('bk_confirmed_customer_1');
      expect(check.isProtected).toBe(true);
      expect(check.status).toBe(BookingStatus.CONFIRMED);
    });

    it('should throw NotFoundException for nonexistent booking verification', async () => {
      await expect(
        integrationsService.verifyBookingIntegrity('bk_nonexistent'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ----------------------------------------------------
  // PART 6: SECURITY & RBAC CONTROLS
  // ----------------------------------------------------
  describe('6. Security & RBAC Controls', () => {
    it('should block unauthenticated requests (JwtAuthGuard)', () => {
      const mockContext = {
        switchToHttp: () => ({
          getRequest: () => ({ headers: {} }),
        }),
      } as any;
      expect(() => jwtAuthGuard.canActivate(mockContext)).toThrow(UnauthorizedException);
    });

    it('should block normal USER from accessing admin integrations endpoints (RolesGuard)', () => {
      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([
        UserRole.ADMIN,
        UserRole.SUPER_ADMIN,
        UserRole.OPERATOR,
      ]);

      const mockContext = {
        getHandler: () => {},
        getClass: () => {},
        switchToHttp: () => ({
          getRequest: () => ({
            user: { sub: 'usr_normal', role: UserRole.USER },
          }),
        }),
      } as any;

      expect(() => rolesGuard.canActivate(mockContext)).toThrow(ForbiddenException);
    });

    it('should allow ADMIN and OPERATOR to access admin integration endpoints', () => {
      jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue([
        UserRole.ADMIN,
        UserRole.SUPER_ADMIN,
        UserRole.OPERATOR,
      ]);

      const mockContextAdmin = {
        getHandler: () => {},
        getClass: () => {},
        switchToHttp: () => ({
          getRequest: () => ({
            user: { sub: 'usr_admin', role: UserRole.ADMIN },
          }),
        }),
      } as any;

      expect(rolesGuard.canActivate(mockContextAdmin)).toBe(true);

      const mockContextOperator = {
        getHandler: () => {},
        getClass: () => {},
        switchToHttp: () => ({
          getRequest: () => ({
            user: { sub: 'usr_op', role: UserRole.OPERATOR },
          }),
        }),
      } as any;

      expect(rolesGuard.canActivate(mockContextOperator)).toBe(true);
    });
  });

  describe('IntegrationsModule NestJS Dependency Resolution', () => {
    it('should successfully compile IntegrationsModule with AuthModule providing JwtService to JwtAuthGuard', async () => {
      const moduleRef = await Test.createTestingModule({
        imports: [IntegrationsModule],
      })
        .overrideProvider(getRepositoryToken(IntegrationMappingEntity))
        .useValue(mockMappingRepo)
        .overrideProvider(getRepositoryToken(IntegrationSyncRunEntity))
        .useValue(mockSyncRunRepo)
        .overrideProvider(getRepositoryToken(BookingEntity))
        .useValue(mockBookingRepo)
        .overrideProvider(getRepositoryToken(User))
        .useValue(mockPartnerUserRepo)
        .compile();

      expect(moduleRef).toBeDefined();
      const controller = moduleRef.get<AdminIntegrationsController>(AdminIntegrationsController);
      expect(controller).toBeDefined();
      const jwtGuard = moduleRef.get<JwtAuthGuard>(JwtAuthGuard);
      expect(jwtGuard).toBeDefined();
      const jwtServiceResolved = moduleRef.get<JwtService>(JwtService);
      expect(jwtServiceResolved).toBeDefined();
    });
  });
});
