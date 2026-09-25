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

  async findAll(category?: string): Promise<HotelEntity[]> {
    if (category) {
      return this.repo.find({ where: { category, isPublished: true } });
    }
    return this.repo.find({ where: { isPublished: true } });
  }

  async findOne(id: string): Promise<HotelEntity> {
    const item = await this.repo.findOne({ where: { id, isPublished: true } });
    if (!item) throw new NotFoundException(`Hotel with ID ${id} not found`);
    return item;
  }
}
