import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { RewardsService } from './rewards.service';
import { RewardEntity } from '../../database/entities/reward.entity';

@ApiTags('rewards')
@Controller('rewards')
export class RewardsController {
  constructor(private readonly service: RewardsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all rewards vouchers' })
  async findAll(): Promise<RewardEntity[]> {
    return this.service.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get reward details' })
  async findOne(@Param('id') id: string): Promise<RewardEntity> {
    return this.service.findOne(id);
  }
}
