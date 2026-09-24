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

  async findAll(category?: string): Promise<EventEntity[]> {
    if (category) {
      return this.repo.find({ where: { category } });
    }
    return this.repo.find();
  }

  async findOne(id: string): Promise<EventEntity> {
    const event = await this.repo.findOne({ where: { id } });
    if (!event) throw new NotFoundException(`Event with ID ${id} not found`);
    return event;
  }
}
