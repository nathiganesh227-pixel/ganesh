import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiResponse } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../../database/entities/user.entity';
import { AdminService } from './admin.service';
import { UpdateRoleDto, PaginationQueryDto } from './dto/admin.dto';
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

@ApiTags('admin')
@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@ApiBearerAuth()
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('health')
  @ApiOperation({ summary: 'Admin health status (restricted to ADMIN role)' })
  getHealth() {
    return this.adminService.getHealth();
  }

  @Get('dashboard')
  @ApiOperation({ summary: 'Admin dashboard metrics and catalog entity counts' })
  async getDashboard() {
    return this.adminService.getDashboardStats();
  }

  // ---------------- USER MANAGEMENT ----------------
  @Get('users')
  @ApiOperation({ summary: 'List all users with safe projections (no secrets/hashes)' })
  async getUsers(@Query() query: PaginationQueryDto) {
    return this.adminService.getUsers(query.limit, query.offset);
  }

  @Get('users/:id')
  @ApiOperation({ summary: 'Get user details by ID (safe projection)' })
  async getUserById(@Param('id') id: string) {
    return this.adminService.getUserById(id);
  }

  @Patch('users/:id/role')
  @ApiOperation({ summary: 'Update user role with last-admin demotion protection' })
  async updateUserRole(
    @Param('id') id: string,
    @Body() dto: UpdateRoleDto,
    @Request() req: any,
  ) {
    return this.adminService.updateUserRole(id, dto, req.user);
  }

  // ---------------- MOVIE MANAGEMENT ----------------
  @Get('movies')
  @ApiOperation({ summary: 'List all movies' })
  async getMovies(@Query() query: PaginationQueryDto) {
    return this.adminService.getMovies(query.limit, query.offset);
  }

  @Post('movies')
  @ApiOperation({ summary: 'Create a new movie release' })
  async createMovie(@Body() dto: CreateMovieDto, @Request() req: any) {
    return this.adminService.createMovie(dto, req.user);
  }

  @Patch('movies/:id')
  @ApiOperation({ summary: 'Update movie details' })
  async updateMovie(
    @Param('id') id: string,
    @Body() dto: UpdateMovieDto,
    @Request() req: any,
  ) {
    return this.adminService.updateMovie(id, dto, req.user);
  }

  @Delete('movies/:id')
  @ApiOperation({ summary: 'Delete or archive a movie' })
  async deleteMovie(@Param('id') id: string, @Request() req: any) {
    return this.adminService.deleteMovie(id, req.user);
  }

  // ---------------- THEATRE MANAGEMENT ----------------
  @Get('theatres')
  @ApiOperation({ summary: 'List all theatres' })
  async getTheatres(@Query() query: PaginationQueryDto) {
    return this.adminService.getTheatres(query.limit, query.offset);
  }

  @Get('theatres/:id')
  @ApiOperation({ summary: 'Get theatre by ID' })
  async getTheatreById(@Param('id') id: string) {
    return this.adminService.getTheatreById(id);
  }

  @Post('theatres')
  @ApiOperation({ summary: 'Create a new theatre venue' })
  async createTheatre(@Body() dto: CreateTheatreDto, @Request() req: any) {
    return this.adminService.createTheatre(dto, req.user);
  }

  @Patch('theatres/:id')
  @ApiOperation({ summary: 'Update theatre details' })
  async updateTheatre(
    @Param('id') id: string,
    @Body() dto: UpdateTheatreDto,
    @Request() req: any,
  ) {
    return this.adminService.updateTheatre(id, dto, req.user);
  }

  // ---------------- SCREEN MANAGEMENT ----------------
  @Get('screens')
  @ApiOperation({ summary: 'List screens, optionally by theatre' })
  async getScreens(
    @Query('theatreId') theatreId?: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    return this.adminService.getScreens(theatreId, limit, offset);
  }

  @Get('screens/:id')
  @ApiOperation({ summary: 'Get screen by ID' })
  async getScreenById(@Param('id') id: string) {
    return this.adminService.getScreenById(id);
  }

  @Post('theatres/:theatreId/screens')
  @ApiOperation({ summary: 'Create a new screen in a theatre' })
  async createScreen(
    @Param('theatreId') theatreId: string,
    @Body() dto: CreateScreenDto,
    @Request() req: any,
  ) {
    return this.adminService.createScreen(theatreId, dto, req.user);
  }

  @Patch('screens/:id')
  @ApiOperation({ summary: 'Update screen configuration' })
  async updateScreen(
    @Param('id') id: string,
    @Body() dto: UpdateScreenDto,
    @Request() req: any,
  ) {
    return this.adminService.updateScreen(id, dto, req.user);
  }

  // ---------------- SHOW MANAGEMENT ----------------
  @Get('shows')
  @ApiOperation({ summary: 'List scheduled movie shows' })
  async getShows(
    @Query('movieId') movieId?: string,
    @Query('theatreId') theatreId?: string,
    @Query('date') date?: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
  ) {
    return this.adminService.getShows(movieId, theatreId, date, limit, offset);
  }

  @Get('shows/:id')
  @ApiOperation({ summary: 'Get show by ID' })
  async getShowById(@Param('id') id: string) {
    return this.adminService.getShowById(id);
  }

  @Post('shows')
  @ApiOperation({ summary: 'Create a new movie showtime slot' })
  async createShow(@Body() dto: CreateShowDto, @Request() req: any) {
    return this.adminService.createShow(dto, req.user);
  }

  @Patch('shows/:id')
  @ApiOperation({ summary: 'Update showtime slot' })
  async updateShow(
    @Param('id') id: string,
    @Body() dto: UpdateShowDto,
    @Request() req: any,
  ) {
    return this.adminService.updateShow(id, dto, req.user);
  }

  @Delete('shows/:id')
  @ApiOperation({ summary: 'Delete or cancel a showtime slot' })
  async deleteShow(@Param('id') id: string, @Request() req: any) {
    return this.adminService.deleteShow(id, req.user);
  }

  // ---------------- DINING MANAGEMENT ----------------
  @Get('dining')
  @ApiOperation({ summary: 'List all dining restaurants (admin view)' })
  async getDining(@Query() query: PaginationQueryDto) {
    return this.adminService.getDining(query.limit, query.offset);
  }

  @Get('dining/:id')
  @ApiOperation({ summary: 'Get restaurant by ID' })
  async getDiningById(@Param('id') id: string) {
    return this.adminService.getDiningById(id);
  }

  @Post('dining')
  @ApiOperation({ summary: 'Create a new restaurant entry' })
  async createDining(@Body() dto: CreateDiningDto, @Request() req: any) {
    return this.adminService.createDining(dto, req.user);
  }

  @Patch('dining/:id')
  @ApiOperation({ summary: 'Update restaurant details' })
  async updateDining(
    @Param('id') id: string,
    @Body() dto: UpdateDiningDto,
    @Request() req: any,
  ) {
    return this.adminService.updateDining(id, dto, req.user);
  }

  @Delete('dining/:id')
  @ApiOperation({ summary: 'Delete a restaurant entry' })
  async deleteDining(@Param('id') id: string, @Request() req: any) {
    return this.adminService.deleteDining(id, req.user);
  }

  @Patch('dining/:id/publish')
  @ApiOperation({ summary: 'Publish a restaurant entry' })
  async publishDining(@Param('id') id: string, @Request() req: any) {
    return this.adminService.publishDining(id, req.user);
  }

  @Patch('dining/:id/unpublish')
  @ApiOperation({ summary: 'Unpublish a restaurant entry' })
  async unpublishDining(@Param('id') id: string, @Request() req: any) {
    return this.adminService.unpublishDining(id, req.user);
  }

  // ---------------- EVENTS MANAGEMENT ----------------
  @Get('events')
  @ApiOperation({ summary: 'List all events (admin view)' })
  async getEvents(@Query() query: PaginationQueryDto) {
    return this.adminService.getEvents(query.limit, query.offset);
  }

  @Get('events/:id')
  @ApiOperation({ summary: 'Get event by ID' })
  async getEventById(@Param('id') id: string) {
    return this.adminService.getEventById(id);
  }

  @Post('events')
  @ApiOperation({ summary: 'Create a new event' })
  async createEvent(@Body() dto: CreateEventDto, @Request() req: any) {
    return this.adminService.createEvent(dto, req.user);
  }

  @Patch('events/:id')
  @ApiOperation({ summary: 'Update event details' })
  async updateEvent(
    @Param('id') id: string,
    @Body() dto: UpdateEventDto,
    @Request() req: any,
  ) {
    return this.adminService.updateEvent(id, dto, req.user);
  }

  @Delete('events/:id')
  @ApiOperation({ summary: 'Delete an event' })
  async deleteEvent(@Param('id') id: string, @Request() req: any) {
    return this.adminService.deleteEvent(id, req.user);
  }

  @Patch('events/:id/publish')
  @ApiOperation({ summary: 'Publish an event' })
  async publishEvent(@Param('id') id: string, @Request() req: any) {
    return this.adminService.publishEvent(id, req.user);
  }

  @Patch('events/:id/unpublish')
  @ApiOperation({ summary: 'Unpublish an event' })
  async unpublishEvent(@Param('id') id: string, @Request() req: any) {
    return this.adminService.unpublishEvent(id, req.user);
  }

  // ---------------- ACTIVITIES MANAGEMENT ----------------
  @Get('activities')
  @ApiOperation({ summary: 'List all activities (admin view)' })
  async getActivities(@Query() query: PaginationQueryDto) {
    return this.adminService.getActivities(query.limit, query.offset);
  }

  @Get('activities/:id')
  @ApiOperation({ summary: 'Get activity by ID' })
  async getActivityById(@Param('id') id: string) {
    return this.adminService.getActivityById(id);
  }

  @Post('activities')
  @ApiOperation({ summary: 'Create a new activity' })
  async createActivity(@Body() dto: CreateActivityDto, @Request() req: any) {
    return this.adminService.createActivity(dto, req.user);
  }

  @Patch('activities/:id')
  @ApiOperation({ summary: 'Update activity details' })
  async updateActivity(
    @Param('id') id: string,
    @Body() dto: UpdateActivityDto,
    @Request() req: any,
  ) {
    return this.adminService.updateActivity(id, dto, req.user);
  }

  @Delete('activities/:id')
  @ApiOperation({ summary: 'Delete an activity' })
  async deleteActivity(@Param('id') id: string, @Request() req: any) {
    return this.adminService.deleteActivity(id, req.user);
  }

  @Patch('activities/:id/publish')
  @ApiOperation({ summary: 'Publish an activity' })
  async publishActivity(@Param('id') id: string, @Request() req: any) {
    return this.adminService.publishActivity(id, req.user);
  }

  @Patch('activities/:id/unpublish')
  @ApiOperation({ summary: 'Unpublish an activity' })
  async unpublishActivity(@Param('id') id: string, @Request() req: any) {
    return this.adminService.unpublishActivity(id, req.user);
  }

  // ---------------- SHOPPING MANAGEMENT ----------------
  @Get('shopping')
  @ApiOperation({ summary: 'List all shopping products (admin view)' })
  async getProducts(@Query() query: PaginationQueryDto) {
    return this.adminService.getProducts(query.limit, query.offset);
  }

  @Get('shopping/:id')
  @ApiOperation({ summary: 'Get product by ID' })
  async getProductById(@Param('id') id: string) {
    return this.adminService.getProductById(id);
  }

  @Post('shopping')
  @ApiOperation({ summary: 'Create a new shopping product' })
  async createProduct(@Body() dto: CreateProductDto, @Request() req: any) {
    return this.adminService.createProduct(dto, req.user);
  }

  @Patch('shopping/:id')
  @ApiOperation({ summary: 'Update product details' })
  async updateProduct(
    @Param('id') id: string,
    @Body() dto: UpdateProductDto,
    @Request() req: any,
  ) {
    return this.adminService.updateProduct(id, dto, req.user);
  }

  @Delete('shopping/:id')
  @ApiOperation({ summary: 'Delete a product' })
  async deleteProduct(@Param('id') id: string, @Request() req: any) {
    return this.adminService.deleteProduct(id, req.user);
  }

  @Patch('shopping/:id/publish')
  @ApiOperation({ summary: 'Publish a product' })
  async publishProduct(@Param('id') id: string, @Request() req: any) {
    return this.adminService.publishProduct(id, req.user);
  }

  @Patch('shopping/:id/unpublish')
  @ApiOperation({ summary: 'Unpublish a product' })
  async unpublishProduct(@Param('id') id: string, @Request() req: any) {
    return this.adminService.unpublishProduct(id, req.user);
  }

  // ---------------- STAYS MANAGEMENT ----------------
  @Get('stays')
  @ApiOperation({ summary: 'List all stay hotels (admin view)' })
  async getHotels(@Query() query: PaginationQueryDto) {
    return this.adminService.getHotels(query.limit, query.offset);
  }

  @Get('stays/:id')
  @ApiOperation({ summary: 'Get hotel by ID' })
  async getHotelById(@Param('id') id: string) {
    return this.adminService.getHotelById(id);
  }

  @Post('stays')
  @ApiOperation({ summary: 'Create a new hotel' })
  async createHotel(@Body() dto: CreateHotelDto, @Request() req: any) {
    return this.adminService.createHotel(dto, req.user);
  }

  @Patch('stays/:id')
  @ApiOperation({ summary: 'Update hotel details' })
  async updateHotel(
    @Param('id') id: string,
    @Body() dto: UpdateHotelDto,
    @Request() req: any,
  ) {
    return this.adminService.updateHotel(id, dto, req.user);
  }

  @Delete('stays/:id')
  @ApiOperation({ summary: 'Delete a hotel' })
  async deleteHotel(@Param('id') id: string, @Request() req: any) {
    return this.adminService.deleteHotel(id, req.user);
  }

  @Patch('stays/:id/publish')
  @ApiOperation({ summary: 'Publish a hotel' })
  async publishHotel(@Param('id') id: string, @Request() req: any) {
    return this.adminService.publishHotel(id, req.user);
  }

  @Patch('stays/:id/unpublish')
  @ApiOperation({ summary: 'Unpublish a hotel' })
  async unpublishHotel(@Param('id') id: string, @Request() req: any) {
    return this.adminService.unpublishHotel(id, req.user);
  }

  // ---------------- SPORTS MANAGEMENT ----------------
  @Get('sports')
  @ApiOperation({ summary: 'List all sports venues (admin view)' })
  async getSportsVenues(@Query() query: PaginationQueryDto) {
    return this.adminService.getSportsVenues(query.limit, query.offset);
  }

  @Get('sports/:id')
  @ApiOperation({ summary: 'Get sports venue by ID' })
  async getSportsVenueById(@Param('id') id: string) {
    return this.adminService.getSportsVenueById(id);
  }

  @Post('sports')
  @ApiOperation({ summary: 'Create a new sports venue' })
  async createSportsVenue(@Body() dto: CreateSportsVenueDto, @Request() req: any) {
    return this.adminService.createSportsVenue(dto, req.user);
  }

  @Patch('sports/:id')
  @ApiOperation({ summary: 'Update sports venue details' })
  async updateSportsVenue(
    @Param('id') id: string,
    @Body() dto: UpdateSportsVenueDto,
    @Request() req: any,
  ) {
    return this.adminService.updateSportsVenue(id, dto, req.user);
  }

  @Delete('sports/:id')
  @ApiOperation({ summary: 'Delete a sports venue' })
  async deleteSportsVenue(@Param('id') id: string, @Request() req: any) {
    return this.adminService.deleteSportsVenue(id, req.user);
  }

  @Patch('sports/:id/publish')
  @ApiOperation({ summary: 'Publish a sports venue' })
  async publishSportsVenue(@Param('id') id: string, @Request() req: any) {
    return this.adminService.publishSportsVenue(id, req.user);
  }

  @Patch('sports/:id/unpublish')
  @ApiOperation({ summary: 'Unpublish a sports venue' })
  async unpublishSportsVenue(@Param('id') id: string, @Request() req: any) {
    return this.adminService.unpublishSportsVenue(id, req.user);
  }

  // ---------------- AUDIT LOGS ----------------
  @Get('audit-logs')
  @ApiOperation({ summary: 'List recent administrative audit logs' })
  async getAuditLogs(@Query() query: PaginationQueryDto) {
    return this.adminService.getAuditLogs(query.limit, query.offset);
  }
}
