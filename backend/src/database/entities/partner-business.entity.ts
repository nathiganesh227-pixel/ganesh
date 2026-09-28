import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export enum BusinessStatus {
  DRAFT = 'draft',
  SUBMITTED = 'submitted',
  UNDER_REVIEW = 'under_review',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  SUSPENDED = 'suspended',
}

@Entity('partner_businesses')
export class PartnerBusinessEntity {
  @PrimaryColumn()
  id: string;

  @Index()
  @Column()
  partnerId: string;

  @Column({ type: 'varchar' })
  vertical: string; // 'dining' | 'event' | 'activity' | 'stay' | 'sports'

  @Column()
  name: string;

  @Column('text')
  description: string;

  @Column('text')
  address: string;

  @Column({ default: 'Hyderabad' })
  city: string;

  @Column()
  contactPhone: string;

  @Column()
  contactEmail: string;

  @Index()
  @Column({ type: 'varchar', default: BusinessStatus.DRAFT })
  status: BusinessStatus;

  @Index()
  @Column({ nullable: true })
  catalogEntityId: string;

  @Column({ type: 'text', nullable: true })
  rejectionReason: string;

  @Column('jsonb', { nullable: true })
  metadata: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
