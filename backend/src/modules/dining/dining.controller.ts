import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { DiningService } from './dining.service';
import { RestaurantEntity } from '../../database/entities/restaurant.entity';

@ApiTags('dining')
@Controller('dining')
export class DiningController {
  constructor(private readonly diningService: DiningService) {}

  @Get()
  @ApiOperation({ summary: 'Get all restaurants with optional cuisine, search query, and city filters' })
  async findAll(
    @Query('cuisine') cuisine?: string,
    @Query('q') q?: string,
    @Query('city') city?: string,
  ): Promise<RestaurantEntity[]> {
    return this.diningService.findAll(cuisine, q, city);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get restaurant details' })
  async findOne(@Param('id') id: string): Promise<RestaurantEntity> {
    return this.diningService.findOne(id);
  }
}
