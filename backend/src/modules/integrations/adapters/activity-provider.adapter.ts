import { Injectable } from '@nestjs/common';
import { IProviderAdapter, SyncExecutionResult } from './provider.adapter.interface';
import {
  IntegrationProviderType,
  AvailabilityResponseDto,
  AvailabilityStatus,
  AvailabilityFreshness,
} from '../dto/integration.dto';

export interface ExternalActivitySlotPayload {
  activityId: string;
  packageId: string;
  slotTime: string;
  totalCapacity: number;
  availableCapacity: number;
  pricePerPerson: number;
}

@Injectable()
export class ActivityProviderAdapter implements IProviderAdapter {
  readonly providerId = 'EXTERNAL_ACTIVITY_OPERATOR';
  readonly providerName = 'Adventure & Experiences Booking Network';
  readonly providerType = IntegrationProviderType.EXTERNAL;
  readonly vertical = 'activity';

  isConfigured(): boolean {
    return Boolean(process.env.ACTIVITY_PROVIDER_API_KEY && process.env.ACTIVITY_PROVIDER_API_URL);
  }

  isEnabled(): boolean {
    return this.isConfigured() && process.env.ACTIVITY_PROVIDER_ENABLED === 'true';
  }

  async sync(correlationId?: string): Promise<SyncExecutionResult> {
    if (!this.isEnabled()) {
      return {
        recordsRead: 0,
        recordsCreated: 0,
        recordsUpdated: 0,
        recordsSkipped: 0,
        recordsFailed: 0,
        errorSummary: 'Activity provider is unconfigured or disabled: commercial credentials required',
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

  normalizeSlot(payload: ExternalActivitySlotPayload) {
    return {
      time: payload.slotTime,
      availableSlots: payload.availableCapacity,
    };
  }
}
