import { Entity, PrimaryColumn, Column, CreateDateColumn, Index } from 'typeorm';

export enum ApprovalAction {
  SUBMIT = 'submit',
  REVIEW_START = 'review_start',
  APPROVE = 'approve',
  REJECT = 'reject',
  SUSPEND = 'suspend',
  RESUME = 'resume',
  CLOSE = 'close',
}

@Entity('partner_approvals')
export class PartnerApprovalEntity {
  @PrimaryColumn()
  id: string;

  @Index()
  @Column()
  partnerId: string;

  @Column()
  targetType: string; // 'partner' | 'business_listing' | 'document'

  @Index()
  @Column()
  targetId: string;

  @Column({ type: 'varchar' })
  action: ApprovalAction;

  @Column()
  actorId: string;

  @Column()
  actorEmail: string;

  @Column()
  actorRole: string;

  @Column({ type: 'text', nullable: true })
  reason: string;

  @Column({ type: 'text', nullable: true })
  comments: string;

  @CreateDateColumn()
  createdAt: Date;
}
