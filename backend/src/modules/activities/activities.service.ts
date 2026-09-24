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

  async findAll(category?: string): Promise<ActivityEntity[]> {
    if (category) {
      return this.repo.find({ where: { category } });
    }
    return this.repo.find();
  }

  async findOne(id: string): Promise<ActivityEntity> {
    const item = await this.repo.findOne({ where: { id } });
    if (!item) throw new NotFoundException(`Activity with ID ${id} not found`);
    return item;
  }
}
