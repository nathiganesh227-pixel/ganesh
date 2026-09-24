import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

export enum BookingType {
  MOVIE = 'movie',
  DINING = 'dining',
  EVENT = 'event',
  ACTIVITY = 'activity',
  SHOPPING = 'shopping',
  STAY = 'stay',
  SPORTS = 'sports',
}

export enum BookingStatus {
  PENDING = 'pending',
  UPCOMING = 'upcoming',
  CONFIRMED = 'confirmed',
  ACTIVE = 'active',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  FAILED = 'failed',
}

export const VALID_BOOKING_TRANSITIONS: Record<BookingStatus, BookingStatus[]> = {
  [BookingStatus.PENDING]: [BookingStatus.UPCOMING, BookingStatus.CONFIRMED, BookingStatus.FAILED, BookingStatus.CANCELLED],
  [BookingStatus.UPCOMING]: [BookingStatus.ACTIVE, BookingStatus.CANCELLED, BookingStatus.COMPLETED],
  [BookingStatus.CONFIRMED]: [BookingStatus.ACTIVE, BookingStatus.CANCELLED, BookingStatus.COMPLETED],
  [BookingStatus.ACTIVE]: [BookingStatus.COMPLETED, BookingStatus.CANCELLED],
  [BookingStatus.COMPLETED]: [],
  [BookingStatus.CANCELLED]: [],
  [BookingStatus.FAILED]: [],
};

@Entity('bookings')
export class BookingEntity {
  @PrimaryColumn()
  id: string;

  @Column({ default: 'user_default' })
  userId: string;

  @Column({ type: 'varchar' })
  type: BookingType;

  @Column()
  title: string;

  @Column()
  subtitle: string;

  @Column()
  imageUrl: string;

  @Column()
  date: string;

  @Column({ nullable: true })
  time: string;

  @Column()
  location: string;

  @Column({ type: 'varchar', default: BookingStatus.UPCOMING })
  status: BookingStatus;

  @Column('float')
  totalPrice: number;

  @Column({ default: 'CONFIRMED' })
  qrCodeData: string;

  @Column('jsonb', { nullable: true })
  metadata: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
