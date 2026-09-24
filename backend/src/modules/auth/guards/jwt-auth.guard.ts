import { Injectable, UnauthorizedException, CanActivate, ExecutionContext } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    if (!authHeader) {
      if (process.env.NODE_ENV === 'production') {
        throw new UnauthorizedException('Authentication token is required');
      }
      // For development, allow fallback to demo user if no header is supplied
      request.user = { id: 'usr_default_1', sub: 'usr_default_1', email: 'guest@plaza.app', name: 'Gopi Ganesh' };
      return true;
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
      };
      return true;
    } catch {
      throw new UnauthorizedException('Your session has expired or is invalid. Please log in again.');
    }
  }
}
