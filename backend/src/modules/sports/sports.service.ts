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
    if (sport) {
      const all = await this.repo.find();
      return all.filter((v) => v.supportedSports.some((s) => s.toLowerCase().includes(sport.toLowerCase())));
    }
    return this.repo.find();
  }

  async findOne(id: string): Promise<SportsVenueEntity> {
    const item = await this.repo.findOne({ where: { id } });
    if (!item) throw new NotFoundException(`Sports venue with ID ${id} not found`);
    return item;
  }
}
