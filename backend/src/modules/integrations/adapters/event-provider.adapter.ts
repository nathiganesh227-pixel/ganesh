import { Injectable } from '@nestjs/common';
import { IProviderAdapter, SyncExecutionResult } from './provider.adapter.interface';
import {
  IntegrationProviderType,
  AvailabilityResponseDto,
  AvailabilityStatus,
  AvailabilityFreshness,
} from '../dto/integration.dto';

export interface ExternalEventTierPayload {
  tierId: string;
  tierName: string;
  price: number;
  totalCapacity: number;
  remainingTickets: number;
}

@Injectable()
export class EventProviderAdapter implements IProviderAdapter {
  readonly providerId = 'EXTERNAL_EVENT_TICKETING';
  readonly providerName = 'Primary Event Ticketing Gateway';
  readonly providerType = IntegrationProviderType.EXTERNAL;
  readonly vertical = 'event';

  isConfigured(): boolean {
    return Boolean(process.env.EVENT_PROVIDER_API_KEY && process.env.EVENT_PROVIDER_API_URL);
  }

  isEnabled(): boolean {
    return this.isConfigured() && process.env.EVENT_PROVIDER_ENABLED === 'true';
  }

  async sync(correlationId?: string): Promise<SyncExecutionResult> {
    if (!this.isEnabled()) {
      return {
        recordsRead: 0,
        recordsCreated: 0,
        recordsUpdated: 0,
        recordsSkipped: 0,
        recordsFailed: 0,
        errorSummary: 'Event ticketing provider is unconfigured or disabled: commercial credentials required',
      };
    }
    return {
      recordsRead: 0,
      recordsCreated: 0,
      recordsUpdated: 0,
      recordsSkipped: 0,
      recordsFailed: 0,
    };
  }

  async getAvailability(providerEntityId: string): Promise<AvailabilityResponseDto> {
    if (!this.isEnabled()) {
      return {
        status: AvailabilityStatus.UNKNOWN,
        freshness: AvailabilityFreshness.UNKNOWN,
        source: 'EXTERNAL',
        sourceReference: providerEntityId,
        lastUpdatedAt: new Date(),
      };
    }
    return {
      status: AvailabilityStatus.AVAILABLE,
      freshness: AvailabilityFreshness.FRESH,
      source: 'EXTERNAL',
      sourceReference: providerEntityId,
      lastUpdatedAt: new Date(),
    };
  }

  normalizeTier(payload: ExternalEventTierPayload) {
    return {
      id: payload.tierId,
      name: payload.tierName,
      price: payload.price,
      remainingCount: payload.remainingTickets,
      perks: [],
    };
  }
}
