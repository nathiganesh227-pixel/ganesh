import { Entity, PrimaryColumn, Column, CreateDateColumn, Index } from 'typeorm';

@Entity('audit_logs')
export class AuditLogEntity {
  @PrimaryColumn()
  id: string;

  @Index()
  @Column()
  actorUserId: string;

  @Column()
  actorEmail: string;

  @Column()
  action: string;

  @Column()
  resourceType: string;

  @Column()
  resourceId: string;

  @Column({ type: 'jsonb', nullable: true })
  metadata: Record<string, any> | null;

  @Index()
  @CreateDateColumn()
  createdAt: Date;
}
