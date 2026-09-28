import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';
import { UserRole } from './user.entity';

@Entity('partner_users')
export class PartnerUserEntity {
  @PrimaryColumn()
  id: string;

  @Index()
  @Column()
  partnerId: string;

  @Index()
  @Column()
  userId: string;

  @Column({ type: 'varchar', default: UserRole.PARTNER_OWNER })
  role: UserRole;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
