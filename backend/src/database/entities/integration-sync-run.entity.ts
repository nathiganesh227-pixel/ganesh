import { Entity, PrimaryColumn, Column, CreateDateColumn, Index } from 'typeorm';

export enum SyncRunStatus {
  SUCCESS = 'SUCCESS',
  PARTIAL = 'PARTIAL',
  FAILED = 'FAILED',
  IN_PROGRESS = 'IN_PROGRESS',
}

@Entity('integration_sync_runs')
export class IntegrationSyncRunEntity {
  @PrimaryColumn()
  id: string; // e.g. isync_1790500000000_abcde

  @Index()
  @Column()
  provider: string;

  @Column()
  vertical: string;

  @Column({ type: 'varchar', default: SyncRunStatus.IN_PROGRESS })
  status: SyncRunStatus;

  @Column('int', { default: 0 })
  recordsRead: number;

  @Column('int', { default: 0 })
  recordsCreated: number;

  @Column('int', { default: 0 })
  recordsUpdated: number;

  @Column('int', { default: 0 })
  recordsSkipped: number;

  @Column('int', { default: 0 })
  recordsFailed: number;

  @Column({ type: 'text', nullable: true })
  errorSummary?: string;

  @Column({ nullable: true })
  correlationId?: string;

  @Column({ type: 'timestamptz' })
  startedAt: Date;

  @Column({ type: 'timestamptz', nullable: true })
  completedAt?: Date;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
