import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export interface ShowPricing {
  gold: number;
  premium: number;
  recliner: number;
}

export interface SeatAvailability {
  totalSeats: number;
  bookedSeats: string[];
  lockedSeats?: string[];
}

@Entity('movie_shows')
export class ShowEntity {
  @PrimaryColumn()
  id: string;

  @Index()
  @Column()
  movieId: string;

  @Index()
  @Column()
  theatreId: string;

  @Index()
  @Column()
  screenId: string;

  @Index()
  @Column()
  showDate: string; // YYYY-MM-DD e.g. 2026-09-26

  @Column()
  startTime: string; // e.g. "10:15 AM"

  @Column({ default: '2D' })
  format: string;

  @Column({ default: 'Telugu' })
  language: string;

  @Column('jsonb')
  pricing: ShowPricing;

  @Column('jsonb', { nullable: true })
  seatAvailability: SeatAvailability;

  @Column({ default: 'active' })
  status: string; // 'active', 'cancelled', 'completed'

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
