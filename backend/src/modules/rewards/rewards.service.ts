import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RewardEntity } from '../../database/entities/reward.entity';

@Injectable()
export class RewardsService {
  constructor(
    @InjectRepository(RewardEntity)
    private readonly repo: Repository<RewardEntity>,
  ) {}

  async findAll(): Promise<RewardEntity[]> {
    return this.repo.find();
  }

  async findOne(id: string): Promise<RewardEntity> {
    const item = await this.repo.findOne({ where: { id } });
    if (!item) throw new NotFoundException(`Reward with ID ${id} not found`);
    return item;
  }
}
