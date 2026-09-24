import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('rewards')
export class RewardEntity {
  @PrimaryColumn()
  id: string;

  @Column()
  title: string;

  @Column()
  partnerName: string;

  @Column('int')
  pointsCost: number;

  @Column()
  discountValue: string;

  @Column()
  category: string;

  @Column()
  code: string;

  @Column()
  expiryDate: string;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
