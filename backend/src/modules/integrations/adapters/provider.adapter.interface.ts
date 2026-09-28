import {
  IntegrationProviderType,
  AvailabilityResponseDto,
} from '../dto/integration.dto';

export interface SyncExecutionResult {
  recordsRead: number;
  recordsCreated: number;
  recordsUpdated: number;
  recordsSkipped: number;
  recordsFailed: number;
  errorSummary?: string;
}

export interface IProviderAdapter {
  readonly providerId: string;
  readonly providerName: string;
  readonly providerType: IntegrationProviderType;
  readonly vertical: string;

  isConfigured(): boolean;
  isEnabled(): boolean;

  sync(correlationId?: string): Promise<SyncExecutionResult>;
  getAvailability(providerEntityId: string): Promise<AvailabilityResponseDto>;
}
