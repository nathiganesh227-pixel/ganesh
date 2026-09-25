import {
  Controller,
  Get,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../../database/entities/user.entity';
import { AdminService } from './admin.service';
import { UpdateRoleDto, PaginationQueryDto } from './dto/admin.dto';

@ApiTags('admin')
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@ApiBearerAuth()
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('health')
  @ApiOperation({ summary: 'Admin health status (restricted to ADMIN role)' })
  getHealth() {
    return this.adminService.getHealth();
  }

  @Get('dashboard')
  @ApiOperation({ summary: 'Admin dashboard metrics and catalog entity counts' })
  @ApiResponse({ status: 200, description: 'Aggregate entity counts returned' })
  async getDashboard() {
    return this.adminService.getDashboardStats();
  }

  @Get('users')
  @ApiOperation({ summary: 'List all users with safe projections (no secrets/hashes)' })
  @ApiResponse({ status: 200, description: 'List of safe users returned' })
  async getUsers(@Query() query: PaginationQueryDto) {
    return this.adminService.getUsers(query.limit, query.offset);
  }

  @Get('users/:id')
  @ApiOperation({ summary: 'Get user details by ID (safe projection)' })
  @ApiResponse({ status: 200, description: 'User details returned' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async getUserById(@Param('id') id: string) {
    return this.adminService.getUserById(id);
  }

  @Patch('users/:id/role')
  @ApiOperation({ summary: 'Update user role with last-admin demotion protection' })
  @ApiResponse({ status: 200, description: 'User role updated and audit logged' })
  @ApiResponse({ status: 400, description: 'Invalid role or last-admin lockout prevented' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async updateUserRole(
    @Param('id') id: string,
    @Body() dto: UpdateRoleDto,
    @Request() req: any,
  ) {
    return this.adminService.updateUserRole(id, dto, req.user);
  }

  @Get('audit-logs')
  @ApiOperation({ summary: 'List recent administrative audit logs' })
  @ApiResponse({ status: 200, description: 'List of audit logs returned' })
  async getAuditLogs(@Query() query: PaginationQueryDto) {
    return this.adminService.getAuditLogs(query.limit, query.offset);
  }
}
