import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { EventsService } from './events.service';
import { EventEntity } from '../../database/entities/event.entity';

@ApiTags('events')
@Controller('events')
export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all events' })
  async findAll(@Query('category') category?: string): Promise<EventEntity[]> {
    return this.eventsService.findAll(category);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get event details' })
  async findOne(@Param('id') id: string): Promise<EventEntity> {
    return this.eventsService.findOne(id);
  }
}
