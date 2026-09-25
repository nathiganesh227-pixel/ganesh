import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { MovieEntity } from '../../database/entities/movie.entity';
import { TheatreEntity } from '../../database/entities/theatre.entity';
import { ScreenEntity } from '../../database/entities/screen.entity';
import { ShowEntity } from '../../database/entities/show.entity';

@Injectable()
export class MoviesService {
  constructor(
    @InjectRepository(MovieEntity)
    private readonly movieRepo: Repository<MovieEntity>,
    @InjectRepository(TheatreEntity)
    private readonly theatreRepo: Repository<TheatreEntity>,
    @InjectRepository(ScreenEntity)
    private readonly screenRepo: Repository<ScreenEntity>,
    @InjectRepository(ShowEntity)
    private readonly showRepo: Repository<ShowEntity>,
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

  async findShowsForMovie(
    movieId: string,
    options?: { date?: string; city?: string; theatreId?: string },
  ) {
    const movie = await this.movieRepo.findOne({ where: { id: movieId } });
    if (!movie) {
      throw new NotFoundException(`Movie with ID ${movieId} not found`);
    }

    const where: any = { movieId, status: 'active' };
    if (options?.date) where.showDate = options.date;
    if (options?.theatreId) where.theatreId = options.theatreId;

    const shows = await this.showRepo.find({
      where,
      order: { showDate: 'ASC', startTime: 'ASC' },
    });

    const theatres = await this.theatreRepo.find();
    const screens = await this.screenRepo.find();

    const theatreMap = new Map(theatres.map((t) => [t.id, t]));
    const screenMap = new Map(screens.map((s) => [s.id, s]));

    let enrichedShows = shows.map((show) => {
      const theatre = theatreMap.get(show.theatreId);
      const screen = screenMap.get(show.screenId);
      return {
        id: show.id,
        movieId: show.movieId,
        movieTitle: movie.title,
        theatreId: show.theatreId,
        theatreName: theatre?.name || 'PLAZA Cinema',
        theatreCity: theatre?.city || 'Hyderabad',
        theatreLocation: theatre?.location || '',
        screenId: show.screenId,
        screenName: screen?.name || 'Screen 1',
        format: show.format,
        language: show.language,
        showDate: show.showDate,
        startTime: show.startTime,
        pricing: show.pricing,
        seatAvailability: {
          totalSeats: show.seatAvailability?.totalSeats || screen?.capacity || 200,
          availableSeats:
            (show.seatAvailability?.totalSeats || screen?.capacity || 200) -
            (show.seatAvailability?.bookedSeats?.length || 0),
        },
      };
    });

    if (options?.city) {
      const cityLower = options.city.toLowerCase();
      enrichedShows = enrichedShows.filter(
        (s) =>
          s.theatreCity.toLowerCase() === cityLower ||
          s.theatreLocation.toLowerCase().includes(cityLower),
      );
    }

    return enrichedShows;
  }
}
