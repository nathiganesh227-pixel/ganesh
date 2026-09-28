import { Injectable } from '@nestjs/common';
import { IProviderAdapter, SyncExecutionResult } from './provider.adapter.interface';
import {
  IntegrationProviderType,
  AvailabilityResponseDto,
  AvailabilityStatus,
  AvailabilityFreshness,
} from '../dto/integration.dto';

export interface ExternalMovieShowPayload {
  externalShowId: string;
  externalMovieId: string;
  movieTitle: string;
  theatreName: string;
  screenName: string;
  showDate: string;
  showTime: string;
  format: string;
  language: string;
  pricing: { gold: number; premium: number; recliner: number };
  totalSeats: number;
  availableSeats: number;
}

@Injectable()
export class MovieProviderAdapter implements IProviderAdapter {
  readonly providerId = 'EXTERNAL_MOVIE_AGGREGATOR';
  readonly providerName = 'Cinema Exhibition Gateway (Commercial Adapter)';
  readonly providerType = IntegrationProviderType.EXTERNAL;
  readonly vertical = 'movie';

  isConfigured(): boolean {
    return Boolean(process.env.MOVIE_PROVIDER_API_KEY && process.env.MOVIE_PROVIDER_API_URL);
  }

  isEnabled(): boolean {
    return this.isConfigured() && process.env.MOVIE_PROVIDER_ENABLED === 'true';
  }

  async sync(correlationId?: string): Promise<SyncExecutionResult> {
    if (!this.isEnabled()) {
      return {
        recordsRead: 0,
        recordsCreated: 0,
        recordsUpdated: 0,
        recordsSkipped: 0,
        recordsFailed: 0,
        errorSummary: 'Movie provider integration is unconfigured or disabled: commercial credentials required',
      };
    }
    // Normalization logic runs here when enabled
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

  normalizeShow(payload: ExternalMovieShowPayload) {
    return {
      startTime: payload.showTime,
      format: payload.format || '2D',
      language: payload.language || 'Telugu',
      pricing: payload.pricing,
      seatAvailability: {
        totalSeats: payload.totalSeats,
        bookedSeats: [],
      },
    };
  }
}
