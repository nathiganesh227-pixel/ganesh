import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('events')
export class EventEntity {
  @PrimaryColumn()
  id: string;

  @Column()
  title: string;

  @Column()
  tagline: string;

  @Column('text')
  description: string;

  @Column()
  category: string;

  @Column()
  posterUrl: string;

  @Column()
  bannerUrl: string;

  @Column()
  eventDate: string;

  @Column()
  time: string;

  @Column()
  venue: string;

  @Column()
  location: string;

  @Column()
  distance: string;

  @Column('float')
  rating: number;

  @Column('int')
  interestedCount: number;

  @Column()
  ageRestriction: string;

  @Column({ default: 'English & Telugu' })
  languages: string;

  @Column('jsonb', { nullable: true })
  ticketTiers: {
    id: string;
    name: string;
    description: string;
    price: number;
    remainingCount: number;
    perks?: string[];
  }[];

  @Column('jsonb', { nullable: true })
  performers: {
    name: string;
    role: string;
    imageUrl: string;
  }[];

  @Column({ default: false })
  isTrending: boolean;

  @Column({ default: false })
  isFeatured: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
