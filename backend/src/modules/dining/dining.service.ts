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

  async findAll(cuisine?: string, q?: string, city?: string): Promise<RestaurantEntity[]> {
    let list = await this.repo.find({ where: { isPublished: true } });
    if (city && city.trim().length > 0) {
      const c = city.trim().toLowerCase();
      list = list.filter((r) => r.location?.toLowerCase().includes(c));
    }
    if (cuisine && cuisine.trim().length > 0) {
      const cu = cuisine.trim().toLowerCase();
      list = list.filter((r) => r.cuisines?.some((c) => c.toLowerCase().includes(cu)));
    }
    if (q && q.trim().length > 0) {
      const query = q.trim().toLowerCase();
      list = list.filter(
        (r) =>
          r.name?.toLowerCase().includes(query) ||
          r.tagline?.toLowerCase().includes(query) ||
          r.about?.toLowerCase().includes(query) ||
          r.location?.toLowerCase().includes(query) ||
          r.cuisines?.some((c) => c.toLowerCase().includes(query)) ||
          r.popularDishes?.some((d) => d.name?.toLowerCase().includes(query)),
      );
    }
    return list;
  }

  async findOne(id: string): Promise<RestaurantEntity> {
    const restaurant = await this.repo.findOne({ where: { id, isPublished: true } });
    if (!restaurant) throw new NotFoundException(`Restaurant with ID ${id} not found`);
    return restaurant;
  }
}
