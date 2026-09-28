import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../../database/entities/user.entity';
import { PartnersService } from './partners.service';
import {
  ReviewPartnerDto,
  SuspendPartnerDto,
  ReviewListingDto,
  ReviewDocumentDto,
} from './dto/partner.dto';

@ApiTags('admin')
@Controller('admin/partners')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@ApiBearerAuth()
export class PartnerAdminController {
  constructor(private readonly partnersService: PartnersService) {}

  @Get()
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN, UserRole.OPERATOR)
  @ApiOperation({ summary: 'List and filter partner organizations (Admin & Operator)' })
  async listPartners(
    @Query('status') status?: string,
    @Query('type') type?: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    return this.partnersService.adminListPartners(status, type, limit || 20, offset || 0);
  }

  @Get(':id')
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN, UserRole.OPERATOR)
  @ApiOperation({ summary: 'Get complete partner inspection dossier' })
  async getPartnerDetails(@Param('id') id: string) {
    return this.partnersService.adminGetPartnerDetails(id);
  }

  @Post(':id/review')
  @ApiOperation({ summary: 'Approve or reject partner onboarding application (Gate 1)' })
  async reviewPartner(
    @Param('id') id: string,
    @Body() dto: ReviewPartnerDto,
    @Request() req: any,
  ) {
    return this.partnersService.adminReviewPartner(id, dto, req.user);
  }

  @Post(':id/suspend')
  @ApiOperation({ summary: 'Suspend partner organization and take listings offline' })
  async suspendPartner(
    @Param('id') id: string,
    @Body() dto: SuspendPartnerDto,
    @Request() req: any,
  ) {
    return this.partnersService.adminSuspendPartner(id, dto, req.user);
  }

  @Post(':id/resume')
  @ApiOperation({ summary: 'Reinstate suspended partner organization' })
  async resumePartner(@Param('id') id: string, @Request() req: any) {
    return this.partnersService.adminResumePartner(id, req.user);
  }

  @Post(':id/documents/:docId/review')
  @ApiOperation({ summary: 'Approve or reject verification document' })
  async reviewDocument(
    @Param('id') id: string,
    @Param('docId') docId: string,
    @Body() dto: ReviewDocumentDto,
    @Request() req: any,
  ) {
    return this.partnersService.adminReviewDocument(id, docId, dto, req.user);
  }

  @Post(':id/businesses/:businessId/review')
  @ApiOperation({ summary: 'Approve or reject business listing publication gate (Gate 2)' })
  async reviewListing(
    @Param('id') id: string,
    @Param('businessId') businessId: string,
    @Body() dto: ReviewListingDto,
    @Request() req: any,
  ) {
    return this.partnersService.adminReviewListing(id, businessId, dto, req.user);
  }
}
