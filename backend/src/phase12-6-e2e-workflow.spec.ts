import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UnauthorizedException, ForbiddenException, BadRequestException, ConflictException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import * as jwt from 'jsonwebtoken';
import { AdminController } from './modules/admin/admin.controller';
import { AdminService } from './modules/admin/admin.service';
import { MoviesController } from './modules/movies/movies.controller';
import { MoviesService } from './modules/movies/movies.service';
import { SearchService } from './modules/search/search.service';
import { DiningService } from './modules/dining/dining.service';
import { EventsService } from './modules/events/events.service';
import { ActivitiesService } from './modules/activities/activities.service';
import { ShoppingService } from './modules/shopping/shopping.service';
import { StaysService } from './modules/stays/stays.service';
import { SportsService } from './modules/sports/sports.service';
import { JwtService } from '@nestjs/jwt';
import { RolesGuard } from './modules/auth/guards/roles.guard';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import { User, UserRole } from './database/entities/user.entity';
import { AuditLogEntity } from './database/entities/audit-log.entity';
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
import { BookingEntity } from './database/entities/booking.entity';

describe('Phase 12.6 — End-to-End Real-World Movie Workflow Verification', () => {
  let adminController: AdminController;
  let adminService: AdminService;
  let moviesController: MoviesController;
  let moviesService: MoviesService;
  let searchService: SearchService;
  let rolesGuard: RolesGuard;
  let reflector: Reflector;

  // In-memory repositories
  let users: User[] = [];
  let movies: MovieEntity[] = [];
  let theatres: TheatreEntity[] = [];
  let screens: ScreenEntity[] = [];
  let shows: ShowEntity[] = [];
  let auditLogs: AuditLogEntity[] = [];
  let bookings: BookingEntity[] = [];

  const JWT_SECRET = 'plaza-dev-jwt-secret-key-2026';
  const getAdminToken = () =>
    jwt.sign({ sub: 'usr_admin_1', email: 'admin@plaza.app', role: UserRole.ADMIN }, JWT_SECRET);
  const getUserToken = () =>
    jwt.sign({ sub: 'usr_normal_1', email: 'user@plaza.app', role: UserRole.USER }, JWT_SECRET);

  const createMockRepo = (storage: any[]) => ({
    find: jest.fn(async (options?: any) => {
      let result = [...storage];
      if (options?.where) {
        result = result.filter((item) =>
          Object.entries(options.where).every(([key, val]) => (item as any)[key] === val),
        );
      }
      if (options?.skip) result = result.slice(options.skip);
      if (options?.take) result = result.slice(0, options.take);
      return result;
    }),
    findOne: jest.fn(async (options?: any) => {
      if (options?.where) {
        return (
          storage.find((item) =>
            Object.entries(options.where).every(([key, val]) => (item as any)[key] === val),
          ) || null
        );
      }
      return null;
    }),
    count: jest.fn(async (options?: any) => {
      if (options?.where) {
        return storage.filter((item) =>
          Object.entries(options.where).every(([key, val]) => (item as any)[key] === val),
        ).length;
      }
      return storage.length;
    }),
    create: jest.fn((dto: any) => ({ ...dto })),
    save: jest.fn(async (entity: any) => {
      const idx = storage.findIndex((e) => e.id === entity.id);
      if (idx >= 0) {
        storage[idx] = { ...storage[idx], ...entity, updatedAt: new Date() };
        return storage[idx];
      } else {
        const item = { ...entity, createdAt: new Date(), updatedAt: new Date() };
        storage.push(item);
        return item;
      }
    }),
    delete: jest.fn(async (criteria: any) => {
      const id = typeof criteria === 'string' ? criteria : criteria.id;
      const idx = storage.findIndex((e) => e.id === id);
      if (idx >= 0) {
        storage.splice(idx, 1);
        return { affected: 1 };
      }
      return { affected: 0 };
    }),
  });

  const emptyMockRepo = () => ({
    find: jest.fn(async () => []),
    findOne: jest.fn(async () => null),
    count: jest.fn(async () => 0),
    create: jest.fn((dto) => dto),
    save: jest.fn(async (dto) => dto),
    delete: jest.fn(async () => ({ affected: 1 })),
  });

  beforeAll(async () => {
    users = [
      {
        id: 'usr_admin_1',
        email: 'admin@plaza.app',
        name: 'Admin User',
        role: UserRole.ADMIN,
      } as User,
      {
        id: 'usr_normal_1',
        email: 'user@plaza.app',
        name: 'Normal User',
        role: UserRole.USER,
      } as User,
    ];

    movies = [
      {
        id: 'mov_kalki',
        title: 'Kalki 2898 AD',
        director: 'Nag Ashwin',
        synopsis: 'Sci-fi epic',
        posterUrl: 'https://images.unsplash.com/kalki.jpg',
        backdropUrl: 'https://images.unsplash.com/kalki_bd.jpg',
        rating: 9.0,
        votesCount: 50000,
        genres: ['Action', 'Sci-Fi'],
        duration: '3h 1min',
        primaryLanguage: 'Telugu',
        availableLanguages: ['Telugu', 'Hindi'],
        formats: ['IMAX 3D', '2D'],
        certificate: 'UA',
        releaseDate: '2024-06-27',
        startingPrice: 250,
        isNowShowing: true,
        isTrending: true,
        isComingSoon: false,
      } as MovieEntity,
    ];

    theatres = [];
    screens = [];
    shows = [];
    auditLogs = [];
    bookings = [];

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AdminController, MoviesController],
      providers: [
        AdminService,
        MoviesService,
        SearchService,
        DiningService,
        EventsService,
        ActivitiesService,
        ShoppingService,
        StaysService,
        SportsService,
        RolesGuard,
        Reflector,
        { provide: JwtService, useValue: new JwtService({ secret: JWT_SECRET }) },
        { provide: getRepositoryToken(User), useValue: createMockRepo(users) },
        { provide: getRepositoryToken(AuditLogEntity), useValue: createMockRepo(auditLogs) },
        { provide: getRepositoryToken(MovieEntity), useValue: createMockRepo(movies) },
        { provide: getRepositoryToken(TheatreEntity), useValue: createMockRepo(theatres) },
        { provide: getRepositoryToken(ScreenEntity), useValue: createMockRepo(screens) },
        { provide: getRepositoryToken(ShowEntity), useValue: createMockRepo(shows) },
        { provide: getRepositoryToken(RestaurantEntity), useValue: emptyMockRepo() },
        { provide: getRepositoryToken(EventEntity), useValue: emptyMockRepo() },
        { provide: getRepositoryToken(ActivityEntity), useValue: emptyMockRepo() },
        { provide: getRepositoryToken(ProductEntity), useValue: emptyMockRepo() },
        { provide: getRepositoryToken(HotelEntity), useValue: emptyMockRepo() },
        { provide: getRepositoryToken(SportsVenueEntity), useValue: emptyMockRepo() },
        { provide: getRepositoryToken(BookingEntity), useValue: createMockRepo(bookings) },
      ],
    }).compile();

    adminController = module.get<AdminController>(AdminController);
    adminService = module.get<AdminService>(AdminService);
    moviesController = module.get<MoviesController>(MoviesController);
    moviesService = module.get<MoviesService>(MoviesService);
    searchService = module.get<SearchService>(SearchService);
    rolesGuard = module.get<RolesGuard>(RolesGuard);
    reflector = module.get<Reflector>(Reflector);
  });

  const simulateGuard = (token: string | null, targetHandler: any) => {
    if (!token) throw new UnauthorizedException('No token provided');
    let decoded: any;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch {
      throw new UnauthorizedException('Invalid token');
    }

    const context = {
      getHandler: () => targetHandler,
      getClass: () => AdminController,
      switchToHttp: () => ({
        getRequest: () => ({ user: decoded }),
      }),
    } as any;

    const canActivate = rolesGuard.canActivate(context);
    if (!canActivate) {
      throw new ForbiddenException('Forbidden resource: requires ADMIN role');
    }
    return decoded;
  };

  describe('Tier 1: Security & RBAC Enforcement on Admin Movie Endpoints', () => {
    it('should reject unauthenticated request with 401 Unauthorized', () => {
      expect(() => simulateGuard(null, AdminController.prototype.createMovie)).toThrow(
        UnauthorizedException,
      );
    });

    it('should reject non-admin (USER) token with 403 Forbidden', () => {
      expect(() => simulateGuard(getUserToken(), AdminController.prototype.createMovie)).toThrow(
        ForbiddenException,
      );
    });

    it('should allow admin token with 200/201 Success', () => {
      const actor = simulateGuard(getAdminToken(), AdminController.prototype.createMovie);
      expect(actor.role).toBe(UserRole.ADMIN);
      expect(actor.email).toBe('admin@plaza.app');
    });
  });

  describe('Tier 2: Real-World Movie Creation & Relationship Flow', () => {
    let createdMovie: MovieEntity;
    let createdTheatre: TheatreEntity;
    let createdScreen: ScreenEntity;
    let createdShow: ShowEntity;

    const uniqueId = `e2e_${Date.now()}`;
    const testMovieTitle = `PLAZA E2E Test Movie 2026 - ${uniqueId}`;
    const testTheatreName = `PLAZA E2E Test Theatre - ${uniqueId}`;
    const testScreenName = `PLAZA Test Screen 1 - ${uniqueId}`;

    it('Step 1: Admin creates unique test Movie', async () => {
      const actor = simulateGuard(getAdminToken(), AdminController.prototype.createMovie);
      createdMovie = await adminController.createMovie(
        {
          title: testMovieTitle,
          synopsis: 'A high-stakes thriller verifying end-to-end PLAZA cinema operations.',
          posterUrl: 'https://images.unsplash.com/photo-test-poster.jpg',
          backdropUrl: 'https://images.unsplash.com/photo-test-backdrop.jpg',
          rating: 9.3,
          votesCount: 1200,
          genres: ['Action', 'Thriller'],
          duration: '2h 45m',
          primaryLanguage: 'Telugu',
          availableLanguages: ['Telugu', 'Hindi', 'English'],
          formats: ['IMAX 3D', '4DX', '2D'],
          certificate: 'UA',
          releaseDate: '2026-10-15',
          startingPrice: 200,
          director: 'S. S. Rajamouli',
          isNowShowing: true,
          isTrending: true,
          isComingSoon: false,
        },
        { user: actor },
      );

      expect(createdMovie).toBeDefined();
      expect(createdMovie.id).toMatch(/^mov_/);
      expect(createdMovie.title).toBe(testMovieTitle);
      expect(createdMovie.isNowShowing).toBe(true);
      expect(movies.some((m) => m.id === createdMovie.id)).toBe(true);

      // Verify audit log
      expect(
        auditLogs.some((l) => l.action === 'CREATE_MOVIE' && l.resourceId === createdMovie.id),
      ).toBe(true);
    });

    it('Step 2: Admin creates unique test Theatre', async () => {
      const actor = simulateGuard(getAdminToken(), AdminController.prototype.createTheatre);
      createdTheatre = await adminController.createTheatre(
        {
          name: testTheatreName,
          location: 'HITEC City, Hyderabad',
          city: 'Hyderabad',
          address: 'Cyber Towers Main Road, HITEC City',
          distance: '2.5 km',
          amenities: ['Dolby Atmos', '4K Laser Projection', 'Gourmet Lounge'],
          isActive: true,
        },
        { user: actor },
      );

      expect(createdTheatre).toBeDefined();
      expect(createdTheatre.id).toMatch(/^theatre_/);
      expect(createdTheatre.name).toBe(testTheatreName);
      expect(theatres.some((t) => t.id === createdTheatre.id)).toBe(true);

      // Verify audit log
      expect(
        auditLogs.some((l) => l.action === 'CREATE_THEATRE' && l.resourceId === createdTheatre.id),
      ).toBe(true);
    });

    it('Step 3: Admin creates unique test Screen under test Theatre', async () => {
      const actor = simulateGuard(getAdminToken(), AdminController.prototype.createScreen);
      createdScreen = await adminController.createScreen(
        createdTheatre.id,
        {
          name: testScreenName,
          screenType: 'IMAX 3D',
          capacity: 180,
          isActive: true,
        },
        { user: actor },
      );

      expect(createdScreen).toBeDefined();
      expect(createdScreen.id).toMatch(/^scr_/);
      expect(createdScreen.theatreId).toBe(createdTheatre.id);
      expect(createdScreen.capacity).toBe(180);
      expect(screens.some((s) => s.id === createdScreen.id)).toBe(true);

      // Verify audit log
      expect(
        auditLogs.some((l) => l.action === 'CREATE_SCREEN' && l.resourceId === createdScreen.id),
      ).toBe(true);
    });

    it('Step 4: Admin creates Show linking Movie + Theatre + Screen with tiered pricing', async () => {
      const actor = simulateGuard(getAdminToken(), AdminController.prototype.createShow);
      createdShow = await adminController.createShow(
        {
          movieId: createdMovie.id,
          theatreId: createdTheatre.id,
          screenId: createdScreen.id,
          showDate: '2026-10-15',
          startTime: '19:30',
          format: 'IMAX 3D',
          language: 'Telugu',
          pricing: {
            gold: 250,
            premium: 350,
            recliner: 500,
          },
        },
        { user: actor },
      );

      expect(createdShow).toBeDefined();
      expect(createdShow.id).toMatch(/^shw_/);
      expect(createdShow.movieId).toBe(createdMovie.id);
      expect(createdShow.theatreId).toBe(createdTheatre.id);
      expect(createdShow.screenId).toBe(createdScreen.id);
      expect(createdShow.pricing.gold).toBe(250);
      expect(createdShow.pricing.premium).toBe(350);
      expect(createdShow.pricing.recliner).toBe(500);
      expect(createdShow.seatAvailability.totalSeats).toBe(180);
      expect(createdShow.status).toBe('active');

      // Verify audit log
      expect(
        auditLogs.some((l) => l.action === 'CREATE_SHOW' && l.resourceId === createdShow.id),
      ).toBe(true);
    });

    it('Step 5: Relational Integrity Verification', async () => {
      // 1. Show foreign references
      expect(createdShow.movieId).toBe(createdMovie.id);
      expect(createdShow.theatreId).toBe(createdTheatre.id);
      expect(createdShow.screenId).toBe(createdScreen.id);

      // 2. Screen foreign reference
      expect(createdScreen.theatreId).toBe(createdTheatre.id);

      // 3. Screen mismatch check: screen belonging to another theatre must be rejected
      const actor = simulateGuard(getAdminToken(), AdminController.prototype.createShow);
      await expect(
        adminController.createShow(
          {
            movieId: createdMovie.id,
            theatreId: 'theatre_different_999',
            screenId: createdScreen.id, // belongs to createdTheatre.id
            showDate: '2026-10-15',
            startTime: '22:30',
            pricing: { gold: 200, premium: 300, recliner: 400 },
          },
          { user: actor },
        ),
      ).rejects.toThrow();
    });

    it('Step 6: Collision Protection rejects duplicate show on same screen + date + time', async () => {
      const actor = simulateGuard(getAdminToken(), AdminController.prototype.createShow);
      await expect(
        adminController.createShow(
          {
            movieId: createdMovie.id,
            theatreId: createdTheatre.id,
            screenId: createdScreen.id,
            showDate: '2026-10-15', // Same date
            startTime: '19:30',     // Same time!
            pricing: { gold: 250, premium: 350, recliner: 500 },
          },
          { user: actor },
        ),
      ).rejects.toThrow(/already scheduled/i);
    });

    it('Step 7: Consumer API returns published movie, theatre, showtime, and authoritative pricing', async () => {
      // 1. GET /api/v1/movies
      const consumerMovies = await moviesController.findAll();
      const foundMovie = consumerMovies.find((m) => m.id === createdMovie.id);
      expect(foundMovie).toBeDefined();
      expect(foundMovie!.title).toBe(testMovieTitle);

      // 2. GET /api/v1/movies/:id
      const movieDetails = await moviesController.findOne(createdMovie.id);
      expect(movieDetails.id).toBe(createdMovie.id);
      expect(movieDetails.title).toBe(testMovieTitle);

      // 3. GET /api/v1/movies/:id/shows
      const movieShows = await moviesController.getMovieShows(createdMovie.id);
      expect(movieShows.length).toBeGreaterThan(0);
      const testShow = movieShows.find((s) => s.id === createdShow.id);
      expect(testShow).toBeDefined();
      expect(testShow!.theatreName).toBe(testTheatreName);
      expect(testShow!.theatreCity).toBe('Hyderabad');
      expect(testShow!.screenName).toBe(testScreenName);
      expect(testShow!.format).toBe('IMAX 3D');
      expect(testShow!.showDate).toBe('2026-10-15');
      expect(testShow!.startTime).toBe('19:30');
      expect(testShow!.pricing.gold).toBe(250);
      expect(testShow!.pricing.premium).toBe(350);
      expect(testShow!.pricing.recliner).toBe(500);
      expect(testShow!.seatAvailability.totalSeats).toBe(180);
      expect(testShow!.seatAvailability.availableSeats).toBe(180);

      // 4. GET /api/v1/search?q=
      const searchResults = await searchService.searchAll('PLAZA E2E');
      expect(searchResults.movies.some((m) => m.id === createdMovie.id)).toBe(true);
    });

    it('Step 8: Negative Test — Unpublishing movie hides it from consumer list & search, republishing restores it', async () => {
      const actor = simulateGuard(getAdminToken(), AdminController.prototype.updateMovie);

      // 1. Admin unpublishes the movie
      await adminController.updateMovie(
        createdMovie.id,
        { isNowShowing: false, isComingSoon: false },
        { user: actor },
      );

      // 2. Consumer findAll must NOT return the unpublished movie
      const consumerMoviesHidden = await moviesController.findAll();
      expect(consumerMoviesHidden.some((m) => m.id === createdMovie.id)).toBe(false);

      // 3. Consumer Search must NOT return the unpublished movie
      const searchHidden = await searchService.searchAll('PLAZA E2E');
      expect(searchHidden.movies.some((m) => m.id === createdMovie.id)).toBe(false);

      // 4. Admin republishes the movie
      await adminController.updateMovie(
        createdMovie.id,
        { isNowShowing: true },
        { user: actor },
      );

      // 5. Consumer findAll must return the movie again
      const consumerMoviesRestored = await moviesController.findAll();
      expect(consumerMoviesRestored.some((m) => m.id === createdMovie.id)).toBe(true);

      // 6. Consumer Search must return the movie again
      const searchRestored = await searchService.searchAll('PLAZA E2E');
      expect(searchRestored.movies.some((m) => m.id === createdMovie.id)).toBe(true);
    });

    it('Step 9: Safe Show Deletion & Archival check', async () => {
      const actor = simulateGuard(getAdminToken(), AdminController.prototype.deleteShow);

      // Deleting a show with no bookings permanently deletes it
      const deleteResult = await adminController.deleteShow(createdShow.id, { user: actor });
      expect(deleteResult.success).toBe(true);
      expect(shows.some((s) => s.id === createdShow.id)).toBe(false);

      // Verify audit log
      expect(
        auditLogs.some((l) => l.action === 'DELETE_SHOW' && l.resourceId === createdShow.id),
      ).toBe(true);
    });
  });
});
