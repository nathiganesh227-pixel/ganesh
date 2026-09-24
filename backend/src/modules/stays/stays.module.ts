import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HotelEntity } from '../../database/entities/hotel.entity';
import { StaysService } from './stays.service';
import { StaysController } from './stays.controller';

@Module({
  imports: [TypeOrmModule.forFeature([HotelEntity])],
  controllers: [StaysController],
  providers: [StaysService],
  exports: [StaysService],
})
export class StaysModule {}
