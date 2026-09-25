import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('sports_venues')
export class SportsVenueEntity {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column('simple-array')
  supportedSports: string[];

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
  amenities: string[];

  @Column('text')
  rules: string;

  @Column('float')
  startingPricePerHour: number;

  @Column('jsonb', { nullable: true })
  slots: {
    id: string;
    time: string;
    duration: string;
    price: number;
    status: string;
    courtName: string;
  }[];

  @Column('jsonb', { nullable: true })
  addOns: {
    id: string;
    name: string;
    price: number;
    description: string;
  }[];

  @Column({ default: false })
  isTrending: boolean;

  @Column({ default: false })
  isPopular: boolean;

  @Column({ default: true })
  isPublished: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
