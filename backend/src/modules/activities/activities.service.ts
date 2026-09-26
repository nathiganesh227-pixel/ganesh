import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ActivityEntity } from '../../database/entities/activity.entity';

@Injectable()
export class ActivitiesService {
  constructor(
    @InjectRepository(ActivityEntity)
    private readonly repo: Repository<ActivityEntity>,
  ) {}

  async findAll(category?: string, q?: string, city?: string): Promise<ActivityEntity[]> {
    let items = await this.repo.find({ where: { isPublished: true } });
    if (category && category.toLowerCase() !== 'all') {
      items = items.filter(
        (a) => a.category?.toLowerCase() === category.toLowerCase(),
      );
    }
    if (city && city.trim() !== '') {
      const c = city.toLowerCase();
      items = items.filter(
        (a) =>
          a.location?.toLowerCase().includes(c) ||
          (c === 'hyderabad' &&
            (a.location?.toLowerCase().includes('hitec') ||
              a.location?.toLowerCase().includes('inorbit') ||
              a.location?.toLowerCase().includes('shamshabad') ||
              a.location?.toLowerCase().includes('gachibowli'))),
      );
    }
    if (q && q.trim() !== '') {
      const query = q.toLowerCase();
      items = items.filter(
        (a) =>
          a.title?.toLowerCase().includes(query) ||
          a.description?.toLowerCase().includes(query) ||
          a.tagline?.toLowerCase().includes(query) ||
          a.category?.toLowerCase().includes(query) ||
          a.location?.toLowerCase().includes(query),
      );
    }
    return items;
  }

  async findOne(id: string): Promise<ActivityEntity> {
    const item = await this.repo.findOne({ where: { id, isPublished: true } });
    if (!item) throw new NotFoundException(`Activity with ID ${id} not found`);
    return item;
  }
}
