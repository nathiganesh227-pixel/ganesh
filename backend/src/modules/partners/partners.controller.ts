import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PartnerTenantGuard } from './guards/partner-tenant.guard';
import { PartnersService } from './partners.service';
import {
  OnboardPartnerDto,
  UpdatePartnerProfileDto,
  UploadDocumentDto,
  CreateBusinessListingDto,
  InviteStaffDto,
  UpdatePayoutProfileDto,
  UpdateBusinessAvailabilityDto,
} from './dto/partner.dto';

@ApiTags('partners')
@Controller('partners')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class PartnersController {
  constructor(private readonly partnersService: PartnersService) {}

  // ---------------- ONBOARDING (STEPS 1 & 2) ----------------
  @Post('onboard')
  @ApiOperation({ summary: 'Register prospective partner organization' })
  async onboardPartner(@Body() dto: OnboardPartnerDto, @Request() req: any) {
    return this.partnersService.onboardPartner(dto, req.user);
  }

  // ---------------- PROFILE & TENANT INSPECTION ----------------
  @Get(':id/profile')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Get partner organization profile' })
  async getProfile(@Param('id') id: string) {
    return this.partnersService.getPartnerProfile(id);
  }

  @Put(':id/profile')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Update partner organization profile' })
  async updateProfile(
    @Param('id') id: string,
    @Body() dto: UpdatePartnerProfileDto,
    @Request() req: any,
  ) {
    return this.partnersService.updatePartnerProfile(id, dto, req.user);
  }

  // ---------------- DOCUMENTS & VERIFICATION (GATE 1) ----------------
  @Post(':id/documents')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Upload verification document' })
  async uploadDocument(
    @Param('id') id: string,
    @Body() dto: UploadDocumentDto,
    @Request() req: any,
  ) {
    return this.partnersService.uploadDocument(id, dto, req.user);
  }

  @Get(':id/documents')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'List submitted partner verification documents' })
  async getDocuments(@Param('id') id: string) {
    return this.partnersService.getPartnerDocuments(id);
  }

  @Post(':id/submit')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Submit partner KYC for PLAZA admin review' })
  async submitForReview(@Param('id') id: string, @Request() req: any) {
    return this.partnersService.submitPartnerForReview(id, req.user);
  }

  // ---------------- BUSINESS LISTINGS & GATES (GATE 2) ----------------
  @Get(':id/businesses')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'List businesses and listings under this partner' })
  async getBusinesses(@Param('id') id: string) {
    return this.partnersService.getPartnerBusinesses(id);
  }

  @Post(':id/businesses')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Create business listing (Requires Gate 1 Partner Approval)' })
  async createListing(
    @Param('id') id: string,
    @Body() dto: CreateBusinessListingDto,
    @Request() req: any,
  ) {
    return this.partnersService.createBusinessListing(id, dto, req.user);
  }

  @Post(':id/businesses/:businessId/submit')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Submit listing for PLAZA publication review' })
  async submitListing(
    @Param('id') id: string,
    @Param('businessId') businessId: string,
    @Request() req: any,
  ) {
    return this.partnersService.submitListingForReview(id, businessId, req.user);
  }

  @Patch(':id/businesses/:businessId/publish')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Publish listing to live customers (Requires Gate 2 Listing Approval)' })
  async publishListing(
    @Param('id') id: string,
    @Param('businessId') businessId: string,
    @Request() req: any,
  ) {
    return this.partnersService.publishListing(id, businessId, req.user);
  }

  @Patch(':id/businesses/:businessId/unpublish')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Take listing offline' })
  async unpublishListing(
    @Param('id') id: string,
    @Param('businessId') businessId: string,
    @Request() req: any,
  ) {
    return this.partnersService.unpublishListing(id, businessId, req.user);
  }

  @Patch(':id/businesses/:businessId/availability')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Update operational availability, slots, or capacity for business' })
  async updateAvailability(
    @Param('id') id: string,
    @Param('businessId') businessId: string,
    @Body() dto: UpdateBusinessAvailabilityDto,
    @Request() req: any,
  ) {
    return this.partnersService.updateBusinessAvailability(id, businessId, dto, req.user);
  }

  // ---------------- BOOKINGS & CHECK-IN ----------------
  @Get(':id/bookings')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'List customer bookings scoped to this partner' })
  async getBookings(@Param('id') id: string, @Query('status') status?: string) {
    return this.partnersService.getPartnerBookings(id, status);
  }

  @Post(':id/bookings/:bookingId/checkin')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Validate pass and check in customer at venue' })
  async checkInCustomer(
    @Param('id') id: string,
    @Param('bookingId') bookingId: string,
    @Request() req: any,
  ) {
    return this.partnersService.checkInCustomer(id, bookingId, req.user);
  }

  // ---------------- STAFF MANAGEMENT ----------------
  @Get(':id/staff')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'List staff members in this partner organization' })
  async getStaff(@Param('id') id: string) {
    return this.partnersService.getPartnerStaff(id);
  }

  @Post(':id/staff/invite')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Invite new staff member or manager' })
  async inviteStaff(
    @Param('id') id: string,
    @Body() dto: InviteStaffDto,
    @Request() req: any,
  ) {
    return this.partnersService.inviteStaff(id, dto, req.user);
  }

  @Delete(':id/staff/:userId')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Deactivate staff member' })
  async removeStaff(
    @Param('id') id: string,
    @Param('userId') userId: string,
    @Request() req: any,
  ) {
    return this.partnersService.removeStaff(id, userId, req.user);
  }

  // ---------------- PAYOUT PROFILE (ENCRYPTED / MASKED) ----------------
  @Get(':id/payout')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Get masked partner bank and payout profile' })
  async getPayout(@Param('id') id: string) {
    return this.partnersService.getPayoutProfile(id);
  }

  @Put(':id/payout')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Update payout bank account details' })
  async updatePayout(
    @Param('id') id: string,
    @Body() dto: UpdatePayoutProfileDto,
    @Request() req: any,
  ) {
    return this.partnersService.updatePayoutProfile(id, dto, req.user);
  }

  // ---------------- DASHBOARD OVERVIEW ----------------
  @Get(':id/dashboard')
  @UseGuards(PartnerTenantGuard)
  @ApiOperation({ summary: 'Get partner live dashboard overview metrics' })
  async getDashboard(@Param('id') id: string) {
    return this.partnersService.getDashboardOverview(id);
  }
}
