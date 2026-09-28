import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('hotels')
export class HotelEntity {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column()
  tagline: string;

  @Column()
  category: string;

  @Column('float')
  startingPricePerNight: number;

  @Column('float', { nullable: true })
  originalPricePerNight: number;

  @Column('float')
  rating: number;

  @Column('int')
  reviewCount: number;

  @Column()
  coverImageUrl: string;

  @Column('simple-array')
  galleryImages: string[];

  @Column('text')
  description: string;

  @Column()
  location: string;

  @Column()
  distance: string;

  @Column('simple-array')
  amenities: string[];

  @Column('jsonb', { nullable: true })
  rooms: {
    id: string;
    name: string;
    description: string;
    imageUrl: string;
    pricePerNight: number;
    originalPricePerNight?: number;
    maxGuests: number;
    bedType: string;
    roomSize: string;
    highlights: string[];
    isAvailable: boolean;
    availableRooms?: number;
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
  isFeatured: boolean;

  @Column({ default: true })
  isPublished: boolean;

  @Column({ nullable: true })
  partnerId?: string;

  @Column({ nullable: true })
  businessId?: string;

  @Column({ default: 'APPROVED' })
  approvalStatus: string;

  @Column({ default: 'ADMIN' })
  source: string; // 'ADMIN' | 'PARTNER' | 'EXTERNAL'

  @Column({ default: 'AVAILABLE' })
  availabilityStatus: string; // 'AVAILABLE' | 'LIMITED' | 'SOLD_OUT' | 'UNAVAILABLE' | 'UNKNOWN'

  @Column({ type: 'timestamptz', nullable: true })
  availabilityUpdatedAt?: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
