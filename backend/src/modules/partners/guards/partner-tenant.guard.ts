import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserRole } from '../../../database/entities/user.entity';
import { PartnerUserEntity } from '../../../database/entities/partner-user.entity';

@Injectable()
export class PartnerTenantGuard implements CanActivate {
  constructor(
    @InjectRepository(PartnerUserEntity)
    private readonly partnerUserRepo: Repository<PartnerUserEntity>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new UnauthorizedException('Authentication required');
    }

    // Platform Super Admin and Admin have overarching cross-tenant administrative access
    if (user.role === UserRole.SUPER_ADMIN || user.role === UserRole.ADMIN) {
      return true;
    }

    // Extract target partnerId from route parameters
    const partnerId = request.params.id || request.params.partnerId;
    if (!partnerId) {
      return true;
    }

    const userId = user.sub || user.id;

    // Verify user is an active member of this partner organization
    const membership = await this.partnerUserRepo.findOne({
      where: {
        partnerId,
        userId,
        isActive: true,
      },
    });

    if (!membership) {
      throw new ForbiddenException(
        'Tenant access denied: You do not possess authorized membership in this partner organization.',
      );
    }

    // Attach membership context to request for downstream authorization
    request.partnerMembership = membership;
    return true;
  }
}
