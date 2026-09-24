import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { DiningService } from './dining.service';
import { RestaurantEntity } from '../../database/entities/restaurant.entity';

@ApiTags('dining')
@Controller('dining')
export class DiningController {
  constructor(private readonly diningService: DiningService) {}

  @Get()
  @ApiOperation({ summary: 'Get all restaurants' })
  async findAll(@Query('cuisine') cuisine?: string): Promise<RestaurantEntity[]> {
    return this.diningService.findAll(cuisine);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get restaurant details' })
  async findOne(@Param('id') id: string): Promise<RestaurantEntity> {
    return this.diningService.findOne(id);
  }
}
