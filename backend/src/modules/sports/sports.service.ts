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

  async findAll(sport?: string, q?: string, city?: string): Promise<SportsVenueEntity[]> {
    let list = await this.repo.find({ where: { isPublished: true } });
    if (city && city.trim() !== '') {
      const cityLower = city.trim().toLowerCase();
      list = list.filter((v) =>
        (v.location && v.location.toLowerCase().includes(cityLower)) ||
        ((v as any).address && (v as any).address.toLowerCase().includes(cityLower))
      );
    }
    if (sport && sport.trim() !== '') {
      const sportLower = sport.trim().toLowerCase();
      list = list.filter((v) =>
        v.supportedSports && v.supportedSports.some((s) => s.toLowerCase().includes(sportLower))
      );
    }
    if (q && q.trim() !== '') {
      const queryLower = q.trim().toLowerCase();
      list = list.filter((v) =>
        v.name?.toLowerCase().includes(queryLower) ||
        v.location?.toLowerCase().includes(queryLower) ||
        ((v as any).address && (v as any).address.toLowerCase().includes(queryLower)) ||
        ((v as any).description && (v as any).description.toLowerCase().includes(queryLower)) ||
        (v.supportedSports && v.supportedSports.some((s) => s.toLowerCase().includes(queryLower)))
      );
    }
    return list;
  }

  async findOne(id: string): Promise<SportsVenueEntity> {
    const item = await this.repo.findOne({ where: { id, isPublished: true } });
    if (!item) throw new NotFoundException(`Sports venue with ID ${id} not found`);
    return item;
  }
}
