import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RestaurantEntity } from '../../database/entities/restaurant.entity';
import { DiningService } from './dining.service';
import { DiningController } from './dining.controller';

@Module({
  imports: [TypeOrmModule.forFeature([RestaurantEntity])],
  controllers: [DiningController],
  providers: [DiningService],
  exports: [DiningService],
})
export class DiningModule {}
