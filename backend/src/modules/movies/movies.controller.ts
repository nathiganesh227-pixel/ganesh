import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { MoviesService } from './movies.service';
import { MovieEntity } from '../../database/entities/movie.entity';
import { TheatreEntity } from '../../database/entities/theatre.entity';

@ApiTags('movies')
@Controller('movies')
export class MoviesController {
  constructor(private readonly moviesService: MoviesService) {}

  @Get()
  @ApiOperation({ summary: 'Get all movies or filter by search query' })
  @ApiResponse({ status: 200, description: 'List of movies returned' })
  async findAll(@Query('q') query?: string): Promise<MovieEntity[]> {
    return this.moviesService.findAll(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get detailed movie info by ID' })
  async findOne(@Param('id') id: string): Promise<MovieEntity> {
    return this.moviesService.findOne(id);
  }

  @Get(':id/showtimes')
  @ApiOperation({ summary: 'Get theatres and showtimes for movie' })
  async findTheatres(@Param('id') id: string): Promise<TheatreEntity[]> {
    return this.moviesService.findTheatres(id);
  }
}
