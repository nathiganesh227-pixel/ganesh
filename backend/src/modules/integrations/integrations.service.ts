import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  IntegrationMappingEntity,
  SyncStatus,
} from '../../database/entities/integration-mapping.entity';
import {
  IntegrationSyncRunEntity,
  SyncRunStatus,
} from '../../database/entities/integration-sync-run.entity';
import { BookingEntity, BookingStatus } from '../../database/entities/booking.entity';
import { ProviderRegistryService } from './registry/provider-registry.service';
import {
  AvailabilityStatus,
  AvailabilityFreshness,
  AvailabilityResponseDto,
  TriggerSyncDto,
} from './dto/integration.dto';

@Injectable()
export class IntegrationsService {
  private readonly logger = new Logger(IntegrationsService.name);
  private activeSyncLocks: Set<string> = new Set();

  constructor(
    @InjectRepository(IntegrationMappingEntity)
    private readonly mappingRepo: Repository<IntegrationMappingEntity>,
    @InjectRepository(IntegrationSyncRunEntity)
    private readonly syncRunRepo: Repository<IntegrationSyncRunEntity>,
    @InjectRepository(BookingEntity)
    private readonly bookingRepo: Repository<BookingEntity>,
    private readonly providerRegistry: ProviderRegistryService,
  ) {}

  // ---------------- PROVIDER STATUS & HEALTH ----------------

  async listProviders() {
    const summaries = this.providerRegistry.getProviderSummaries();

    // Enrich with last sync timestamps from the database
    for (const p of summaries) {
      const lastRun = await this.syncRunRepo.findOne({
        where: { provider: p.providerId },
        order: { startedAt: 'DESC' },
      });
      if (lastRun) {
        p.lastSyncedAt = lastRun.completedAt || lastRun.startedAt;
        if (lastRun.status === SyncRunStatus.SUCCESS) {
          p.lastSuccessfulSyncAt = lastRun.completedAt;
        } else if (lastRun.errorSummary) {
          p.errorSummary = lastRun.errorSummary;
        }
      }
    }

    return summaries;
  }

  async getHealth() {
    const providers = await this.listProviders();
    const total = providers.length;
    const active = providers.filter((p) => p.isEnabled).length;
    const configured = providers.filter((p) => p.isConfigured).length;
    const unconfigured = providers.filter((p) => !p.isConfigured).length;

    const recentRuns = await this.syncRunRepo.find({
      order: { startedAt: 'DESC' },
      take: 10,
    });

    const hasFailures = recentRuns.some((r) => r.status === SyncRunStatus.FAILED);

    return {
      status: hasFailures ? 'DEGRADED' : 'HEALTHY',
      timestamp: new Date().toISOString(),
      summary: {
        totalProviders: total,
        activeProviders: active,
        configuredProviders: configured,
        unconfiguredProviders: unconfigured,
      },
      freshnessPolicyMinutes: 15,
      recentSyncRuns: recentRuns,
    };
  }

  // ---------------- MAPPINGS (CANONICAL TO PROVIDER) ----------------

  async createOrUpdateMapping(params: {
    provider: string;
    providerEntityId: string;
    plazaEntityId: string;
    vertical: string;
    partnerId?: string;
    metadata?: Record<string, any>;
  }): Promise<IntegrationMappingEntity> {
    let mapping = await this.mappingRepo.findOne({
      where: {
        provider: params.provider,
        providerEntityId: params.providerEntityId,
      },
    });

    const now = new Date();

    if (!mapping) {
      mapping = this.mappingRepo.create({
        id: `imap_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        provider: params.provider,
        providerEntityId: params.providerEntityId,
        plazaEntityId: params.plazaEntityId,
        vertical: params.vertical,
        partnerId: params.partnerId || null,
        syncStatus: SyncStatus.SYNCED,
        lastSyncedAt: now,
        lastSuccessfulSyncAt: now,
        metadata: params.metadata || {},
      });
    } else {
      mapping.plazaEntityId = params.plazaEntityId;
      mapping.vertical = params.vertical;
      if (params.partnerId) mapping.partnerId = params.partnerId;
      mapping.syncStatus = SyncStatus.SYNCED;
      mapping.lastSyncedAt = now;
      mapping.lastSuccessfulSyncAt = now;
      mapping.metadata = { ...(mapping.metadata || {}), ...(params.metadata || {}) };
    }

    return this.mappingRepo.save(mapping);
  }

  async getMappings(vertical?: string, partnerId?: string, limit = 50, offset = 0) {
    const qb = this.mappingRepo.createQueryBuilder('m');
    if (vertical) {
      qb.andWhere('m.vertical = :vertical', { vertical });
    }
    if (partnerId) {
      qb.andWhere('m.partnerId = :partnerId', { partnerId });
    }
    qb.orderBy('m.updatedAt', 'DESC').skip(offset).take(limit);

    const [items, total] = await qb.getManyAndCount();
    return { items, total, limit, offset };
  }

  // ---------------- SYNCHRONIZATION EXECUTION ----------------

  async triggerSync(providerId: string, dto: TriggerSyncDto = {}, correlationId?: string) {
    const adapter = this.providerRegistry.getAdapter(providerId);
    if (!adapter) {
      throw new NotFoundException(`Provider '${providerId}' is not registered`);
    }

    // Concurrency Lock Check
    if (this.activeSyncLocks.has(providerId)) {
      throw new ConflictException(`Sync for provider '${providerId}' is already in progress`);
    }

    this.activeSyncLocks.add(providerId);
    const syncRunId = `isync_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const startedAt = new Date();

    const syncRun = this.syncRunRepo.create({
      id: syncRunId,
      provider: providerId,
      vertical: adapter.vertical,
      status: SyncRunStatus.IN_PROGRESS,
      correlationId: correlationId || `corr_${Date.now()}`,
      startedAt,
    });
    await this.syncRunRepo.save(syncRun);

    try {
      this.logger.log(`Starting sync for provider ${providerId} (runId: ${syncRunId})`);
      const result = await adapter.sync(correlationId);

      syncRun.recordsRead = result.recordsRead;
      syncRun.recordsCreated = result.recordsCreated;
      syncRun.recordsUpdated = result.recordsUpdated;
      syncRun.recordsSkipped = result.recordsSkipped;
      syncRun.recordsFailed = result.recordsFailed;
      syncRun.errorSummary = result.errorSummary || null;
      syncRun.status = result.recordsFailed > 0 ? SyncRunStatus.PARTIAL : SyncRunStatus.SUCCESS;
      syncRun.completedAt = new Date();

      await this.syncRunRepo.save(syncRun);
      return syncRun;
    } catch (err: any) {
      this.logger.error(`Sync failed for provider ${providerId}: ${err?.message || err}`);
      syncRun.status = SyncRunStatus.FAILED;
      syncRun.errorSummary = err?.message || 'Unknown sync error';
      syncRun.completedAt = new Date();
      await this.syncRunRepo.save(syncRun);
      return syncRun;
    } finally {
      this.activeSyncLocks.delete(providerId);
    }
  }

  async listSyncRuns(provider?: string, limit = 20, offset = 0) {
    const qb = this.syncRunRepo.createQueryBuilder('r');
    if (provider) {
      qb.andWhere('r.provider = :provider', { provider });
    }
    qb.orderBy('r.startedAt', 'DESC').skip(offset).take(limit);

    const [items, total] = await qb.getManyAndCount();
    return { items, total, limit, offset };
  }

  // ---------------- TRUTHFUL AVAILABILITY & FRESHNESS ----------------

  calculateFreshness(lastUpdatedAt?: Date | string | null, ttlMinutes = 15): AvailabilityFreshness {
    if (!lastUpdatedAt) {
      return AvailabilityFreshness.UNKNOWN;
    }
    const date = new Date(lastUpdatedAt);
    if (isNaN(date.getTime())) {
      return AvailabilityFreshness.UNKNOWN;
    }

    const ageMinutes = (Date.now() - date.getTime()) / (1000 * 60);
    if (ageMinutes < 0) {
      return AvailabilityFreshness.UNKNOWN;
    }
    if (ageMinutes <= ttlMinutes) {
      return AvailabilityFreshness.FRESH;
    }
    return AvailabilityFreshness.STALE;
  }

  async evaluateAvailability(
    providerId: string,
    providerEntityId: string,
    fallbackStatus: AvailabilityStatus = AvailabilityStatus.UNKNOWN,
  ): Promise<AvailabilityResponseDto> {
    const adapter = this.providerRegistry.getAdapter(providerId);
    if (!adapter || !adapter.isEnabled()) {
      return {
        status: fallbackStatus,
        freshness: AvailabilityFreshness.UNKNOWN,
        source: adapter?.providerType || 'EXTERNAL',
        sourceReference: providerEntityId,
        lastUpdatedAt: new Date(),
      };
    }

    return adapter.getAvailability(providerEntityId);
  }

  // ---------------- BOOKING SAFETY & RECONCILIATION GUARD ----------------

  async verifyBookingIntegrity(bookingId: string) {
    const booking = await this.bookingRepo.findOne({ where: { id: bookingId } });
    if (!booking) {
      throw new NotFoundException(`Booking #${bookingId} not found`);
    }

    // Active bookings can NEVER be silently invalidated by external sync
    const immutableStatuses = [
      BookingStatus.CONFIRMED,
      BookingStatus.ACTIVE,
      BookingStatus.UPCOMING,
    ];

    return {
      bookingId: booking.id,
      status: booking.status,
      isProtected: immutableStatuses.includes(booking.status),
      partnerId: booking.partnerId,
    };
  }
}
