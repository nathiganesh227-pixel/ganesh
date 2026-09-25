import { Injectable, UnauthorizedException, CanActivate, ExecutionContext } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '../../../database/entities/user.entity';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers?.authorization;

    if (!authHeader) {
      throw new UnauthorizedException('Authentication token is required');
    }

    const [bearer, token] = authHeader.split(' ');
    if (bearer !== 'Bearer' || !token) {
      throw new UnauthorizedException('Invalid or missing authentication token');
    }

    try {
      const payload = this.jwtService.verify(token);
      request.user = {
        ...payload,
        id: payload.sub || payload.id,
        sub: payload.sub || payload.id,
        role: payload.role || UserRole.USER,
      };
      return true;
    } catch {
      throw new UnauthorizedException('Your session has expired or is invalid. Please log in again.');
    }
  }
}
