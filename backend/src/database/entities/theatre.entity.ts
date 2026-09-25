import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('theatres')
export class TheatreEntity {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column({ default: 'Hyderabad' })
  city: string;

  @Column({ nullable: true })
  address: string;

  @Column()
  location: string;

  @Column({ default: '0 km' })
  distance: string;

  @Column('simple-array')
  amenities: string[];

  @Column('jsonb', { nullable: true })
  showtimes: {
    id: string;
    time: string;
    format: string;
    language: string;
    screenName: string;
    basePrice: number;
    isFillingFast?: boolean;
    isAlmostFull?: boolean;
    isSoldOut?: boolean;
  }[];

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
