import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export enum PartnerType {
  RESTAURANT = 'restaurant',
  EVENT_ORGANIZER = 'event_organizer',
  ACTIVITY_OPERATOR = 'activity_operator',
  HOTEL = 'hotel',
  SPORTS_VENUE = 'sports_venue',
}

export enum PartnerStatus {
  DRAFT = 'draft',
  SUBMITTED = 'submitted',
  UNDER_REVIEW = 'under_review',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  SUSPENDED = 'suspended',
  CLOSED = 'closed',
}

@Entity('partners')
export class PartnerEntity {
  @PrimaryColumn()
  id: string;

  @Column()
  legalName: string;

  @Column()
  displayName: string;

  @Column({ type: 'varchar', default: PartnerType.RESTAURANT })
  partnerType: PartnerType;

  @Index()
  @Column({ type: 'varchar', default: PartnerStatus.DRAFT })
  status: PartnerStatus;

  @Column()
  email: string;

  @Column()
  phone: string;

  @Column({ default: 'Hyderabad' })
  city: string;

  @Column({ default: 'Telangana' })
  state: string;

  @Column('text')
  address: string;

  @Column({ default: '500081' })
  pinCode: string;

  @Column({ nullable: true })
  website: string;

  @Column({ nullable: true })
  gstNumber: string;

  @Column({ nullable: true })
  panNumber: string;

  @Column({ type: 'text', nullable: true })
  rejectionReason: string;

  @Column({ type: 'text', nullable: true })
  suspensionReason: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
