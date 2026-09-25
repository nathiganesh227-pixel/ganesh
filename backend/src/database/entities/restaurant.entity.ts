import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('restaurants')
export class RestaurantEntity {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column()
  tagline: string;

  @Column('text')
  about: string;

  @Column()
  coverImageUrl: string;

  @Column('simple-array')
  galleryImages: string[];

  @Column('float')
  rating: number;

  @Column('int')
  reviewCount: number;

  @Column('simple-array')
  cuisines: string[];

  @Column('float')
  priceForTwo: number;

  @Column()
  location: string;

  @Column()
  distance: string;

  @Column()
  openingHours: string;

  @Column({ default: false })
  isPureVeg: boolean;

  @Column({ default: false })
  hasOutdoor: boolean;

  @Column({ default: true })
  isOpenNow: boolean;

  @Column({ nullable: true })
  offerBadge: string;

  @Column('simple-array')
  amenities: string[];

  @Column('jsonb', { nullable: true })
  popularDishes: {
    name: string;
    description: string;
    price: number;
    isVeg: boolean;
    isChefSpecial: boolean;
    imageUrl: string;
  }[];

  @Column('jsonb', { nullable: true })
  reviews: {
    userName: string;
    rating: number;
    comment: string;
    date: string;
  }[];

  @Column('jsonb', { nullable: true })
  availableSlots: {
    time: string;
    status: string;
    tablesLeft: number;
  }[];

  @Column({ default: false })
  isTrending: boolean;

  @Column({ default: false })
  isFineDining: boolean;

  @Column({ default: true })
  isPublished: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
