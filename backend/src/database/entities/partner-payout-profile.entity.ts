import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export enum PayoutStatus {
  PENDING_VERIFICATION = 'pending_verification',
  VERIFIED = 'verified',
  REJECTED = 'rejected',
  SUSPENDED = 'suspended',
}

@Entity('partner_payout_profiles')
export class PartnerPayoutProfileEntity {
  @PrimaryColumn()
  id: string;

  @Index({ unique: true })
  @Column()
  partnerId: string;

  @Column()
  accountHolderName: string;

  @Column()
  bankName: string;

  @Column()
  accountNumberMasked: string; // e.g., '••••••••1234'

  @Column()
  accountNumberEncrypted: string;

  @Column()
  ifscCode: string;

  @Column({ type: 'varchar', default: PayoutStatus.PENDING_VERIFICATION })
  payoutStatus: PayoutStatus;

  @Column({ nullable: true })
  verifiedAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
