import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SportsVenueEntity } from '../../database/entities/sports-venue.entity';
import { SportsService } from './sports.service';
import { SportsController } from './sports.controller';

@Module({
  imports: [TypeOrmModule.forFeature([SportsVenueEntity])],
  controllers: [SportsController],
  providers: [SportsService],
  exports: [SportsService],
})
export class SportsModule {}
