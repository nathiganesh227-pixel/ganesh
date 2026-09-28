import { Injectable } from '@nestjs/common';
import { IProviderAdapter, SyncExecutionResult } from './provider.adapter.interface';
import {
  IntegrationProviderType,
  AvailabilityResponseDto,
  AvailabilityStatus,
  AvailabilityFreshness,
} from '../dto/integration.dto';

export interface ExternalCourtSlotPayload {
  venueId: string;
  courtId: string;
  courtName: string;
  sport: string;
  date: string;
  startTime: string;
  durationMinutes: number;
  price: number;
  status: 'AVAILABLE' | 'BOOKED' | 'MAINTENANCE';
}

@Injectable()
export class SportsProviderAdapter implements IProviderAdapter {
  readonly providerId = 'EXTERNAL_SPORTS_FACILITY';
  readonly providerName = 'Sports Venues & Turf Management API';
  readonly providerType = IntegrationProviderType.EXTERNAL;
  readonly vertical = 'sports';

  isConfigured(): boolean {
    return Boolean(process.env.SPORTS_PROVIDER_API_KEY && process.env.SPORTS_PROVIDER_API_URL);
  }

  isEnabled(): boolean {
    return this.isConfigured() && process.env.SPORTS_PROVIDER_ENABLED === 'true';
  }

  async sync(correlationId?: string): Promise<SyncExecutionResult> {
    if (!this.isEnabled()) {
      return {
        recordsRead: 0,
        recordsCreated: 0,
        recordsUpdated: 0,
        recordsSkipped: 0,
        recordsFailed: 0,
        errorSummary: 'Sports facility API is unconfigured or disabled: commercial credentials required',
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

  normalizeCourtSlot(payload: ExternalCourtSlotPayload) {
    return {
      id: `slot_${payload.courtId}_${payload.startTime.replace(/[^a-zA-Z0-9]/g, '')}`,
      time: payload.startTime,
      duration: `${payload.durationMinutes} mins`,
      price: payload.price,
      status: payload.status === 'AVAILABLE' ? 'AVAILABLE' : 'BOOKED',
      courtName: payload.courtName,
    };
  }
}
