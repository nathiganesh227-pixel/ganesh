import { Injectable } from '@nestjs/common';
import { IProviderAdapter, SyncExecutionResult } from './provider.adapter.interface';
import {
  IntegrationProviderType,
  AvailabilityResponseDto,
  AvailabilityStatus,
  AvailabilityFreshness,
} from '../dto/integration.dto';

@Injectable()
export class PartnerIntegrationAdapter implements IProviderAdapter {
  readonly providerId = 'INTERNAL_PARTNER';
  readonly providerName = 'PLAZA Partner Network';
  readonly providerType = IntegrationProviderType.PARTNER;
  readonly vertical = 'multi';

  isConfigured(): boolean {
    return true; // Internal system is natively configured
  }

  isEnabled(): boolean {
    return true; // Real partner pipeline is live
  }

  async sync(correlationId?: string): Promise<SyncExecutionResult> {
    // Partner changes synchronize directly via two-gate lifecycle
    return {
      recordsRead: 0,
      recordsCreated: 0,
      recordsUpdated: 0,
      recordsSkipped: 0,
      recordsFailed: 0,
    };
  }

  async getAvailability(providerEntityId: string): Promise<AvailabilityResponseDto> {
    return {
      status: AvailabilityStatus.AVAILABLE,
      freshness: AvailabilityFreshness.FRESH,
      source: 'PARTNER',
      sourceReference: providerEntityId,
      lastUpdatedAt: new Date(),
    };
  }
}
