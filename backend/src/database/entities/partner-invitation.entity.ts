import { Entity, PrimaryColumn, Column, CreateDateColumn, Index } from 'typeorm';
import { UserRole } from './user.entity';

export enum InvitationStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
  REVOKED = 'revoked',
  EXPIRED = 'expired',
}

@Entity('partner_invitations')
export class PartnerInvitationEntity {
  @PrimaryColumn()
  id: string;

  @Index()
  @Column()
  partnerId: string;

  @Index()
  @Column()
  invitedEmail: string;

  @Column({ type: 'varchar', default: UserRole.PARTNER_STAFF })
  invitedRole: UserRole;

  @Column({ unique: true })
  invitationCode: string;

  @Column({ type: 'varchar', default: InvitationStatus.PENDING })
  status: InvitationStatus;

  @Column()
  invitedBy: string;

  @Column()
  expiresAt: Date;

  @CreateDateColumn()
  createdAt: Date;
}
