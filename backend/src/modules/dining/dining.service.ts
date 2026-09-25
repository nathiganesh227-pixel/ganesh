import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RestaurantEntity } from '../../database/entities/restaurant.entity';

@Injectable()
export class DiningService {
  constructor(
    @InjectRepository(RestaurantEntity)
    private readonly repo: Repository<RestaurantEntity>,
  ) {}

  async findAll(cuisine?: string): Promise<RestaurantEntity[]> {
    const list = await this.repo.find({ where: { isPublished: true } });
    if (cuisine) {
      return list.filter((r) => r.cuisines.some((c) => c.toLowerCase().includes(cuisine.toLowerCase())));
    }
    return list;
  }

  async findOne(id: string): Promise<RestaurantEntity> {
    const restaurant = await this.repo.findOne({ where: { id, isPublished: true } });
    if (!restaurant) throw new NotFoundException(`Restaurant with ID ${id} not found`);
    return restaurant;
  }
}
