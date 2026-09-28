import { Injectable } from '@nestjs/common';
import { IProviderAdapter, SyncExecutionResult } from './provider.adapter.interface';
import {
  IntegrationProviderType,
  AvailabilityResponseDto,
  AvailabilityStatus,
  AvailabilityFreshness,
} from '../dto/integration.dto';

export interface ExternalProductStockPayload {
  productId: string;
  sku: string;
  currentStock: number;
  inStock: boolean;
  price: number;
}

@Injectable()
export class ShoppingProviderAdapter implements IProviderAdapter {
  readonly providerId = 'EXTERNAL_RETAIL_ERP';
  readonly providerName = 'Retail ERP & Warehouse Inventory Feed';
  readonly providerType = IntegrationProviderType.EXTERNAL;
  readonly vertical = 'shopping';

  isConfigured(): boolean {
    return Boolean(process.env.SHOPPING_PROVIDER_API_KEY && process.env.SHOPPING_PROVIDER_API_URL);
  }

  isEnabled(): boolean {
    return this.isConfigured() && process.env.SHOPPING_PROVIDER_ENABLED === 'true';
  }

  async sync(correlationId?: string): Promise<SyncExecutionResult> {
    if (!this.isEnabled()) {
      return {
        recordsRead: 0,
        recordsCreated: 0,
        recordsUpdated: 0,
        recordsSkipped: 0,
        recordsFailed: 0,
        errorSummary: 'Retail ERP provider is unconfigured or disabled: commercial credentials required',
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

  normalizeStock(payload: ExternalProductStockPayload) {
    return {
      inStock: payload.inStock && payload.currentStock > 0,
      price: payload.price,
      availabilityStatus:
        payload.currentStock > 5
          ? AvailabilityStatus.AVAILABLE
          : payload.currentStock > 0
          ? AvailabilityStatus.LIMITED
          : AvailabilityStatus.SOLD_OUT,
    };
  }
}
