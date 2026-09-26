import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { HotelEntity } from '../../database/entities/hotel.entity';

@Injectable()
export class StaysService {
  constructor(
    @InjectRepository(HotelEntity)
    private readonly repo: Repository<HotelEntity>,
  ) {}

  async findAll(category?: string, q?: string, city?: string): Promise<HotelEntity[]> {
    let items = await this.repo.find({ where: { isPublished: true } });
    if (category && category.toLowerCase() !== 'all') {
      items = items.filter(
        (h) => h.category?.toLowerCase() === category.toLowerCase(),
      );
    }
    if (city && city.trim() !== '') {
      const c = city.toLowerCase();
      items = items.filter(
        (h) =>
          h.location?.toLowerCase().includes(c) ||
          (c === 'hyderabad' &&
            (h.location?.toLowerCase().includes('falaknuma') ||
              h.location?.toLowerCase().includes('banjara') ||
              h.location?.toLowerCase().includes('hitec') ||
              h.location?.toLowerCase().includes('gachibowli'))),
      );
    }
    if (q && q.trim() !== '') {
      const query = q.toLowerCase();
      items = items.filter(
        (h) =>
          h.name?.toLowerCase().includes(query) ||
          h.tagline?.toLowerCase().includes(query) ||
          h.description?.toLowerCase().includes(query) ||
          h.location?.toLowerCase().includes(query) ||
          h.category?.toLowerCase().includes(query),
      );
    }
    return items;
  }

  async findOne(id: string): Promise<HotelEntity> {
    const item = await this.repo.findOne({ where: { id, isPublished: true } });
    if (!item) throw new NotFoundException(`Hotel with ID ${id} not found`);
    return item;
  }
}
