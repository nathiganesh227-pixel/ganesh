import { Controller, Get, Post, Delete, Param, Query, Body, Headers, UseGuards, Request, HttpCode, HttpStatus, BadRequestException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { BookingsService } from './bookings.service';
import { IdempotencyService } from './idempotency.service';
import { BookingEntity } from '../../database/entities/booking.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('bookings')
@Controller('bookings')
export class BookingsController {
  constructor(
    private readonly service: BookingsService,
    private readonly idempotencyService: IdempotencyService,
  ) {}

  @Post('quote')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Calculate server-authoritative pricing quote for any vertical' })
  async calculateQuote(@Body() body: any, @Request() req?: any) {
    if (!body || !body.type) {
      throw new BadRequestException('Missing booking type for quote calculation');
    }
    const authenticatedUserId = req?.user?.sub || req?.user?.id;
    return this.service.calculateQuote(body.type, body, authenticatedUserId);
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get unified bookings for authenticated user' })
  async findAll(@Request() req: any, @Query('status') status?: string): Promise<BookingEntity[]> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    return this.service.findAll(userId, status);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get booking by ID' })
  async findOne(@Request() req: any, @Param('id') id: string): Promise<BookingEntity> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    return this.service.findOne(id, userId);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Cancel booking by ID' })
  async cancel(
    @Request() req: any,
    @Param('id') id: string,
    @Headers('idempotency-key') idempotencyKey?: string,
    @Headers('x-idempotency-key') xIdempotencyKey?: string,
  ): Promise<BookingEntity> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    const effectiveKey = idempotencyKey || xIdempotencyKey;
    return this.service.cancel(id, userId, { idempotencyKey: effectiveKey, idempotent: true });
  }

  @Post('movie/lock-seats')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Acquire temporary lock on movie seats with automatic TTL expiration' })
  async lockSeats(
    @Request() req: any,
    @Body() body: { theatreId: string; showtimeId: string; seatIds: string[]; ttlSeconds?: number },
  ) {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    return this.service.lockSeats({ ...body, userId });
  }

  @Post('movie/release-seats')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Release temporary seat lock held by authenticated user' })
  async releaseSeats(
    @Request() req: any,
    @Body() body: { theatreId: string; showtimeId: string; seatIds?: string[] },
  ) {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    return this.service.releaseSeatLock({ ...body, userId });
  }

  @Post(':id/verify-pass')
  @ApiOperation({ summary: 'Verify digital pass QR code and check-in eligibility' })
  async verifyPass(
    @Param('id') id: string,
    @Body() body?: { qrCodeData?: string },
  ) {
    return this.service.verifyPass(id, body?.qrCodeData);
  }

  @Post('movie')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create movie seat booking with server-side validation & idempotency' })
  async createMovieBooking(
    @Request() req: any,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Body() body: any,
    @Headers('x-idempotency-key') xIdempotencyKey?: string,
  ): Promise<BookingEntity> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    const effectiveKey = idempotencyKey || xIdempotencyKey || body?.idempotencyKey;
    const cached = await this.idempotencyService.get(userId, effectiveKey, body);
    if (cached) return cached as BookingEntity;

    const result = await this.service.createMovieBooking({ ...body, userId });
    await this.idempotencyService.save(userId, effectiveKey, '/bookings/movie', result, {
      requestPayload: body,
      operation: 'booking:movie',
      resourceId: result.id,
    });
    return result;
  }

  @Post('dining')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create restaurant table reservation with idempotency' })
  async createDiningReservation(
    @Request() req: any,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Body() body: any,
    @Headers('x-idempotency-key') xIdempotencyKey?: string,
  ): Promise<BookingEntity> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    const effectiveKey = idempotencyKey || xIdempotencyKey || body?.idempotencyKey;
    const cached = await this.idempotencyService.get(userId, effectiveKey, body);
    if (cached) return cached as BookingEntity;

    const result = await this.service.createDiningReservation({ ...body, userId });
    await this.idempotencyService.save(userId, effectiveKey, '/bookings/dining', result, {
      requestPayload: body,
      operation: 'booking:dining',
      resourceId: result.id,
    });
    return result;
  }

  @Post('sports')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create sports court booking with concurrent slot lock & idempotency' })
  async createSportsBooking(
    @Request() req: any,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Body() body: any,
    @Headers('x-idempotency-key') xIdempotencyKey?: string,
  ): Promise<BookingEntity> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    const effectiveKey = idempotencyKey || xIdempotencyKey || body?.idempotencyKey;
    const cached = await this.idempotencyService.get(userId, effectiveKey, body);
    if (cached) return cached as BookingEntity;

    const result = await this.service.createSportsBooking({ ...body, userId });
    await this.idempotencyService.save(userId, effectiveKey, '/bookings/sports', result, {
      requestPayload: body,
      operation: 'booking:sports',
      resourceId: result.id,
    });
    return result;
  }

  @Post('stays')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create hotel room stay booking with verified total & idempotency' })
  async createStayBooking(
    @Request() req: any,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Body() body: any,
    @Headers('x-idempotency-key') xIdempotencyKey?: string,
  ): Promise<BookingEntity> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    const effectiveKey = idempotencyKey || xIdempotencyKey || body?.idempotencyKey;
    const cached = await this.idempotencyService.get(userId, effectiveKey, body);
    if (cached) return cached as BookingEntity;

    const result = await this.service.createStayBooking({ ...body, userId });
    await this.idempotencyService.save(userId, effectiveKey, '/bookings/stays', result, {
      requestPayload: body,
      operation: 'booking:stay',
      resourceId: result.id,
    });
    return result;
  }

  @Post('shopping')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create shopping order with verified item prices & idempotency' })
  async createShoppingOrder(
    @Request() req: any,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Body() body: any,
    @Headers('x-idempotency-key') xIdempotencyKey?: string,
  ): Promise<BookingEntity> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    const effectiveKey = idempotencyKey || xIdempotencyKey || body?.idempotencyKey;
    const cached = await this.idempotencyService.get(userId, effectiveKey, body);
    if (cached) return cached as BookingEntity;

    const result = await this.service.createShoppingOrder({ ...body, userId });
    await this.idempotencyService.save(userId, effectiveKey, '/bookings/shopping', result, {
      requestPayload: body,
      operation: 'booking:shopping',
      resourceId: result.id,
    });
    return result;
  }

  @Post('event')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create event ticket booking with idempotency' })
  async createEventBooking(
    @Request() req: any,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Body() body: any,
    @Headers('x-idempotency-key') xIdempotencyKey?: string,
  ): Promise<BookingEntity> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    const effectiveKey = idempotencyKey || xIdempotencyKey || body?.idempotencyKey;
    const cached = await this.idempotencyService.get(userId, effectiveKey, body);
    if (cached) return cached as BookingEntity;

    const result = await this.service.createEventBooking({ ...body, userId });
    await this.idempotencyService.save(userId, effectiveKey, '/bookings/event', result, {
      requestPayload: body,
      operation: 'booking:event',
      resourceId: result.id,
    });
    return result;
  }

  @Post('activity')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create activity slot booking with idempotency' })
  async createActivityBooking(
    @Request() req: any,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Body() body: any,
    @Headers('x-idempotency-key') xIdempotencyKey?: string,
  ): Promise<BookingEntity> {
    const userId = req.user?.sub || req.user?.id || 'usr_default_1';
    const effectiveKey = idempotencyKey || xIdempotencyKey || body?.idempotencyKey;
    const cached = await this.idempotencyService.get(userId, effectiveKey, body);
    if (cached) return cached as BookingEntity;

    const result = await this.service.createActivityBooking({ ...body, userId });
    await this.idempotencyService.save(userId, effectiveKey, '/bookings/activity', result, {
      requestPayload: body,
      operation: 'booking:activity',
      resourceId: result.id,
    });
    return result;
  }
}
