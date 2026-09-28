import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

export enum UserRole {
  USER = 'user',
  ADMIN = 'admin',
  OPERATOR = 'operator',
  SUPER_ADMIN = 'super_admin',
  PARTNER_OWNER = 'partner_owner',
  PARTNER_MANAGER = 'partner_manager',
  PARTNER_STAFF = 'partner_staff',
}

@Entity('users')
export class User {
  @PrimaryColumn()
  id: string;

  @Column({ unique: true })
  email: string;

  @Column({ nullable: true })
  passwordHash: string;

  @Column({ default: 'Guest User' })
  name: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ nullable: true })
  avatarUrl: string;

  @Column({ type: 'varchar', default: UserRole.USER })
  role: UserRole;

  @Column({ default: 'Hyderabad' })
  city: string;

  @Column({ default: 1250 })
  rewardPoints: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
