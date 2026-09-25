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

  // ---------------- AUDIT LOGS ----------------
  @Get('audit-logs')
  @ApiOperation({ summary: 'List recent administrative audit logs' })
  async getAuditLogs(@Query() query: PaginationQueryDto) {
    return this.adminService.getAuditLogs(query.limit, query.offset);
  }
}
