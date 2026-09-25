import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('products')
export class ProductEntity {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column()
  brand: string;

  @Column()
  category: string;

  @Column('float')
  price: number;

  @Column('float', { nullable: true })
  originalPrice: number;

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

  @Column('jsonb', { nullable: true })
  specifications: Record<string, string>;

  @Column('jsonb', { nullable: true })
  variants: {
    id: string;
    name: string;
    priceDelta: number;
    inStock: boolean;
  }[];

  @Column()
  storeId: string;

  @Column()
  storeName: string;

  @Column()
  storeLocation: string;

  @Column()
  distance: string;

  @Column({ default: false })
  isTrending: boolean;

  @Column({ default: false })
  isDealOfTheDay: boolean;

  @Column({ nullable: true })
  discountBadge: string;

  @Column({ default: true })
  inStock: boolean;

  @Column({ default: true })
  isPublished: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
