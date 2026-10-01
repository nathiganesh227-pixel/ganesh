import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User, UserRole } from '../../database/entities/user.entity';
import { RegisterDto, LoginDto } from './dto/auth.dto';

export function isDemoLoginEnabled(env: NodeJS.ProcessEnv = process.env): boolean {
  const nodeEnv = (env.NODE_ENV || 'development').toLowerCase();
  if (env.ENABLE_DEMO_LOGIN === 'true') {
    return true;
  }
  if (env.ENABLE_DEMO_LOGIN === 'false') {
    return false;
  }
  // Default: enabled only in development and test environments
  return nodeEnv === 'development' || nodeEnv === 'test';
}

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto): Promise<{ user: Partial<User>; token: string }> {
    const existing = await this.userRepo.findOne({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException('An account with this email already exists.');
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(dto.password, salt);

    const newUser = this.userRepo.create({
      id: `usr_${Date.now()}`,
      email: dto.email,
      passwordHash,
      name: dto.name,
      phone: dto.phone || '',
      city: dto.city || 'Hyderabad',
      role: UserRole.USER,
      rewardPoints: 500, // Welcome bonus!
    });

    await this.userRepo.save(newUser);
    const token = this.generateToken(newUser);

    const { passwordHash: _, ...safeUser } = newUser;
    return { user: safeUser, token };
  }

  async login(dto: LoginDto): Promise<{ user: Partial<User>; token: string }> {
    const user = await this.userRepo.findOne({ where: { email: dto.email } });
    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    const isValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    const token = this.generateToken(user);
    const { passwordHash: _, ...safeUser } = user;
    return { user: safeUser, token };
  }

  async getProfile(userId: string): Promise<Partial<User>> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User profile not found.');
    }
    const { passwordHash: _, ...safeUser } = user;
    return safeUser;
  }

  isDemoLoginEnabled(env: NodeJS.ProcessEnv = process.env): boolean {
    return isDemoLoginEnabled(env);
  }

  async validateOrCreateDemoUser(): Promise<{ user: Partial<User>; token: string }> {
    if (!this.isDemoLoginEnabled()) {
      throw new UnauthorizedException('Demo login is disabled in this environment.');
    }

    let user = await this.userRepo.findOne({ where: { email: 'guest@plaza.app' } });
    if (!user) {
      const salt = await bcrypt.genSalt(10);
      const randomDemoSecret = `Demo_${Date.now()}_${Math.random().toString(36).substring(2, 10)}`;
      const passwordHash = await bcrypt.hash(randomDemoSecret, salt);
      user = this.userRepo.create({
        id: 'usr_default_1',
        email: 'guest@plaza.app',
        passwordHash,
        name: 'Gopi Ganesh',
        phone: '+91 98765 43210',
        city: 'Hyderabad',
        rewardPoints: 2480,
        role: UserRole.USER,
      });
      await this.userRepo.save(user);
    }
    const token = this.generateToken(user);
    const { passwordHash: _, ...safeUser } = user;
    return { user: safeUser, token };
  }

  private generateToken(user: User): string {
    return this.jwtService.sign({
      sub: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
    });
  }
}

