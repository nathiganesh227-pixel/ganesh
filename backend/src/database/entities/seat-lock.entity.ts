import { Entity, PrimaryColumn, Column, CreateDateColumn, Index } from 'typeorm';

@Entity('seat_locks')
@Index(['theatreId', 'showtimeId', 'seatId'])
@Index(['expiresAt'])
@Index(['userId'])
export class SeatLockEntity {
  @PrimaryColumn()
  id: string;

  @Column()
  theatreId: string;

  @Column()
  showtimeId: string;

  @Column()
  seatId: string;

  @Column()
  userId: string;

  @Column({ type: 'timestamptz' })
  expiresAt: Date;

  @CreateDateColumn()
  createdAt: Date;
}
