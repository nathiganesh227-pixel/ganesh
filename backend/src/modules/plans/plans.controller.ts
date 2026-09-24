import { Controller, Get, Post, Param, Body, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PlansService } from './plans.service';
import { PlanEntity } from '../../database/entities/plan.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('plans')
@Controller('plans')
export class PlansController {
  constructor(private readonly service: PlansService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all saved plans for authenticated user' })
  async findAll(@Request() req: any): Promise<PlanEntity[]> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    return this.service.findAll(userId);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get plan details' })
  async findOne(@Request() req: any, @Param('id') id: string): Promise<PlanEntity> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    return this.service.findOne(id, userId);
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Save new plan' })
  async create(@Request() req: any, @Body() body: Partial<PlanEntity>): Promise<PlanEntity> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    return this.service.create({ ...body, userId });
  }
}
