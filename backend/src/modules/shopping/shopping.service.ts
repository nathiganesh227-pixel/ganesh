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

  async findAll(category?: string, q?: string, brand?: string): Promise<ProductEntity[]> {
    let items = await this.repo.find({ where: { isPublished: true } });
    if (category && category !== 'all') {
      const catLower = category.toLowerCase();
      items = items.filter(
        (i) => i.category && i.category.toLowerCase().includes(catLower),
      );
    }
    if (brand) {
      const brandLower = brand.toLowerCase();
      items = items.filter(
        (i) => i.brand && i.brand.toLowerCase().includes(brandLower),
      );
    }
    if (q) {
      const qLower = q.toLowerCase();
      items = items.filter(
        (i) =>
          (i.name && i.name.toLowerCase().includes(qLower)) ||
          (i.brand && i.brand.toLowerCase().includes(qLower)) ||
          (i.category && i.category.toLowerCase().includes(qLower)) ||
          (i.description && i.description.toLowerCase().includes(qLower)) ||
          (i.storeName && i.storeName.toLowerCase().includes(qLower)),
      );
    }
    return items;
  }

  async findOne(id: string): Promise<ProductEntity> {
    const item = await this.repo.findOne({ where: { id, isPublished: true } });
    if (!item) throw new NotFoundException(`Product with ID ${id} not found`);
    return item;
  }
}
