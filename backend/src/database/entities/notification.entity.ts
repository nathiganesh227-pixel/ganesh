import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('notifications')
export class NotificationEntity {
  @PrimaryColumn()
  id: string;

  @Column({ default: 'user_default' })
  userId: string;

  @Column()
  title: string;

  @Column('text')
  message: string;

  @Column()
  type: string;

  @Column()
  timeAgo: string;

  @Column({ default: false })
  isRead: boolean;

  @Column({ nullable: true })
  actionRoute: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
