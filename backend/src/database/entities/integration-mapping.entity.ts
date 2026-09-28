import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export enum SyncStatus {
  SYNCED = 'SYNCED',
  PENDING = 'PENDING',
  FAILED = 'FAILED',
  STALE = 'STALE',
}

@Entity('integration_mappings')
export class IntegrationMappingEntity {
  @PrimaryColumn()
  id: string; // e.g. imap_1790500000000_abcde

  @Index()
  @Column()
  provider: string; // e.g. 'INTERNAL_PARTNER', 'ADMIN_CURATED', 'BMS_MOVIES', 'HOTEL_BEDS'

  @Index()
  @Column()
  providerEntityId: string; // External or partner-scoped source ID

  @Index()
  @Column()
  plazaEntityId: string; // Canonical PLAZA catalog entity ID

  @Index()
  @Column()
  vertical: string; // 'movie' | 'dining' | 'event' | 'activity' | 'stay' | 'sports' | 'shopping'

  @Index()
  @Column({ nullable: true })
  partnerId?: string; // Tenant isolation key if partner-owned

  @Column({ type: 'varchar', default: SyncStatus.SYNCED })
  syncStatus: SyncStatus;

  @Column({ type: 'timestamptz', nullable: true })
  lastSyncedAt?: Date;

  @Column({ type: 'timestamptz', nullable: true })
  lastSuccessfulSyncAt?: Date;

  @Column('jsonb', { nullable: true })
  metadata?: Record<string, any>;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt: Date;
}
