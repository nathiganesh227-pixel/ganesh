import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export type IdempotencyStatus = 'PROCESSING' | 'COMPLETED' | 'FAILED';

@Entity('idempotency_records')
export class IdempotencyRecordEntity {
  @PrimaryColumn()
  key: string; // Composite key: `${userId}:${idempotencyKey}` or logical operation key

  @Column()
  @Index('IDX_idempotency_records_userId')
  userId: string;

  @Column()
  @Index('IDX_idempotency_records_idempotencyKey')
  idempotencyKey: string;

  @Column()
  endpoint: string;

  @Column({ nullable: true })
  @Index('IDX_idempotency_records_operation')
  operation?: string; // 'payment:create' | 'payment:verify' | 'payment:refund' | 'booking:create' | 'booking:cancel'

  @Column({ nullable: true })
  requestHash?: string; // SHA-256 hash of canonical request parameters

  @Column({ nullable: true })
  @Index('IDX_idempotency_records_resourceId')
  resourceId?: string; // paymentId, bookingId, quoteId, etc.

  @Column({ default: 'COMPLETED' })
  @Index('IDX_idempotency_records_status')
  status: IdempotencyStatus;

  @Column('jsonb', { nullable: true })
  responseBody: Record<string, any>;

  @Column({ type: 'text', nullable: true })
  failureReason?: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
