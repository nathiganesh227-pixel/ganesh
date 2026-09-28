import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PartnersController } from './partners.controller';
import { PartnerAdminController } from './partner-admin.controller';
import { PartnersService } from './partners.service';
import { PartnerTenantGuard } from './guards/partner-tenant.guard';

import { User } from '../../database/entities/user.entity';
import { PartnerEntity } from '../../database/entities/partner.entity';
import { PartnerUserEntity } from '../../database/entities/partner-user.entity';
import { PartnerBusinessEntity } from '../../database/entities/partner-business.entity';
import { PartnerDocumentEntity } from '../../database/entities/partner-document.entity';
import { PartnerApprovalEntity } from '../../database/entities/partner-approval.entity';
import { PartnerInvitationEntity } from '../../database/entities/partner-invitation.entity';
import { PartnerPayoutProfileEntity } from '../../database/entities/partner-payout-profile.entity';
import { PartnerAuditLogEntity } from '../../database/entities/partner-audit-log.entity';
import { BookingEntity } from '../../database/entities/booking.entity';
import { RestaurantEntity } from '../../database/entities/restaurant.entity';
import { EventEntity } from '../../database/entities/event.entity';
import { ActivityEntity } from '../../database/entities/activity.entity';
import { HotelEntity } from '../../database/entities/hotel.entity';
import { SportsVenueEntity } from '../../database/entities/sports-venue.entity';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      PartnerEntity,
      PartnerUserEntity,
      PartnerBusinessEntity,
      PartnerDocumentEntity,
      PartnerApprovalEntity,
      PartnerInvitationEntity,
      PartnerPayoutProfileEntity,
      PartnerAuditLogEntity,
      BookingEntity,
      RestaurantEntity,
      EventEntity,
      ActivityEntity,
      HotelEntity,
      SportsVenueEntity,
    ]),
    AuthModule,
  ],
  controllers: [PartnersController, PartnerAdminController],
  providers: [PartnersService, PartnerTenantGuard],
  exports: [PartnersService, PartnerTenantGuard],
})
export class PartnersModule {}
