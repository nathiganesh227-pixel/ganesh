import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { ActivitiesService } from './activities.service';
import { ActivityEntity } from '../../database/entities/activity.entity';

@ApiTags('activities')
@Controller('activities')
export class ActivitiesController {
  constructor(private readonly service: ActivitiesService) {}

  @Get()
  @ApiOperation({ summary: 'Get all activities' })
  async findAll(@Query('category') category?: string): Promise<ActivityEntity[]> {
    return this.service.findAll(category);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get activity details' })
  async findOne(@Param('id') id: string): Promise<ActivityEntity> {
    return this.service.findOne(id);
  }
}
