import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MovieEntity } from '../../database/entities/movie.entity';
import { TheatreEntity } from '../../database/entities/theatre.entity';
import { ScreenEntity } from '../../database/entities/screen.entity';
import { ShowEntity } from '../../database/entities/show.entity';
import { MoviesService } from './movies.service';
import { MoviesController } from './movies.controller';

@Module({
  imports: [TypeOrmModule.forFeature([MovieEntity, TheatreEntity, ScreenEntity, ShowEntity])],
  controllers: [MoviesController],
  providers: [MoviesService],
  exports: [MoviesService],
})
export class MoviesModule {}
