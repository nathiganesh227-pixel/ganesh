import {
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';

import { PartnersService } from './modules/partners/partners.service';
import { PartnersController } from './modules/partners/partners.controller';
import { PartnerAdminController } from './modules/partners/partner-admin.controller';
import { PartnerTenantGuard } from './modules/partners/guards/partner-tenant.guard';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import { RolesGuard } from './modules/auth/guards/roles.guard';
import { ROLES_KEY } from './modules/auth/decorators/roles.decorator';

import { User, UserRole } from './database/entities/user.entity';
import {
  PartnerEntity,
  PartnerStatus,
  PartnerType,
} from './database/entities/partner.entity';
import { PartnerUserEntity } from './database/entities/partner-user.entity';
import {
  PartnerBusinessEntity,
  BusinessStatus,
} from './database/entities/partner-business.entity';
import {
  PartnerDocumentEntity,
  DocumentStatus,
} from './database/entities/partner-document.entity';
import { PartnerApprovalEntity } from './database/entities/partner-approval.entity';
import {
  PartnerInvitationEntity,
  InvitationStatus,
} from './database/entities/partner-invitation.entity';
import {
  PartnerPayoutProfileEntity,
  PayoutStatus,
} from './database/entities/partner-payout-profile.entity';
import { PartnerAuditLogEntity } from './database/entities/partner-audit-log.entity';
import { BookingEntity, BookingStatus, BookingType } from './database/entities/booking.entity';
import { RestaurantEntity } from './database/entities/restaurant.entity';
import { EventEntity } from './database/entities/event.entity';
import { ActivityEntity } from './database/entities/activity.entity';
import { HotelEntity } from './database/entities/hotel.entity';
import { SportsVenueEntity } from './database/entities/sports-venue.entity';
import { AdminController } from './modules/admin/admin.controller';

describe('Phase 22 — Real Partner/Vendor System (Two-Gate Multi-Tenant)', () => {
  const TEST_JWT_SECRET = 'test_phase22_partner_vendor_secret_2026';
  let jwtService: JwtService;
  let partnersService: PartnersService;
  let partnersController: PartnersController;
  let partnerAdminController: PartnerAdminController;
  let partnerTenantGuard: PartnerTenantGuard;
  let jwtAuthGuard: JwtAuthGuard;
  let rolesGuard: RolesGuard;
  let reflector: Reflector;

  // In-memory repositories
  let mockPartners: PartnerEntity[] = [];
  let mockPartnerUsers: PartnerUserEntity[] = [];
  let mockPartnerBusinesses: PartnerBusinessEntity[] = [];
  let mockPartnerDocs: PartnerDocumentEntity[] = [];
  let mockPartnerApprovals: PartnerApprovalEntity[] = [];
  let mockPartnerInvs: PartnerInvitationEntity[] = [];
  let mockPayoutProfiles: PartnerPayoutProfileEntity[] = [];
  let mockPartnerAudits: PartnerAuditLogEntity[] = [];
  let mockUsers: User[] = [];
  let mockBookings: BookingEntity[] = [];
  let mockRestaurants: RestaurantEntity[] = [];
  let mockEvents: EventEntity[] = [];
  let mockActivities: ActivityEntity[] = [];
  let mockHotels: HotelEntity[] = [];
  let mockSportsVenues: SportsVenueEntity[] = [];

  // Mock repos
  let mockPartnerRepo: any;
  let mockPartnerUserRepo: any;
  let mockPartnerBusinessRepo: any;
  let mockPartnerDocRepo: any;
  let mockPartnerApprovalRepo: any;
  let mockPartnerInvRepo: any;
  let mockPayoutProfileRepo: any;
  let mockPartnerAuditRepo: any;
  let mockUserRepo: any;
  let mockBookingRepo: any;
  let mockRestaurantRepo: any;
  let mockEventRepo: any;
  let mockActivityRepo: any;
  let mockHotelRepo: any;
  let mockSportsVenueRepo: any;

  beforeEach(() => {
    jwtService = new JwtService({
      secret: TEST_JWT_SECRET,
      signOptions: { expiresIn: '1h' },
    });

    mockUsers = [
      {
        id: 'usr_admin_1',
        email: 'admin@plaza.app',
        name: 'Plaza Admin',
        role: UserRole.ADMIN,
      } as User,
      {
        id: 'usr_operator_1',
        email: 'operator@plaza.app',
        name: 'Plaza Operator',
        role: UserRole.OPERATOR,
      } as User,
      {
        id: 'usr_partner_owner_1',
        email: 'owner@spicegarden.com',
        name: 'Suresh Babu',
        role: UserRole.PARTNER_OWNER,
      } as User,
      {
        id: 'usr_partner_owner_2',
        email: 'owner@novotelhyd.com',
        name: 'Hotel GM',
        role: UserRole.PARTNER_OWNER,
      } as User,
      {
        id: 'usr_customer_1',
        email: 'customer@gmail.com',
        name: 'Ganesh Nathi',
        role: UserRole.USER,
      } as User,
    ];

    mockPartners = [];
    mockPartnerUsers = [];
    mockPartnerBusinesses = [];
    mockPartnerDocs = [];
    mockPartnerApprovals = [];
    mockPartnerInvs = [];
    mockPayoutProfiles = [];
    mockPartnerAudits = [];
    mockBookings = [];
    mockRestaurants = [];
    mockEvents = [];
    mockActivities = [];
    mockHotels = [];
    mockSportsVenues = [];

    mockPartnerRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (p: PartnerEntity) => {
        const idx = mockPartners.findIndex((x) => x.id === p.id);
        if (idx >= 0) mockPartners[idx] = { ...mockPartners[idx], ...p };
        else mockPartners.push(p);
        return p;
      }),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockPartners.find((p) => p.id === where?.id || p.email === where?.email) || null;
      }),
      find: jest.fn().mockImplementation(async () => mockPartners),
      createQueryBuilder: jest.fn().mockReturnValue({
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockImplementation(async () => [mockPartners, mockPartners.length]),
      }),
    };

    mockPartnerUserRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (pu: PartnerUserEntity) => {
        const idx = mockPartnerUsers.findIndex((x) => x.id === pu.id);
        if (idx >= 0) mockPartnerUsers[idx] = { ...mockPartnerUsers[idx], ...pu };
        else mockPartnerUsers.push(pu);
        return pu;
      }),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return (
          mockPartnerUsers.find((pu) => {
            if (where.partnerId && pu.partnerId !== where.partnerId) return false;
            if (where.userId && pu.userId !== where.userId) return false;
            if (where.isActive !== undefined && pu.isActive !== where.isActive) return false;
            return true;
          }) || null
        );
      }),
      find: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockPartnerUsers.filter((pu) => !where?.partnerId || pu.partnerId === where.partnerId);
      }),
      count: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockPartnerUsers.filter(
          (pu) => (!where?.partnerId || pu.partnerId === where.partnerId) && (!where?.isActive || pu.isActive === where.isActive),
        ).length;
      }),
    };

    mockPartnerBusinessRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (b: PartnerBusinessEntity) => {
        const idx = mockPartnerBusinesses.findIndex((x) => x.id === b.id);
        if (idx >= 0) mockPartnerBusinesses[idx] = { ...mockPartnerBusinesses[idx], ...b };
        else mockPartnerBusinesses.push(b);
        return b;
      }),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return (
          mockPartnerBusinesses.find((b) => {
            if (where.id && b.id !== where.id) return false;
            if (where.partnerId && b.partnerId !== where.partnerId) return false;
            return true;
          }) || null
        );
      }),
      find: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockPartnerBusinesses.filter((b) => !where?.partnerId || b.partnerId === where.partnerId);
      }),
      count: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockPartnerBusinesses.filter((b) => !where?.partnerId || b.partnerId === where.partnerId).length;
      }),
    };

    mockPartnerDocRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (doc: PartnerDocumentEntity) => {
        const idx = mockPartnerDocs.findIndex((x) => x.id === doc.id);
        if (idx >= 0) mockPartnerDocs[idx] = { ...mockPartnerDocs[idx], ...doc };
        else mockPartnerDocs.push(doc);
        return doc;
      }),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockPartnerDocs.find((d) => d.id === where?.id && (!where.partnerId || d.partnerId === where.partnerId)) || null;
      }),
      find: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockPartnerDocs.filter((d) => !where?.partnerId || d.partnerId === where.partnerId);
      }),
      count: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockPartnerDocs.filter((d) => !where?.partnerId || d.partnerId === where.partnerId).length;
      }),
    };

    mockPartnerApprovalRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (a: PartnerApprovalEntity) => {
        mockPartnerApprovals.push(a);
        return a;
      }),
      find: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockPartnerApprovals.filter((a) => !where?.partnerId || a.partnerId === where.partnerId);
      }),
    };

    mockPartnerInvRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (inv: PartnerInvitationEntity) => {
        mockPartnerInvs.push(inv);
        return inv;
      }),
    };

    mockPayoutProfileRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (p: PartnerPayoutProfileEntity) => {
        const idx = mockPayoutProfiles.findIndex((x) => x.id === p.id);
        if (idx >= 0) mockPayoutProfiles[idx] = { ...mockPayoutProfiles[idx], ...p };
        else mockPayoutProfiles.push(p);
        return p;
      }),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockPayoutProfiles.find((p) => p.partnerId === where?.partnerId) || null;
      }),
    };

    mockPartnerAuditRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (l: PartnerAuditLogEntity) => {
        mockPartnerAudits.push(l);
        return l;
      }),
      find: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockPartnerAudits.filter((l) => !where?.partnerId || l.partnerId === where.partnerId);
      }),
    };

    mockUserRepo = {
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockUsers.find((u) => u.id === where?.id || u.email === where?.email) || null;
      }),
      findByIds: jest.fn().mockImplementation(async (ids: string[]) => {
        return mockUsers.filter((u) => ids.includes(u.id));
      }),
      save: jest.fn().mockImplementation(async (u: User) => {
        const idx = mockUsers.findIndex((x) => x.id === u.id);
        if (idx >= 0) mockUsers[idx] = { ...mockUsers[idx], ...u };
        return u;
      }),
    };

    mockBookingRepo = {
      find: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockBookings.filter((b) => !where?.partnerId || b.partnerId === where.partnerId);
      }),
      findOne: jest.fn().mockImplementation(async ({ where }: any) => {
        return mockBookings.find((b) => b.id === where?.id && (!where.partnerId || b.partnerId === where.partnerId)) || null;
      }),
      save: jest.fn().mockImplementation(async (b: BookingEntity) => {
        const idx = mockBookings.findIndex((x) => x.id === b.id);
        if (idx >= 0) mockBookings[idx] = { ...mockBookings[idx], ...b };
        else mockBookings.push(b);
        return b;
      }),
      createQueryBuilder: jest.fn().mockImplementation(() => {
        let partnerFilter: string | null = null;
        const qb: any = {
          where: jest.fn().mockImplementation((clause: string, params?: any) => {
            if (params?.partnerId) partnerFilter = params.partnerId;
            return qb;
          }),
          andWhere: jest.fn().mockReturnThis(),
          orderBy: jest.fn().mockReturnThis(),
          getMany: jest.fn().mockImplementation(async () => {
            if (partnerFilter) {
              return mockBookings.filter((b) => b.partnerId === partnerFilter);
            }
            return mockBookings;
          }),
        };
        return qb;
      }),
    };

    mockRestaurantRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (r: RestaurantEntity) => {
        mockRestaurants.push(r);
        return r;
      }),
      update: jest.fn().mockImplementation(async (id: string, updates: any) => {
        const r = mockRestaurants.find((x) => x.id === id);
        if (r) Object.assign(r, updates);
      }),
    };

    mockEventRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (e: EventEntity) => {
        mockEvents.push(e);
        return e;
      }),
      update: jest.fn().mockImplementation(async (id: string, updates: any) => {
        const e = mockEvents.find((x) => x.id === id);
        if (e) Object.assign(e, updates);
      }),
    };

    mockActivityRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (a: ActivityEntity) => {
        mockActivities.push(a);
        return a;
      }),
      update: jest.fn().mockImplementation(async (id: string, updates: any) => {
        const a = mockActivities.find((x) => x.id === id);
        if (a) Object.assign(a, updates);
      }),
    };

    mockHotelRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (h: HotelEntity) => {
        mockHotels.push(h);
        return h;
      }),
      update: jest.fn().mockImplementation(async (id: string, updates: any) => {
        const h = mockHotels.find((x) => x.id === id);
        if (h) Object.assign(h, updates);
      }),
    };

    mockSportsVenueRepo = {
      create: jest.fn().mockImplementation((d) => ({ ...d })),
      save: jest.fn().mockImplementation(async (s: SportsVenueEntity) => {
        mockSportsVenues.push(s);
        return s;
      }),
      update: jest.fn().mockImplementation(async (id: string, updates: any) => {
        const s = mockSportsVenues.find((x) => x.id === id);
        if (s) Object.assign(s, updates);
      }),
    };

    partnersService = new PartnersService(
      mockPartnerRepo,
      mockPartnerUserRepo,
      mockPartnerBusinessRepo,
      mockPartnerDocRepo,
      mockPartnerApprovalRepo,
      mockPartnerInvRepo,
      mockPayoutProfileRepo,
      mockPartnerAuditRepo,
      mockUserRepo,
      mockBookingRepo,
      mockRestaurantRepo,
      mockEventRepo,
      mockActivityRepo,
      mockHotelRepo,
      mockSportsVenueRepo,
    );

    partnersController = new PartnersController(partnersService);
    partnerAdminController = new PartnerAdminController(partnersService);

    partnerTenantGuard = new PartnerTenantGuard(mockPartnerUserRepo);
    jwtAuthGuard = new JwtAuthGuard(jwtService);
    reflector = new Reflector();
    rolesGuard = new RolesGuard(reflector);
  });

  // Helpers
  function createToken(payload: { sub: string; email: string; role: UserRole }): string {
    return jwtService.sign(payload);
  }

  // ---------------- 1. ONBOARDING & GATE 1 (BUSINESS LEGITIMACY) ----------------
  describe('1. Partner Onboarding & Gate 1 Business Verification', () => {
    it('should complete initial onboarding, create partner in DRAFT state, and assign PARTNER_OWNER', async () => {
      const onboardDto = {
        legalName: 'Spice Garden Hospitality Pvt Ltd',
        displayName: 'Spice Garden Fine Dining',
        partnerType: PartnerType.RESTAURANT,
        email: 'owner@spicegarden.com',
        phone: '+91 98765 00001',
        city: 'Hyderabad',
        state: 'Telangana',
        address: 'Plot 42, Hitec City',
        pinCode: '500081',
        gstNumber: '36AABCS1429B1Z1',
        panNumber: 'AABCS1429B',
      };

      const result = await partnersService.onboardPartner(onboardDto, {
        sub: 'usr_partner_owner_1',
        email: 'owner@spicegarden.com',
        role: UserRole.USER,
      });

      expect(result.partner.id).toBeDefined();
      expect(result.partner.status).toBe(PartnerStatus.DRAFT);
      expect(result.membership.role).toBe(UserRole.PARTNER_OWNER);

      // Verify audit log generated
      expect(mockPartnerAudits.length).toBeGreaterThan(0);
      expect(mockPartnerAudits[0].action).toBe('PARTNER_REGISTERED');
    });

    it('should upload documents and submit for review (DRAFT -> SUBMITTED)', async () => {
      // Setup existing partner
      const partner = await mockPartnerRepo.save({
        id: 'prt_spice_1',
        legalName: 'Spice Garden',
        displayName: 'Spice Garden',
        status: PartnerStatus.DRAFT,
      });

      // Upload mandatory FSSAI food license
      const doc = await partnersService.uploadDocument(
        partner.id,
        {
          documentType: 'fssai_license',
          fileName: 'fssai_certificate.pdf',
          fileUrl: 'https://cdn.plaza.app/docs/fssai_123.pdf',
          fileSize: 204800,
        },
        { sub: 'usr_partner_owner_1', email: 'owner@spicegarden.com' },
      );
      expect(doc.status).toBe(DocumentStatus.PENDING);

      // Submit for review
      const submitted = await partnersService.submitPartnerForReview(partner.id, {
        sub: 'usr_partner_owner_1',
        email: 'owner@spicegarden.com',
      });
      expect(submitted.status).toBe(PartnerStatus.SUBMITTED);
      expect(mockPartnerApprovals.some((a) => a.action === 'submit')).toBe(true);
    });

    it('should REJECT partner submission if no documents were uploaded', async () => {
      await mockPartnerRepo.save({
        id: 'prt_empty_1',
        status: PartnerStatus.DRAFT,
      });

      await expect(
        partnersService.submitPartnerForReview('prt_empty_1', { sub: 'usr_partner_owner_1' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('Gate 1 Approval: PLAZA Admin can approve partner organization', async () => {
      await mockPartnerRepo.save({
        id: 'prt_spice_1',
        displayName: 'Spice Garden',
        status: PartnerStatus.SUBMITTED,
      });

      const res = await partnersService.adminReviewPartner(
        'prt_spice_1',
        { action: 'approve' },
        { sub: 'usr_admin_1', email: 'admin@plaza.app', role: UserRole.ADMIN },
      );

      expect(res.success).toBe(true);
      expect(res.partner.status).toBe(PartnerStatus.APPROVED);
      expect(mockPartnerApprovals.some((a) => a.action === 'approve')).toBe(true);
    });

    it('Gate 1 Separation: Admin cannot approve their own partner organization', async () => {
      // Admin is also a member of this partner
      await mockPartnerRepo.save({
        id: 'prt_conflict_1',
        status: PartnerStatus.SUBMITTED,
      });
      await mockPartnerUserRepo.save({
        id: 'pu_conflict_1',
        partnerId: 'prt_conflict_1',
        userId: 'usr_admin_1',
        isActive: true,
      });

      await expect(
        partnersService.adminReviewPartner(
          'prt_conflict_1',
          { action: 'approve' },
          { sub: 'usr_admin_1', email: 'admin@plaza.app', role: UserRole.ADMIN },
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('Gate 1 Rejection: Admin must provide an explanation reason upon rejection', async () => {
      await mockPartnerRepo.save({
        id: 'prt_spice_1',
        status: PartnerStatus.SUBMITTED,
      });

      // Missing reason should fail
      await expect(
        partnersService.adminReviewPartner(
          'prt_spice_1',
          { action: 'reject' as any },
          { sub: 'usr_admin_1', email: 'admin@plaza.app' },
        ),
      ).rejects.toThrow(BadRequestException);

      // With reason succeeds
      const res = await partnersService.adminReviewPartner(
        'prt_spice_1',
        { action: 'reject', reason: 'FSSAI License registration number is expired' },
        { sub: 'usr_admin_1', email: 'admin@plaza.app' },
      );
      expect(res.partner.status).toBe(PartnerStatus.REJECTED);
      expect(res.partner.rejectionReason).toContain('expired');
    });
  });

  // ---------------- 2. GATE 2 (LISTING & PUBLICATION GATES) ----------------
  describe('2. Gate 2 Listing Review & Publication Gates', () => {
    it('should PREVENT creating listings if Partner is NOT yet approved (Gate 1 incomplete)', async () => {
      await mockPartnerRepo.save({
        id: 'prt_unapproved_1',
        status: PartnerStatus.DRAFT, // Not approved
      });

      await expect(
        partnersService.createBusinessListing(
          'prt_unapproved_1',
          {
            vertical: 'dining',
            name: 'Fine Dine 101',
            description: 'Luxury food',
            address: 'Hitec City',
            city: 'Hyderabad',
            contactPhone: '+91 99999 11111',
            contactEmail: 'info@finedine.com',
          },
          { sub: 'usr_partner_owner_1' },
        ),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should create listing in DRAFT state when partner is approved, creating unapproved catalog shadow', async () => {
      await mockPartnerRepo.save({
        id: 'prt_approved_1',
        status: PartnerStatus.APPROVED,
      });

      const listing = await partnersService.createBusinessListing(
        'prt_approved_1',
        {
          vertical: 'dining',
          name: 'The Royal Bistro',
          description: 'Authentic Nawabi cuisine',
          address: 'Road 36, Jubilee Hills',
          city: 'Hyderabad',
          contactPhone: '+91 98765 43210',
          contactEmail: 'royal@bistro.com',
          metadata: { priceForTwo: 1800 },
        },
        { sub: 'usr_partner_owner_1' },
      );

      expect(listing.id).toBeDefined();
      expect(listing.status).toBe(BusinessStatus.DRAFT);
      expect(listing.catalogEntityId).toBeDefined();

      // Check shadow catalog entity is unapproved and unpublished
      const restaurant = mockRestaurants.find((r) => r.id === listing.catalogEntityId);
      expect(restaurant).toBeDefined();
      expect(restaurant?.isPublished).toBe(false);
      expect(restaurant?.approvalStatus).toBe('UNDER_REVIEW');
    });

    it('Gate 2 Guardrail: Partner CANNOT publish an unapproved listing directly', async () => {
      await mockPartnerRepo.save({ id: 'prt_approved_1', status: PartnerStatus.APPROVED });
      const business = await mockPartnerBusinessRepo.save({
        id: 'pb_royal_1',
        partnerId: 'prt_approved_1',
        status: BusinessStatus.DRAFT, // Not yet approved by Admin
        vertical: 'dining',
      });

      await expect(
        partnersService.publishListing('prt_approved_1', 'pb_royal_1', { sub: 'usr_partner_owner_1' }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('Gate 2 Approval: Admin approval of listing allows partner to publish to live customers', async () => {
      await mockPartnerRepo.save({ id: 'prt_approved_1', status: PartnerStatus.APPROVED });
      const business = await mockPartnerBusinessRepo.save({
        id: 'pb_royal_1',
        partnerId: 'prt_approved_1',
        name: 'The Royal Bistro',
        status: BusinessStatus.SUBMITTED,
        vertical: 'dining',
        catalogEntityId: 'cat_royal_1',
      });
      mockRestaurants.push({
        id: 'cat_royal_1',
        name: 'The Royal Bistro',
        isPublished: false,
        approvalStatus: 'UNDER_REVIEW',
      } as unknown as RestaurantEntity);

      // 1. Admin approves Gate 2
      const reviewRes = await partnersService.adminReviewListing(
        'prt_approved_1',
        'pb_royal_1',
        { action: 'approve' },
        { sub: 'usr_admin_1', email: 'admin@plaza.app' },
      );
      expect(reviewRes.business.status).toBe(BusinessStatus.APPROVED);

      // 2. Partner publishes listing
      const pubRes = await partnersService.publishListing('prt_approved_1', 'pb_royal_1', {
        sub: 'usr_partner_owner_1',
      });
      expect(pubRes.success).toBe(true);

      const r = mockRestaurants.find((x) => x.id === 'cat_royal_1');
      expect(r?.isPublished).toBe(true);
    });
  });

  // ---------------- 3. STRICT MULTI-TENANT ISOLATION ----------------
  describe('3. Strict Multi-Tenant Server-Side Ownership Isolation', () => {
    it('PartnerTenantGuard blocks Partner A from accessing Partner B tenant resources (IDOR Protection)', async () => {
      // Partner 1 owned by usr_partner_owner_1
      await mockPartnerUserRepo.save({
        id: 'pu_owner_1',
        partnerId: 'prt_partner_1',
        userId: 'usr_partner_owner_1',
        isActive: true,
      });

      // Partner 2 owned by usr_partner_owner_2
      await mockPartnerUserRepo.save({
        id: 'pu_owner_2',
        partnerId: 'prt_partner_2',
        userId: 'usr_partner_owner_2',
        isActive: true,
      });

      // usr_partner_owner_1 attempts to access prt_partner_2
      const mockContext = {
        switchToHttp: () => ({
          getRequest: () => ({
            user: { sub: 'usr_partner_owner_1', role: UserRole.PARTNER_OWNER },
            params: { id: 'prt_partner_2' },
          }),
        }),
      } as unknown as ExecutionContext;

      await expect(partnerTenantGuard.canActivate(mockContext)).rejects.toThrow(ForbiddenException);
    });

    it('PartnerTenantGuard allows platform ADMIN full access to any partner tenant', async () => {
      const mockContext = {
        switchToHttp: () => ({
          getRequest: () => ({
            user: { sub: 'usr_admin_1', role: UserRole.ADMIN },
            params: { id: 'prt_partner_2' },
          }),
        }),
      } as unknown as ExecutionContext;

      const canActivate = await partnerTenantGuard.canActivate(mockContext);
      expect(canActivate).toBe(true);
    });
  });

  // ---------------- 4. SCOPED BOOKINGS & CUSTOMER CHECK-IN ----------------
  describe('4. Scoped Bookings & QR Check-In', () => {
    it('should return bookings scoped exclusively to the partner tenant', async () => {
      mockBookings = [
        {
          id: 'bk_1',
          partnerId: 'prt_spice_1',
          title: 'Spice Garden Table 4',
          totalPrice: 1500,
          status: BookingStatus.CONFIRMED,
          metadata: { customerName: 'Ravi Kumar' },
          createdAt: new Date(),
        } as unknown as BookingEntity,
        {
          id: 'bk_2',
          partnerId: 'prt_hotel_2', // Other partner
          title: 'Novotel Suite 202',
          totalPrice: 8500,
          status: BookingStatus.CONFIRMED,
          metadata: { customerName: 'Ananya Sharma' },
          createdAt: new Date(),
        } as unknown as BookingEntity,
      ];

      const bookings = await partnersService.getPartnerBookings('prt_spice_1');
      expect(bookings.length).toBe(1);
      expect(bookings[0].id).toBe('bk_1');
      expect(bookings[0].title).toContain('Spice Garden');
    });

    it('should check in customer pass at venue and transition booking to COMPLETED', async () => {
      mockBookings = [
        {
          id: 'bk_checkin_1',
          partnerId: 'prt_spice_1',
          title: 'Spice Garden Table 4',
          status: BookingStatus.CONFIRMED,
        } as unknown as BookingEntity,
      ];

      const res = await partnersService.checkInCustomer('prt_spice_1', 'bk_checkin_1', {
        sub: 'usr_partner_owner_1',
      });
      expect(res.success).toBe(true);
      expect(res.booking.status).toBe(BookingStatus.COMPLETED);
    });
  });

  // ---------------- 5. STAFF INVITATIONS & PAYOUT SECURITY ----------------
  describe('5. Staff Invitations & Payout Protection', () => {
    it('should invite staff member with unique invitation code', async () => {
      await mockPartnerRepo.save({ id: 'prt_spice_1' });

      const invite = await partnersService.inviteStaff(
        'prt_spice_1',
        { email: 'manager@spicegarden.com', role: UserRole.PARTNER_MANAGER },
        { sub: 'usr_partner_owner_1', email: 'owner@spicegarden.com' },
      );

      expect(invite.invitationCode).toBeDefined();
      expect(invite.invitedRole).toBe(UserRole.PARTNER_MANAGER);
      expect(invite.status).toBe(InvitationStatus.PENDING);
    });

    it('should never expose full bank account numbers in payout profile projections', async () => {
      await mockPayoutProfileRepo.save({
        id: 'payprof_1',
        partnerId: 'prt_spice_1',
        accountHolderName: 'Spice Garden Pvt Ltd',
        bankName: 'HDFC Bank',
        accountNumberMasked: '••••••••4892',
        accountNumberEncrypted: 'sensitive_encrypted_blob',
        ifscCode: 'HDFC0001234',
        payoutStatus: PayoutStatus.VERIFIED,
      });

      const profile = await partnersService.getPayoutProfile('prt_spice_1');
      expect(profile.accountNumberMasked).toBe('••••••••4892');
      // Verify raw encrypted account number is omitted from returned projection
      expect((profile as any).accountNumberEncrypted).toBeUndefined();
    });
  });

  // ---------------- 6. SUSPENSION & REINSTATEMENT ----------------
  describe('6. Suspension & Reinstatement Workflow', () => {
    it('should suspend partner and take all active listings offline automatically', async () => {
      await mockPartnerRepo.save({
        id: 'prt_spice_1',
        displayName: 'Spice Garden',
        status: PartnerStatus.APPROVED,
      });

      mockPartnerBusinesses = [
        {
          id: 'pb_1',
          partnerId: 'prt_spice_1',
          vertical: 'dining',
          catalogEntityId: 'cat_r1',
        } as unknown as PartnerBusinessEntity,
      ];
      mockRestaurants = [
        { id: 'cat_r1', isPublished: true } as unknown as RestaurantEntity,
      ];

      const res = await partnersService.adminSuspendPartner(
        'prt_spice_1',
        { reason: 'Severe food safety complaint under investigation' },
        { sub: 'usr_admin_1', email: 'admin@plaza.app' },
      );

      expect(res.partner.status).toBe(PartnerStatus.SUSPENDED);
      expect(res.partner.suspensionReason).toContain('food safety');

      // Check catalog shadow was automatically unpublished
      const r = mockRestaurants.find((x) => x.id === 'cat_r1');
      expect(r?.isPublished).toBe(false);
    });
  });

  // ---------------- 7. ROUTE ALIASING (PHASE 21 AUDIT FIX) ----------------
  describe('7. Route Aliasing & Operations Paths', () => {
    it('AdminController routes support both flat and operations/ path variants', () => {
      const healthMetadata = Reflect.getMetadata('path', AdminController.prototype.getHealth);
      expect(healthMetadata).toEqual(['health', 'operations/health']);

      const searchMetadata = Reflect.getMetadata('path', AdminController.prototype.search);
      expect(searchMetadata).toEqual(['search', 'operations/search']);

      const incidentsMetadata = Reflect.getMetadata('path', AdminController.prototype.getIncidents);
      expect(incidentsMetadata).toEqual(['incidents', 'operations/incidents']);
    });
  });
});
