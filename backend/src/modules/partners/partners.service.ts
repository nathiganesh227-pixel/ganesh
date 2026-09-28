import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from '../../database/entities/user.entity';
import {
  PartnerEntity,
  PartnerStatus,
  PartnerType,
} from '../../database/entities/partner.entity';
import { PartnerUserEntity } from '../../database/entities/partner-user.entity';
import {
  PartnerBusinessEntity,
  BusinessStatus,
} from '../../database/entities/partner-business.entity';
import {
  PartnerDocumentEntity,
  DocumentStatus,
} from '../../database/entities/partner-document.entity';
import {
  PartnerApprovalEntity,
  ApprovalAction,
} from '../../database/entities/partner-approval.entity';
import {
  PartnerInvitationEntity,
  InvitationStatus,
} from '../../database/entities/partner-invitation.entity';
import {
  PartnerPayoutProfileEntity,
  PayoutStatus,
} from '../../database/entities/partner-payout-profile.entity';
import { PartnerAuditLogEntity } from '../../database/entities/partner-audit-log.entity';
import { RestaurantEntity } from '../../database/entities/restaurant.entity';
import { EventEntity } from '../../database/entities/event.entity';
import { ActivityEntity } from '../../database/entities/activity.entity';
import { HotelEntity } from '../../database/entities/hotel.entity';
import { SportsVenueEntity } from '../../database/entities/sports-venue.entity';
import { BookingEntity, BookingStatus } from '../../database/entities/booking.entity';

import {
  OnboardPartnerDto,
  UpdatePartnerProfileDto,
  UploadDocumentDto,
  CreateBusinessListingDto,
  UpdateBusinessListingDto,
  InviteStaffDto,
  UpdatePayoutProfileDto,
  ReviewPartnerDto,
  SuspendPartnerDto,
  ReviewListingDto,
  ReviewDocumentDto,
} from './dto/partner.dto';

@Injectable()
export class PartnersService {
  constructor(
    @InjectRepository(PartnerEntity)
    private readonly partnerRepo: Repository<PartnerEntity>,
    @InjectRepository(PartnerUserEntity)
    private readonly partnerUserRepo: Repository<PartnerUserEntity>,
    @InjectRepository(PartnerBusinessEntity)
    private readonly partnerBusinessRepo: Repository<PartnerBusinessEntity>,
    @InjectRepository(PartnerDocumentEntity)
    private readonly partnerDocRepo: Repository<PartnerDocumentEntity>,
    @InjectRepository(PartnerApprovalEntity)
    private readonly partnerApprovalRepo: Repository<PartnerApprovalEntity>,
    @InjectRepository(PartnerInvitationEntity)
    private readonly partnerInvRepo: Repository<PartnerInvitationEntity>,
    @InjectRepository(PartnerPayoutProfileEntity)
    private readonly payoutProfileRepo: Repository<PartnerPayoutProfileEntity>,
    @InjectRepository(PartnerAuditLogEntity)
    private readonly partnerAuditRepo: Repository<PartnerAuditLogEntity>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(BookingEntity)
    private readonly bookingRepo: Repository<BookingEntity>,
    @InjectRepository(RestaurantEntity)
    private readonly restaurantRepo: Repository<RestaurantEntity>,
    @InjectRepository(EventEntity)
    private readonly eventRepo: Repository<EventEntity>,
    @InjectRepository(ActivityEntity)
    private readonly activityRepo: Repository<ActivityEntity>,
    @InjectRepository(HotelEntity)
    private readonly hotelRepo: Repository<HotelEntity>,
    @InjectRepository(SportsVenueEntity)
    private readonly sportsVenueRepo: Repository<SportsVenueEntity>,
  ) {}

  // ==========================================
  // PARTNER ONBOARDING & PROFILE (TENANT)
  // ==========================================

  async onboardPartner(dto: OnboardPartnerDto, actor: any) {
    const userId = actor?.sub || actor?.id;
    if (!userId) {
      throw new BadRequestException('Authenticated user ID missing');
    }

    const partnerId = `prt_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;

    const newPartner = this.partnerRepo.create({
      id: partnerId,
      legalName: dto.legalName,
      displayName: dto.displayName,
      partnerType: dto.partnerType,
      status: PartnerStatus.DRAFT,
      email: dto.email,
      phone: dto.phone,
      city: dto.city,
      state: dto.state,
      address: dto.address,
      pinCode: dto.pinCode,
      website: dto.website || null,
      gstNumber: dto.gstNumber || null,
      panNumber: dto.panNumber || null,
    });

    await this.partnerRepo.save(newPartner);

    // Create owner membership
    const ownerMembership = this.partnerUserRepo.create({
      id: `pu_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      partnerId,
      userId,
      role: UserRole.PARTNER_OWNER,
      isActive: true,
    });
    await this.partnerUserRepo.save(ownerMembership);

    // Upgrade user role if currently a standard user
    const dbUser = await this.userRepo.findOne({ where: { id: userId } });
    if (dbUser && dbUser.role === UserRole.USER) {
      dbUser.role = UserRole.PARTNER_OWNER;
      await this.userRepo.save(dbUser);
    }

    // Initialize blank payout profile
    const payout = this.payoutProfileRepo.create({
      id: `payprof_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      partnerId,
      accountHolderName: dto.legalName,
      bankName: 'Pending Setup',
      accountNumberMasked: '••••••••0000',
      accountNumberEncrypted: 'pending',
      ifscCode: 'PLZA0000000',
      payoutStatus: PayoutStatus.PENDING_VERIFICATION,
    });
    await this.payoutProfileRepo.save(payout);

    // Record audit log
    await this.recordAudit(
      partnerId,
      userId,
      actor?.email || 'unknown',
      UserRole.PARTNER_OWNER,
      'PARTNER_REGISTERED',
      'partner',
      partnerId,
      { legalName: dto.legalName, partnerType: dto.partnerType },
    );

    return {
      partner: newPartner,
      membership: ownerMembership,
    };
  }

  async getPartnerProfile(partnerId: string) {
    const partner = await this.partnerRepo.findOne({ where: { id: partnerId } });
    if (!partner) {
      throw new NotFoundException(`Partner with ID ${partnerId} not found`);
    }
    return partner;
  }

  async updatePartnerProfile(partnerId: string, dto: UpdatePartnerProfileDto, actor: any) {
    const partner = await this.getPartnerProfile(partnerId);

    if (dto.displayName) partner.displayName = dto.displayName;
    if (dto.address) partner.address = dto.address;
    if (dto.city) partner.city = dto.city;
    if (dto.phone) partner.phone = dto.phone;
    if (dto.website !== undefined) partner.website = dto.website;
    if (dto.gstNumber !== undefined) partner.gstNumber = dto.gstNumber;
    if (dto.panNumber !== undefined) partner.panNumber = dto.panNumber;

    await this.partnerRepo.save(partner);

    await this.recordAudit(
      partnerId,
      actor?.sub || actor?.id,
      actor?.email,
      actor?.role,
      'PARTNER_PROFILE_UPDATED',
      'partner',
      partnerId,
      dto,
    );

    return partner;
  }

  // ==========================================
  // DOCUMENT VERIFICATION (GATE 1)
  // ==========================================

  async uploadDocument(partnerId: string, dto: UploadDocumentDto, actor: any) {
    await this.getPartnerProfile(partnerId);

    const docId = `doc_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const newDoc = this.partnerDocRepo.create({
      id: docId,
      partnerId,
      documentType: dto.documentType,
      fileUrl: dto.fileUrl,
      fileName: dto.fileName,
      fileSize: dto.fileSize || 1024,
      status: DocumentStatus.PENDING,
      submittedAt: new Date(),
    });

    await this.partnerDocRepo.save(newDoc);

    await this.recordAudit(
      partnerId,
      actor?.sub || actor?.id,
      actor?.email,
      actor?.role,
      'DOCUMENT_UPLOADED',
      'document',
      docId,
      { documentType: dto.documentType, fileName: dto.fileName },
    );

    return newDoc;
  }

  async getPartnerDocuments(partnerId: string) {
    return this.partnerDocRepo.find({
      where: { partnerId },
      order: { createdAt: 'DESC' },
    });
  }

  async submitPartnerForReview(partnerId: string, actor: any) {
    const partner = await this.getPartnerProfile(partnerId);

    if (partner.status === PartnerStatus.APPROVED) {
      throw new BadRequestException('Partner is already approved');
    }

    const docs = await this.partnerDocRepo.find({ where: { partnerId } });
    if (docs.length === 0) {
      throw new BadRequestException('At least one verification document is required before submission');
    }

    partner.status = PartnerStatus.SUBMITTED;
    partner.rejectionReason = null;
    await this.partnerRepo.save(partner);

    // Record approval submission
    const approval = this.partnerApprovalRepo.create({
      id: `pappr_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      partnerId,
      targetType: 'partner',
      targetId: partnerId,
      action: ApprovalAction.SUBMIT,
      actorId: actor?.sub || actor?.id,
      actorEmail: actor?.email,
      actorRole: actor?.role,
      comments: 'Partner KYC submitted for PLAZA admin review',
    });
    await this.partnerApprovalRepo.save(approval);

    await this.recordAudit(
      partnerId,
      actor?.sub || actor?.id,
      actor?.email,
      actor?.role,
      'PARTNER_SUBMITTED',
      'partner',
      partnerId,
      { documentsCount: docs.length },
    );

    return partner;
  }

  // ==========================================
  // BUSINESS LISTINGS & CATALOG (GATE 2)
  // ==========================================

  async createBusinessListing(partnerId: string, dto: CreateBusinessListingDto, actor: any) {
    const partner = await this.getPartnerProfile(partnerId);

    // GATE 1 CHECK: Must be approved before creating live customer listings
    if (partner.status !== PartnerStatus.APPROVED) {
      throw new ForbiddenException(
        'Gate 1 Incomplete: Partner business organization must be fully approved by PLAZA Admin before creating listings.',
      );
    }

    const businessId = `pb_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const business = this.partnerBusinessRepo.create({
      id: businessId,
      partnerId,
      vertical: dto.vertical,
      name: dto.name,
      description: dto.description,
      address: dto.address,
      city: dto.city,
      contactPhone: dto.contactPhone,
      contactEmail: dto.contactEmail,
      status: BusinessStatus.DRAFT,
      metadata: dto.metadata || {},
    });

    // Create corresponding catalog entity in DRAFT / UNPUBLISHED state
    const catalogId = await this.createCatalogShadow(partnerId, businessId, dto);
    business.catalogEntityId = catalogId;

    await this.partnerBusinessRepo.save(business);

    await this.recordAudit(
      partnerId,
      actor?.sub || actor?.id,
      actor?.email,
      actor?.role,
      'LISTING_CREATED',
      'business_listing',
      businessId,
      { vertical: dto.vertical, name: dto.name, catalogId },
    );

    return business;
  }

  async getPartnerBusinesses(partnerId: string) {
    return this.partnerBusinessRepo.find({
      where: { partnerId },
      order: { createdAt: 'DESC' },
    });
  }

  async submitListingForReview(partnerId: string, businessId: string, actor: any) {
    const business = await this.partnerBusinessRepo.findOne({
      where: { id: businessId, partnerId },
    });
    if (!business) {
      throw new NotFoundException(`Listing with ID ${businessId} not found under this partner`);
    }

    business.status = BusinessStatus.SUBMITTED;
    business.rejectionReason = null;
    await this.partnerBusinessRepo.save(business);

    const approval = this.partnerApprovalRepo.create({
      id: `pappr_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      partnerId,
      targetType: 'business_listing',
      targetId: businessId,
      action: ApprovalAction.SUBMIT,
      actorId: actor?.sub || actor?.id,
      actorEmail: actor?.email,
      actorRole: actor?.role,
      comments: `Listing submitted for publication review (${business.name})`,
    });
    await this.partnerApprovalRepo.save(approval);

    await this.recordAudit(
      partnerId,
      actor?.sub || actor?.id,
      actor?.email,
      actor?.role,
      'LISTING_SUBMITTED',
      'business_listing',
      businessId,
      { name: business.name },
    );

    return business;
  }

  async publishListing(partnerId: string, businessId: string, actor: any) {
    const business = await this.partnerBusinessRepo.findOne({
      where: { id: businessId, partnerId },
    });
    if (!business) {
      throw new NotFoundException(`Listing with ID ${businessId} not found`);
    }

    // GATE 2 CHECK: Listing must be approved by PLAZA Admin
    if (business.status !== BusinessStatus.APPROVED) {
      throw new ForbiddenException(
        'Gate 2 Incomplete: Listing must receive explicit PLAZA Admin approval before it can be published to customers.',
      );
    }

    // Set catalog entity isPublished = true
    if (business.catalogEntityId) {
      await this.setCatalogPublication(business.vertical, business.catalogEntityId, true);
    }

    await this.recordAudit(
      partnerId,
      actor?.sub || actor?.id,
      actor?.email,
      actor?.role,
      'LISTING_PUBLISHED',
      'business_listing',
      businessId,
      { name: business.name },
    );

    return {
      success: true,
      message: `Listing '${business.name}' is now live to customers on PLAZA.`,
      business,
    };
  }

  async unpublishListing(partnerId: string, businessId: string, actor: any) {
    const business = await this.partnerBusinessRepo.findOne({
      where: { id: businessId, partnerId },
    });
    if (!business) {
      throw new NotFoundException(`Listing with ID ${businessId} not found`);
    }

    if (business.catalogEntityId) {
      await this.setCatalogPublication(business.vertical, business.catalogEntityId, false);
    }

    await this.recordAudit(
      partnerId,
      actor?.sub || actor?.id,
      actor?.email,
      actor?.role,
      'LISTING_UNPUBLISHED',
      'business_listing',
      businessId,
      { name: business.name },
    );

    return {
      success: true,
      message: `Listing '${business.name}' has been taken offline.`,
      business,
    };
  }

  // ==========================================
  // BOOKINGS & CUSTOMER FULFILLMENT
  // ==========================================

  async getPartnerBookings(partnerId: string, status?: string) {
    const qb = this.bookingRepo.createQueryBuilder('b')
      .where('b.partnerId = :partnerId', { partnerId });

    if (status && status !== 'all') {
      qb.andWhere('b.status = :status', { status });
    }

    qb.orderBy('b.createdAt', 'DESC');
    const bookings = await qb.getMany();

    // Safe customer projection (no payment signatures, no secrets)
    return bookings.map((b) => ({
      id: b.id,
      type: b.type,
      title: b.title,
      subtitle: b.subtitle,
      date: b.date,
      time: b.time,
      location: b.location,
      status: b.status,
      totalPrice: b.totalPrice,
      qrCodeData: b.qrCodeData,
      customerName: b.metadata?.customerName || 'PLAZA Customer',
      customerPhone: b.metadata?.customerPhone || '',
      seats: b.metadata?.seats || b.metadata?.tickets || 1,
      createdAt: b.createdAt,
    }));
  }

  async checkInCustomer(partnerId: string, bookingId: string, actor: any) {
    const booking = await this.bookingRepo.findOne({
      where: { id: bookingId, partnerId },
    });
    if (!booking) {
      throw new NotFoundException(`Booking #${bookingId} not found for this partner venue`);
    }

    if (booking.status === BookingStatus.COMPLETED) {
      throw new BadRequestException('Customer pass has already been checked in');
    }

    if (booking.status === BookingStatus.CANCELLED || booking.status === BookingStatus.FAILED) {
      throw new BadRequestException(`Cannot check in an invalid booking (${booking.status})`);
    }

    booking.status = BookingStatus.COMPLETED;
    await this.bookingRepo.save(booking);

    await this.recordAudit(
      partnerId,
      actor?.sub || actor?.id,
      actor?.email,
      actor?.role,
      'BOOKING_CHECKED_IN',
      'booking',
      bookingId,
      { title: booking.title },
    );

    return {
      success: true,
      message: `Pass checked in successfully for ${booking.title}`,
      booking,
    };
  }

  // ==========================================
  // STAFF INVITATIONS & MANAGEMENT
  // ==========================================

  async getPartnerStaff(partnerId: string) {
    const memberships = await this.partnerUserRepo.find({
      where: { partnerId },
      order: { createdAt: 'ASC' },
    });

    const userIds = memberships.map((m) => m.userId);
    const users = await this.userRepo.findByIds(userIds);

    return memberships.map((m) => {
      const u = users.find((usr) => usr.id === m.userId);
      return {
        id: m.id,
        userId: m.userId,
        name: u?.name || 'Staff Member',
        email: u?.email || '',
        phone: u?.phone || '',
        role: m.role,
        isActive: m.isActive,
        joinedAt: m.createdAt,
      };
    });
  }

  async inviteStaff(partnerId: string, dto: InviteStaffDto, actor: any) {
    const code = `INV_${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    const invitation = this.partnerInvRepo.create({
      id: `pinv_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      partnerId,
      invitedEmail: dto.email,
      invitedRole: dto.role,
      invitationCode: code,
      status: InvitationStatus.PENDING,
      invitedBy: actor?.sub || actor?.id,
      expiresAt,
    });

    await this.partnerInvRepo.save(invitation);

    await this.recordAudit(
      partnerId,
      actor?.sub || actor?.id,
      actor?.email,
      actor?.role,
      'STAFF_INVITED',
      'invitation',
      invitation.id,
      { invitedEmail: dto.email, role: dto.role },
    );

    return invitation;
  }

  async removeStaff(partnerId: string, targetUserId: string, actor: any) {
    const membership = await this.partnerUserRepo.findOne({
      where: { partnerId, userId: targetUserId },
    });
    if (!membership) {
      throw new NotFoundException('Staff member not found in this organization');
    }

    if (membership.role === UserRole.PARTNER_OWNER) {
      throw new ForbiddenException('The partner owner cannot be removed');
    }

    membership.isActive = false;
    await this.partnerUserRepo.save(membership);

    await this.recordAudit(
      partnerId,
      actor?.sub || actor?.id,
      actor?.email,
      actor?.role,
      'STAFF_REMOVED',
      'partner_user',
      membership.id,
      { targetUserId },
    );

    return { success: true, message: 'Staff member deactivated successfully' };
  }

  // ==========================================
  // PAYOUT PROFILE (ENCRYPTED / MASKED)
  // ==========================================

  async getPayoutProfile(partnerId: string) {
    const profile = await this.payoutProfileRepo.findOne({ where: { partnerId } });
    if (!profile) {
      throw new NotFoundException('Payout profile not found for this partner');
    }
    // Return safe projection without full unmasked account number
    return {
      id: profile.id,
      partnerId: profile.partnerId,
      accountHolderName: profile.accountHolderName,
      bankName: profile.bankName,
      accountNumberMasked: profile.accountNumberMasked,
      ifscCode: profile.ifscCode,
      payoutStatus: profile.payoutStatus,
      verifiedAt: profile.verifiedAt,
      updatedAt: profile.updatedAt,
    };
  }

  async updatePayoutProfile(partnerId: string, dto: UpdatePayoutProfileDto, actor: any) {
    let profile = await this.payoutProfileRepo.findOne({ where: { partnerId } });
    if (!profile) {
      profile = this.payoutProfileRepo.create({
        id: `payprof_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        partnerId,
      });
    }

    // Mask account number (preserve only last 4 digits)
    const cleanAcc = dto.accountNumber.trim();
    const last4 = cleanAcc.length >= 4 ? cleanAcc.substring(cleanAcc.length - 4) : '0000';
    const masked = `••••••••${last4}`;

    profile.accountHolderName = dto.accountHolderName;
    profile.bankName = dto.bankName;
    profile.accountNumberMasked = masked;
    profile.accountNumberEncrypted = Buffer.from(cleanAcc).toString('base64'); // Protected storage
    profile.ifscCode = dto.ifscCode.toUpperCase().trim();
    profile.payoutStatus = PayoutStatus.PENDING_VERIFICATION;
    profile.verifiedAt = null;

    await this.payoutProfileRepo.save(profile);

    await this.recordAudit(
      partnerId,
      actor?.sub || actor?.id,
      actor?.email,
      actor?.role,
      'PAYOUT_ACCOUNT_CHANGED',
      'payout_profile',
      profile.id,
      { bankName: dto.bankName, ifscCode: profile.ifscCode },
    );

    return this.getPayoutProfile(partnerId);
  }

  // ==========================================
  // PARTNER DASHBOARD OVERVIEW METRICS
  // ==========================================

  async getDashboardOverview(partnerId: string) {
    const partner = await this.getPartnerProfile(partnerId);

    const businessesCount = await this.partnerBusinessRepo.count({ where: { partnerId } });
    const docsCount = await this.partnerDocRepo.count({ where: { partnerId } });
    const staffCount = await this.partnerUserRepo.count({ where: { partnerId, isActive: true } });

    const bookings = await this.bookingRepo.find({ where: { partnerId } });
    const totalBookings = bookings.length;
    const upcomingBookings = bookings.filter(
      (b) => b.status === BookingStatus.UPCOMING || b.status === BookingStatus.CONFIRMED,
    ).length;
    const completedBookings = bookings.filter((b) => b.status === BookingStatus.COMPLETED).length;

    const totalRevenue = bookings
      .filter((b) => b.status !== BookingStatus.CANCELLED && b.status !== BookingStatus.FAILED)
      .reduce((acc, curr) => acc + (curr.totalPrice || 0), 0);

    const pendingActions: string[] = [];
    if (partner.status === PartnerStatus.DRAFT) {
      pendingActions.push('Upload mandatory verification documents and submit for PLAZA approval');
    } else if (partner.status === PartnerStatus.SUBMITTED) {
      pendingActions.push('PLAZA Admin verification in progress (Gate 1)');
    } else if (partner.status === PartnerStatus.REJECTED) {
      pendingActions.push(`Action Required: ${partner.rejectionReason || 'Please update details and resubmit'}`);
    } else if (partner.status === PartnerStatus.APPROVED && businessesCount === 0) {
      pendingActions.push('Create your first business listing (Gate 2)');
    }

    return {
      partner: {
        id: partner.id,
        displayName: partner.displayName,
        legalName: partner.legalName,
        status: partner.status,
        partnerType: partner.partnerType,
        city: partner.city,
      },
      metrics: {
        totalBookings,
        upcomingBookings,
        completedBookings,
        totalRevenue,
        businessesCount,
        docsCount,
        staffCount,
      },
      pendingActions,
    };
  }

  // ==========================================
  // PLAZA ADMIN GOVERNANCE & GATES
  // ==========================================

  async adminListPartners(status?: string, type?: string, limit: number = 20, offset: number = 0) {
    const qb = this.partnerRepo.createQueryBuilder('p');

    if (status && status !== 'all') {
      qb.andWhere('p.status = :status', { status });
    }
    if (type && type !== 'all') {
      qb.andWhere('p.partnerType = :type', { type });
    }

    qb.orderBy('p.createdAt', 'DESC').skip(offset).take(limit);

    const [partners, total] = await qb.getManyAndCount();
    return { partners, total, limit, offset };
  }

  async adminGetPartnerDetails(partnerId: string) {
    const partner = await this.getPartnerProfile(partnerId);
    const documents = await this.partnerDocRepo.find({ where: { partnerId } });
    const businesses = await this.partnerBusinessRepo.find({ where: { partnerId } });
    const staff = await this.getPartnerStaff(partnerId);
    const payout = await this.getPayoutProfile(partnerId).catch(() => null);
    const approvals = await this.partnerApprovalRepo.find({
      where: { partnerId },
      order: { createdAt: 'DESC' },
    });
    const auditLogs = await this.partnerAuditRepo.find({
      where: { partnerId },
      order: { createdAt: 'DESC' },
      take: 50,
    });

    return {
      partner,
      documents,
      businesses,
      staff,
      payout,
      approvals,
      auditLogs,
    };
  }

  async adminReviewPartner(partnerId: string, dto: ReviewPartnerDto, adminActor: any) {
    const partner = await this.getPartnerProfile(partnerId);

    // CRITICAL SEPARATION RULE: Cannot approve own partner
    const adminUserId = adminActor?.sub || adminActor?.id;
    const isMember = await this.partnerUserRepo.findOne({
      where: { partnerId, userId: adminUserId },
    });
    if (isMember) {
      throw new ForbiddenException(
        'Separation of Duties Violation: You own or belong to this partner organization and cannot approve your own business.',
      );
    }

    if (dto.action === 'approve') {
      partner.status = PartnerStatus.APPROVED;
      partner.rejectionReason = null;
    } else {
      if (!dto.reason) {
        throw new BadRequestException('A clear explanation is mandatory when rejecting a partner submission');
      }
      partner.status = PartnerStatus.REJECTED;
      partner.rejectionReason = dto.reason;
    }

    await this.partnerRepo.save(partner);

    const approval = this.partnerApprovalRepo.create({
      id: `pappr_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      partnerId,
      targetType: 'partner',
      targetId: partnerId,
      action: dto.action === 'approve' ? ApprovalAction.APPROVE : ApprovalAction.REJECT,
      actorId: adminUserId,
      actorEmail: adminActor?.email,
      actorRole: adminActor?.role,
      reason: dto.reason || null,
      comments: dto.comments || null,
    });
    await this.partnerApprovalRepo.save(approval);

    await this.recordAudit(
      partnerId,
      adminUserId,
      adminActor?.email,
      adminActor?.role,
      dto.action === 'approve' ? 'PARTNER_APPROVED' : 'PARTNER_REJECTED',
      'partner',
      partnerId,
      { reason: dto.reason },
    );

    return {
      success: true,
      message: `Partner status transitioned to ${partner.status.toUpperCase()}`,
      partner,
    };
  }

  async adminSuspendPartner(partnerId: string, dto: SuspendPartnerDto, adminActor: any) {
    const partner = await this.getPartnerProfile(partnerId);

    partner.status = PartnerStatus.SUSPENDED;
    partner.suspensionReason = dto.reason;
    await this.partnerRepo.save(partner);

    // Automatically unpublish all live businesses under this partner
    const businesses = await this.partnerBusinessRepo.find({ where: { partnerId } });
    for (const b of businesses) {
      if (b.catalogEntityId) {
        await this.setCatalogPublication(b.vertical, b.catalogEntityId, false);
      }
    }

    const approval = this.partnerApprovalRepo.create({
      id: `pappr_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      partnerId,
      targetType: 'partner',
      targetId: partnerId,
      action: ApprovalAction.SUSPEND,
      actorId: adminActor?.sub || adminActor?.id,
      actorEmail: adminActor?.email,
      actorRole: adminActor?.role,
      reason: dto.reason,
    });
    await this.partnerApprovalRepo.save(approval);

    await this.recordAudit(
      partnerId,
      adminActor?.sub || adminActor?.id,
      adminActor?.email,
      adminActor?.role,
      'PARTNER_SUSPENDED',
      'partner',
      partnerId,
      { reason: dto.reason },
    );

    return {
      success: true,
      message: `Partner '${partner.displayName}' has been suspended. All live listings taken offline.`,
      partner,
    };
  }

  async adminResumePartner(partnerId: string, adminActor: any) {
    const partner = await this.getPartnerProfile(partnerId);
    if (partner.status !== PartnerStatus.SUSPENDED) {
      throw new BadRequestException('Only suspended partners can be resumed');
    }

    partner.status = PartnerStatus.APPROVED;
    partner.suspensionReason = null;
    await this.partnerRepo.save(partner);

    await this.recordAudit(
      partnerId,
      adminActor?.sub || adminActor?.id,
      adminActor?.email,
      adminActor?.role,
      'PARTNER_RESUMED',
      'partner',
      partnerId,
      {},
    );

    return {
      success: true,
      message: `Partner '${partner.displayName}' has been reinstated.`,
      partner,
    };
  }

  async adminReviewDocument(partnerId: string, docId: string, dto: ReviewDocumentDto, adminActor: any) {
    const doc = await this.partnerDocRepo.findOne({ where: { id: docId, partnerId } });
    if (!doc) {
      throw new NotFoundException(`Document #${docId} not found`);
    }

    if (dto.action === 'approve') {
      doc.status = DocumentStatus.APPROVED;
      doc.rejectionReason = null;
    } else {
      if (!dto.reason) {
        throw new BadRequestException('A reason is required when rejecting a verification document');
      }
      doc.status = DocumentStatus.REJECTED;
      doc.rejectionReason = dto.reason;
    }

    doc.reviewedAt = new Date();
    doc.reviewedBy = adminActor?.email;
    await this.partnerDocRepo.save(doc);

    await this.recordAudit(
      partnerId,
      adminActor?.sub || adminActor?.id,
      adminActor?.email,
      adminActor?.role,
      dto.action === 'approve' ? 'DOCUMENT_APPROVED' : 'DOCUMENT_REJECTED',
      'document',
      docId,
      { reason: dto.reason },
    );

    return doc;
  }

  async adminReviewListing(partnerId: string, businessId: string, dto: ReviewListingDto, adminActor: any) {
    const business = await this.partnerBusinessRepo.findOne({
      where: { id: businessId, partnerId },
    });
    if (!business) {
      throw new NotFoundException(`Business listing #${businessId} not found`);
    }

    if (dto.action === 'approve') {
      business.status = BusinessStatus.APPROVED;
      business.rejectionReason = null;

      // Update catalog entity approval status
      if (business.catalogEntityId) {
        await this.setCatalogApproval(business.vertical, business.catalogEntityId, 'APPROVED');
      }
    } else {
      if (!dto.reason) {
        throw new BadRequestException('A reason is required when rejecting a listing publication gate');
      }
      business.status = BusinessStatus.REJECTED;
      business.rejectionReason = dto.reason;

      if (business.catalogEntityId) {
        await this.setCatalogPublication(business.vertical, business.catalogEntityId, false);
        await this.setCatalogApproval(business.vertical, business.catalogEntityId, 'REJECTED');
      }
    }

    await this.partnerBusinessRepo.save(business);

    const approval = this.partnerApprovalRepo.create({
      id: `pappr_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      partnerId,
      targetType: 'business_listing',
      targetId: businessId,
      action: dto.action === 'approve' ? ApprovalAction.APPROVE : ApprovalAction.REJECT,
      actorId: adminActor?.sub || adminActor?.id,
      actorEmail: adminActor?.email,
      actorRole: adminActor?.role,
      reason: dto.reason || null,
      comments: `Listing review: ${business.name}`,
    });
    await this.partnerApprovalRepo.save(approval);

    await this.recordAudit(
      partnerId,
      adminActor?.sub || adminActor?.id,
      adminActor?.email,
      adminActor?.role,
      dto.action === 'approve' ? 'LISTING_APPROVED' : 'LISTING_REJECTED',
      'business_listing',
      businessId,
      { reason: dto.reason },
    );

    return {
      success: true,
      message: `Listing publication status transitioned to ${business.status.toUpperCase()}`,
      business,
    };
  }

  // ==========================================
  // INTERNAL HELPERS
  // ==========================================

  private async recordAudit(
    partnerId: string,
    actorUserId: string,
    actorEmail: string,
    actorRole: string,
    action: string,
    resourceType: string,
    resourceId: string,
    metadata: any,
  ) {
    try {
      const log = this.partnerAuditRepo.create({
        id: `pal_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        partnerId,
        actorUserId: actorUserId || 'anonymous',
        actorEmail: actorEmail || 'system@plaza.app',
        actorRole: actorRole || 'partner_owner',
        action,
        resourceType,
        resourceId,
        metadata: metadata || null,
      });
      await this.partnerAuditRepo.save(log);
    } catch (e) {
      // Non-blocking audit logger
    }
  }

  private async createCatalogShadow(
    partnerId: string,
    businessId: string,
    dto: CreateBusinessListingDto,
  ): Promise<string> {
    const id = `cat_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const v = dto.vertical.toLowerCase();

    if (v === 'dining') {
      const r = this.restaurantRepo.create({
        id,
        name: dto.name,
        tagline: dto.metadata?.tagline || 'Exquisite dining experience',
        about: dto.description,
        coverImageUrl: dto.metadata?.coverImageUrl || 'https://images.unsplash.com/dining.jpg',
        galleryImages: [],
        rating: 4.5,
        reviewCount: 0,
        cuisines: dto.metadata?.cuisines || ['Multi-Cuisine'],
        priceForTwo: dto.metadata?.priceForTwo || 1200,
        location: dto.address,
        distance: '2.5 km',
        openingHours: dto.metadata?.openingHours || '11:00 AM - 11:00 PM',
        amenities: dto.metadata?.amenities || ['Air Conditioned', 'WiFi', 'Valet Parking'],
        isPublished: false,
        partnerId,
        businessId,
        approvalStatus: 'UNDER_REVIEW',
      });
      await this.restaurantRepo.save(r);
      return id;
    }

    if (v === 'event') {
      const e = this.eventRepo.create({
        id,
        title: dto.name,
        tagline: dto.metadata?.tagline || dto.name,
        description: dto.description,
        category: dto.metadata?.category || 'Music',
        posterUrl: dto.metadata?.posterUrl || 'https://images.unsplash.com/event.jpg',
        bannerUrl: dto.metadata?.bannerUrl || 'https://images.unsplash.com/event.jpg',
        eventDate: dto.metadata?.date || '2026-11-01',
        time: dto.metadata?.time || '18:00',
        venue: dto.name,
        location: dto.address,
        distance: '3.0 km',
        rating: 4.8,
        interestedCount: 50,
        ageRestriction: '16+',
        languages: 'English & Telugu',
        ticketTiers: dto.metadata?.ticketTiers || [
          { id: 'tier_gen', name: 'General Admission', price: 999, remainingCount: 100, perks: [] },
        ],
        performers: [],
        isPublished: false,
        partnerId,
        businessId,
        approvalStatus: 'UNDER_REVIEW',
      });
      await this.eventRepo.save(e);
      return id;
    }

    if (v === 'activity') {
      const a = this.activityRepo.create({
        id,
        title: dto.name,
        tagline: dto.metadata?.tagline || dto.name,
        description: dto.description,
        category: dto.metadata?.category || 'Adventure',
        coverImageUrl: dto.metadata?.coverImageUrl || 'https://images.unsplash.com/activity.jpg',
        galleryImages: [],
        rating: 4.8,
        reviewCount: 12,
        location: dto.address,
        distance: '4.0 km',
        highlights: ['Safety Gear Included', 'Certified Instructors'],
        safetyGuidelines: ['Wear closed shoes', 'Follow staff directions'],
        packages: dto.metadata?.packages || [
          { id: 'pkg_standard', name: 'Standard Pass', pricePerPerson: 599, duration: '60 mins' },
        ],
        timeSlots: [{ time: '10:00 AM', availableSlots: 10 }],
        isPublished: false,
        partnerId,
        businessId,
        approvalStatus: 'UNDER_REVIEW',
      });
      await this.activityRepo.save(a);
      return id;
    }

    if (v === 'stay' || v === 'hotel') {
      const h = this.hotelRepo.create({
        id,
        name: dto.name,
        tagline: dto.metadata?.tagline || 'Comfortable stay',
        category: dto.metadata?.category || 'Resort',
        description: dto.description,
        startingPricePerNight: dto.metadata?.pricePerNight || 3500,
        rating: 4.8,
        reviewCount: 0,
        coverImageUrl: dto.metadata?.coverImageUrl || 'https://images.unsplash.com/hotel.jpg',
        galleryImages: [],
        location: dto.address,
        distance: '5.0 km',
        amenities: ['Pool', 'Spa', 'Breakfast Included'],
        rooms: [
          {
            id: 'rm_deluxe',
            name: 'Deluxe Room',
            description: 'Spacious room with luxury amenities',
            imageUrl: 'https://images.unsplash.com/room.jpg',
            pricePerNight: 3500,
            maxGuests: 2,
            bedType: 'King Bed',
            roomSize: '320 sq.ft',
            highlights: ['AC', 'WiFi', 'City View'],
            isAvailable: true,
          },
        ],
        addOns: [],
        isPublished: false,
        partnerId,
        businessId,
        approvalStatus: 'UNDER_REVIEW',
      });
      await this.hotelRepo.save(h);
      return id;
    }

    if (v === 'sports') {
      const s = this.sportsVenueRepo.create({
        id,
        name: dto.name,
        supportedSports: dto.metadata?.sports || ['Badminton', 'Box Cricket'],
        coverImageUrl: dto.metadata?.coverImageUrl || 'https://images.unsplash.com/sports.jpg',
        galleryImages: [],
        rating: 4.7,
        reviewCount: 0,
        location: dto.address,
        distance: '2.0 km',
        amenities: ['Parking', 'Drinking Water', 'Lockers'],
        rules: 'Standard venue guidelines apply',
        startingPricePerHour: dto.metadata?.startingPrice || 600,
        slots: [
          { id: 'slot_1', time: '06:00 AM', duration: '60 mins', price: 600, status: 'AVAILABLE', courtName: 'Court 1' },
        ],
        addOns: [],
        isPublished: false,
        partnerId,
        businessId,
        approvalStatus: 'UNDER_REVIEW',
      });
      await this.sportsVenueRepo.save(s);
      return id;
    }

    return id;
  }

  private async setCatalogPublication(vertical: string, id: string, isPublished: boolean) {
    const v = vertical.toLowerCase();
    if (v === 'dining') await this.restaurantRepo.update(id, { isPublished });
    else if (v === 'event') await this.eventRepo.update(id, { isPublished });
    else if (v === 'activity') await this.activityRepo.update(id, { isPublished });
    else if (v === 'stay' || v === 'hotel') await this.hotelRepo.update(id, { isPublished });
    else if (v === 'sports') await this.sportsVenueRepo.update(id, { isPublished });
  }

  private async setCatalogApproval(vertical: string, id: string, approvalStatus: string) {
    const v = vertical.toLowerCase();
    if (v === 'dining') await this.restaurantRepo.update(id, { approvalStatus });
    else if (v === 'event') await this.eventRepo.update(id, { approvalStatus });
    else if (v === 'activity') await this.activityRepo.update(id, { approvalStatus });
    else if (v === 'stay' || v === 'hotel') await this.hotelRepo.update(id, { approvalStatus });
    else if (v === 'sports') await this.sportsVenueRepo.update(id, { approvalStatus });
  }
}
