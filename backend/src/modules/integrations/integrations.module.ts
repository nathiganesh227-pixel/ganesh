import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { IntegrationMappingEntity } from '../../database/entities/integration-mapping.entity';
import { IntegrationSyncRunEntity } from '../../database/entities/integration-sync-run.entity';
import { BookingEntity } from '../../database/entities/booking.entity';

import { PartnerIntegrationAdapter } from './adapters/partner.adapter';
import { AdminCuratedAdapter } from './adapters/admin.adapter';
import { MovieProviderAdapter } from './adapters/movie-provider.adapter';
import { DiningProviderAdapter } from './adapters/dining-provider.adapter';
import { EventProviderAdapter } from './adapters/event-provider.adapter';
import { ActivityProviderAdapter } from './adapters/activity-provider.adapter';
import { StayProviderAdapter } from './adapters/stay-provider.adapter';
import { SportsProviderAdapter } from './adapters/sports-provider.adapter';
import { ShoppingProviderAdapter } from './adapters/shopping-provider.adapter';

import { ProviderRegistryService } from './registry/provider-registry.service';
import { IntegrationsService } from './integrations.service';
import { AdminIntegrationsController } from './admin-integrations.controller';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      IntegrationMappingEntity,
      IntegrationSyncRunEntity,
      BookingEntity,
    ]),
    AuthModule,
  ],
  controllers: [AdminIntegrationsController],
  providers: [
    PartnerIntegrationAdapter,
    AdminCuratedAdapter,
    MovieProviderAdapter,
    DiningProviderAdapter,
    EventProviderAdapter,
    ActivityProviderAdapter,
    StayProviderAdapter,
    SportsProviderAdapter,
    ShoppingProviderAdapter,
    ProviderRegistryService,
    IntegrationsService,
  ],
  exports: [IntegrationsService, ProviderRegistryService],
})
export class IntegrationsModule {}
