import { Injectable } from '@nestjs/common';
import { IProviderAdapter, SyncExecutionResult } from './provider.adapter.interface';
import {
  IntegrationProviderType,
  AvailabilityResponseDto,
  AvailabilityStatus,
  AvailabilityFreshness,
} from '../dto/integration.dto';

@Injectable()
export class AdminCuratedAdapter implements IProviderAdapter {
  readonly providerId = 'ADMIN_CURATED';
  readonly providerName = 'PLAZA Admin Curated Catalog';
  readonly providerType = IntegrationProviderType.ADMIN;
  readonly vertical = 'multi';

  isConfigured(): boolean {
    return true;
  }

  isEnabled(): boolean {
    return true;
  }

  async sync(correlationId?: string): Promise<SyncExecutionResult> {
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
      source: 'ADMIN',
      sourceReference: providerEntityId,
      lastUpdatedAt: new Date(),
    };
  }
}
