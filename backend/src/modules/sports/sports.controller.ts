import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { SportsService } from './sports.service';
import { SportsVenueEntity } from '../../database/entities/sports-venue.entity';

@ApiTags('sports')
@Controller('sports')
export class SportsController {
  constructor(private readonly service: SportsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all sports venues' })
  async findAll(@Query('sport') sport?: string): Promise<SportsVenueEntity[]> {
    return this.service.findAll(sport);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get sports venue details' })
  async findOne(@Param('id') id: string): Promise<SportsVenueEntity> {
    return this.service.findOne(id);
  }
}
