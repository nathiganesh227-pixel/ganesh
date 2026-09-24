import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('activities')
export class ActivityEntity {
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
  coverImageUrl: string;

  @Column('simple-array')
  galleryImages: string[];

  @Column('float')
  rating: number;

  @Column('int')
  reviewCount: number;

  @Column()
  location: string;

  @Column()
  distance: string;

  @Column('simple-array')
  highlights: string[];

  @Column('simple-array')
  safetyGuidelines: string[];

  @Column('jsonb', { nullable: true })
  packages: {
    id: string;
    name: string;
    description: string;
    pricePerPerson: number;
    duration: string;
    includedFeatures: string[];
  }[];

  @Column('jsonb', { nullable: true })
  addOns: {
    id: string;
    name: string;
    description: string;
    price: number;
  }[];

  @Column('jsonb', { nullable: true })
  timeSlots: {
    time: string;
    availableSlots: number;
    isFillingFast?: boolean;
  }[];

  @Column({ default: false })
  isTrending: boolean;

  @Column({ default: false })
  isPopular: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
