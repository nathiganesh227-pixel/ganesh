import {
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';
import * as bcrypt from 'bcrypt';

import { AdminController } from './modules/admin/admin.controller';
import { AdminService } from './modules/admin/admin.service';
import { MoviesService } from './modules/movies/movies.service';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from './modules/auth/guards/roles.guard';
import { ROLES_KEY } from './modules/auth/decorators/roles.decorator';
import { User, UserRole } from './database/entities/user.entity';
import { MovieEntity } from './database/entities/movie.entity';
import { TheatreEntity } from './database/entities/theatre.entity';
import { ScreenEntity } from './database/entities/screen.entity';
import { ShowEntity } from './database/entities/show.entity';
import { AuditLogEntity } from './database/entities/audit-log.entity';
import { AuthService } from './modules/auth/auth.service';
import { UpdateRoleDto } from './modules/admin/dto/admin.dto';
import {
  CreateMovieDto,
  UpdateMovieDto,
  CreateTheatreDto,
  UpdateTheatreDto,
  CreateScreenDto,
  CreateShowDto,
} from './modules/admin/dto/movie-show.dto';

describe('Phase 12 — Admin Foundation, RBAC, Dashboard & Real Movie Show Management', () => {
  const TEST_JWT_SECRET = 'test_phase12_admin_secret_key_2026';
  let jwtService: JwtService;
  let adminService: AdminService;
  let adminController: AdminController;
  let moviesService: MoviesService;
  let jwtAuthGuard: JwtAuthGuard;
  let rolesGuard: RolesGuard;
  let reflector: Reflector;

  // In-memory repositories storage
  let mockUsers: User[] = [];
  let mockMovies: MovieEntity[] = [];
  let mockTheatres: TheatreEntity[] = [];
  let mockScreens: ScreenEntity[] = [];
  let mockShows: ShowEntity[] = [];
  let mockAuditLogs: AuditLogEntity[] = [];

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
        name: 'PLAZA Admin',
        phone: '+91 99999 00000',
        city: 'Hyderabad',
        role: UserRole.ADMIN,
        rewardPoints: 0,
        createdAt: new Date('2026-01-01T00:00:00Z'),
        updatedAt: new Date('2026-01-01T00:00:00Z'),
      } as User,
      {
        id: 'usr_normal_1',
        email: 'user@plaza.app',
        passwordHash: '$2b$10$hashedUserPassword',
        name: 'Normal User',
        phone: '+91 98765 43210',
        city: 'Hyderabad',
        role: UserRole.USER,
        rewardPoints: 500,
        createdAt: new Date('2026-01-02T00:00:00Z'),
        updatedAt: new Date('2026-01-02T00:00:00Z'),
      } as User,
    ];

    mockMovies = [
      {
        id: 'mov_1',
        title: 'Kalki 2898 AD',
        director: 'Nag Ashwin',
        synopsis: 'Mythological sci-fi epic',
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
        createdAt: new Date(),
        updatedAt: new Date(),
      } as MovieEntity,
    ];

    mockTheatres = [
      {
        id: 'theatre_amb',
        name: 'AMB Cinemas',
        location: 'Gachibowli',
        city: 'Hyderabad',
        address: 'Sarath City Capital Mall, Gachibowli',
        distance: '2.4 km',
        amenities: ['Laser IMAX', 'Dolby Atmos'],
        showtimes: [],
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as TheatreEntity,
    ];

    mockScreens = [
      {
        id: 'scr_1',
        theatreId: 'theatre_amb',
        name: 'Screen 1 (Laser IMAX)',
        screenType: 'IMAX 3D',
        capacity: 250,
        seatLayout: null,
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as ScreenEntity,
    ];

    mockShows = [
      {
        id: 'shw_1',
        movieId: 'mov_1',
        theatreId: 'theatre_amb',
        screenId: 'scr_1',
        showDate: '2026-09-26',
        startTime: '10:15 AM',
        format: 'IMAX 3D',
        language: 'Telugu',
        pricing: { gold: 295, premium: 350, recliner: 450 },
        seatAvailability: {
          totalSeats: 250,
          bookedSeats: [],
        },
        status: 'active',
        createdAt: new Date(),
        updatedAt: new Date(),
      } as ShowEntity,
    ];
    mockAuditLogs = [];

    mockUserRepo = {
      count: jest.fn().mockImplementation(async (opts?: any) => {
        if (opts?.where?.role) {
          return mockUsers.filter((u) => u.role === opts.where.role).length;
        }
        return mockUsers.length;
      }),
      find: jest.fn().mockImplementation(async (opts?: any) => {
        const take = opts?.take || mockUsers.length;
        const skip = opts?.skip || 0;
        return mockUsers.slice(skip, skip + take);
      }),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        const conditions = Array.isArray(where) ? where : [where];
        return (
          mockUsers.find((u) =>
            conditions.some(
              (cond: any) =>
                (cond.id && u.id === cond.id) || (cond.email && u.email === cond.email),
            ),
          ) || null
        );
      }),
      create: jest.fn().mockImplementation((dto) => ({ ...dto })),
      save: jest.fn().mockImplementation(async (entity) => {
        const list = Array.isArray(entity) ? entity : [entity];
        for (const item of list) {
          const idx = mockUsers.findIndex((u) => u.id === item.id || u.email === item.email);
          if (idx >= 0) {
            mockUsers[idx] = { ...mockUsers[idx], ...item };
          } else {
            mockUsers.push(item);
          }
        }
        return entity;
      }),
    };

    mockMovieRepo = {
      count: jest.fn().mockImplementation(async () => mockMovies.length),
      find: jest.fn().mockImplementation(async () => mockMovies),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockMovies.find((m) => m.id === where?.id) || null;
      }),
      create: jest.fn().mockImplementation((dto) => ({ ...dto })),
      save: jest.fn().mockImplementation(async (entity) => {
        const idx = mockMovies.findIndex((m) => m.id === entity.id);
        if (idx >= 0) {
          mockMovies[idx] = { ...mockMovies[idx], ...entity };
        } else {
          mockMovies.push(entity);
        }
        return entity;
      }),
      delete: jest.fn().mockImplementation(async (id: string) => {
        mockMovies = mockMovies.filter((m) => m.id !== id);
        return { affected: 1 };
      }),
    };

    mockTheatreRepo = {
      count: jest.fn().mockImplementation(async () => mockTheatres.length),
      find: jest.fn().mockImplementation(async () => mockTheatres),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockTheatres.find((t) => t.id === where?.id) || null;
      }),
      create: jest.fn().mockImplementation((dto) => ({ ...dto })),
      save: jest.fn().mockImplementation(async (entity) => {
        const idx = mockTheatres.findIndex((t) => t.id === entity.id);
        if (idx >= 0) {
          mockTheatres[idx] = { ...mockTheatres[idx], ...entity };
        } else {
          mockTheatres.push(entity);
        }
        return entity;
      }),
    };

    mockScreenRepo = {
      count: jest.fn().mockImplementation(async () => mockScreens.length),
      find: jest.fn().mockImplementation(async (opts?: any) => {
        if (opts?.where?.theatreId) {
          return mockScreens.filter((s) => s.theatreId === opts.where.theatreId);
        }
        return mockScreens;
      }),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockScreens.find((s) => s.id === where?.id) || null;
      }),
      create: jest.fn().mockImplementation((dto) => ({ ...dto })),
      save: jest.fn().mockImplementation(async (entity) => {
        const idx = mockScreens.findIndex((s) => s.id === entity.id);
        if (idx >= 0) {
          mockScreens[idx] = { ...mockScreens[idx], ...entity };
        } else {
          mockScreens.push(entity);
        }
        return entity;
      }),
    };

    mockShowRepo = {
      count: jest.fn().mockImplementation(async (opts?: any) => {
        if (opts?.where?.movieId) {
          return mockShows.filter((s) => s.movieId === opts.where.movieId).length;
        }
        return mockShows.length;
      }),
      find: jest.fn().mockImplementation(async (opts?: any) => {
        let list = [...mockShows];
        if (opts?.where?.movieId) list = list.filter((s) => s.movieId === opts.where.movieId);
        if (opts?.where?.theatreId) list = list.filter((s) => s.theatreId === opts.where.theatreId);
        if (opts?.where?.showDate) list = list.filter((s) => s.showDate === opts.where.showDate);
        return list;
      }),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return (
          mockShows.find((s) => {
            if (where.id && s.id !== where.id) return false;
            if (where.screenId && s.screenId !== where.screenId) return false;
            if (where.showDate && s.showDate !== where.showDate) return false;
            if (where.startTime && s.startTime !== where.startTime) return false;
            if (where.status && s.status !== where.status) return false;
            return true;
          }) || null
        );
      }),
      create: jest.fn().mockImplementation((dto) => ({ ...dto })),
      save: jest.fn().mockImplementation(async (entity) => {
        const idx = mockShows.findIndex((s) => s.id === entity.id);
        if (idx >= 0) {
          mockShows[idx] = { ...mockShows[idx], ...entity };
        } else {
          mockShows.push(entity);
        }
        return entity;
      }),
      delete: jest.fn().mockImplementation(async (id: string) => {
        mockShows = mockShows.filter((s) => s.id !== id);
        return { affected: 1 };
      }),
    };

    mockRestaurantRepo = { count: jest.fn().mockResolvedValue(8) };
    mockEventRepo = { count: jest.fn().mockResolvedValue(5) };
    mockActivityRepo = { count: jest.fn().mockResolvedValue(6) };
    mockProductRepo = { count: jest.fn().mockResolvedValue(25) };
    mockHotelRepo = { count: jest.fn().mockResolvedValue(4) };
    mockSportsVenueRepo = { count: jest.fn().mockResolvedValue(7) };
    mockBookingRepo = { count: jest.fn().mockResolvedValue(42) };

    mockAuditLogRepo = {
      count: jest.fn().mockImplementation(async () => mockAuditLogs.length),
      find: jest.fn().mockImplementation(async (opts?: any) => {
        const take = opts?.take || mockAuditLogs.length;
        const skip = opts?.skip || 0;
        return mockAuditLogs.slice(skip, skip + take);
      }),
      save: jest.fn().mockImplementation(async (log: AuditLogEntity) => {
        mockAuditLogs.push(log);
        return log;
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
    );

    adminController = new AdminController(adminService);
    moviesService = new MoviesService(
      mockMovieRepo,
      mockTheatreRepo,
      mockScreenRepo,
      mockShowRepo,
    );

    jwtAuthGuard = new JwtAuthGuard(jwtService);
    reflector = new Reflector();
    rolesGuard = new RolesGuard(reflector);
  });

  // Pipeline execution helper simulating NestJS Guards and Controller
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

  describe('1. Admin Controller & Security Baseline', () => {
    it('should verify AdminController has @Roles(UserRole.ADMIN)', () => {
      const classRoles = reflector.get<UserRole[]>(ROLES_KEY, AdminController);
      expect(classRoles).toContain(UserRole.ADMIN);
      expect(classRoles).not.toContain(UserRole.USER);
    });

    it('should reject unauthenticated requests with 401 Unauthorized', async () => {
      await expect(
        executePipeline(AdminController.prototype.getHealth, {}, () =>
          adminController.getHealth(),
        ),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should reject non-admin USER with 403 Forbidden', async () => {
      await expect(
        executePipeline(
          AdminController.prototype.getHealth,
          { authorization: `Bearer ${getUserToken()}` },
          () => adminController.getHealth(),
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should allow ADMIN token with 200 OK', async () => {
      const result = await executePipeline(
        AdminController.prototype.getHealth,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.getHealth(),
      );
      expect(result).toEqual({ admin: true });
    });
  });

  describe('2. Admin Dashboard Stats (GET /api/v1/admin/dashboard)', () => {
    it('should return aggregate counts for all 9 entities for ADMIN', async () => {
      const result = await executePipeline(
        AdminController.prototype.getDashboard,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.getDashboard(),
      );

      expect(result).toEqual({
        users: 2,
        movies: 1,
        dining: 8,
        events: 5,
        activities: 6,
        shopping: 25,
        stays: 4,
        sports: 7,
        bookings: 42,
      });
    });
  });

  describe('3. Admin Movie Management (CRUD & Audit)', () => {
    it('should allow ADMIN to create a new movie and record audit log', async () => {
      const dto: CreateMovieDto = {
        title: 'Pushpa 2: The Rule',
        synopsis: 'The rule of Pushpa Raj begins',
        posterUrl: 'https://images.unsplash.com/pushpa2.jpg',
        backdropUrl: 'https://images.unsplash.com/pushpa2_bd.jpg',
        rating: 9.3,
        votesCount: 85000,
        genres: ['Action', 'Drama'],
        duration: '3h 20min',
        primaryLanguage: 'Telugu',
        availableLanguages: ['Telugu', 'Hindi', 'Tamil'],
        formats: ['IMAX 2D', 'Dolby Atmos'],
        certificate: 'A',
        releaseDate: '2024-12-05',
        startingPrice: 300,
        director: 'Sukumar',
      };

      const result = await executePipeline(
        AdminController.prototype.createMovie,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.createMovie(dto, { user: { id: 'usr_admin_1', email: 'admin@plaza.app' } }),
      );

      expect(result.title).toBe('Pushpa 2: The Rule');
      expect(mockMovies.length).toBe(2);

      // Audit check
      expect(mockAuditLogs.some((l) => l.action === 'CREATE_MOVIE' && l.resourceType === 'Movie')).toBe(true);
    });

    it('should allow ADMIN to update an existing movie', async () => {
      const dto: UpdateMovieDto = { rating: 9.5 };

      const result = await executePipeline(
        AdminController.prototype.updateMovie,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.updateMovie('mov_1', dto, { user: { id: 'usr_admin_1', email: 'admin@plaza.app' } }),
      );

      expect(result.rating).toBe(9.5);
      expect(mockAuditLogs.some((l) => l.action === 'UPDATE_MOVIE')).toBe(true);
    });

    it('should safely archive a movie with active shows by setting isNowShowing to false', async () => {
      const result = await executePipeline(
        AdminController.prototype.deleteMovie,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.deleteMovie('mov_1', { user: { id: 'usr_admin_1', email: 'admin@plaza.app' } }),
      );

      expect(result.success).toBe(true);
      expect(result.message).toMatch(/archived/i);
      expect(mockMovies.find((m) => m.id === 'mov_1')?.isNowShowing).toBe(false);
      expect(mockAuditLogs.some((l) => l.action === 'ARCHIVE_MOVIE')).toBe(true);
    });

    it('should permanently delete a movie if no active shows reference it', async () => {
      mockMovies.push({
        id: 'mov_temp',
        title: 'Temporary Movie',
        isNowShowing: false,
      } as MovieEntity);

      const result = await executePipeline(
        AdminController.prototype.deleteMovie,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.deleteMovie('mov_temp', { user: { id: 'usr_admin_1', email: 'admin@plaza.app' } }),
      );

      expect(result.success).toBe(true);
      expect(mockMovies.find((m) => m.id === 'mov_temp')).toBeUndefined();
      expect(mockAuditLogs.some((l) => l.action === 'DELETE_MOVIE')).toBe(true);
    });

    it('should reject normal USER from creating or deleting movies', async () => {
      await expect(
        executePipeline(
          AdminController.prototype.createMovie,
          { authorization: `Bearer ${getUserToken()}` },
          () => adminController.createMovie({} as any, { user: {} }),
        ),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('4. Admin Theatre & Screen Management', () => {
    it('should allow ADMIN to create a theatre and record audit log', async () => {
      const dto: CreateTheatreDto = {
        name: 'PVR Forum Sujana Mall',
        location: 'Kukatpally, Hyderabad',
        city: 'Hyderabad',
        address: 'Sujana Forum Mall, KPHB Phase 9',
        amenities: ['4K Dolby', 'PXL Screen'],
      };

      const result = await executePipeline(
        AdminController.prototype.createTheatre,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.createTheatre(dto, { user: { id: 'usr_admin_1', email: 'admin@plaza.app' } }),
      );

      expect(result.name).toBe('PVR Forum Sujana Mall');
      expect(result.city).toBe('Hyderabad');
      expect(mockAuditLogs.some((l) => l.action === 'CREATE_THEATRE')).toBe(true);
    });

    it('should create screen in theatre and validate positive capacity', async () => {
      const dto: CreateScreenDto = {
        name: 'Audi 2 (Dolby Atmos)',
        screenType: 'Dolby Atmos',
        capacity: 180,
      };

      const result = await executePipeline(
        AdminController.prototype.createScreen,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.createScreen('theatre_amb', dto, { user: { id: 'usr_admin_1', email: 'admin@plaza.app' } }),
      );

      expect(result.name).toBe('Audi 2 (Dolby Atmos)');
      expect(result.capacity).toBe(180);
      expect(result.theatreId).toBe('theatre_amb');
      expect(mockAuditLogs.some((l) => l.action === 'CREATE_SCREEN')).toBe(true);
    });

    it('should reject creating screen with non-positive capacity', async () => {
      const dto: CreateScreenDto = {
        name: 'Invalid Screen',
        capacity: 0,
      };

      await expect(
        adminService.createScreen('theatre_amb', dto, { id: 'usr_admin_1', email: 'admin@plaza.app' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw NotFoundException if theatre does not exist when creating screen', async () => {
      const dto: CreateScreenDto = {
        name: 'Screen 1',
        capacity: 100,
      };

      await expect(
        adminService.createScreen('non_existent_theatre', dto, { id: 'usr_admin_1', email: 'admin@plaza.app' }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('5. Real Movie Show Management & Pricing Model', () => {
    beforeEach(() => {
      // Re-seed mov_1 if deleted in earlier test
      if (!mockMovies.find((m) => m.id === 'mov_1')) {
        mockMovies.push({
          id: 'mov_1',
          title: 'Kalki 2898 AD',
          primaryLanguage: 'Telugu',
        } as MovieEntity);
      }
    });

    it('should create a show with Gold, Premium, Recliner pricing and availability foundation', async () => {
      const dto: CreateShowDto = {
        movieId: 'mov_1',
        theatreId: 'theatre_amb',
        screenId: 'scr_1',
        showDate: '2026-09-26',
        startTime: '01:45 PM',
        format: 'IMAX 3D',
        language: 'Telugu',
        pricing: {
          gold: 295,
          premium: 350,
          recliner: 450,
        },
      };

      const result = await executePipeline(
        AdminController.prototype.createShow,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.createShow(dto, { user: { id: 'usr_admin_1', email: 'admin@plaza.app' } }),
      );

      expect(result.movieId).toBe('mov_1');
      expect(result.pricing).toEqual({ gold: 295, premium: 350, recliner: 450 });
      expect(result.seatAvailability.totalSeats).toBe(250);
      expect(result.seatAvailability.bookedSeats).toEqual([]);
      expect(mockAuditLogs.some((l) => l.action === 'CREATE_SHOW')).toBe(true);
    });

    it('should prevent duplicate show collision on same screen, date, and start time', async () => {
      const dto: CreateShowDto = {
        movieId: 'mov_1',
        theatreId: 'theatre_amb',
        screenId: 'scr_1',
        showDate: '2026-09-26',
        startTime: '10:15 AM',
        pricing: { gold: 295, premium: 350, recliner: 450 },
      };

      await expect(
        adminService.createShow(dto, { id: 'usr_admin_1', email: 'admin@plaza.app' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject show creation if screen does not belong to theatre', async () => {
      // Mock another theatre
      mockTheatres.push({
        id: 'theatre_prasads',
        name: 'Prasads Multiplex',
      } as TheatreEntity);

      const dto: CreateShowDto = {
        movieId: 'mov_1',
        theatreId: 'theatre_prasads', // screen scr_1 belongs to theatre_amb
        screenId: 'scr_1',
        showDate: '2026-09-26',
        startTime: '02:30 PM',
        pricing: { gold: 250, premium: 300, recliner: 400 },
      };

      await expect(
        adminService.createShow(dto, { id: 'usr_admin_1', email: 'admin@plaza.app' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should reject show creation if movie does not exist', async () => {
      const dto: CreateShowDto = {
        movieId: 'non_existent_movie',
        theatreId: 'theatre_amb',
        screenId: 'scr_1',
        showDate: '2026-09-26',
        startTime: '06:00 PM',
        pricing: { gold: 295, premium: 350, recliner: 450 },
      };

      await expect(
        adminService.createShow(dto, { id: 'usr_admin_1', email: 'admin@plaza.app' }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('6. Consumer Movie Shows API (GET /api/v1/movies/:id/shows)', () => {
    it('should return enriched movie shows with theatre, screen, pricing, and availability', async () => {
      const shows = await moviesService.findShowsForMovie('mov_1');
      expect(Array.isArray(shows)).toBe(true);
      expect(shows.length).toBeGreaterThanOrEqual(1);

      const first = shows[0];
      expect(first.movieTitle).toBe('Kalki 2898 AD');
      expect(first.theatreName).toBe('AMB Cinemas');
      expect(first.screenName).toBe('Screen 1 (Laser IMAX)');
      expect(first.pricing).toEqual({ gold: 295, premium: 350, recliner: 450 });
      expect(first.seatAvailability.availableSeats).toBe(250);
    });

    it('should support filtering by date, city, and theatre', async () => {
      const filteredByDate = await moviesService.findShowsForMovie('mov_1', { date: '2026-09-26' });
      expect(filteredByDate.length).toBe(1);

      const filteredByWrongDate = await moviesService.findShowsForMovie('mov_1', { date: '2099-01-01' });
      expect(filteredByWrongDate.length).toBe(0);

      const filteredByCity = await moviesService.findShowsForMovie('mov_1', { city: 'Hyderabad' });
      expect(filteredByCity.length).toBe(1);

      const filteredByOtherCity = await moviesService.findShowsForMovie('mov_1', { city: 'Mumbai' });
      expect(filteredByOtherCity.length).toBe(0);
    });
  });
});
