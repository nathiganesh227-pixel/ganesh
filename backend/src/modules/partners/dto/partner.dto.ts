import {
  IsString,
  IsNotEmpty,
  IsEmail,
  IsOptional,
  IsEnum,
  IsArray,
  IsNumber,
  Min,
  Max,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PartnerType } from '../../../database/entities/partner.entity';
import { UserRole } from '../../../database/entities/user.entity';

export class OnboardPartnerDto {
  @ApiProperty({ description: 'Legal name of the business entity' })
  @IsString()
  @IsNotEmpty()
  legalName: string;

  @ApiProperty({ description: 'Display name seen by customers' })
  @IsString()
  @IsNotEmpty()
  displayName: string;

  @ApiProperty({ enum: PartnerType, description: 'Vertical category of the partner' })
  @IsEnum(PartnerType)
  partnerType: PartnerType;

  @ApiProperty({ description: 'Business contact email' })
  @IsEmail()
  email: string;

  @ApiProperty({ description: 'Business contact phone' })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiProperty({ description: 'City where business is operating' })
  @IsString()
  @IsNotEmpty()
  city: string;

  @ApiProperty({ description: 'State where business is operating' })
  @IsString()
  @IsNotEmpty()
  state: string;

  @ApiProperty({ description: 'Physical address of the business' })
  @IsString()
  @IsNotEmpty()
  address: string;

  @ApiProperty({ description: 'PIN code of the business address' })
  @IsString()
  @IsNotEmpty()
  pinCode: string;

  @ApiPropertyOptional({ description: 'Business website' })
  @IsString()
  @IsOptional()
  website?: string;

  @ApiPropertyOptional({ description: 'GSTIN tax registration number' })
  @IsString()
  @IsOptional()
  gstNumber?: string;

  @ApiPropertyOptional({ description: 'Permanent Account Number (PAN)' })
  @IsString()
  @IsOptional()
  panNumber?: string;
}

export class UpdatePartnerProfileDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  displayName?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  address?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  city?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  phone?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  website?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  gstNumber?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  panNumber?: string;
}

export class UploadDocumentDto {
  @ApiProperty({ description: 'Type of verification document' })
  @IsString()
  @IsNotEmpty()
  documentType: string;

  @ApiProperty({ description: 'URL or storage reference to uploaded file' })
  @IsString()
  @IsNotEmpty()
  fileUrl: string;

  @ApiProperty({ description: 'Original file name' })
  @IsString()
  @IsNotEmpty()
  fileName: string;

  @ApiPropertyOptional({ description: 'File size in bytes' })
  @IsNumber()
  @IsOptional()
  fileSize?: number;
}

export class CreateBusinessListingDto {
  @ApiProperty({ description: 'Vertical category: dining, event, activity, stay, sports' })
  @IsString()
  @IsNotEmpty()
  vertical: string;

  @ApiProperty({ description: 'Listing title / business name' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ description: 'Detailed description of the business/listing' })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiProperty({ description: 'Physical location / venue address' })
  @IsString()
  @IsNotEmpty()
  address: string;

  @ApiProperty({ description: 'City' })
  @IsString()
  @IsNotEmpty()
  city: string;

  @ApiProperty({ description: 'Customer contact phone' })
  @IsString()
  @IsNotEmpty()
  contactPhone: string;

  @ApiProperty({ description: 'Customer contact email' })
  @IsEmail()
  contactEmail: string;

  @ApiPropertyOptional({ description: 'Vertical-specific operational metadata (hours, slots, pricing, amenities)' })
  @IsOptional()
  metadata?: Record<string, any>;
}

export class UpdateBusinessListingDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  address?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  contactPhone?: string;

  @ApiPropertyOptional()
  @IsEmail()
  @IsOptional()
  contactEmail?: string;

  @ApiPropertyOptional()
  @IsOptional()
  metadata?: Record<string, any>;
}

export class InviteStaffDto {
  @ApiProperty({ description: 'Email address of staff member to invite' })
  @IsEmail()
  email: string;

  @ApiProperty({ enum: [UserRole.PARTNER_MANAGER, UserRole.PARTNER_STAFF], description: 'Role assigned to staff member' })
  @IsEnum(UserRole)
  role: UserRole;
}

export class UpdatePayoutProfileDto {
  @ApiProperty({ description: 'Name of bank account holder' })
  @IsString()
  @IsNotEmpty()
  accountHolderName: string;

  @ApiProperty({ description: 'Bank institution name' })
  @IsString()
  @IsNotEmpty()
  bankName: string;

  @ApiProperty({ description: 'Full bank account number' })
  @IsString()
  @IsNotEmpty()
  accountNumber: string;

  @ApiProperty({ description: 'Bank IFSC code' })
  @IsString()
  @IsNotEmpty()
  ifscCode: string;
}

export class ReviewPartnerDto {
  @ApiProperty({ enum: ['approve', 'reject'], description: 'Admin verification decision' })
  @IsString()
  @IsNotEmpty()
  action: 'approve' | 'reject';

  @ApiPropertyOptional({ description: 'Reason for rejection (mandatory when action is reject)' })
  @IsString()
  @IsOptional()
  reason?: string;

  @ApiPropertyOptional({ description: 'Internal admin notes / reviewer comments' })
  @IsString()
  @IsOptional()
  comments?: string;
}

export class SuspendPartnerDto {
  @ApiProperty({ description: 'Detailed reason for suspension' })
  @IsString()
  @IsNotEmpty()
  reason: string;
}

export class ReviewListingDto {
  @ApiProperty({ enum: ['approve', 'reject'], description: 'Admin listing publication decision' })
  @IsString()
  @IsNotEmpty()
  action: 'approve' | 'reject';

  @ApiPropertyOptional({ description: 'Reason for rejection (mandatory when action is reject)' })
  @IsString()
  @IsOptional()
  reason?: string;
}

export class ReviewDocumentDto {
  @ApiProperty({ enum: ['approve', 'reject'], description: 'Document review decision' })
  @IsString()
  @IsNotEmpty()
  action: 'approve' | 'reject';

  @ApiPropertyOptional({ description: 'Reason for rejection (mandatory when action is reject)' })
  @IsString()
  @IsOptional()
  reason?: string;
}

export class UpdateBusinessAvailabilityDto {
  @ApiProperty({ enum: ['AVAILABLE', 'LIMITED', 'SOLD_OUT', 'UNAVAILABLE', 'UNKNOWN'] })
  @IsString()
  @IsNotEmpty()
  availabilityStatus: string;

  @ApiPropertyOptional({ description: 'Operational slots, tiers, or room rates payload' })
  @IsOptional()
  slotsOrTiers?: any;
}

