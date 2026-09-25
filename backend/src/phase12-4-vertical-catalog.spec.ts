import {
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';

import { AdminController } from './modules/admin/admin.controller';
import { AdminService } from './modules/admin/admin.service';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from './modules/auth/guards/roles.guard';
import { User, UserRole } from './database/entities/user.entity';
import { MovieEntity } from './database/entities/movie.entity';
import { TheatreEntity } from './database/entities/theatre.entity';
import { ScreenEntity } from './database/entities/screen.entity';
import { ShowEntity } from './database/entities/show.entity';
import { RestaurantEntity } from './database/entities/restaurant.entity';
import { EventEntity } from './database/entities/event.entity';
import { ActivityEntity } from './database/entities/activity.entity';
import { ProductEntity } from './database/entities/product.entity';
import { HotelEntity } from './database/entities/hotel.entity';
import { SportsVenueEntity } from './database/entities/sports-venue.entity';
import { AuditLogEntity } from './database/entities/audit-log.entity';

import { DiningService } from './modules/dining/dining.service';
import { EventsService } from './modules/events/events.service';
import { ActivitiesService } from './modules/activities/activities.service';
import { ShoppingService } from './modules/shopping/shopping.service';
import { StaysService } from './modules/stays/stays.service';
import { SportsService } from './modules/sports/sports.service';
import { MoviesService } from './modules/movies/movies.service';
import { SearchService } from './modules/search/search.service';

import {
  CreateDiningDto,
  UpdateDiningDto,
  CreateEventDto,
  UpdateEventDto,
  CreateActivityDto,
  UpdateActivityDto,
  CreateProductDto,
  UpdateProductDto,
  CreateHotelDto,
  UpdateHotelDto,
  CreateSportsVenueDto,
  UpdateSportsVenueDto,
} from './modules/admin/dto/vertical-catalog.dto';

describe('Phase 12.4 — All-Vertical Admin Catalog Management & Publish/Unpublish Lifecycle', () => {
  const TEST_JWT_SECRET = 'test_phase12_4_secret_key_2026';
  let jwtService: JwtService;
  let adminService: AdminService;
  let adminController: AdminController;

  let diningService: DiningService;
  let eventsService: EventsService;
  let activitiesService: ActivitiesService;
  let shoppingService: ShoppingService;
  let staysService: StaysService;
  let sportsService: SportsService;
  let moviesService: MoviesService;
  let searchService: SearchService;

  let jwtAuthGuard: JwtAuthGuard;
  let rolesGuard: RolesGuard;
  let reflector: Reflector;

  // In-memory repositories storage
  let mockRestaurants: RestaurantEntity[] = [];
  let mockEvents: EventEntity[] = [];
  let mockActivities: ActivityEntity[] = [];
  let mockProducts: ProductEntity[] = [];
  let mockHotels: HotelEntity[] = [];
  let mockSportsVenues: SportsVenueEntity[] = [];
  let mockAuditLogs: AuditLogEntity[] = [];

  const createMockRepo = (list: any[]) => ({
    count: jest.fn().mockImplementation(async () => list.length),
    find: jest.fn().mockImplementation(async (opts?: any) => {
      let res = [...list];
      if (opts?.where?.isPublished !== undefined) {
        res = res.filter((item) => item.isPublished === opts.where.isPublished);
      }
      if (opts?.where?.category) {
        res = res.filter((item) => item.category === opts.where.category);
      }
      const take = opts?.take || res.length;
      const skip = opts?.skip || 0;
      return res.slice(skip, skip + take);
    }),
    findOne: jest.fn().mockImplementation(async ({ where }: any) => {
      return (
        list.find((item) => {
          if (where.id && item.id !== where.id) return false;
          if (where.isPublished !== undefined && item.isPublished !== where.isPublished)
            return false;
          return true;
        }) || null
      );
    }),
    create: jest.fn().mockImplementation((dto) => ({ ...dto })),
    save: jest.fn().mockImplementation(async (entity) => {
      const idx = list.findIndex((item) => item.id === entity.id);
      if (idx >= 0) {
        list[idx] = { ...list[idx], ...entity };
      } else {
        list.push(entity);
      }
      return entity;
    }),
    delete: jest.fn().mockImplementation(async (id: string) => {
      const idx = list.findIndex((item) => item.id === id);
      if (idx >= 0) {
        list.splice(idx, 1);
      }
      return { affected: 1 };
    }),
  });

  beforeEach(() => {
    jwtService = new JwtService({
      secret: TEST_JWT_SECRET,
      signOptions: { expiresIn: '1h' },
    });

    mockRestaurants = [
      {
        id: 'din_existing_1',
        name: 'Jewel of Nizam',
        tagline: 'Royal Fine Dining',
        about: 'Authentic Hyderabadi flavours',
        coverImageUrl: 'https://images.unsplash.com/dining.jpg',
        galleryImages: [],
        rating: 4.8,
        reviewCount: 300,
        cuisines: ['Nizami', 'Hyderabadi'],
        priceForTwo: 2500,
        location: 'Gandipet, Hyderabad',
        distance: '8.2 km',
        openingHours: '12:30 PM - 11:30 PM',
        isPureVeg: false,
        hasOutdoor: true,
        isOpenNow: true,
        isPublished: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as RestaurantEntity,
    ];

    mockEvents = [
      {
        id: 'evt_existing_1',
        title: 'Sunburn Arena ft. Alan Walker',
        tagline: 'Walkerworld Tour',
        description: 'Electronic dance music extravaganza',
        category: 'Music Festivals',
        posterUrl: 'https://images.unsplash.com/event.jpg',
        bannerUrl: 'https://images.unsplash.com/event_b.jpg',
        eventDate: '2026-10-18',
        time: '5:00 PM',
        venue: 'GMR Arena',
        location: 'Shamshabad, Hyderabad',
        distance: '18.4 km',
        rating: 4.9,
        interestedCount: 15000,
        ageRestriction: '16+',
        languages: 'English',
        isPublished: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as EventEntity,
    ];

    mockActivities = [
      {
        id: 'act_existing_1',
        title: 'Pitstop Go-Karting Championship',
        tagline: 'High-speed professional track',
        description: 'Asphalt track racing experience',
        category: 'Motorsports',
        coverImageUrl: 'https://images.unsplash.com/karting.jpg',
        galleryImages: [],
        rating: 4.7,
        reviewCount: 220,
        location: 'Necklace Road, Hyderabad',
        distance: '4.1 km',
        highlights: ['900m Track'],
        safetyGuidelines: ['Helmets required'],
        isPublished: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as ActivityEntity,
    ];

    mockProducts = [
      {
        id: 'prod_existing_1',
        name: 'Handwoven Chanderi Sari',
        brand: 'Raw Mango',
        category: 'Luxury Apparel',
        price: 48500,
        rating: 4.9,
        reviewCount: 45,
        coverImageUrl: 'https://images.unsplash.com/sari.jpg',
        galleryImages: [],
        description: 'Handwoven pure silk sari',
        storeId: 'store_01',
        storeName: 'Banjara Hills Boutique',
        storeLocation: 'Road No. 10, Banjara Hills',
        distance: '3.4 km',
        inStock: true,
        isPublished: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as ProductEntity,
    ];

    mockHotels = [
      {
        id: 'htl_existing_1',
        name: 'Taj Falaknuma Palace',
        tagline: 'Mirror of the Sky',
        category: 'Heritage Palace',
        startingPricePerNight: 45000,
        rating: 4.9,
        reviewCount: 1200,
        coverImageUrl: 'https://images.unsplash.com/palace.jpg',
        galleryImages: [],
        description: 'Historic palace hotel',
        location: 'Engine Bowli, Falaknuma, Hyderabad',
        distance: '14.5 km',
        amenities: ['Pool', 'Spa'],
        isPublished: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as HotelEntity,
    ];

    mockSportsVenues = [
      {
        id: 'spt_existing_1',
        name: 'Gamepoint Gachibowli',
        supportedSports: ['Badminton', 'Box Cricket'],
        coverImageUrl: 'https://images.unsplash.com/sports.jpg',
        galleryImages: [],
        rating: 4.8,
        reviewCount: 510,
        location: 'Near Bio-Diversity Park, Gachibowli',
        distance: '3.1 km',
        amenities: ['Floodlights'],
        startingPricePerHour: 400,
        isPublished: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as SportsVenueEntity,
    ];

    mockAuditLogs = [];

    const mockRestaurantRepo = createMockRepo(mockRestaurants);
    const mockEventRepo = createMockRepo(mockEvents);
    const mockActivityRepo = createMockRepo(mockActivities);
    const mockProductRepo = createMockRepo(mockProducts);
    const mockHotelRepo = createMockRepo(mockHotels);
    const mockSportsVenueRepo = createMockRepo(mockSportsVenues);

    const mockUserRepo: any = { count: jest.fn().mockResolvedValue(10) };
    const mockMovieRepo: any = {
      count: jest.fn().mockResolvedValue(1),
      find: jest.fn().mockResolvedValue([
        { id: 'mov_1', title: 'Kalki 2898 AD', director: 'Nag Ashwin', genres: ['Action'] },
      ]),
    };
    const mockTheatreRepo: any = { count: jest.fn().mockResolvedValue(1) };
    const mockBookingRepo: any = { count: jest.fn().mockResolvedValue(42) };
    const mockScreenRepo: any = { count: jest.fn().mockResolvedValue(5) };
    const mockShowRepo: any = { count: jest.fn().mockResolvedValue(8) };
    const mockAuditLogRepo: any = {
      save: jest.fn().mockImplementation(async (log) => {
        mockAuditLogs.push(log);
        return log;
      }),
      find: jest.fn().mockImplementation(async () => mockAuditLogs),
    };

    adminService = new AdminService(
      mockUserRepo as any,
      mockMovieRepo as any,
      mockTheatreRepo as any,
      mockRestaurantRepo as any,
      mockEventRepo as any,
      mockActivityRepo as any,
      mockProductRepo as any,
      mockHotelRepo as any,
      mockSportsVenueRepo as any,
      mockBookingRepo as any,
      mockAuditLogRepo as any,
      mockScreenRepo as any,
      mockShowRepo as any,
    );

    adminController = new AdminController(adminService);

    diningService = new DiningService(mockRestaurantRepo as any);
    eventsService = new EventsService(mockEventRepo as any);
    activitiesService = new ActivitiesService(mockActivityRepo as any);
    shoppingService = new ShoppingService(mockProductRepo as any);
    staysService = new StaysService(mockHotelRepo as any);
    sportsService = new SportsService(mockSportsVenueRepo as any);
    moviesService = new MoviesService(
      mockMovieRepo,
      mockTheatreRepo,
      mockScreenRepo,
      mockShowRepo,
    );
    searchService = new SearchService(
      moviesService,
      diningService,
      eventsService,
      activitiesService,
      shoppingService,
      staysService,
      sportsService,
    );

    jwtAuthGuard = new JwtAuthGuard(jwtService);
    reflector = new Reflector();
    rolesGuard = new RolesGuard(reflector);
  });

  const getAdminToken = () =>
    jwtService.sign({
      sub: 'usr_admin_1',
      email: 'admin@plaza.app',
      name: 'PLAZA Admin',
      role: UserRole.ADMIN,
    });

  const getUserToken = () =>
    jwtService.sign({
      sub: 'usr_normal_1',
      email: 'user@plaza.app',
      name: 'Normal User',
      role: UserRole.USER,
    });

  const executePipeline = async (
    handler: (...args: any[]) => any,
    headers: Record<string, string>,
    action: () => Promise<any> | any,
  ) => {
    const req: any = { headers };
    const context = {
      switchToHttp: () => ({
        getRequest: () => req,
      }),
      getHandler: () => handler,
      getClass: () => AdminController,
    } as unknown as ExecutionContext;

    jwtAuthGuard.canActivate(context);
    rolesGuard.canActivate(context);
    return action();
  };

  const adminActor = { user: { id: 'usr_admin_1', email: 'admin@plaza.app' } };

  // ========================================================
  // 1. DINING MANAGEMENT & PUBLICATION LIFECYCLE
  // ========================================================
  describe('1. Dining Management & Lifecycle', () => {
    it('should create, read, update, unpublish, publish and delete a restaurant', async () => {
      // CREATE
      const createDto: CreateDiningDto = {
        name: 'Olive Bistro',
        tagline: 'Rustic Mediterranean Elegance',
        about: 'Perched overlooking the secret lake...',
        coverImageUrl: 'https://images.unsplash.com/olive.jpg',
        cuisines: ['Mediterranean', 'Italian'],
        priceForTwo: 2200,
        location: 'Jubilee Hills, Hyderabad',
      };

      const created = await executePipeline(
        AdminController.prototype.createDining,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.createDining(createDto, adminActor),
      );

      expect(created.id).toBeDefined();
      expect(created.name).toBe('Olive Bistro');
      expect(created.isPublished).toBe(true);
      expect(mockRestaurants.length).toBe(2);
      expect(mockAuditLogs.some((l) => l.action === 'CREATE_DINING')).toBe(true);

      // GET ALL
      const list = await adminController.getDining({ limit: 10, offset: 0 });
      expect(list.length).toBe(2);

      // GET BY ID
      const single = await adminController.getDiningById(created.id);
      expect(single.name).toBe('Olive Bistro');

      // UPDATE
      const updated = await executePipeline(
        AdminController.prototype.updateDining,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.updateDining(created.id, { priceForTwo: 2400 }, adminActor),
      );
      expect(updated.priceForTwo).toBe(2400);
      expect(mockAuditLogs.some((l) => l.action === 'UPDATE_DINING')).toBe(true);

      // UNPUBLISH
      const unpublished = await executePipeline(
        AdminController.prototype.unpublishDining,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.unpublishDining(created.id, adminActor),
      );
      expect(unpublished.isPublished).toBe(false);
      expect(mockAuditLogs.some((l) => l.action === 'UNPUBLISH_DINING')).toBe(true);

      // Consumer should now ONLY see 1 restaurant (the published one)
      const consumerList = await diningService.findAll();
      expect(consumerList.length).toBe(1);
      expect(consumerList.find((r) => r.id === created.id)).toBeUndefined();

      // RE-PUBLISH
      const republished = await executePipeline(
        AdminController.prototype.publishDining,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.publishDining(created.id, adminActor),
      );
      expect(republished.isPublished).toBe(true);
      expect(mockAuditLogs.some((l) => l.action === 'PUBLISH_DINING')).toBe(true);

      // Consumer can see it again
      const consumerListAfter = await diningService.findAll();
      expect(consumerListAfter.length).toBe(2);

      // DELETE
      const del = await executePipeline(
        AdminController.prototype.deleteDining,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.deleteDining(created.id, adminActor),
      );
      expect(del.success).toBe(true);
      expect(mockRestaurants.length).toBe(1);
      expect(mockAuditLogs.some((l) => l.action === 'DELETE_DINING')).toBe(true);
    });
  });

  // ========================================================
  // 2. EVENTS MANAGEMENT & PUBLICATION LIFECYCLE
  // ========================================================
  describe('2. Events Management & Lifecycle', () => {
    it('should create, update, unpublish, publish and delete an event', async () => {
      const createDto: CreateEventDto = {
        title: 'Coldplay: Music of the Spheres Tour',
        tagline: 'Live in Hyderabad',
        description: 'Global stadium concert',
        category: 'Concerts',
        posterUrl: 'https://images.unsplash.com/coldplay.jpg',
        bannerUrl: 'https://images.unsplash.com/coldplay_b.jpg',
        eventDate: '2026-11-20',
        time: '6:00 PM',
        venue: 'GMC Balayogi Stadium',
        location: 'Gachibowli, Hyderabad',
      };

      const created = await executePipeline(
        AdminController.prototype.createEvent,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.createEvent(createDto, adminActor),
      );

      expect(created.title).toBe('Coldplay: Music of the Spheres Tour');
      expect(created.isPublished).toBe(true);
      expect(mockAuditLogs.some((l) => l.action === 'CREATE_EVENT')).toBe(true);

      // UPDATE
      await adminController.updateEvent(created.id, { tagline: 'Updated Tour Tagline' }, adminActor);
      expect(mockAuditLogs.some((l) => l.action === 'UPDATE_EVENT')).toBe(true);

      // UNPUBLISH
      await adminController.unpublishEvent(created.id, adminActor);
      expect(mockAuditLogs.some((l) => l.action === 'UNPUBLISH_EVENT')).toBe(true);

      // Consumer should not see unpublished event
      const consumerEvents = await eventsService.findAll();
      expect(consumerEvents.find((e) => e.id === created.id)).toBeUndefined();

      // PUBLISH
      await adminController.publishEvent(created.id, adminActor);
      expect(mockAuditLogs.some((l) => l.action === 'PUBLISH_EVENT')).toBe(true);

      // DELETE
      await adminController.deleteEvent(created.id, adminActor);
      expect(mockAuditLogs.some((l) => l.action === 'DELETE_EVENT')).toBe(true);
    });
  });

  // ========================================================
  // 3. ACTIVITIES MANAGEMENT & PUBLICATION LIFECYCLE
  // ========================================================
  describe('3. Activities Management & Lifecycle', () => {
    it('should create, update, unpublish, publish and delete an activity', async () => {
      const createDto: CreateActivityDto = {
        title: 'Himalayan Rock Climbing Wall',
        tagline: 'Scale new heights',
        description: 'Indoor adventure climbing wall',
        category: 'Adventure',
        coverImageUrl: 'https://images.unsplash.com/climbing.jpg',
        location: 'Financial District, Hyderabad',
      };

      const created = await executePipeline(
        AdminController.prototype.createActivity,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.createActivity(createDto, adminActor),
      );

      expect(created.title).toBe('Himalayan Rock Climbing Wall');
      expect(created.isPublished).toBe(true);
      expect(mockAuditLogs.some((l) => l.action === 'CREATE_ACTIVITY')).toBe(true);

      // UNPUBLISH & verify consumer hiding
      await adminController.unpublishActivity(created.id, adminActor);
      const consumerActs = await activitiesService.findAll();
      expect(consumerActs.find((a) => a.id === created.id)).toBeUndefined();

      // PUBLISH
      await adminController.publishActivity(created.id, adminActor);
      const consumerActs2 = await activitiesService.findAll();
      expect(consumerActs2.find((a) => a.id === created.id)).toBeDefined();

      // DELETE
      await adminController.deleteActivity(created.id, adminActor);
      expect(mockAuditLogs.some((l) => l.action === 'DELETE_ACTIVITY')).toBe(true);
    });
  });

  // ========================================================
  // 4. SHOPPING MANAGEMENT & PUBLICATION LIFECYCLE
  // ========================================================
  describe('4. Shopping Management & Lifecycle', () => {
    it('should create, update, unpublish, publish and delete a product', async () => {
      const createDto: CreateProductDto = {
        name: 'Sabyasachi Heritage Belt',
        brand: 'Sabyasachi',
        category: 'Accessories',
        price: 24500,
        coverImageUrl: 'https://images.unsplash.com/belt.jpg',
        description: 'Signature Royal Bengal Tiger buckle',
        storeId: 'store_sabya_01',
        storeName: 'Sabyasachi Flagship',
        storeLocation: 'Banjara Hills',
      };

      const created = await executePipeline(
        AdminController.prototype.createProduct,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.createProduct(createDto, adminActor),
      );

      expect(created.name).toBe('Sabyasachi Heritage Belt');
      expect(created.isPublished).toBe(true);
      expect(mockAuditLogs.some((l) => l.action === 'CREATE_PRODUCT')).toBe(true);

      // UNPUBLISH
      await adminController.unpublishProduct(created.id, adminActor);
      const consumerProducts = await shoppingService.findAll();
      expect(consumerProducts.find((p) => p.id === created.id)).toBeUndefined();

      // PUBLISH
      await adminController.publishProduct(created.id, adminActor);
      const consumerProducts2 = await shoppingService.findAll();
      expect(consumerProducts2.find((p) => p.id === created.id)).toBeDefined();

      // DELETE
      await adminController.deleteProduct(created.id, adminActor);
      expect(mockAuditLogs.some((l) => l.action === 'DELETE_PRODUCT')).toBe(true);
    });
  });

  // ========================================================
  // 5. STAYS MANAGEMENT & PUBLICATION LIFECYCLE
  // ========================================================
  describe('5. Stays Management & Lifecycle', () => {
    it('should create, update, unpublish, publish and delete a hotel', async () => {
      const createDto: CreateHotelDto = {
        name: 'ITC Kohenur',
        tagline: 'A Luxury Collection Hotel',
        category: 'Luxury Hotel',
        startingPricePerNight: 18500,
        coverImageUrl: 'https://images.unsplash.com/kohenur.jpg',
        description: 'Modern luxury overlooking Durgam Cheruvu',
        location: 'HITEC City, Hyderabad',
      };

      const created = await executePipeline(
        AdminController.prototype.createHotel,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.createHotel(createDto, adminActor),
      );

      expect(created.name).toBe('ITC Kohenur');
      expect(created.isPublished).toBe(true);
      expect(mockAuditLogs.some((l) => l.action === 'CREATE_HOTEL')).toBe(true);

      // UNPUBLISH
      await adminController.unpublishHotel(created.id, adminActor);
      const consumerHotels = await staysService.findAll();
      expect(consumerHotels.find((h) => h.id === created.id)).toBeUndefined();

      // PUBLISH
      await adminController.publishHotel(created.id, adminActor);
      const consumerHotels2 = await staysService.findAll();
      expect(consumerHotels2.find((h) => h.id === created.id)).toBeDefined();

      // DELETE
      await adminController.deleteHotel(created.id, adminActor);
      expect(mockAuditLogs.some((l) => l.action === 'DELETE_HOTEL')).toBe(true);
    });
  });

  // ========================================================
  // 6. SPORTS MANAGEMENT & PUBLICATION LIFECYCLE
  // ========================================================
  describe('6. Sports Management & Lifecycle', () => {
    it('should create, update, unpublish, publish and delete a sports venue', async () => {
      const createDto: CreateSportsVenueDto = {
        name: 'Pullela Gopichand Badminton Academy',
        supportedSports: ['Badminton', 'Fitness'],
        coverImageUrl: 'https://images.unsplash.com/badminton.jpg',
        location: 'Gachibowli, Hyderabad',
        startingPricePerHour: 600,
      };

      const created = await executePipeline(
        AdminController.prototype.createSportsVenue,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.createSportsVenue(createDto, adminActor),
      );

      expect(created.name).toBe('Pullela Gopichand Badminton Academy');
      expect(created.isPublished).toBe(true);
      expect(mockAuditLogs.some((l) => l.action === 'CREATE_SPORTS_VENUE')).toBe(true);

      // UNPUBLISH
      await adminController.unpublishSportsVenue(created.id, adminActor);
      const consumerVenues = await sportsService.findAll();
      expect(consumerVenues.find((v) => v.id === created.id)).toBeUndefined();

      // PUBLISH
      await adminController.publishSportsVenue(created.id, adminActor);
      const consumerVenues2 = await sportsService.findAll();
      expect(consumerVenues2.find((v) => v.id === created.id)).toBeDefined();

      // DELETE
      await adminController.deleteSportsVenue(created.id, adminActor);
      expect(mockAuditLogs.some((l) => l.action === 'DELETE_SPORTS_VENUE')).toBe(true);
    });
  });

  // ========================================================
  // 7. UNIFIED SEARCH & PUBLICATION FILTERING
  // ========================================================
  describe('7. Unified Search Respects Publication Lifecycle', () => {
    it('should exclude unpublished items across all verticals from search results', async () => {
      // Initially, Jewel of Nizam is published
      let searchRes = await searchService.searchAll('nizam');
      expect(searchRes.dining.length).toBe(1);

      // Admin unpublishes Jewel of Nizam
      await adminService.unpublishDining('din_existing_1', adminActor.user);

      // Search should no longer return it
      searchRes = await searchService.searchAll('nizam');
      expect(searchRes.dining.length).toBe(0);

      // Re-publish
      await adminService.publishDining('din_existing_1', adminActor.user);
      searchRes = await searchService.searchAll('nizam');
      expect(searchRes.dining.length).toBe(1);
    });
  });

  // ========================================================
  // 8. SECURITY & RBAC ENFORCEMENT
  // ========================================================
  describe('8. RBAC & Security on All-Vertical Admin Endpoints', () => {
    it('should reject unauthenticated caller with 401 Unauthorized', async () => {
      await expect(
        executePipeline(AdminController.prototype.getDining, {}, () =>
          adminController.getDining({ limit: 10, offset: 0 }),
        ),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should reject non-admin caller with 403 Forbidden', async () => {
      await expect(
        executePipeline(
          AdminController.prototype.createDining,
          { authorization: `Bearer ${getUserToken()}` },
          () => adminController.createDining({} as any, { user: {} }),
        ),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        executePipeline(
          AdminController.prototype.publishEvent,
          { authorization: `Bearer ${getUserToken()}` },
          () => adminController.publishEvent('evt_existing_1', { user: {} }),
        ),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        executePipeline(
          AdminController.prototype.deleteHotel,
          { authorization: `Bearer ${getUserToken()}` },
          () => adminController.deleteHotel('htl_existing_1', { user: {} }),
        ),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
