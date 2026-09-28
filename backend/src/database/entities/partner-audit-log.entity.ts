import { Entity, PrimaryColumn, Column, CreateDateColumn, Index } from 'typeorm';

@Entity('partner_audit_logs')
export class PartnerAuditLogEntity {
  @PrimaryColumn()
  id: string;

  @Index()
  @Column()
  partnerId: string;

  @Column()
  actorUserId: string;

  @Column()
  actorEmail: string;

  @Column()
  actorRole: string;

  @Column()
  action: string;

  @Column()
  resourceType: string;

  @Column()
  resourceId: string;

  @Column({ type: 'jsonb', nullable: true })
  metadata: Record<string, any> | null;

  @CreateDateColumn()
  createdAt: Date;
}
