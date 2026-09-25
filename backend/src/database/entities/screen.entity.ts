import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export interface SeatLayoutInfo {
  rows: number;
  cols: number;
  tiers: {
    name: string; // e.g. "Recliner", "Premium", "Gold"
    rows: string[]; // e.g. ["A", "B"]
    basePrice: number;
  }[];
}

@Entity('screens')
export class ScreenEntity {
  @PrimaryColumn()
  id: string;

  @Index()
  @Column()
  theatreId: string;

  @Column()
  name: string;

  @Column({ default: 'standard' })
  screenType: string;

  @Column('int')
  capacity: number;

  @Column('jsonb', { nullable: true })
  seatLayout: SeatLayoutInfo | null;

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
