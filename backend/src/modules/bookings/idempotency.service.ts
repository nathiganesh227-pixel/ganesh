import * as crypto from 'crypto';
import { Injectable, Logger, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  IdempotencyRecordEntity,
  IdempotencyStatus,
} from '../../database/entities/idempotency-record.entity';

export interface IdempotencyOptions {
  requestPayload?: any;
  operation?: string;
  resourceId?: string;
  status?: IdempotencyStatus;
  failureReason?: string;
}

@Injectable()
export class IdempotencyService {
  private readonly logger = new Logger(IdempotencyService.name);
  private readonly inFlightLocks = new Map<string, Promise<any>>();

  constructor(
    @InjectRepository(IdempotencyRecordEntity)
    private readonly repo: Repository<IdempotencyRecordEntity>,
  ) {}

  /**
   * Deterministically computes a SHA-256 fingerprint for arbitrary request payloads.
   * Recursively canonicalizes object keys to ensure consistent hashing regardless of key order.
   */
  computeFingerprint(payload: any): string {
    if (payload === undefined || payload === null) {
      return crypto.createHash('sha256').update('').digest('hex');
    }

    const canonicalString = this.canonicalize(payload);
    return crypto.createHash('sha256').update(canonicalString).digest('hex');
  }

  private canonicalize(obj: any): string {
    if (obj === null || typeof obj !== 'object') {
      return JSON.stringify(obj);
    }

    if (Array.isArray(obj)) {
      return '[' + obj.map((item) => this.canonicalize(item)).join(',') + ']';
    }

    const sortedKeys = Object.keys(obj).sort();
    const keyValues = sortedKeys
      .filter((k) => obj[k] !== undefined)
      .map((k) => `${JSON.stringify(k)}:${this.canonicalize(obj[k])}`);

    return '{' + keyValues.join(',') + '}';
  }

  /**
   * Retrieves a cached idempotent response if the key exists.
   * If requestPayload is provided, validates that the request fingerprint matches.
   * If the key was used with a DIFFERENT request payload, throws ConflictException (409).
   */
  async get(
    userId: string,
    idempotencyKey?: string,
    requestPayload?: any,
  ): Promise<Record<string, any> | null> {
    if (!idempotencyKey || typeof idempotencyKey !== 'string' || !idempotencyKey.trim()) {
      return null;
    }

    const trimmedKey = idempotencyKey.trim();
    const compositeKey = trimmedKey.includes(':')
      ? trimmedKey
      : `${userId}:${trimmedKey}`;

    let record = await this.repo.findOne({ where: { key: compositeKey } });
    if (!record && compositeKey !== trimmedKey) {
      record = await this.repo.findOne({ where: { key: trimmedKey } });
    }

    if (record) {
      // 1. Conflict detection: Same key + Different request payload
      if (requestPayload !== undefined && record.requestHash) {
        const currentHash = this.computeFingerprint(requestPayload);
        if (record.requestHash !== currentHash) {
          this.logger.warn(
            `[Idempotency] Conflict detected for key ${idempotencyKey}: stored hash ${record.requestHash} != current hash ${currentHash}`,
          );
          throw new ConflictException(
            `Idempotency conflict: key '${idempotencyKey}' was previously used with different request parameters.`,
          );
        }
      }

      // 2. Return cached result if already completed
      if (record.status === 'COMPLETED' && record.responseBody) {
        this.logger.log(
          `[Idempotency] Returning cached response for key: ${idempotencyKey} (User: ${userId})`,
        );
        return {
          ...record.responseBody,
          idempotentReplay: true,
        };
      }

      // 3. Handle in-flight processing
      if (record.status === 'PROCESSING') {
        this.logger.log(
          `[Idempotency] Request for key ${idempotencyKey} is currently processing`,
        );
        return {
          status: 'PROCESSING',
          idempotencyKey,
          idempotentReplay: true,
          inFlight: true,
        };
      }
    }

    return null;
  }

  /**
   * Persists an idempotency record with status, request fingerprint, and response.
   */
  async save(
    userId: string,
    idempotencyKey: string | undefined,
    endpoint: string,
    responseBody: Record<string, any>,
    options?: IdempotencyOptions,
  ): Promise<void> {
    if (!idempotencyKey || typeof idempotencyKey !== 'string' || !idempotencyKey.trim()) {
      return;
    }

    const trimmedKey = idempotencyKey.trim();
    const compositeKey = trimmedKey.includes(':')
      ? trimmedKey
      : `${userId}:${trimmedKey}`;

    const requestHash = options?.requestPayload !== undefined
      ? this.computeFingerprint(options.requestPayload)
      : undefined;

    try {
      let record = await this.repo.findOne({ where: { key: compositeKey } });
      if (!record) {
        record = this.repo.create({
          key: compositeKey,
          userId,
          idempotencyKey: trimmedKey,
          endpoint,
          operation: options?.operation,
          resourceId: options?.resourceId,
          requestHash,
          status: options?.status || 'COMPLETED',
          responseBody,
          failureReason: options?.failureReason,
        });
      } else {
        record.status = options?.status || 'COMPLETED';
        record.responseBody = responseBody;
        record.operation = options?.operation || record.operation;
        record.resourceId = options?.resourceId || record.resourceId;
        record.requestHash = requestHash || record.requestHash;
        record.failureReason = options?.failureReason || record.failureReason;
      }

      await this.repo.save(record);
      this.logger.log(
        `[Idempotency] Cached response for key: ${idempotencyKey} (User: ${userId}, Status: ${record.status})`,
      );
    } catch (err: any) {
      this.logger.warn(`[Idempotency] Failed to store record ${compositeKey}: ${err.message}`);
    }
  }

  /**
   * Executes an action under full atomic idempotency protection.
   * Replays previous results safely on identical requests.
   * Throws ConflictException (409) if the same key is reused with different parameters.
   */
  async execute<T extends Record<string, any>>(
    userId: string,
    idempotencyKey: string | undefined,
    endpoint: string,
    requestPayload: any,
    executor: () => Promise<T>,
    options?: { operation?: string; resourceId?: string },
  ): Promise<T> {
    if (!idempotencyKey || typeof idempotencyKey !== 'string' || !idempotencyKey.trim()) {
      return executor();
    }

    const trimmedKey = idempotencyKey.trim();
    const compositeKey = trimmedKey.includes(':')
      ? trimmedKey
      : `${userId}:${trimmedKey}`;

    // If an in-flight execution is currently running for this composite key, await it
    if (this.inFlightLocks.has(compositeKey)) {
      try {
        const inFlightRes = await this.inFlightLocks.get(compositeKey);
        return {
          ...inFlightRes,
          idempotentReplay: true,
        } as T;
      } catch (e) {
        // let subsequent attempt re-run if previous failed
      }
    }

    const requestHash = this.computeFingerprint(requestPayload);

    const runExecution = async (): Promise<T> => {
      // 1. Check existing record
      const existing = await this.repo.findOne({ where: { key: compositeKey } });
      if (existing) {
        if (existing.requestHash && existing.requestHash !== requestHash) {
          this.logger.warn(
            `[Idempotency] Conflict detected for key ${idempotencyKey}: stored hash ${existing.requestHash} != current hash ${requestHash}`,
          );
          throw new ConflictException(
            `Idempotency conflict: key '${idempotencyKey}' was previously used with different request parameters.`,
          );
        }

        if (existing.status === 'COMPLETED' && existing.responseBody) {
          this.logger.log(
            `[Idempotency] Returning cached response for key: ${idempotencyKey} (User: ${userId})`,
          );
          return {
            ...existing.responseBody,
            idempotentReplay: true,
          } as unknown as T;
        }
      }

      // 2. Mark initial state as PROCESSING
      try {
        const processingRecord = this.repo.create({
          key: compositeKey,
          userId,
          idempotencyKey: trimmedKey,
          endpoint,
          operation: options?.operation,
          resourceId: options?.resourceId,
          requestHash,
          status: 'PROCESSING',
          responseBody: {},
        });
        await this.repo.save(processingRecord);
      } catch {
        // Concurrency race: another thread might have inserted PROCESSING
      }

      // 3. Execute work
      try {
        const result = await executor();

        // 4. Save COMPLETED result
        await this.save(userId, trimmedKey, endpoint, result, {
          requestPayload,
          operation: options?.operation,
          resourceId: options?.resourceId,
          status: 'COMPLETED',
        });

        return result;
      } catch (err: any) {
        if (err instanceof ConflictException) {
          throw err;
        }

        // 5. Record failure state
        await this.save(userId, trimmedKey, endpoint, {}, {
          requestPayload,
          operation: options?.operation,
          resourceId: options?.resourceId,
          status: 'FAILED',
          failureReason: err.message,
        });

        throw err;
      }
    };

    const taskPromise = runExecution();
    this.inFlightLocks.set(compositeKey, taskPromise);
    try {
      return await taskPromise;
    } finally {
      this.inFlightLocks.delete(compositeKey);
    }
  }
}
