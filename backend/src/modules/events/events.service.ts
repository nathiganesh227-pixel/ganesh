import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EventEntity } from '../../database/entities/event.entity';

@Injectable()
export class EventsService {
  constructor(
    @InjectRepository(EventEntity)
    private readonly repo: Repository<EventEntity>,
  ) {}

  async findAll(category?: string, q?: string, city?: string): Promise<EventEntity[]> {
    let list = await this.repo.find({ where: { isPublished: true } });

    if (category && category.trim().length > 0) {
      const cat = category.trim().toLowerCase();
      list = list.filter((e) => e.category?.toLowerCase().includes(cat));
    }

    if (city && city.trim().length > 0) {
      const c = city.trim().toLowerCase();
      list = list.filter(
        (e) => e.location?.toLowerCase().includes(c) || e.venue?.toLowerCase().includes(c),
      );
    }

    if (q && q.trim().length > 0) {
      const query = q.trim().toLowerCase();
      list = list.filter(
        (e) =>
          e.title?.toLowerCase().includes(query) ||
          e.tagline?.toLowerCase().includes(query) ||
          e.description?.toLowerCase().includes(query) ||
          e.venue?.toLowerCase().includes(query) ||
          e.location?.toLowerCase().includes(query) ||
          e.category?.toLowerCase().includes(query) ||
          e.languages?.toLowerCase().includes(query) ||
          e.performers?.some((p) => p.name?.toLowerCase().includes(query)),
      );
    }

    return list;
  }

  async findOne(id: string): Promise<EventEntity> {
    const event = await this.repo.findOne({ where: { id, isPublished: true } });
    if (!event) throw new NotFoundException(`Event with ID ${id} not found`);
    return event;
  }
}
