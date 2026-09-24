import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';

@Entity('movies')
export class MovieEntity {
  @PrimaryColumn()
  id: string;

  @Column()
  title: string;

  @Column({ nullable: true })
  tagline: string;

  @Column('text')
  synopsis: string;

  @Column()
  posterUrl: string;

  @Column()
  backdropUrl: string;

  @Column('float')
  rating: number;

  @Column('int')
  votesCount: number;

  @Column('simple-array')
  genres: string[];

  @Column()
  duration: string;

  @Column()
  primaryLanguage: string;

  @Column('simple-array')
  availableLanguages: string[];

  @Column('simple-array')
  formats: string[];

  @Column()
  certificate: string;

  @Column()
  releaseDate: string;

  @Column('float')
  startingPrice: number;

  @Column({ nullable: true })
  trailerYoutubeId: string;

  @Column()
  director: string;

  @Column('jsonb', { nullable: true })
  cast: { name: string; role: string; imageUrl: string }[];

  @Column({ default: true })
  isNowShowing: boolean;

  @Column({ default: false })
  isTrending: boolean;

  @Column({ default: false })
  isComingSoon: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
