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
import { IntegrationsService } from './integrations.service';
import { TriggerSyncDto } from './dto/integration.dto';

@ApiTags('admin')
@Controller('admin/integrations')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN, UserRole.OPERATOR)
@ApiBearerAuth()
export class AdminIntegrationsController {
  constructor(private readonly integrationsService: IntegrationsService) {}

  @Get('providers')
  @ApiOperation({ summary: 'List all registered integration providers and configuration statuses' })
  async getProviders() {
    return this.integrationsService.listProviders();
  }

  @Get('health')
  @ApiOperation({ summary: 'Get integration subsystem health, provider readiness, and recent sync summary' })
  async getHealth() {
    return this.integrationsService.getHealth();
  }

  @Get('sync-runs')
  @ApiOperation({ summary: 'List recent synchronization run logs' })
  async getSyncRuns(
    @Query('provider') provider?: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    return this.integrationsService.listSyncRuns(provider, limit || 20, offset || 0);
  }

  @Get('mappings')
  @ApiOperation({ summary: 'List entity mappings between external/partner IDs and PLAZA canonical IDs' })
  async getMappings(
    @Query('vertical') vertical?: string,
    @Query('partnerId') partnerId?: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    return this.integrationsService.getMappings(vertical, partnerId, limit || 50, offset || 0);
  }

  @Post(':providerId/sync')
  @Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN) // Sync trigger requires full admin authority
  @ApiOperation({ summary: 'Trigger manual synchronization run for a registered provider' })
  async triggerSync(
    @Param('providerId') providerId: string,
    @Body() dto: TriggerSyncDto,
    @Request() req: any,
  ) {
    const correlationId = `admin_sync_${Date.now()}_${req.user?.sub || 'admin'}`;
    return this.integrationsService.triggerSync(providerId, dto, correlationId);
  }
}
