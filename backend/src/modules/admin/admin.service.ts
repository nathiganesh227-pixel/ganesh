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
import {
  CreateDiningDto,
  UpdateDiningDto,
  CreateEventDto,
  UpdateEventDto,
  CreateActivityDto,
  UpdateActivityDto,
  CreateProductDto,
  UpdateProductDto,
  CreateHotelDto,
  UpdateHotelDto,
  CreateSportsVenueDto,
  UpdateSportsVenueDto,
} from './dto/vertical-catalog.dto';

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

  // ---------------- DINING MANAGEMENT ----------------
  async getDining(limit = 50, offset = 0) {
    return this.restaurantRepo.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
    });
  }

  async getDiningById(id: string) {
    const restaurant = await this.restaurantRepo.findOne({ where: { id } });
    if (!restaurant) {
      throw new NotFoundException(`Restaurant with ID ${id} not found`);
    }
    return restaurant;
  }

  async createDining(dto: CreateDiningDto, actor: any) {
    const id = `din_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const restaurant = this.restaurantRepo.create({
      id,
      ...dto,
      isPublished: dto.isPublished ?? true,
    });
    await this.restaurantRepo.save(restaurant);

    await this.createAuditRecord(actor, 'CREATE_DINING', 'Restaurant', restaurant.id, {
      name: restaurant.name,
      location: restaurant.location,
    });

    return restaurant;
  }

  async updateDining(id: string, dto: UpdateDiningDto, actor: any) {
    const restaurant = await this.restaurantRepo.findOne({ where: { id } });
    if (!restaurant) {
      throw new NotFoundException(`Restaurant with ID ${id} not found`);
    }

    Object.assign(restaurant, dto);
    await this.restaurantRepo.save(restaurant);

    await this.createAuditRecord(actor, 'UPDATE_DINING', 'Restaurant', restaurant.id, {
      updatedFields: Object.keys(dto),
    });

    return restaurant;
  }

  async deleteDining(id: string, actor: any) {
    const restaurant = await this.restaurantRepo.findOne({ where: { id } });
    if (!restaurant) {
      throw new NotFoundException(`Restaurant with ID ${id} not found`);
    }

    await this.restaurantRepo.delete(id);

    await this.createAuditRecord(actor, 'DELETE_DINING', 'Restaurant', id, {
      name: restaurant.name,
    });

    return { success: true, message: 'Restaurant deleted successfully' };
  }

  async publishDining(id: string, actor: any) {
    const restaurant = await this.restaurantRepo.findOne({ where: { id } });
    if (!restaurant) {
      throw new NotFoundException(`Restaurant with ID ${id} not found`);
    }

    restaurant.isPublished = true;
    await this.restaurantRepo.save(restaurant);

    await this.createAuditRecord(actor, 'PUBLISH_DINING', 'Restaurant', id);
    return restaurant;
  }

  async unpublishDining(id: string, actor: any) {
    const restaurant = await this.restaurantRepo.findOne({ where: { id } });
    if (!restaurant) {
      throw new NotFoundException(`Restaurant with ID ${id} not found`);
    }

    restaurant.isPublished = false;
    await this.restaurantRepo.save(restaurant);

    await this.createAuditRecord(actor, 'UNPUBLISH_DINING', 'Restaurant', id);
    return restaurant;
  }

  // ---------------- EVENT MANAGEMENT ----------------
  async getEvents(limit = 50, offset = 0) {
    return this.eventRepo.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
    });
  }

  async getEventById(id: string) {
    const event = await this.eventRepo.findOne({ where: { id } });
    if (!event) {
      throw new NotFoundException(`Event with ID ${id} not found`);
    }
    return event;
  }

  async createEvent(dto: CreateEventDto, actor: any) {
    const id = `evt_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const event = this.eventRepo.create({
      id,
      ...dto,
      isPublished: dto.isPublished ?? true,
    });
    await this.eventRepo.save(event);

    await this.createAuditRecord(actor, 'CREATE_EVENT', 'Event', event.id, {
      title: event.title,
      venue: event.venue,
    });

    return event;
  }

  async updateEvent(id: string, dto: UpdateEventDto, actor: any) {
    const event = await this.eventRepo.findOne({ where: { id } });
    if (!event) {
      throw new NotFoundException(`Event with ID ${id} not found`);
    }

    Object.assign(event, dto);
    await this.eventRepo.save(event);

    await this.createAuditRecord(actor, 'UPDATE_EVENT', 'Event', event.id, {
      updatedFields: Object.keys(dto),
    });

    return event;
  }

  async deleteEvent(id: string, actor: any) {
    const event = await this.eventRepo.findOne({ where: { id } });
    if (!event) {
      throw new NotFoundException(`Event with ID ${id} not found`);
    }

    await this.eventRepo.delete(id);

    await this.createAuditRecord(actor, 'DELETE_EVENT', 'Event', id, {
      title: event.title,
    });

    return { success: true, message: 'Event deleted successfully' };
  }

  async publishEvent(id: string, actor: any) {
    const event = await this.eventRepo.findOne({ where: { id } });
    if (!event) {
      throw new NotFoundException(`Event with ID ${id} not found`);
    }

    event.isPublished = true;
    await this.eventRepo.save(event);

    await this.createAuditRecord(actor, 'PUBLISH_EVENT', 'Event', id);
    return event;
  }

  async unpublishEvent(id: string, actor: any) {
    const event = await this.eventRepo.findOne({ where: { id } });
    if (!event) {
      throw new NotFoundException(`Event with ID ${id} not found`);
    }

    event.isPublished = false;
    await this.eventRepo.save(event);

    await this.createAuditRecord(actor, 'UNPUBLISH_EVENT', 'Event', id);
    return event;
  }

  // ---------------- ACTIVITY MANAGEMENT ----------------
  async getActivities(limit = 50, offset = 0) {
    return this.activityRepo.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
    });
  }

  async getActivityById(id: string) {
    const activity = await this.activityRepo.findOne({ where: { id } });
    if (!activity) {
      throw new NotFoundException(`Activity with ID ${id} not found`);
    }
    return activity;
  }

  async createActivity(dto: CreateActivityDto, actor: any) {
    const id = `act_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const activity = this.activityRepo.create({
      id,
      ...dto,
      isPublished: dto.isPublished ?? true,
    });
    await this.activityRepo.save(activity);

    await this.createAuditRecord(actor, 'CREATE_ACTIVITY', 'Activity', activity.id, {
      title: activity.title,
      location: activity.location,
    });

    return activity;
  }

  async updateActivity(id: string, dto: UpdateActivityDto, actor: any) {
    const activity = await this.activityRepo.findOne({ where: { id } });
    if (!activity) {
      throw new NotFoundException(`Activity with ID ${id} not found`);
    }

    Object.assign(activity, dto);
    await this.activityRepo.save(activity);

    await this.createAuditRecord(actor, 'UPDATE_ACTIVITY', 'Activity', activity.id, {
      updatedFields: Object.keys(dto),
    });

    return activity;
  }

  async deleteActivity(id: string, actor: any) {
    const activity = await this.activityRepo.findOne({ where: { id } });
    if (!activity) {
      throw new NotFoundException(`Activity with ID ${id} not found`);
    }

    await this.activityRepo.delete(id);

    await this.createAuditRecord(actor, 'DELETE_ACTIVITY', 'Activity', id, {
      title: activity.title,
    });

    return { success: true, message: 'Activity deleted successfully' };
  }

  async publishActivity(id: string, actor: any) {
    const activity = await this.activityRepo.findOne({ where: { id } });
    if (!activity) {
      throw new NotFoundException(`Activity with ID ${id} not found`);
    }

    activity.isPublished = true;
    await this.activityRepo.save(activity);

    await this.createAuditRecord(actor, 'PUBLISH_ACTIVITY', 'Activity', id);
    return activity;
  }

  async unpublishActivity(id: string, actor: any) {
    const activity = await this.activityRepo.findOne({ where: { id } });
    if (!activity) {
      throw new NotFoundException(`Activity with ID ${id} not found`);
    }

    activity.isPublished = false;
    await this.activityRepo.save(activity);

    await this.createAuditRecord(actor, 'UNPUBLISH_ACTIVITY', 'Activity', id);
    return activity;
  }

  // ---------------- SHOPPING MANAGEMENT ----------------
  async getProducts(limit = 50, offset = 0) {
    return this.productRepo.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
    });
  }

  async getProductById(id: string) {
    const product = await this.productRepo.findOne({ where: { id } });
    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }
    return product;
  }

  async createProduct(dto: CreateProductDto, actor: any) {
    const id = `prod_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const product = this.productRepo.create({
      id,
      ...dto,
      isPublished: dto.isPublished ?? true,
    });
    await this.productRepo.save(product);

    await this.createAuditRecord(actor, 'CREATE_PRODUCT', 'Product', product.id, {
      name: product.name,
      brand: product.brand,
    });

    return product;
  }

  async updateProduct(id: string, dto: UpdateProductDto, actor: any) {
    const product = await this.productRepo.findOne({ where: { id } });
    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }

    Object.assign(product, dto);
    await this.productRepo.save(product);

    await this.createAuditRecord(actor, 'UPDATE_PRODUCT', 'Product', product.id, {
      updatedFields: Object.keys(dto),
    });

    return product;
  }

  async deleteProduct(id: string, actor: any) {
    const product = await this.productRepo.findOne({ where: { id } });
    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }

    await this.productRepo.delete(id);

    await this.createAuditRecord(actor, 'DELETE_PRODUCT', 'Product', id, {
      name: product.name,
    });

    return { success: true, message: 'Product deleted successfully' };
  }

  async publishProduct(id: string, actor: any) {
    const product = await this.productRepo.findOne({ where: { id } });
    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }

    product.isPublished = true;
    await this.productRepo.save(product);

    await this.createAuditRecord(actor, 'PUBLISH_PRODUCT', 'Product', id);
    return product;
  }

  async unpublishProduct(id: string, actor: any) {
    const product = await this.productRepo.findOne({ where: { id } });
    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }

    product.isPublished = false;
    await this.productRepo.save(product);

    await this.createAuditRecord(actor, 'UNPUBLISH_PRODUCT', 'Product', id);
    return product;
  }

  // ---------------- STAYS MANAGEMENT ----------------
  async getHotels(limit = 50, offset = 0) {
    return this.hotelRepo.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
    });
  }

  async getHotelById(id: string) {
    const hotel = await this.hotelRepo.findOne({ where: { id } });
    if (!hotel) {
      throw new NotFoundException(`Hotel with ID ${id} not found`);
    }
    return hotel;
  }

  async createHotel(dto: CreateHotelDto, actor: any) {
    const id = `htl_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const hotel = this.hotelRepo.create({
      id,
      ...dto,
      isPublished: dto.isPublished ?? true,
    });
    await this.hotelRepo.save(hotel);

    await this.createAuditRecord(actor, 'CREATE_HOTEL', 'Hotel', hotel.id, {
      name: hotel.name,
      location: hotel.location,
    });

    return hotel;
  }

  async updateHotel(id: string, dto: UpdateHotelDto, actor: any) {
    const hotel = await this.hotelRepo.findOne({ where: { id } });
    if (!hotel) {
      throw new NotFoundException(`Hotel with ID ${id} not found`);
    }

    Object.assign(hotel, dto);
    await this.hotelRepo.save(hotel);

    await this.createAuditRecord(actor, 'UPDATE_HOTEL', 'Hotel', hotel.id, {
      updatedFields: Object.keys(dto),
    });

    return hotel;
  }

  async deleteHotel(id: string, actor: any) {
    const hotel = await this.hotelRepo.findOne({ where: { id } });
    if (!hotel) {
      throw new NotFoundException(`Hotel with ID ${id} not found`);
    }

    await this.hotelRepo.delete(id);

    await this.createAuditRecord(actor, 'DELETE_HOTEL', 'Hotel', id, {
      name: hotel.name,
    });

    return { success: true, message: 'Hotel deleted successfully' };
  }

  async publishHotel(id: string, actor: any) {
    const hotel = await this.hotelRepo.findOne({ where: { id } });
    if (!hotel) {
      throw new NotFoundException(`Hotel with ID ${id} not found`);
    }

    hotel.isPublished = true;
    await this.hotelRepo.save(hotel);

    await this.createAuditRecord(actor, 'PUBLISH_HOTEL', 'Hotel', id);
    return hotel;
  }

  async unpublishHotel(id: string, actor: any) {
    const hotel = await this.hotelRepo.findOne({ where: { id } });
    if (!hotel) {
      throw new NotFoundException(`Hotel with ID ${id} not found`);
    }

    hotel.isPublished = false;
    await this.hotelRepo.save(hotel);

    await this.createAuditRecord(actor, 'UNPUBLISH_HOTEL', 'Hotel', id);
    return hotel;
  }

  // ---------------- SPORTS MANAGEMENT ----------------
  async getSportsVenues(limit = 50, offset = 0) {
    return this.sportsVenueRepo.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
    });
  }

  async getSportsVenueById(id: string) {
    const venue = await this.sportsVenueRepo.findOne({ where: { id } });
    if (!venue) {
      throw new NotFoundException(`Sports venue with ID ${id} not found`);
    }
    return venue;
  }

  async createSportsVenue(dto: CreateSportsVenueDto, actor: any) {
    const id = `spt_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const venue = this.sportsVenueRepo.create({
      id,
      ...dto,
      isPublished: dto.isPublished ?? true,
    });
    await this.sportsVenueRepo.save(venue);

    await this.createAuditRecord(actor, 'CREATE_SPORTS_VENUE', 'SportsVenue', venue.id, {
      name: venue.name,
      location: venue.location,
    });

    return venue;
  }

  async updateSportsVenue(id: string, dto: UpdateSportsVenueDto, actor: any) {
    const venue = await this.sportsVenueRepo.findOne({ where: { id } });
    if (!venue) {
      throw new NotFoundException(`Sports venue with ID ${id} not found`);
    }

    Object.assign(venue, dto);
    await this.sportsVenueRepo.save(venue);

    await this.createAuditRecord(actor, 'UPDATE_SPORTS_VENUE', 'SportsVenue', venue.id, {
      updatedFields: Object.keys(dto),
    });

    return venue;
  }

  async deleteSportsVenue(id: string, actor: any) {
    const venue = await this.sportsVenueRepo.findOne({ where: { id } });
    if (!venue) {
      throw new NotFoundException(`Sports venue with ID ${id} not found`);
    }

    await this.sportsVenueRepo.delete(id);

    await this.createAuditRecord(actor, 'DELETE_SPORTS_VENUE', 'SportsVenue', id, {
      name: venue.name,
    });

    return { success: true, message: 'Sports venue deleted successfully' };
  }

  async publishSportsVenue(id: string, actor: any) {
    const venue = await this.sportsVenueRepo.findOne({ where: { id } });
    if (!venue) {
      throw new NotFoundException(`Sports venue with ID ${id} not found`);
    }

    venue.isPublished = true;
    await this.sportsVenueRepo.save(venue);

    await this.createAuditRecord(actor, 'PUBLISH_SPORTS_VENUE', 'SportsVenue', id);
    return venue;
  }

  async unpublishSportsVenue(id: string, actor: any) {
    const venue = await this.sportsVenueRepo.findOne({ where: { id } });
    if (!venue) {
      throw new NotFoundException(`Sports venue with ID ${id} not found`);
    }

    venue.isPublished = false;
    await this.sportsVenueRepo.save(venue);

    await this.createAuditRecord(actor, 'UNPUBLISH_SPORTS_VENUE', 'SportsVenue', id);
    return venue;
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
