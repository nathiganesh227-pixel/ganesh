import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { StaysService } from './stays.service';
import { HotelEntity } from '../../database/entities/hotel.entity';

@ApiTags('stays')
@Controller('stays')
export class StaysController {
  constructor(private readonly service: StaysService) {}

  @Get()
  @ApiOperation({ summary: 'Get all hotels' })
  async findAll(
    @Query('category') category?: string,
    @Query('q') q?: string,
    @Query('city') city?: string,
  ): Promise<HotelEntity[]> {
    return this.service.findAll(category, q, city);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get hotel details' })
  async findOne(@Param('id') id: string): Promise<HotelEntity> {
    return this.service.findOne(id);
  }
}
