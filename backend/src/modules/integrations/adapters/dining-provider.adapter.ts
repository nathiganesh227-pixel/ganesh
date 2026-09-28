import { Injectable } from '@nestjs/common';
import { IProviderAdapter, SyncExecutionResult } from './provider.adapter.interface';
import {
  IntegrationProviderType,
  AvailabilityResponseDto,
  AvailabilityStatus,
  AvailabilityFreshness,
} from '../dto/integration.dto';

export interface ExternalDiningSlotPayload {
  externalRestaurantId: string;
  slotTime: string;
  partySize: number;
  availableTables: number;
  status: 'OPEN' | 'LIMITED' | 'FULL';
}

@Injectable()
export class DiningProviderAdapter implements IProviderAdapter {
  readonly providerId = 'EXTERNAL_DINING_AGGREGATOR';
  readonly providerName = 'Restaurant POS & Reservation Gateway';
  readonly providerType = IntegrationProviderType.EXTERNAL;
  readonly vertical = 'dining';

  isConfigured(): boolean {
    return Boolean(process.env.DINING_PROVIDER_API_KEY && process.env.DINING_PROVIDER_API_URL);
  }

  isEnabled(): boolean {
    return this.isConfigured() && process.env.DINING_PROVIDER_ENABLED === 'true';
  }

  async sync(correlationId?: string): Promise<SyncExecutionResult> {
    if (!this.isEnabled()) {
      return {
        recordsRead: 0,
        recordsCreated: 0,
        recordsUpdated: 0,
        recordsSkipped: 0,
        recordsFailed: 0,
        errorSummary: 'Dining provider integration is unconfigured or disabled: commercial credentials required',
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

  normalizeSlot(payload: ExternalDiningSlotPayload) {
    return {
      time: payload.slotTime,
      tablesLeft: payload.availableTables,
      status: payload.status === 'OPEN' ? 'AVAILABLE' : payload.status === 'LIMITED' ? 'LIMITED' : 'SOLD_OUT',
    };
  }
}
