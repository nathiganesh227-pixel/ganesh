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

export class AdminWebhookQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ example: 'PROCESSED' })
  @IsOptional()
  status?: string;

  @ApiPropertyOptional({ example: 'payment.captured' })
  @IsOptional()
  eventType?: string;

  @ApiPropertyOptional({ example: 'bk_' })
  @IsOptional()
  bookingId?: string;

  @ApiPropertyOptional({ example: 'pay_' })
  @IsOptional()
  providerPaymentId?: string;

  @ApiPropertyOptional({ example: 'order_' })
  @IsOptional()
  providerOrderId?: string;
}

export class AdminRecoveryQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ example: 'REQUIRED' })
  @IsOptional()
  status?: string;

  @ApiPropertyOptional({ example: 'UNKNOWN_PROVIDER_OUTCOME' })
  @IsOptional()
  failureCategory?: string;

  @ApiPropertyOptional({ example: 'bk_' })
  @IsOptional()
  bookingId?: string;

  @ApiPropertyOptional({ example: 'pay_' })
  @IsOptional()
  paymentId?: string;

  @ApiPropertyOptional({ example: 'rec_' })
  @IsOptional()
  search?: string;
}

export class ResolveRecoveryDto {
  @ApiPropertyOptional({ example: 'Manually verified capture on gateway dashboard; ticket confirmed' })
  @IsOptional()
  notes?: string;
}

export class AdminReconciliationQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ example: 'REQUIRED' })
  @IsOptional()
  status?: string;

  @ApiPropertyOptional({ example: 'AMOUNT_MISMATCH' })
  @IsOptional()
  mismatchCategory?: string;

  @ApiPropertyOptional({ example: 'pay_' })
  @IsOptional()
  paymentId?: string;

  @ApiPropertyOptional({ example: 'bk_' })
  @IsOptional()
  bookingId?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  requiresManualIntervention?: boolean;
}

export class ResolveReconciliationDto {
  @ApiPropertyOptional({ example: 'CONFIRMED_MANUAL_CAPTURE' })
  @IsOptional()
  action?: string;

  @ApiPropertyOptional({ example: 'Manually verified gateway settlement' })
  @IsOptional()
  notes?: string;

  @ApiPropertyOptional({ example: 'CAPTURED' })
  @IsOptional()
  targetPaymentStatus?: string;

  @ApiPropertyOptional({ example: 'CONFIRMED' })
  @IsOptional()
  targetBookingStatus?: string;
}

export class TriggerReconcileDto {
  @ApiPropertyOptional({ example: true })
  @IsOptional()
  force?: boolean;

  @ApiPropertyOptional({ example: 'Manual operator audit trigger' })
  @IsOptional()
  notes?: string;
}

export class AdminUnifiedIncidentQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ example: 'ALL', enum: ['ALL', 'RECOVERY', 'RECONCILIATION', 'WEBHOOK'] })
  @IsOptional()
  type?: string;

  @ApiPropertyOptional({ example: 'REQUIRED' })
  @IsOptional()
  status?: string;

  @ApiPropertyOptional({ example: 'HIGH', enum: ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'] })
  @IsOptional()
  severity?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  requiresManualIntervention?: boolean;

  @ApiPropertyOptional({ example: 'pay_' })
  @IsOptional()
  search?: string;
}

export class ResolveUnifiedIncidentDto {
  @ApiPropertyOptional({ example: 'MANUAL_RESOLUTION' })
  @IsOptional()
  action?: string;

  @ApiPropertyOptional({ example: 'Operator resolved discrepancy following gateway log check' })
  @IsOptional()
  notes?: string;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  force?: boolean;

  @ApiPropertyOptional({ example: 'CAPTURED' })
  @IsOptional()
  targetPaymentStatus?: string;

  @ApiPropertyOptional({ example: 'CONFIRMED' })
  @IsOptional()
  targetBookingStatus?: string;
}



