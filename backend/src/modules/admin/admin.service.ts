import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { User, UserRole } from '../../database/entities/user.entity';
import { MovieEntity } from '../../database/entities/movie.entity';
import { RestaurantEntity } from '../../database/entities/restaurant.entity';
import { EventEntity } from '../../database/entities/event.entity';
import { ActivityEntity } from '../../database/entities/activity.entity';
import { ProductEntity } from '../../database/entities/product.entity';
import { HotelEntity } from '../../database/entities/hotel.entity';
import { SportsVenueEntity } from '../../database/entities/sports-venue.entity';
import { BookingEntity } from '../../database/entities/booking.entity';
import { AuditLogEntity } from '../../database/entities/audit-log.entity';
import { UpdateRoleDto } from './dto/admin.dto';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(MovieEntity)
    private readonly movieRepo: Repository<MovieEntity>,
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

    // Protection against removing/demoting the final administrator account
    if (user.role === UserRole.ADMIN && dto.role !== UserRole.ADMIN) {
      const adminCount = await this.userRepo.count({ where: { role: UserRole.ADMIN } });
      if (adminCount <= 1) {
        throw new BadRequestException('Cannot demote the last remaining administrator account.');
      }
    }

    const previousRole = user.role;
    user.role = dto.role;
    await this.userRepo.save(user);

    // Record audit log entry (actor, action, resources; no secrets)
    await this.auditLogRepo.save({
      id: `aud_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      actorUserId: actor.sub || actor.id || 'unknown_admin',
      actorEmail: actor.email || 'unknown@plaza.app',
      action: 'UPDATE_USER_ROLE',
      resourceType: 'User',
      resourceId: user.id,
      metadata: {
        targetEmail: user.email,
        previousRole,
        newRole: dto.role,
      },
    });

    return this.toSafeUser(user);
  }

  async getAuditLogs(limit = 50, offset = 0) {
    return this.auditLogRepo.find({
      take: limit,
      skip: offset,
      order: { createdAt: 'DESC' },
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
