import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductEntity } from '../../database/entities/product.entity';

@Injectable()
export class ShoppingService {
  constructor(
    @InjectRepository(ProductEntity)
    private readonly repo: Repository<ProductEntity>,
  ) {}

  async findAll(category?: string): Promise<ProductEntity[]> {
    if (category) {
      return this.repo.find({ where: { category, isPublished: true } });
    }
    return this.repo.find({ where: { isPublished: true } });
  }

  async findOne(id: string): Promise<ProductEntity> {
    const item = await this.repo.findOne({ where: { id, isPublished: true } });
    if (!item) throw new NotFoundException(`Product with ID ${id} not found`);
    return item;
  }
}
