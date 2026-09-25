import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { User, UserRole } from '../../database/entities/user.entity';
import { MovieEntity } from '../../database/entities/movie.entity';
import { TheatreEntity } from '../../database/entities/theatre.entity';
import { RestaurantEntity } from '../../database/entities/restaurant.entity';
import { EventEntity } from '../../database/entities/event.entity';
import { ActivityEntity } from '../../database/entities/activity.entity';
import { ProductEntity } from '../../database/entities/product.entity';
import { HotelEntity } from '../../database/entities/hotel.entity';
import { SportsVenueEntity } from '../../database/entities/sports-venue.entity';
import { BookingEntity } from '../../database/entities/booking.entity';
import { AuditLogEntity } from '../../database/entities/audit-log.entity';
import { ScreenEntity } from '../../database/entities/screen.entity';
import { ShowEntity } from '../../database/entities/show.entity';

import { UpdateRoleDto } from './dto/admin.dto';
import {
  CreateMovieDto,
  UpdateMovieDto,
  CreateTheatreDto,
  UpdateTheatreDto,
  CreateScreenDto,
  UpdateScreenDto,
  CreateShowDto,
  UpdateShowDto,
} from './dto/movie-show.dto';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(MovieEntity)
    private readonly movieRepo: Repository<MovieEntity>,
    @InjectRepository(TheatreEntity)
    private readonly theatreRepo: Repository<TheatreEntity>,
    @InjectRepository(RestaurantEntity)
    private readonly restaurantRepo: Repository<RestaurantEntity>,
    @InjectRepository(EventEntity)
    private readonly eventRepo: Repository<EventEntity>,
    @InjectRepository(ActivityEntity)
    private readonly activityRepo: Repository<ActivityEntity>,
    @InjectRepository(ProductEntity)
    private readonly productRepo: Repository<ProductEntity>,
    @InjectRepository(HotelEntity)
    private readonly hotelRepo: Repository<HotelEntity>,
    @InjectRepository(SportsVenueEntity)
    private readonly sportsVenueRepo: Repository<SportsVenueEntity>,
    @InjectRepository(BookingEntity)
    private readonly bookingRepo: Repository<BookingEntity>,
    @InjectRepository(AuditLogEntity)
    private readonly auditLogRepo: Repository<AuditLogEntity>,
    @InjectRepository(ScreenEntity)
    private readonly screenRepo: Repository<ScreenEntity>,
    @InjectRepository(ShowEntity)
    private readonly showRepo: Repository<ShowEntity>,
  ) {}

  getHealth() {
    return {
      admin: true,
    };
  }

  async getDashboardStats() {
    const [
      users,
      movies,
      dining,
      events,
      activities,
      shopping,
      stays,
      sports,
      bookings,
    ] = await Promise.all([
      this.userRepo.count(),
      this.movieRepo.count(),
      this.restaurantRepo.count(),
      this.eventRepo.count(),
      this.activityRepo.count(),
      this.productRepo.count(),
      this.hotelRepo.count(),
      this.sportsVenueRepo.count(),
      this.bookingRepo.count(),
    ]);

    return {
      users,
      movies,
      dining,
      events,
      activities,
      shopping,
      stays,
      sports,
      bookings,
    };
  }

  // ---------------- USER MANAGEMENT ----------------
  async getUsers(limit = 50, offset = 0) {
    const users = await this.userRepo.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
    });
    return users.map((user) => this.toSafeUser(user));
  }

  async getUserById(id: string) {
    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return this.toSafeUser(user);
  }

  async updateUserRole(
    userId: string,
    dto: UpdateRoleDto,
    actor: { id?: string; sub?: string; email: string },
  ) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    if (user.role === UserRole.ADMIN && dto.role !== UserRole.ADMIN) {
      const adminCount = await this.userRepo.count({ where: { role: UserRole.ADMIN } });
      if (adminCount <= 1) {
        throw new BadRequestException('Cannot demote the last remaining administrator account.');
      }
    }

    const previousRole = user.role;
    user.role = dto.role;
    await this.userRepo.save(user);

    await this.createAuditRecord(actor, 'UPDATE_USER_ROLE', 'User', user.id, {
      targetEmail: user.email,
      previousRole,
      newRole: dto.role,
    });

    return this.toSafeUser(user);
  }

  // ---------------- MOVIE MANAGEMENT ----------------
  async getMovies(limit = 50, offset = 0) {
    return this.movieRepo.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
    });
  }

  async createMovie(dto: CreateMovieDto, actor: any) {
    const id = `mov_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const movie = this.movieRepo.create({
      id,
      ...dto,
      isNowShowing: dto.isNowShowing ?? true,
      isTrending: dto.isTrending ?? false,
      isComingSoon: dto.isComingSoon ?? false,
    });
    await this.movieRepo.save(movie);

    await this.createAuditRecord(actor, 'CREATE_MOVIE', 'Movie', movie.id, {
      title: movie.title,
    });

    return movie;
  }

  async updateMovie(id: string, dto: UpdateMovieDto, actor: any) {
    const movie = await this.movieRepo.findOne({ where: { id } });
    if (!movie) {
      throw new NotFoundException(`Movie with ID ${id} not found`);
    }

    Object.assign(movie, dto);
    await this.movieRepo.save(movie);

    await this.createAuditRecord(actor, 'UPDATE_MOVIE', 'Movie', movie.id, {
      updatedFields: Object.keys(dto),
    });

    return movie;
  }

  async deleteMovie(id: string, actor: any) {
    const movie = await this.movieRepo.findOne({ where: { id } });
    if (!movie) {
      throw new NotFoundException(`Movie with ID ${id} not found`);
    }

    // Check if bookings or shows reference this movie
    const activeShowsCount = await this.showRepo.count({
      where: { movieId: id, status: 'active' },
    });

    if (activeShowsCount > 0) {
      // Safe lifecycle archival if active shows exist
      movie.isNowShowing = false;
      await this.movieRepo.save(movie);

      await this.createAuditRecord(actor, 'ARCHIVE_MOVIE', 'Movie', id, {
        reason: 'Active shows exist; set isNowShowing to false',
      });

      return { success: true, message: 'Movie archived (marked not showing) due to active shows' };
    }

    await this.movieRepo.delete(id);

    await this.createAuditRecord(actor, 'DELETE_MOVIE', 'Movie', id, {
      title: movie.title,
    });

    return { success: true, message: 'Movie deleted successfully' };
  }

  // ---------------- THEATRE MANAGEMENT ----------------
  async getTheatres(limit = 50, offset = 0) {
    return this.theatreRepo.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
    });
  }

  async getTheatreById(id: string) {
    const theatre = await this.theatreRepo.findOne({ where: { id } });
    if (!theatre) {
      throw new NotFoundException(`Theatre with ID ${id} not found`);
    }
    return theatre;
  }

  async createTheatre(dto: CreateTheatreDto, actor: any) {
    const id = `theatre_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const theatre = this.theatreRepo.create({
      id,
      name: dto.name,
      location: dto.location,
      city: dto.city || 'Hyderabad',
      address: dto.address || dto.location,
      distance: dto.distance || '0 km',
      amenities: dto.amenities || ['Dolby Atmos', '4K Projection'],
      isActive: dto.isActive ?? true,
      showtimes: [],
    });
    await this.theatreRepo.save(theatre);

    await this.createAuditRecord(actor, 'CREATE_THEATRE', 'Theatre', theatre.id, {
      name: theatre.name,
      city: theatre.city,
    });

    return theatre;
  }

  async updateTheatre(id: string, dto: UpdateTheatreDto, actor: any) {
    const theatre = await this.theatreRepo.findOne({ where: { id } });
    if (!theatre) {
      throw new NotFoundException(`Theatre with ID ${id} not found`);
    }

    Object.assign(theatre, dto);
    await this.theatreRepo.save(theatre);

    await this.createAuditRecord(actor, 'UPDATE_THEATRE', 'Theatre', theatre.id, {
      updatedFields: Object.keys(dto),
    });

    return theatre;
  }

  // ---------------- SCREEN MANAGEMENT ----------------
  async getScreens(theatreId?: string, limit = 50, offset = 0) {
    const where = theatreId ? { theatreId } : {};
    return this.screenRepo.find({
      where,
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
    });
  }

  async getScreenById(id: string) {
    const screen = await this.screenRepo.findOne({ where: { id } });
    if (!screen) {
      throw new NotFoundException(`Screen with ID ${id} not found`);
    }
    return screen;
  }

  async createScreen(theatreId: string, dto: CreateScreenDto, actor: any) {
    const theatre = await this.theatreRepo.findOne({ where: { id: theatreId } });
    if (!theatre) {
      throw new NotFoundException(`Theatre with ID ${theatreId} not found`);
    }

    if (!dto.capacity || dto.capacity <= 0) {
      throw new BadRequestException('Screen capacity must be a positive integer');
    }

    const id = `scr_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const screen = this.screenRepo.create({
      id,
      theatreId,
      name: dto.name,
      screenType: dto.screenType || 'standard',
      capacity: dto.capacity,
      seatLayout: dto.seatLayout || null,
      isActive: dto.isActive ?? true,
    });

    await this.screenRepo.save(screen);

    await this.createAuditRecord(actor, 'CREATE_SCREEN', 'Screen', screen.id, {
      theatreId,
      screenName: screen.name,
      capacity: screen.capacity,
    });

    return screen;
  }

  async updateScreen(id: string, dto: UpdateScreenDto, actor: any) {
    const screen = await this.screenRepo.findOne({ where: { id } });
    if (!screen) {
      throw new NotFoundException(`Screen with ID ${id} not found`);
    }

    if (dto.capacity !== undefined && dto.capacity <= 0) {
      throw new BadRequestException('Screen capacity must be a positive integer');
    }

    Object.assign(screen, dto);
    await this.screenRepo.save(screen);

    await this.createAuditRecord(actor, 'UPDATE_SCREEN', 'Screen', screen.id, {
      updatedFields: Object.keys(dto),
    });

    return screen;
  }

  // ---------------- SHOW MANAGEMENT ----------------
  async getShows(
    movieId?: string,
    theatreId?: string,
    date?: string,
    limit = 50,
    offset = 0,
  ) {
    const where: any = {};
    if (movieId) where.movieId = movieId;
    if (theatreId) where.theatreId = theatreId;
    if (date) where.showDate = date;

    return this.showRepo.find({
      where,
      take: limit,
      skip: offset,
      order: { showDate: 'ASC', startTime: 'ASC' },
    });
  }

  async getShowById(id: string) {
    const show = await this.showRepo.findOne({ where: { id } });
    if (!show) {
      throw new NotFoundException(`Show with ID ${id} not found`);
    }
    return show;
  }

  async createShow(dto: CreateShowDto, actor: any) {
    // 1. Verify movie exists
    const movie = await this.movieRepo.findOne({ where: { id: dto.movieId } });
    if (!movie) {
      throw new NotFoundException(`Movie with ID ${dto.movieId} not found`);
    }

    // 2. Verify theatre exists
    const theatre = await this.theatreRepo.findOne({ where: { id: dto.theatreId } });
    if (!theatre) {
      throw new NotFoundException(`Theatre with ID ${dto.theatreId} not found`);
    }

    // 3. Verify screen exists
    const screen = await this.screenRepo.findOne({ where: { id: dto.screenId } });
    if (!screen) {
      throw new NotFoundException(`Screen with ID ${dto.screenId} not found`);
    }

    // 4. Verify screen belongs to the specified theatre
    if (screen.theatreId !== dto.theatreId) {
      throw new BadRequestException(
        `Screen ${dto.screenId} does not belong to Theatre ${dto.theatreId}`,
      );
    }

    // 5. Check duplicate show collision on same screen at same date & time
    const collision = await this.showRepo.findOne({
      where: {
        screenId: dto.screenId,
        showDate: dto.showDate,
        startTime: dto.startTime,
        status: 'active',
      },
    });

    if (collision) {
      throw new BadRequestException(
        `A show is already scheduled on Screen ${dto.screenId} on ${dto.showDate} at ${dto.startTime}`,
      );
    }

    const id = `shw_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const show = this.showRepo.create({
      id,
      movieId: dto.movieId,
      theatreId: dto.theatreId,
      screenId: dto.screenId,
      showDate: dto.showDate,
      startTime: dto.startTime,
      format: dto.format || screen.screenType || '2D',
      language: dto.language || movie.primaryLanguage || 'Telugu',
      pricing: dto.pricing,
      seatAvailability: {
        totalSeats: screen.capacity,
        bookedSeats: [],
      },
      status: 'active',
    });

    await this.showRepo.save(show);

    await this.createAuditRecord(actor, 'CREATE_SHOW', 'Show', show.id, {
      movieId: show.movieId,
      theatreId: show.theatreId,
      screenId: show.screenId,
      showDate: show.showDate,
      startTime: show.startTime,
    });

    return show;
  }

  async updateShow(id: string, dto: UpdateShowDto, actor: any) {
    const show = await this.showRepo.findOne({ where: { id } });
    if (!show) {
      throw new NotFoundException(`Show with ID ${id} not found`);
    }

    Object.assign(show, dto);
    await this.showRepo.save(show);

    await this.createAuditRecord(actor, 'UPDATE_SHOW', 'Show', show.id, {
      updatedFields: Object.keys(dto),
    });

    return show;
  }

  async deleteShow(id: string, actor: any) {
    const show = await this.showRepo.findOne({ where: { id } });
    if (!show) {
      throw new NotFoundException(`Show with ID ${id} not found`);
    }

    // Check if seats have already been booked
    const bookedCount = show.seatAvailability?.bookedSeats?.length || 0;
    if (bookedCount > 0) {
      // Mark cancelled rather than deleting active bookings
      show.status = 'cancelled';
      await this.showRepo.save(show);

      await this.createAuditRecord(actor, 'CANCEL_SHOW', 'Show', id, {
        reason: 'Bookings exist; marked status to cancelled',
        bookedCount,
      });

      return { success: true, message: 'Show cancelled (bookings exist)' };
    }

    await this.showRepo.delete(id);

    await this.createAuditRecord(actor, 'DELETE_SHOW', 'Show', id, {
      movieId: show.movieId,
      showDate: show.showDate,
      startTime: show.startTime,
    });

    return { success: true, message: 'Show deleted successfully' };
  }

  // ---------------- AUDIT LOGS ----------------
  async getAuditLogs(limit = 50, offset = 0) {
    return this.auditLogRepo.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
    });
  }

  private async createAuditRecord(
    actor: { id?: string; sub?: string; email?: string },
    action: string,
    resourceType: string,
    resourceId: string,
    metadata?: Record<string, any>,
  ) {
    await this.auditLogRepo.save({
      id: `aud_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      actorUserId: actor?.sub || actor?.id || 'admin',
      actorEmail: actor?.email || 'admin@plaza.app',
      action,
      resourceType,
      resourceId,
      metadata: metadata || null,
    });
  }

  private toSafeUser(user: User) {
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone || null,
      city: user.city || null,
      role: user.role,
      rewardPoints: user.rewardPoints,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }
}
