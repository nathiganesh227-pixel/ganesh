import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsEnum, IsNumber, Min } from 'class-validator';

export enum IntegrationProviderType {
  PARTNER = 'INTERNAL_PARTNER',
  ADMIN = 'ADMIN_CURATED',
  EXTERNAL = 'EXTERNAL_PROVIDER',
}

export enum IntegrationStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  CONFIGURED = 'CONFIGURED',
  UNCONFIGURED = 'UNCONFIGURED',
  DISABLED = 'DISABLED',
  ERROR = 'ERROR',
}

export enum AvailabilityStatus {
  AVAILABLE = 'AVAILABLE',
  LIMITED = 'LIMITED',
  SOLD_OUT = 'SOLD_OUT',
  UNAVAILABLE = 'UNAVAILABLE',
  UNKNOWN = 'UNKNOWN',
}

export enum AvailabilityFreshness {
  FRESH = 'FRESH',
  STALE = 'STALE',
  EXPIRED = 'EXPIRED',
  UNKNOWN = 'UNKNOWN',
}

export class TriggerSyncDto {
  @ApiPropertyOptional({ description: 'Optional vertical filter for the sync' })
  @IsOptional()
  @IsString()
  vertical?: string;

  @ApiPropertyOptional({ description: 'Optional force sync flag' })
  @IsOptional()
  force?: boolean;
}

export class UpdateAvailabilityDto {
  @ApiProperty({ enum: AvailabilityStatus, example: AvailabilityStatus.AVAILABLE })
  @IsEnum(AvailabilityStatus)
  status: AvailabilityStatus;

  @ApiPropertyOptional({ example: 12, description: 'Remaining available units or tables or tickets' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  remainingQuantity?: number;

  @ApiPropertyOptional({ example: 50, description: 'Total capacity' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  totalCapacity?: number;

  @ApiPropertyOptional({ description: 'Optional updated pricing or slot details' })
  @IsOptional()
  details?: Record<string, any>;
}

export class ProviderStatusDto {
  @ApiProperty()
  providerId: string;

  @ApiProperty()
  providerName: string;

  @ApiProperty({ enum: IntegrationProviderType })
  providerType: IntegrationProviderType;

  @ApiProperty()
  vertical: string;

  @ApiProperty()
  isConfigured: boolean;

  @ApiProperty()
  isEnabled: boolean;

  @ApiProperty({ enum: IntegrationStatus })
  status: IntegrationStatus;

  @ApiPropertyOptional()
  lastSyncedAt?: Date;

  @ApiPropertyOptional()
  lastSuccessfulSyncAt?: Date;

  @ApiPropertyOptional()
  errorSummary?: string;

  @ApiPropertyOptional()
  syncFrequencyMinutes?: number;
}

export class AvailabilityResponseDto {
  @ApiProperty({ enum: AvailabilityStatus })
  status: AvailabilityStatus;

  @ApiProperty({ enum: AvailabilityFreshness })
  freshness: AvailabilityFreshness;

  @ApiPropertyOptional()
  remainingQuantity?: number;

  @ApiPropertyOptional()
  totalCapacity?: number;

  @ApiProperty()
  source: string;

  @ApiPropertyOptional()
  sourceReference?: string;

  @ApiProperty()
  lastUpdatedAt: Date;
}
