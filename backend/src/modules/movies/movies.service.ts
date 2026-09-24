import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MovieEntity } from '../../database/entities/movie.entity';
import { TheatreEntity } from '../../database/entities/theatre.entity';

@Injectable()
export class MoviesService {
  constructor(
    @InjectRepository(MovieEntity)
    private readonly movieRepo: Repository<MovieEntity>,
    @InjectRepository(TheatreEntity)
    private readonly theatreRepo: Repository<TheatreEntity>,
  ) {}

  async findAll(query?: string): Promise<MovieEntity[]> {
    if (query) {
      const q = query.toLowerCase();
      const all = await this.movieRepo.find();
      return all.filter(
        (m) =>
          m.title.toLowerCase().includes(q) ||
          m.director.toLowerCase().includes(q) ||
          m.genres.some((g) => g.toLowerCase().includes(q)),
      );
    }
    return this.movieRepo.find();
  }

  async findOne(id: string): Promise<MovieEntity> {
    const movie = await this.movieRepo.findOne({ where: { id } });
    if (!movie) {
      throw new NotFoundException(`Movie with ID ${id} not found`);
    }
    return movie;
  }

  async findTheatres(movieId: string): Promise<TheatreEntity[]> {
    return this.theatreRepo.find();
  }
}
