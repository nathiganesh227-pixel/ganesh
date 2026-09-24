import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { ShoppingService } from './shopping.service';
import { ProductEntity } from '../../database/entities/product.entity';

@ApiTags('shopping')
@Controller('shopping')
export class ShoppingController {
  constructor(private readonly service: ShoppingService) {}

  @Get()
  @ApiOperation({ summary: 'Get all products' })
  async findAll(@Query('category') category?: string): Promise<ProductEntity[]> {
    return this.service.findAll(category);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get product details' })
  async findOne(@Param('id') id: string): Promise<ProductEntity> {
    return this.service.findOne(id);
  }
}
