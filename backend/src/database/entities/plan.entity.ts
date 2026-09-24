import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('plans')
export class PlanEntity {
  @PrimaryColumn()
  id: string;

  @Column({ default: 'user_default' })
  userId: string;

  @Column()
  title: string;

  @Column()
  date: string;

  @Column('float')
  totalEstimatedCost: number;

  @Column('int')
  totalDurationHours: number;

  @Column('jsonb')
  slots: {
    slotNumber: number;
    time: string;
    vertical: string;
    title: string;
    location: string;
    estimatedCost: number;
  }[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
