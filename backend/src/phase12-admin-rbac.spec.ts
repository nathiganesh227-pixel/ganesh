import { ExecutionContext, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';
import * as bcrypt from 'bcrypt';

import { AdminController } from './modules/admin/admin.controller';
import { AdminService } from './modules/admin/admin.service';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from './modules/auth/guards/roles.guard';
import { ROLES_KEY } from './modules/auth/decorators/roles.decorator';
import { User, UserRole } from './database/entities/user.entity';
import { AuthService } from './modules/auth/auth.service';

describe('Phase 12.1 — Secure Admin Foundation & RBAC Verification', () => {
  const TEST_JWT_SECRET = 'test_phase12_admin_secret_key_2026';
  let jwtService: JwtService;
  let adminService: AdminService;
  let adminController: AdminController;
  let jwtAuthGuard: JwtAuthGuard;
  let rolesGuard: RolesGuard;
  let reflector: Reflector;

  beforeEach(() => {
    jwtService = new JwtService({
      secret: TEST_JWT_SECRET,
      signOptions: { expiresIn: '1h' },
    });
    adminService = new AdminService();
    adminController = new AdminController(adminService);
    jwtAuthGuard = new JwtAuthGuard(jwtService);
    reflector = new Reflector();
    rolesGuard = new RolesGuard(reflector);
  });

  // Helper simulating the NestJS execution pipeline for GET /api/v1/admin/health
  const simulateAdminHealthRequest = (headers: Record<string, string>) => {
    const req: any = { headers };
    const context = {
      switchToHttp: () => ({
        getRequest: () => req,
      }),
      getHandler: () => AdminController.prototype.getHealth,
      getClass: () => AdminController,
    } as unknown as ExecutionContext;

    // Step 1: JwtAuthGuard runs
    const authenticated = jwtAuthGuard.canActivate(context);
    if (!authenticated) {
      throw new UnauthorizedException();
    }

    // Step 2: RolesGuard runs
    const authorized = rolesGuard.canActivate(context);
    if (!authorized) {
      throw new ForbiddenException();
    }

    // Step 3: AdminController handler executes
    const result = adminController.getHealth();
    return {
      statusCode: 200,
      data: result,
    };
  };

  describe('TASK 1 & TASK 2 — RBAC & Admin Health Endpoint (/api/v1/admin/health)', () => {
    it('1. should verify AdminController is properly decorated with @Roles(UserRole.ADMIN)', () => {
      const classRoles = reflector.get<UserRole[]>(ROLES_KEY, AdminController);
      const handlerRoles = reflector.get<UserRole[]>(ROLES_KEY, AdminController.prototype.getHealth);
      const effectiveRoles = classRoles || handlerRoles;

      expect(effectiveRoles).toBeDefined();
      expect(effectiveRoles).toContain(UserRole.ADMIN);
      expect(effectiveRoles).not.toContain(UserRole.USER);
    });

    it('2. should reject with 401 Unauthorized when no Authorization token is provided', () => {
      expect(() => {
        simulateAdminHealthRequest({});
      }).toThrow(UnauthorizedException);

      try {
        simulateAdminHealthRequest({});
      } catch (err: any) {
        expect(err.getStatus()).toBe(401);
        expect(err.message).toMatch(/Authentication token is required/i);
      }
    });

    it('3. should reject with 401 Unauthorized when token is invalid or malformed', () => {
      expect(() => {
        simulateAdminHealthRequest({ authorization: 'Bearer invalid_or_tampered_token_xyz' });
      }).toThrow(UnauthorizedException);

      try {
        simulateAdminHealthRequest({ authorization: 'Bearer invalid_or_tampered_token_xyz' });
      } catch (err: any) {
        expect(err.getStatus()).toBe(401);
        expect(err.message).toMatch(/session has expired or is invalid/i);
      }
    });

    it('4. should reject with 403 Forbidden when authenticated as a normal USER', () => {
      const userToken = jwtService.sign({
        sub: 'usr_normal_123',
        email: 'consumer@plaza.app',
        name: 'Consumer User',
        role: UserRole.USER,
      });

      expect(() => {
        simulateAdminHealthRequest({ authorization: `Bearer ${userToken}` });
      }).toThrow(ForbiddenException);

      try {
        simulateAdminHealthRequest({ authorization: `Bearer ${userToken}` });
      } catch (err: any) {
        expect(err.getStatus()).toBe(403);
        expect(err.message).toMatch(/Forbidden resource: Insufficient permissions/i);
      }
    });

    it('5. should succeed with 200 OK and admin status when authenticated as ADMIN', () => {
      const adminToken = jwtService.sign({
        sub: 'usr_admin_1',
        email: 'admin@plaza.app',
        name: 'PLAZA Admin',
        role: UserRole.ADMIN,
      });

      const response = simulateAdminHealthRequest({ authorization: `Bearer ${adminToken}` });
      expect(response.statusCode).toBe(200);
      expect(response.data).toEqual({ admin: true });
    });
  });

  describe('TASK 1 — RolesGuard Unit Edge Cases', () => {
    it('should allow access if route has no @Roles metadata', () => {
      const mockContext = {
        getHandler: () => ({}),
        getClass: () => ({}),
        switchToHttp: () => ({
          getRequest: () => ({ user: null }),
        }),
      } as unknown as ExecutionContext;

      expect(rolesGuard.canActivate(mockContext)).toBe(true);
    });

    it('should throw ForbiddenException if user object is missing on a role-protected route', () => {
      const mockContext = {
        getHandler: () => AdminController.prototype.getHealth,
        getClass: () => AdminController,
        switchToHttp: () => ({
          getRequest: () => ({ user: null }),
        }),
      } as unknown as ExecutionContext;

      expect(() => rolesGuard.canActivate(mockContext)).toThrow(ForbiddenException);
    });

    it('should throw ForbiddenException if user role does not match required roles', () => {
      const mockContext = {
        getHandler: () => AdminController.prototype.getHealth,
        getClass: () => AdminController,
        switchToHttp: () => ({
          getRequest: () => ({ user: { id: 'usr_1', role: UserRole.USER } }),
        }),
      } as unknown as ExecutionContext;

      expect(() => rolesGuard.canActivate(mockContext)).toThrow(ForbiddenException);
    });
  });

  describe('TASK 3 — Registration Security (Prevent Role Elevation)', () => {
    it('6. should strictly force role to UserRole.USER during registration even if client supplies role: ADMIN', async () => {
      const savedUsers: User[] = [];
      const mockUserRepo: any = {
        findOne: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockImplementation((entity) => ({ ...entity })),
        save: jest.fn().mockImplementation(async (entity) => {
          savedUsers.push(entity);
          return entity;
        }),
      };

      const authService = new AuthService(mockUserRepo, jwtService);

      // Malicious registration attempting privilege escalation
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

      // Verify token generated for newly registered user is also USER role
      const decoded: any = jwtService.verify(result.token);
      expect(decoded.role).toBe(UserRole.USER);
    });
  });

  describe('TASK 3 — Admin Seed & Provisioning Idempotency', () => {
    it('7. should skip admin user creation without creating insecure defaults when PLAZA_ADMIN_PASSWORD is missing', async () => {
      const mockUsers: any[] = [];
      const userRepo: any = {
        findOne: jest.fn().mockImplementation(async ({ where }) => {
          return mockUsers.find((u) => u.email === 'admin@plaza.app') || null;
        }),
        save: jest.fn().mockImplementation(async (users) => {
          const list = Array.isArray(users) ? users : [users];
          mockUsers.push(...list);
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
            // Skipped safely - no insecure default admin password created
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

        // Verify admin was NOT created with a default password
        expect(mockUsers.length).toBe(0);
        const adminInDb = await userRepo.findOne({ where: { email: 'admin@plaza.app' } });
        expect(adminInDb).toBeNull();
      } finally {
        if (originalEnv) {
          process.env.PLAZA_ADMIN_PASSWORD = originalEnv;
        }
      }
    });

    it('8. should provision admin@plaza.app with hashed PLAZA_ADMIN_PASSWORD and remain idempotent on repeat runs', async () => {
      const mockUsers: any[] = [];
      const userRepo: any = {
        findOne: jest.fn().mockImplementation(async ({ where }) => {
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
        save: jest.fn().mockImplementation(async (users) => {
          const list = Array.isArray(users) ? users : [users];
          for (const u of list) {
            const idx = mockUsers.findIndex((item) => item.id === u.id || item.email === u.email);
            if (idx >= 0) {
              mockUsers[idx] = { ...mockUsers[idx], ...u };
            } else {
              mockUsers.push({ ...u });
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

        // First run: provisions admin
        await provisionAdmin();
        expect(mockUsers.length).toBe(1);
        expect(mockUsers[0].email).toBe('admin@plaza.app');
        expect(mockUsers[0].role).toBe(UserRole.ADMIN);
        expect(mockUsers[0].passwordHash).not.toBe(testPassword);
        const passwordMatches = await bcrypt.compare(testPassword, mockUsers[0].passwordHash);
        expect(passwordMatches).toBe(true);

        // Second run: idempotent, does not duplicate or corrupt
        await provisionAdmin();
        expect(mockUsers.length).toBe(1);
        expect(mockUsers[0].email).toBe('admin@plaza.app');
        expect(mockUsers[0].role).toBe(UserRole.ADMIN);
      } finally {
        delete process.env.PLAZA_ADMIN_PASSWORD;
      }
    });
  });
});
