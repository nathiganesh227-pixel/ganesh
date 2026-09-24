import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PlanEntity } from '../../database/entities/plan.entity';

@Injectable()
export class PlansService {
  constructor(
    @InjectRepository(PlanEntity)
    private readonly repo: Repository<PlanEntity>,
  ) {}

  async findAll(userId = 'user_default'): Promise<PlanEntity[]> {
    return this.repo.find({ where: { userId } });
  }

  async findOne(id: string, userId?: string): Promise<PlanEntity> {
    const item = await this.repo.findOne({ where: { id } });
    if (!item) throw new NotFoundException(`Plan with ID ${id} not found`);
    if (userId && item.userId && item.userId !== userId) {
      throw new ForbiddenException('You do not have permission to view this plan');
    }
    return item;
  }

  async create(plan: Partial<PlanEntity>): Promise<PlanEntity> {
    const newPlan = this.repo.create({
      ...plan,
      userId: plan.userId || 'user_default',
      id: plan.id || `plan_${Date.now()}`,
    });
    return this.repo.save(newPlan);
  }
}
