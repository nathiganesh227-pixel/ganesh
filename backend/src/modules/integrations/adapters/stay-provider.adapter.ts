import { Injectable } from '@nestjs/common';
import { IProviderAdapter, SyncExecutionResult } from './provider.adapter.interface';
import {
  IntegrationProviderType,
  AvailabilityResponseDto,
  AvailabilityStatus,
  AvailabilityFreshness,
} from '../dto/integration.dto';

export interface ExternalHotelRatePayload {
  hotelId: string;
  roomTypeId: string;
  checkInDate: string;
  checkOutDate: string;
  ratePerNight: number;
  availableRooms: number;
  isAvailable: boolean;
}

@Injectable()
export class StayProviderAdapter implements IProviderAdapter {
  readonly providerId = 'EXTERNAL_HOTEL_CHANNEL';
  readonly providerName = 'Global Hospitality Channel Manager';
  readonly providerType = IntegrationProviderType.EXTERNAL;
  readonly vertical = 'stay';

  isConfigured(): boolean {
    return Boolean(process.env.STAY_PROVIDER_API_KEY && process.env.STAY_PROVIDER_API_URL);
  }

  isEnabled(): boolean {
    return this.isConfigured() && process.env.STAY_PROVIDER_ENABLED === 'true';
  }

  async sync(correlationId?: string): Promise<SyncExecutionResult> {
    if (!this.isEnabled()) {
      return {
        recordsRead: 0,
        recordsCreated: 0,
        recordsUpdated: 0,
        recordsSkipped: 0,
        recordsFailed: 0,
        errorSummary: 'Hospitality channel manager is unconfigured or disabled: commercial credentials required',
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

  normalizeRoomRate(payload: ExternalHotelRatePayload) {
    return {
      pricePerNight: payload.ratePerNight,
      isAvailable: payload.isAvailable && payload.availableRooms > 0,
    };
  }
}
