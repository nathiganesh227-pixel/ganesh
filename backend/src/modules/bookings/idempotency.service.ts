import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { IdempotencyRecordEntity } from '../../database/entities/idempotency-record.entity';

@Injectable()
export class IdempotencyService {
  private readonly logger = new Logger(IdempotencyService.name);

  constructor(
    @InjectRepository(IdempotencyRecordEntity)
    private readonly repo: Repository<IdempotencyRecordEntity>,
  ) {}

  async get(userId: string, idempotencyKey?: string): Promise<Record<string, any> | null> {
    if (!idempotencyKey) return null;
    const compositeKey = `${userId}:${idempotencyKey}`;
    const record = await this.repo.findOne({ where: { key: compositeKey } });
    if (record) {
      this.logger.log(`[Idempotency] Returning cached response for key: ${idempotencyKey} (User: ${userId})`);
      return record.responseBody;
    }
    return null;
  }

  async save(
    userId: string,
    idempotencyKey: string | undefined,
    endpoint: string,
    responseBody: Record<string, any>,
  ): Promise<void> {
    if (!idempotencyKey) return;
    const compositeKey = `${userId}:${idempotencyKey}`;
    try {
      const record = this.repo.create({
        key: compositeKey,
        userId,
        idempotencyKey,
        endpoint,
        responseBody,
      });
      await this.repo.save(record);
      this.logger.log(`[Idempotency] Cached response for key: ${idempotencyKey} (User: ${userId})`);
    } catch (err: any) {
      this.logger.warn(`[Idempotency] Failed to store record ${compositeKey}: ${err.message}`);
    }
  }
}
