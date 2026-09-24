import { Controller, Get, Patch, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { NotificationEntity } from '../../database/entities/notification.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('notifications')
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all user notifications for authenticated user' })
  async findAll(@Request() req: any): Promise<NotificationEntity[]> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    return this.service.findAll(userId);
  }

  @Patch(':id/read')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Mark notification as read' })
  async markAsRead(@Request() req: any, @Param('id') id: string): Promise<NotificationEntity> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    return this.service.markAsRead(id, userId);
  }
}

