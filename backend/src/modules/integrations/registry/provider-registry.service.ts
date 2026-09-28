import { Injectable } from '@nestjs/common';
import { IProviderAdapter } from '../adapters/provider.adapter.interface';
import { PartnerIntegrationAdapter } from '../adapters/partner.adapter';
import { AdminCuratedAdapter } from '../adapters/admin.adapter';
import { MovieProviderAdapter } from '../adapters/movie-provider.adapter';
import { DiningProviderAdapter } from '../adapters/dining-provider.adapter';
import { EventProviderAdapter } from '../adapters/event-provider.adapter';
import { ActivityProviderAdapter } from '../adapters/activity-provider.adapter';
import { StayProviderAdapter } from '../adapters/stay-provider.adapter';
import { SportsProviderAdapter } from '../adapters/sports-provider.adapter';
import { ShoppingProviderAdapter } from '../adapters/shopping-provider.adapter';
import { ProviderStatusDto, IntegrationStatus } from '../dto/integration.dto';

@Injectable()
export class ProviderRegistryService {
  private readonly adapters: Map<string, IProviderAdapter> = new Map();

  constructor(
    private readonly partnerAdapter: PartnerIntegrationAdapter,
    private readonly adminAdapter: AdminCuratedAdapter,
    private readonly movieAdapter: MovieProviderAdapter,
    private readonly diningAdapter: DiningProviderAdapter,
    private readonly eventAdapter: EventProviderAdapter,
    private readonly activityAdapter: ActivityProviderAdapter,
    private readonly stayAdapter: StayProviderAdapter,
    private readonly sportsAdapter: SportsProviderAdapter,
    private readonly shoppingAdapter: ShoppingProviderAdapter,
  ) {
    this.register(partnerAdapter);
    this.register(adminAdapter);
    this.register(movieAdapter);
    this.register(diningAdapter);
    this.register(eventAdapter);
    this.register(activityAdapter);
    this.register(stayAdapter);
    this.register(sportsAdapter);
    this.register(shoppingAdapter);
  }

  register(adapter: IProviderAdapter) {
    this.adapters.set(adapter.providerId, adapter);
  }

  getAdapter(providerId: string): IProviderAdapter | undefined {
    return this.adapters.get(providerId);
  }

  getAllAdapters(): IProviderAdapter[] {
    return Array.from(this.adapters.values());
  }

  getProviderSummaries(): ProviderStatusDto[] {
    return this.getAllAdapters().map((adapter) => {
      const isConfigured = adapter.isConfigured();
      const isEnabled = adapter.isEnabled();

      let status = IntegrationStatus.UNCONFIGURED;
      if (isEnabled) {
        status = IntegrationStatus.ACTIVE;
      } else if (isConfigured) {
        status = IntegrationStatus.CONFIGURED;
      } else {
        status = IntegrationStatus.DISABLED;
      }

      return {
        providerId: adapter.providerId,
        providerName: adapter.providerName,
        providerType: adapter.providerType,
        vertical: adapter.vertical,
        isConfigured,
        isEnabled,
        status,
        syncFrequencyMinutes: 60,
      };
    });
  }
}
