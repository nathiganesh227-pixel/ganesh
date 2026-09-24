import { Entity, PrimaryColumn, Column, CreateDateColumn, Index } from 'typeorm';

@Entity('idempotency_records')
export class IdempotencyRecordEntity {
  @PrimaryColumn()
  key: string; // Composite key: `${userId}:${idempotencyKey}`

  @Column()
  @Index()
  userId: string;

  @Column()
  idempotencyKey: string;

  @Column()
  endpoint: string;

  @Column('jsonb')
  responseBody: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;
}
