import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SportsVenueEntity } from '../../database/entities/sports-venue.entity';

@Injectable()
export class SportsService {
  constructor(
    @InjectRepository(SportsVenueEntity)
    private readonly repo: Repository<SportsVenueEntity>,
  ) {}

  async findAll(sport?: string): Promise<SportsVenueEntity[]> {
    const list = await this.repo.find({ where: { isPublished: true } });
    if (sport) {
      return list.filter((v) => v.supportedSports.some((s) => s.toLowerCase().includes(sport.toLowerCase())));
    }
    return list;
  }

  async findOne(id: string): Promise<SportsVenueEntity> {
    const item = await this.repo.findOne({ where: { id, isPublished: true } });
    if (!item) throw new NotFoundException(`Sports venue with ID ${id} not found`);
    return item;
  }
}
