import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { DataSource } from 'typeorm';
import { BookingEntity, BookingType, BookingStatus, VALID_BOOKING_TRANSITIONS } from '../../database/entities/booking.entity';
import { SportsVenueEntity } from '../../database/entities/sports-venue.entity';
import { ActivityEntity } from '../../database/entities/activity.entity';
import { TheatreEntity } from '../../database/entities/theatre.entity';
import { HotelEntity } from '../../database/entities/hotel.entity';
import { ProductEntity } from '../../database/entities/product.entity';
import { RestaurantEntity } from '../../database/entities/restaurant.entity';
import { EventEntity } from '../../database/entities/event.entity';
import { User } from '../../database/entities/user.entity';
import { PaymentService } from './payment.service';

@Injectable()
export class BookingsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly paymentService: PaymentService,
  ) {}

  async findAll(userId = 'usr_default_1', status?: string): Promise<BookingEntity[]> {
    const repo = this.dataSource.getRepository(BookingEntity);
    if (status) {
      return repo.find({
        where: { userId, status: status as BookingStatus },
        order: { createdAt: 'DESC' },
      });
    }
    return repo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string, userId?: string): Promise<BookingEntity> {
    const repo = this.dataSource.getRepository(BookingEntity);
    const item = await repo.findOne({ where: { id } });
    if (!item) throw new NotFoundException(`Booking with ID ${id} not found`);
    if (userId && item.userId && item.userId !== userId) {
      throw new ForbiddenException('You do not have permission to access this booking.');
    }
    return item;
  }

  async cancel(id: string, userId?: string): Promise<BookingEntity> {
    const repo = this.dataSource.getRepository(BookingEntity);
    const item = await this.findOne(id, userId);

    if (item.status === BookingStatus.CANCELLED) {
      throw new BadRequestException('This booking is already cancelled.');
    }

    const allowedNext = VALID_BOOKING_TRANSITIONS[item.status] || [];
    if (!allowedNext.includes(BookingStatus.CANCELLED)) {
      throw new BadRequestException(`Cannot cancel booking with current status '${item.status}'.`);
    }

    item.status = BookingStatus.CANCELLED;

    // Trigger simulated refund if payment was recorded
    if (item.totalPrice > 0 && item.metadata?.payment?.paymentId) {
      const refund = await this.paymentService.processRefund(
        item.metadata.payment.paymentId,
        item.totalPrice,
        'Booking cancelled by user',
      );
      item.metadata = {
        ...item.metadata,
        refund,
      };
    }

    return repo.save(item);
  }

  // 1. Transactional Movie Booking
  async createMovieBooking(payload: {
    userId?: string;
    movieId: string;
    theatreId: string;
    showtimeId: string;
    seatIds: string[];
    movieTitle: string;
    theatreName: string;
    posterUrl: string;
    date: string;
    time: string;
  }): Promise<BookingEntity> {
    return this.dataSource.transaction(async (manager) => {
      const theatre = await manager.findOne(TheatreEntity, {
        where: { id: payload.theatreId },
      });
      if (!theatre) throw new NotFoundException('Theatre not found');

      const slot = theatre.showtimes?.find((s) => s.id === payload.showtimeId);
      if (!slot) throw new NotFoundException('Showtime slot not found');

      const bookingRepo = manager.getRepository(BookingEntity);
      const existing = await bookingRepo
        .createQueryBuilder('b')
        .where("b.metadata->>'theatreId' = :tId", { tId: payload.theatreId })
        .andWhere("b.metadata->>'showtimeId' = :stId", { stId: payload.showtimeId })
        .andWhere('b.status != :status', { status: BookingStatus.CANCELLED })
        .getMany();

      for (const b of existing) {
        const bookedSeats: string[] = b.metadata?.seatIds || [];
        for (const seat of payload.seatIds) {
          if (bookedSeats.includes(seat)) {
            throw new ConflictException(`Seat ${seat} is already reserved by another user.`);
          }
        }
      }

      // Server-side calculated price
      const seatPrice = slot.basePrice;
      const subtotal = seatPrice * payload.seatIds.length;
      const convenienceFee = 70.0;
      const taxes = Math.round(subtotal * 0.05);
      const totalPrice = subtotal + convenienceFee + taxes;

      const bookingId = `PLZ-MOV-${Date.now().toString().slice(-5)}${Math.floor(Math.random() * 900 + 100)}`;
      const payment = await this.paymentService.processPayment(
        bookingId,
        totalPrice,
        (payload as any).paymentMethod || 'UPI_FAST',
      );

      const booking = bookingRepo.create({
        id: bookingId,
        userId: payload.userId || 'usr_default_1',
        type: BookingType.MOVIE,
        title: payload.movieTitle,
        subtitle: `${payload.theatreName} • ${slot.format}`,
        imageUrl: payload.posterUrl,
        date: payload.date,
        time: payload.time,
        location: theatre.location,
        status: BookingStatus.UPCOMING,
        totalPrice,
        qrCodeData: `QR-MOV-${bookingId}`,
        metadata: {
          movieId: payload.movieId,
          theatreId: payload.theatreId,
          showtimeId: payload.showtimeId,
          seatIds: payload.seatIds,
          payment,
        },
      });

      await bookingRepo.save(booking);
      await this.awardPoints(manager, payload.userId || 'usr_default_1', Math.round(totalPrice * 0.1));
      return booking;
    });
  }

  // 2. Transactional Sports Slot Booking (Concurrency protection)
  async createSportsBooking(payload: {
    userId?: string;
    venueId: string;
    sportName: string;
    slotId: string;
    date: string;
    playersCount: number;
    squadName?: string;
    addOnIds?: string[];
  }): Promise<BookingEntity> {
    return this.dataSource.transaction(async (manager) => {
      const venue = await manager.findOne(SportsVenueEntity, {
        where: { id: payload.venueId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!venue) throw new NotFoundException('Sports venue not found');

      const slot = venue.slots?.find((s) => s.id === payload.slotId);
      if (!slot) throw new NotFoundException('Selected sports slot not found');

      // Check double-booking
      const bookingRepo = manager.getRepository(BookingEntity);
      const conflict = await bookingRepo
        .createQueryBuilder('b')
        .where("b.metadata->>'venueId' = :vId", { vId: payload.venueId })
        .andWhere("b.metadata->>'slotId' = :sId", { sId: payload.slotId })
        .andWhere("b.date = :date", { date: payload.date })
        .andWhere('b.status != :status', { status: BookingStatus.CANCELLED })
        .getOne();

      if (conflict) {
        throw new ConflictException('That sports court slot is already booked for this date and time.');
      }

      // Server-side price calculation
      let addOnsTotal = 0;
      if (payload.addOnIds && payload.addOnIds.length > 0) {
        for (const addOnId of payload.addOnIds) {
          const item = venue.addOns?.find((a) => a.id === addOnId);
          if (item) addOnsTotal += item.price;
        }
      }
      const courtPrice = slot.price;
      const convenienceFee = 50.0;
      const totalPrice = courtPrice + addOnsTotal + convenienceFee;

      const bookingId = `PLZ-SPT-${Date.now().toString().slice(-5)}${Math.floor(Math.random() * 900 + 100)}`;
      const payment = await this.paymentService.processPayment(
        bookingId,
        totalPrice,
        (payload as any).paymentMethod || 'UPI_FAST',
      );

      const booking = bookingRepo.create({
        id: bookingId,
        userId: payload.userId || 'usr_default_1',
        type: BookingType.SPORTS,
        title: venue.name,
        subtitle: `${payload.sportName} • ${slot.duration}`,
        imageUrl: venue.coverImageUrl,
        date: payload.date,
        time: slot.time,
        location: venue.location,
        status: BookingStatus.UPCOMING,
        totalPrice,
        qrCodeData: `QR-SPT-${bookingId}`,
        metadata: {
          venueId: payload.venueId,
          slotId: payload.slotId,
          sport: payload.sportName,
          courtName: slot.courtName,
          playersCount: payload.playersCount,
          squadName: payload.squadName || '',
          payment,
        },
      });

      await bookingRepo.save(booking);
      await this.awardPoints(manager, payload.userId || 'usr_default_1', Math.round(totalPrice * 0.1));
      return booking;
    });
  }

  // 3. Dining Table Reservation
  async createDiningReservation(payload: {
    userId?: string;
    restaurantId: string;
    date: string;
    timeSlot: string;
    partySize: number;
    seatingPreference: string;
    guestName: string;
    guestPhone: string;
    specialRequest?: string;
  }): Promise<BookingEntity> {
    return this.dataSource.transaction(async (manager) => {
      const rest = await manager.findOne(RestaurantEntity, {
        where: { id: payload.restaurantId },
      });
      if (!rest) throw new NotFoundException('Restaurant not found');

      const bookingRepo = manager.getRepository(BookingEntity);
      const bookingId = `PLZ-DIN-${Date.now().toString().slice(-5)}${Math.floor(Math.random() * 900 + 100)}`;
      const payment = await this.paymentService.processPayment(
        bookingId,
        0.0,
        'COMPLIMENTARY',
      );

      const booking = bookingRepo.create({
        id: bookingId,
        userId: payload.userId || 'usr_default_1',
        type: BookingType.DINING,
        title: rest.name,
        subtitle: `${payload.partySize} Guests • ${payload.seatingPreference}`,
        imageUrl: rest.coverImageUrl,
        date: payload.date,
        time: payload.timeSlot,
        location: rest.location,
        status: BookingStatus.UPCOMING,
        totalPrice: 0.0, // Table reservations are complimentary
        qrCodeData: `QR-DIN-${bookingId}`,
        metadata: {
          restaurantId: payload.restaurantId,
          partySize: payload.partySize,
          seatingPreference: payload.seatingPreference,
          guestName: payload.guestName,
          guestPhone: payload.guestPhone,
          specialRequest: payload.specialRequest,
          payment,
        },
      });

      await bookingRepo.save(booking);
      await this.awardPoints(manager, payload.userId || 'usr_default_1', 100);
      return booking;
    });
  }

  // 4. Stays Reservation (Server-side price verification)
  async createStayBooking(payload: {
    userId?: string;
    hotelId: string;
    roomTypeId: string;
    checkInDate: string;
    checkOutDate: string;
    nights: number;
    guestsCount: number;
    roomsCount: number;
    addOnIds?: string[];
  }): Promise<BookingEntity> {
    return this.dataSource.transaction(async (manager) => {
      const hotel = await manager.findOne(HotelEntity, {
        where: { id: payload.hotelId },
      });
      if (!hotel) throw new NotFoundException('Hotel not found');

      const room = hotel.rooms?.find((r) => r.id === payload.roomTypeId);
      if (!room) throw new NotFoundException('Room type not found');

      // Server-side calculation: room price * nights * rooms + add-ons + taxes
      const roomTotal = room.pricePerNight * payload.nights * payload.roomsCount;
      let addOnsTotal = 0;
      if (payload.addOnIds && payload.addOnIds.length > 0) {
        for (const addOnId of payload.addOnIds) {
          const item = hotel.addOns?.find((a) => a.id === addOnId);
          if (item) addOnsTotal += item.price;
        }
      }
      const taxesAndFees = Math.round((roomTotal + addOnsTotal) * 0.12);
      const grandTotal = roomTotal + addOnsTotal + taxesAndFees;

      const bookingRepo = manager.getRepository(BookingEntity);
      const bookingId = `PLZ-STY-${Date.now().toString().slice(-5)}${Math.floor(Math.random() * 900 + 100)}`;
      const payment = await this.paymentService.processPayment(
        bookingId,
        grandTotal,
        (payload as any).paymentMethod || 'CARD_FAST',
      );

      const booking = bookingRepo.create({
        id: bookingId,
        userId: payload.userId || 'usr_default_1',
        type: BookingType.STAY,
        title: hotel.name,
        subtitle: `${room.name} (${payload.nights} Nights)`,
        imageUrl: hotel.coverImageUrl,
        date: payload.checkInDate,
        time: 'Check-in: 02:00 PM',
        location: hotel.location,
        status: BookingStatus.UPCOMING,
        totalPrice: grandTotal,
        qrCodeData: `QR-STY-${bookingId}`,
        metadata: {
          hotelId: payload.hotelId,
          roomTypeId: payload.roomTypeId,
          nights: payload.nights,
          guestsCount: payload.guestsCount,
          roomsCount: payload.roomsCount,
          payment,
        },
      });

      await bookingRepo.save(booking);
      await this.awardPoints(manager, payload.userId || 'usr_default_1', Math.round(grandTotal * 0.05));
      return booking;
    });
  }

  // 5. Shopping Order (Server-side price verification)
  async createShoppingOrder(payload: {
    userId?: string;
    items: { productId: string; variantId?: string; quantity: number }[];
    fulfillmentType: string;
  }): Promise<BookingEntity> {
    return this.dataSource.transaction(async (manager) => {
      const productRepo = manager.getRepository(ProductEntity);
      let itemsTotal = 0;
      let storeName = 'PLAZA Partner Store';
      let storeLocation = 'Hyderabad';
      let coverImage = '';

      for (const item of payload.items) {
        const prod = await productRepo.findOne({ where: { id: item.productId } });
        if (!prod) throw new NotFoundException(`Product ${item.productId} not found`);

        let unitPrice = prod.price;
        if (item.variantId && prod.variants) {
          const variant = prod.variants.find((v) => v.id === item.variantId);
          if (variant) unitPrice += variant.priceDelta;
        }

        itemsTotal += unitPrice * item.quantity;
        storeName = prod.storeName;
        storeLocation = prod.storeLocation;
        coverImage = prod.coverImageUrl;
      }

      const platformFee = 29.0;
      const gst = Math.round(itemsTotal * 0.05);
      const grandTotal = itemsTotal + platformFee + gst;

      const bookingRepo = manager.getRepository(BookingEntity);
      const bookingId = `ORD-PLZ-${Date.now().toString().slice(-5)}${Math.floor(Math.random() * 900 + 100)}`;
      const payment = await this.paymentService.processPayment(
        bookingId,
        grandTotal,
        (payload as any).paymentMethod || 'UPI_FAST',
      );

      const booking = bookingRepo.create({
        id: bookingId,
        userId: payload.userId || 'usr_default_1',
        type: BookingType.SHOPPING,
        title: storeName,
        subtitle: `${payload.items.length} items • ${payload.fulfillmentType}`,
        imageUrl: coverImage,
        date: 'Today',
        time: 'Express Pickup',
        location: storeLocation,
        status: BookingStatus.UPCOMING,
        totalPrice: grandTotal,
        qrCodeData: `QR-${bookingId}`,
        metadata: {
          items: payload.items,
          fulfillmentType: payload.fulfillmentType,
          payment,
        },
      });

      await bookingRepo.save(booking);
      await this.awardPoints(manager, payload.userId || 'usr_default_1', Math.round(grandTotal * 0.05));
      return booking;
    });
  }

  // 6. Event Ticket Booking
  async createEventBooking(payload: {
    userId?: string;
    eventId: string;
    tierId: string;
    ticketCount: number;
  }): Promise<BookingEntity> {
    return this.dataSource.transaction(async (manager) => {
      const event = await manager.findOne(EventEntity, {
        where: { id: payload.eventId },
      });
      if (!event) throw new NotFoundException('Event not found');

      const tier = event.ticketTiers?.find((t) => t.id === payload.tierId);
      if (!tier) throw new NotFoundException('Ticket tier not found');

      if (tier.remainingCount < payload.ticketCount) {
        throw new ConflictException('Not enough tickets remaining for this tier.');
      }

      tier.remainingCount -= payload.ticketCount;
      await manager.save(event);

      const subtotal = tier.price * payload.ticketCount;
      const convenienceFee = Math.round(subtotal * 0.05);
      const grandTotal = subtotal + convenienceFee;

      const bookingRepo = manager.getRepository(BookingEntity);
      const bookingId = `PLZ-EVT-${Date.now().toString().slice(-5)}${Math.floor(Math.random() * 900 + 100)}`;
      const payment = await this.paymentService.processPayment(
        bookingId,
        grandTotal,
        (payload as any).paymentMethod || 'UPI_FAST',
      );

      const booking = bookingRepo.create({
        id: bookingId,
        userId: payload.userId || 'usr_default_1',
        type: BookingType.EVENT,
        title: event.title,
        subtitle: `${payload.ticketCount}x ${tier.name}`,
        imageUrl: event.posterUrl,
        date: event.eventDate,
        time: event.time,
        location: `${event.venue}, ${event.location}`,
        status: BookingStatus.UPCOMING,
        totalPrice: grandTotal,
        qrCodeData: `QR-EVT-${bookingId}`,
        metadata: {
          eventId: payload.eventId,
          tierId: payload.tierId,
          ticketCount: payload.ticketCount,
          tierName: tier.name,
          payment,
        },
      });

      await bookingRepo.save(booking);
      await this.awardPoints(manager, payload.userId || 'usr_default_1', Math.round(grandTotal * 0.05));
      return booking;
    });
  }

  // 7. Activity Session Booking
  async createActivityBooking(payload: {
    userId?: string;
    activityId: string;
    packageId: string;
    date: string;
    timeSlot: string;
    numberOfPeople: number;
    addOnIds?: string[];
  }): Promise<BookingEntity> {
    return this.dataSource.transaction(async (manager) => {
      const act = await manager.findOne(ActivityEntity, {
        where: { id: payload.activityId },
      });
      if (!act) throw new NotFoundException('Activity not found');

      const pkg = act.packages?.find((p) => p.id === payload.packageId);
      if (!pkg) throw new NotFoundException('Package not found');

      let addOnsTotal = 0;
      if (payload.addOnIds && payload.addOnIds.length > 0) {
        for (const addOnId of payload.addOnIds) {
          const item = act.addOns?.find((a) => a.id === addOnId);
          if (item) addOnsTotal += item.price;
        }
      }

      const subtotal = (pkg.pricePerPerson * payload.numberOfPeople) + addOnsTotal;
      const taxes = Math.round(subtotal * 0.18);
      const grandTotal = subtotal + taxes;

      const bookingRepo = manager.getRepository(BookingEntity);
      const bookingId = `PLZ-ACT-${Date.now().toString().slice(-5)}${Math.floor(Math.random() * 900 + 100)}`;
      const payment = await this.paymentService.processPayment(
        bookingId,
        grandTotal,
        (payload as any).paymentMethod || 'UPI_FAST',
      );

      const booking = bookingRepo.create({
        id: bookingId,
        userId: payload.userId || 'usr_default_1',
        type: BookingType.ACTIVITY,
        title: act.title,
        subtitle: `${payload.numberOfPeople} Guests • ${pkg.name}`,
        imageUrl: act.coverImageUrl,
        date: payload.date,
        time: payload.timeSlot,
        location: act.location,
        status: BookingStatus.UPCOMING,
        totalPrice: grandTotal,
        qrCodeData: `QR-ACT-${bookingId}`,
        metadata: {
          activityId: payload.activityId,
          packageId: payload.packageId,
          numberOfPeople: payload.numberOfPeople,
          packageName: pkg.name,
          payment,
        },
      });

      await bookingRepo.save(booking);
      await this.awardPoints(manager, payload.userId || 'usr_default_1', Math.round(grandTotal * 0.05));
      return booking;
    });
  }

  private async awardPoints(manager: any, userId: string, points: number) {
    if (points <= 0) return;
    const userRepo = manager.getRepository(User);
    const user = await userRepo.findOne({ where: { id: userId } });
    if (user) {
      user.rewardPoints = (user.rewardPoints || 0) + points;
      await userRepo.save(user);
    }
  }
}
