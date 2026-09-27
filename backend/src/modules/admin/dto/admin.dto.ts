import { IsEnum, IsNotEmpty, IsOptional, IsInt, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserRole } from '../../../database/entities/user.entity';

export class UpdateRoleDto {
  @ApiProperty({ enum: UserRole, example: UserRole.USER })
  @IsEnum(UserRole, { message: 'Role must be user, admin, or operator' })
  @IsNotEmpty()
  role: UserRole;
}

export class PaginationQueryDto {
  @ApiPropertyOptional({ default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 50;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset?: number = 0;
}

export class RefundBookingDto {
  @ApiProperty({ example: 'Customer requested cancellation via admin support' })
  @IsNotEmpty()
  reason: string;
}

export class AdjustRewardsDto {
  @ApiProperty({ example: 100, description: 'Points to add (positive) or deduct (negative)' })
  @IsInt()
  @IsNotEmpty()
  amount: number;

  @ApiProperty({ example: 'Discretionary goodwill gesture for late screening' })
  @IsNotEmpty()
  reason: string;
}

export class AdminSearchQueryDto {
  @ApiProperty({ example: 'avatar' })
  @IsNotEmpty()
  q: string;
}

export class AdminBookingQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ example: 'movie' })
  @IsOptional()
  vertical?: string;

  @ApiPropertyOptional({ example: 'upcoming' })
  @IsOptional()
  status?: string;

  @ApiPropertyOptional({ example: 'CAPTURED' })
  @IsOptional()
  paymentStatus?: string;

  @ApiPropertyOptional({ example: 'bk_' })
  @IsOptional()
  search?: string;
}

export class AdminPaymentQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ example: 'CAPTURED' })
  @IsOptional()
  status?: string;

  @ApiPropertyOptional({ example: 'pay_' })
  @IsOptional()
  search?: string;
}

export class AdminAuditLogQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ example: 'REFUND_BOOKING' })
  @IsOptional()
  action?: string;

  @ApiPropertyOptional({ example: 'Booking' })
  @IsOptional()
  resourceType?: string;

  @ApiPropertyOptional({ example: 'usr_' })
  @IsOptional()
  actorUserId?: string;
}
