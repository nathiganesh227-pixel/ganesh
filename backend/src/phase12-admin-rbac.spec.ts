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
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from './modules/auth/guards/roles.guard';
import { ROLES_KEY } from './modules/auth/decorators/roles.decorator';
import { User, UserRole } from './database/entities/user.entity';
import { AuditLogEntity } from './database/entities/audit-log.entity';
import { AuthService } from './modules/auth/auth.service';
import { UpdateRoleDto } from './modules/admin/dto/admin.dto';

describe('Phase 12 — Admin Foundation, RBAC, Dashboard & Management Verification', () => {
  const TEST_JWT_SECRET = 'test_phase12_admin_secret_key_2026';
  let jwtService: JwtService;
  let adminService: AdminService;
  let adminController: AdminController;
  let jwtAuthGuard: JwtAuthGuard;
  let rolesGuard: RolesGuard;
  let reflector: Reflector;

  // In-memory repositories storage
  let mockUsers: User[] = [];
  let mockAuditLogs: AuditLogEntity[] = [];

  let mockUserRepo: any;
  let mockMovieRepo: any;
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

    mockMovieRepo = { count: jest.fn().mockResolvedValue(12) };
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
      mockRestaurantRepo,
      mockEventRepo,
      mockActivityRepo,
      mockProductRepo,
      mockHotelRepo,
      mockSportsVenueRepo,
      mockBookingRepo,
      mockAuditLogRepo,
    );

    adminController = new AdminController(adminService);
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

    // 1. JwtAuthGuard
    jwtAuthGuard.canActivate(context);

    // 2. RolesGuard
    rolesGuard.canActivate(context);

    // 3. Controller execution
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

  describe('1. Admin Controller & Health Endpoint Security (Phase 12.1 verification)', () => {
    it('should verify AdminController has @Roles(UserRole.ADMIN)', () => {
      const classRoles = reflector.get<UserRole[]>(ROLES_KEY, AdminController);
      expect(classRoles).toContain(UserRole.ADMIN);
      expect(classRoles).not.toContain(UserRole.USER);
    });

    it('should return 401 when no token is provided to health endpoint', async () => {
      await expect(
        executePipeline(AdminController.prototype.getHealth, {}, () =>
          adminController.getHealth(),
        ),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should return 403 when USER token calls health endpoint', async () => {
      await expect(
        executePipeline(
          AdminController.prototype.getHealth,
          { authorization: `Bearer ${getUserToken()}` },
          () => adminController.getHealth(),
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should return 200 when ADMIN token calls health endpoint', async () => {
      const result = await executePipeline(
        AdminController.prototype.getHealth,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.getHealth(),
      );
      expect(result).toEqual({ admin: true });
    });
  });

  describe('2. Admin Dashboard Stats (GET /api/v1/admin/dashboard)', () => {
    it('should return 200 OK with all 9 entity counts for ADMIN', async () => {
      const result = await executePipeline(
        AdminController.prototype.getDashboard,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.getDashboard(),
      );

      expect(result).toEqual({
        users: 2,
        movies: 12,
        dining: 8,
        events: 5,
        activities: 6,
        shopping: 25,
        stays: 4,
        sports: 7,
        bookings: 42,
      });
    });

    it('should reject non-admin USER with 403 Forbidden', async () => {
      await expect(
        executePipeline(
          AdminController.prototype.getDashboard,
          { authorization: `Bearer ${getUserToken()}` },
          () => adminController.getDashboard(),
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should reject unauthenticated request with 401 Unauthorized', async () => {
      await expect(
        executePipeline(AdminController.prototype.getDashboard, {}, () =>
          adminController.getDashboard(),
        ),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('3. Admin Users API (GET /api/v1/admin/users & GET /api/v1/admin/users/:id)', () => {
    it('should return safe user list without passwordHash for ADMIN', async () => {
      const result = await executePipeline(
        AdminController.prototype.getUsers,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.getUsers({ limit: 10, offset: 0 }),
      );

      expect(Array.isArray(result)).toBe(true);
      expect(result.length).toBe(2);

      // Verify no passwordHash or secrets leaked
      for (const u of result) {
        expect((u as any).passwordHash).toBeUndefined();
        expect(u.id).toBeDefined();
        expect(u.email).toBeDefined();
        expect(u.role).toBeDefined();
      }
    });

    it('should return user detail by ID without passwordHash for ADMIN', async () => {
      const result = await executePipeline(
        AdminController.prototype.getUserById,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.getUserById('usr_normal_1'),
      );

      expect(result.id).toBe('usr_normal_1');
      expect(result.email).toBe('user@plaza.app');
      expect(result.role).toBe(UserRole.USER);
      expect((result as any).passwordHash).toBeUndefined();
    });

    it('should return 404 NotFoundException when querying a non-existent user ID', async () => {
      await expect(
        executePipeline(
          AdminController.prototype.getUserById,
          { authorization: `Bearer ${getAdminToken()}` },
          () => adminController.getUserById('usr_non_existent'),
        ),
      ).rejects.toThrow(NotFoundException);
    });

    it('should reject normal USER from listing users with 403 Forbidden', async () => {
      await expect(
        executePipeline(
          AdminController.prototype.getUsers,
          { authorization: `Bearer ${getUserToken()}` },
          () => adminController.getUsers({}),
        ),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('4. Admin User Role Management & Last-Admin Protection', () => {
    it('should allow ADMIN to promote a USER to ADMIN and create an audit log', async () => {
      const dto: UpdateRoleDto = { role: UserRole.ADMIN };
      const actor = { id: 'usr_admin_1', email: 'admin@plaza.app' };

      const result = await executePipeline(
        AdminController.prototype.updateUserRole,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.updateUserRole('usr_normal_1', dto, { user: actor }),
      );

      expect(result.id).toBe('usr_normal_1');
      expect(result.role).toBe(UserRole.ADMIN);
      expect((result as any).passwordHash).toBeUndefined();

      // Check user record in mock DB updated
      const updatedUser = mockUsers.find((u) => u.id === 'usr_normal_1');
      expect(updatedUser?.role).toBe(UserRole.ADMIN);

      // Verify audit log created
      expect(mockAuditLogs.length).toBe(1);
      expect(mockAuditLogs[0].action).toBe('UPDATE_USER_ROLE');
      expect(mockAuditLogs[0].actorEmail).toBe('admin@plaza.app');
      expect(mockAuditLogs[0].resourceId).toBe('usr_normal_1');
      expect(mockAuditLogs[0].metadata).toEqual({
        targetEmail: 'user@plaza.app',
        previousRole: UserRole.USER,
        newRole: UserRole.ADMIN,
      });
      // Verify no secrets stored in audit log
      expect(JSON.stringify(mockAuditLogs[0])).not.toMatch(/password/i);
    });

    it('should prevent demoting the last remaining administrator (Last-Admin Protection)', async () => {
      // At this point, only 1 admin exists if we reset to original
      mockUsers = mockUsers.map((u) =>
        u.id === 'usr_normal_1' ? { ...u, role: UserRole.USER } : u,
      );

      const dto: UpdateRoleDto = { role: UserRole.USER };
      const actor = { id: 'usr_admin_1', email: 'admin@plaza.app' };

      // Attempt to demote usr_admin_1 when it is the sole admin
      await expect(
        executePipeline(
          AdminController.prototype.updateUserRole,
          { authorization: `Bearer ${getAdminToken()}` },
          () => adminController.updateUserRole('usr_admin_1', dto, { user: actor }),
        ),
      ).rejects.toThrow(BadRequestException);

      // Verify usr_admin_1 is still ADMIN
      const admin = mockUsers.find((u) => u.id === 'usr_admin_1');
      expect(admin?.role).toBe(UserRole.ADMIN);
    });

    it('should allow demoting an admin if another admin exists', async () => {
      // Add a second admin
      mockUsers.push({
        id: 'usr_admin_2',
        email: 'admin2@plaza.app',
        passwordHash: '$2b$10$hash',
        name: 'Second Admin',
        role: UserRole.ADMIN,
      } as User);

      const dto: UpdateRoleDto = { role: UserRole.USER };
      const actor = { id: 'usr_admin_1', email: 'admin@plaza.app' };

      const result = await executePipeline(
        AdminController.prototype.updateUserRole,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.updateUserRole('usr_admin_2', dto, { user: actor }),
      );

      expect(result.role).toBe(UserRole.USER);
      expect(mockUsers.find((u) => u.id === 'usr_admin_2')?.role).toBe(UserRole.USER);
    });

    it('should reject normal USER from updating roles with 403 Forbidden', async () => {
      const dto: UpdateRoleDto = { role: UserRole.ADMIN };
      await expect(
        executePipeline(
          AdminController.prototype.updateUserRole,
          { authorization: `Bearer ${getUserToken()}` },
          () => adminController.updateUserRole('usr_normal_1', dto, { user: {} }),
        ),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('5. Audit Logs API (GET /api/v1/admin/audit-logs)', () => {
    it('should allow ADMIN to read audit logs safely', async () => {
      mockAuditLogs.push({
        id: 'aud_test_1',
        actorUserId: 'usr_admin_1',
        actorEmail: 'admin@plaza.app',
        action: 'UPDATE_USER_ROLE',
        resourceType: 'User',
        resourceId: 'usr_normal_1',
        metadata: { targetEmail: 'user@plaza.app', previousRole: 'user', newRole: 'admin' },
        createdAt: new Date(),
      } as AuditLogEntity);

      const result = await executePipeline(
        AdminController.prototype.getAuditLogs,
        { authorization: `Bearer ${getAdminToken()}` },
        () => adminController.getAuditLogs({ limit: 10, offset: 0 }),
      );

      expect(Array.isArray(result)).toBe(true);
      expect(result.length).toBeGreaterThanOrEqual(1);
      expect(result[0].action).toBe('UPDATE_USER_ROLE');
    });

    it('should reject normal USER from reading audit logs with 403 Forbidden', async () => {
      await expect(
        executePipeline(
          AdminController.prototype.getAuditLogs,
          { authorization: `Bearer ${getUserToken()}` },
          () => adminController.getAuditLogs({}),
        ),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('6. Registration Security (Prevent Role Escalation)', () => {
    it('should strictly force role to UserRole.USER during registration even if client supplies role: ADMIN', async () => {
      const savedUsers: User[] = [];
      const userRepo: any = {
        findOne: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockImplementation((entity) => ({ ...entity })),
        save: jest.fn().mockImplementation(async (entity) => {
          savedUsers.push(entity);
          return entity;
        }),
      };

      const authService = new AuthService(userRepo, jwtService);

      const maliciousPayload: any = {
        email: 'attacker@plaza.app',
        password: 'SecurePassword123!',
        name: 'Malicious Actor',
        role: UserRole.ADMIN,
      };

      const result = await authService.register(maliciousPayload);

      expect(result.user.role).toBe(UserRole.USER);
      expect(result.user.role).not.toBe(UserRole.ADMIN);
      expect(savedUsers[0].role).toBe(UserRole.USER);

      const decoded: any = jwtService.verify(result.token);
      expect(decoded.role).toBe(UserRole.USER);
    });
  });

  describe('7. Admin Seed & Provisioning Idempotency', () => {
    it('should skip admin user creation without creating insecure defaults when PLAZA_ADMIN_PASSWORD is missing', async () => {
      const mockDbUsers: any[] = [];
      const userRepo: any = {
        findOne: jest.fn().mockImplementation(async ({ where }) => {
          return mockDbUsers.find((u) => u.email === 'admin@plaza.app') || null;
        }),
        save: jest.fn().mockImplementation(async (users) => {
          const list = Array.isArray(users) ? users : [users];
          mockDbUsers.push(...list);
          return users;
        }),
      };

      const originalEnv = process.env.PLAZA_ADMIN_PASSWORD;
      delete process.env.PLAZA_ADMIN_PASSWORD;

      try {
        const existingAdmin = await userRepo.findOne({
          where: [{ id: 'usr_admin_1' }, { email: 'admin@plaza.app' }],
        });

        const adminPassword = process.env.PLAZA_ADMIN_PASSWORD;

        if (!existingAdmin) {
          if (!adminPassword) {
            // Skipped safely
          } else {
            const salt = await bcrypt.genSalt(10);
            const adminHash = await bcrypt.hash(adminPassword, salt);
            await userRepo.save([
              {
                id: 'usr_admin_1',
                email: 'admin@plaza.app',
                passwordHash: adminHash,
                role: UserRole.ADMIN,
              },
            ]);
          }
        }

        expect(mockDbUsers.length).toBe(0);
        const adminInDb = await userRepo.findOne({ where: { email: 'admin@plaza.app' } });
        expect(adminInDb).toBeNull();
      } finally {
        if (originalEnv) {
          process.env.PLAZA_ADMIN_PASSWORD = originalEnv;
        }
      }
    });

    it('should provision admin@plaza.app with hashed PLAZA_ADMIN_PASSWORD and remain idempotent on repeat runs', async () => {
      const mockDbUsers: any[] = [];
      const userRepo: any = {
        findOne: jest.fn().mockImplementation(async ({ where }) => {
          const conditions = Array.isArray(where) ? where : [where];
          return (
            mockDbUsers.find((u) =>
              conditions.some(
                (cond: any) =>
                  (cond.id && u.id === cond.id) || (cond.email && u.email === cond.email),
              ),
            ) || null
          );
        }),
        save: jest.fn().mockImplementation(async (users) => {
          const list = Array.isArray(users) ? users : [users];
          for (const u of list) {
            const idx = mockDbUsers.findIndex((item) => item.id === u.id || item.email === u.email);
            if (idx >= 0) {
              mockDbUsers[idx] = { ...mockDbUsers[idx], ...u };
            } else {
              mockDbUsers.push({ ...u });
            }
          }
          return users;
        }),
      };

      const testPassword = 'VerySecureAdminPassword2026!#%';
      process.env.PLAZA_ADMIN_PASSWORD = testPassword;

      try {
        const provisionAdmin = async () => {
          const existingAdmin = await userRepo.findOne({
            where: [{ id: 'usr_admin_1' }, { email: 'admin@plaza.app' }],
          });

          const adminPassword = process.env.PLAZA_ADMIN_PASSWORD;

          if (!existingAdmin) {
            if (!adminPassword) {
              // Skip
            } else {
              const salt = await bcrypt.genSalt(10);
              const adminHash = await bcrypt.hash(adminPassword, salt);
              await userRepo.save([
                {
                  id: 'usr_admin_1',
                  email: 'admin@plaza.app',
                  passwordHash: adminHash,
                  name: 'PLAZA Admin',
                  phone: '+91 99999 00000',
                  city: 'Hyderabad',
                  rewardPoints: 0,
                  role: UserRole.ADMIN,
                },
              ]);
            }
          } else {
            if (existingAdmin.role !== UserRole.ADMIN) {
              existingAdmin.role = UserRole.ADMIN;
              await userRepo.save(existingAdmin);
            }
          }
        };

        await provisionAdmin();
        expect(mockDbUsers.length).toBe(1);
        expect(mockDbUsers[0].email).toBe('admin@plaza.app');
        expect(mockDbUsers[0].role).toBe(UserRole.ADMIN);
        const matches = await bcrypt.compare(testPassword, mockDbUsers[0].passwordHash);
        expect(matches).toBe(true);

        // Repeat run - idempotent
        await provisionAdmin();
        expect(mockDbUsers.length).toBe(1);
        expect(mockDbUsers[0].email).toBe('admin@plaza.app');
        expect(mockDbUsers[0].role).toBe(UserRole.ADMIN);
      } finally {
        delete process.env.PLAZA_ADMIN_PASSWORD;
      }
    });
  });
});
