import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsInt,
  Min,
  IsArray,
  IsOptional,
  IsBoolean,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateMovieDto {
  @ApiProperty({ example: 'Kalki 2898 AD' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({ example: 'The future begins now' })
  @IsOptional()
  @IsString()
  tagline?: string;

  @ApiProperty({ example: 'A modern avatar of Vishnu descends...' })
  @IsString()
  @IsNotEmpty()
  synopsis: string;

  @ApiProperty({ example: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=800' })
  @IsString()
  @IsNotEmpty()
  posterUrl: string;

  @ApiProperty({ example: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1200' })
  @IsString()
  @IsNotEmpty()
  backdropUrl: string;

  @ApiProperty({ example: 9.1 })
  @IsNumber()
  rating: number;

  @ApiProperty({ example: 45200 })
  @IsInt()
  @Min(0)
  votesCount: number;

  @ApiProperty({ example: ['Sci-Fi', 'Action', 'Mythology'] })
  @IsArray()
  genres: string[];

  @ApiProperty({ example: '3h 1min' })
  @IsString()
  duration: string;

  @ApiProperty({ example: 'Telugu' })
  @IsString()
  primaryLanguage: string;

  @ApiProperty({ example: ['Telugu', 'Hindi', 'Tamil', 'Malayalam'] })
  @IsArray()
  availableLanguages: string[];

  @ApiProperty({ example: ['IMAX 3D', 'Dolby Atmos', '4DX', '2D'] })
  @IsArray()
  formats: string[];

  @ApiProperty({ example: 'UA' })
  @IsString()
  certificate: string;

  @ApiProperty({ example: '2024-06-27' })
  @IsString()
  releaseDate: string;

  @ApiProperty({ example: 250 })
  @IsNumber()
  @Min(0)
  startingPrice: number;

  @ApiProperty({ example: 'Nag Ashwin' })
  @IsString()
  director: string;

  @ApiPropertyOptional({ example: 'kalki_trailer_id' })
  @IsOptional()
  @IsString()
  trailerYoutubeId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  cast?: { name: string; role: string; imageUrl: string }[];

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isNowShowing?: boolean;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isComingSoon?: boolean;
}

export class UpdateMovieDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  tagline?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  synopsis?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  posterUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  backdropUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  votesCount?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  genres?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  duration?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  primaryLanguage?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  availableLanguages?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  formats?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  certificate?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  releaseDate?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  startingPrice?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  director?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  trailerYoutubeId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  cast?: { name: string; role: string; imageUrl: string }[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isNowShowing?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isComingSoon?: boolean;
}

export class CreateTheatreDto {
  @ApiProperty({ example: 'AMB Cinemas' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'Sarath City Capital Mall, Gachibowli' })
  @IsString()
  @IsNotEmpty()
  location: string;

  @ApiPropertyOptional({ example: 'Hyderabad', default: 'Hyderabad' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({ example: 'Gachibowli, Miyapur Road, Hyderabad' })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({ example: '2.4 km' })
  @IsOptional()
  @IsString()
  distance?: string;

  @ApiPropertyOptional({ example: ['Laser IMAX', 'Dolby Atmos', 'VIP Recliner Lounge'] })
  @IsOptional()
  @IsArray()
  amenities?: string[];

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateTheatreDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  distance?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  amenities?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class CreateScreenDto {
  @ApiProperty({ example: 'Screen 1 (Laser IMAX)' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ example: 'IMAX 3D', default: 'standard' })
  @IsOptional()
  @IsString()
  screenType?: string;

  @ApiProperty({ example: 250 })
  @IsInt()
  @Min(1)
  capacity: number;

  @ApiPropertyOptional()
  @IsOptional()
  seatLayout?: any;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateScreenDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  screenType?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(1)
  capacity?: number;

  @ApiPropertyOptional()
  @IsOptional()
  seatLayout?: any;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class PricingDto {
  @ApiProperty({ example: 295 })
  @IsNumber()
  @Min(1)
  gold: number;

  @ApiProperty({ example: 350 })
  @IsNumber()
  @Min(1)
  premium: number;

  @ApiProperty({ example: 450 })
  @IsNumber()
  @Min(1)
  recliner: number;
}

export class CreateShowDto {
  @ApiProperty({ example: 'mov_1' })
  @IsString()
  @IsNotEmpty()
  movieId: string;

  @ApiProperty({ example: 'theatre_amb' })
  @IsString()
  @IsNotEmpty()
  theatreId: string;

  @ApiProperty({ example: 'scr_1' })
  @IsString()
  @IsNotEmpty()
  screenId: string;

  @ApiProperty({ example: '2026-09-26' })
  @IsString()
  @IsNotEmpty()
  showDate: string;

  @ApiProperty({ example: '10:15 AM' })
  @IsString()
  @IsNotEmpty()
  startTime: string;

  @ApiPropertyOptional({ example: 'IMAX 3D', default: '2D' })
  @IsOptional()
  @IsString()
  format?: string;

  @ApiPropertyOptional({ example: 'Telugu', default: 'Telugu' })
  @IsOptional()
  @IsString()
  language?: string;

  @ApiProperty({ type: PricingDto })
  @ValidateNested()
  @Type(() => PricingDto)
  pricing: PricingDto;
}

export class UpdateShowDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  showDate?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  startTime?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  format?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  language?: string;

  @ApiPropertyOptional({ type: PricingDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => PricingDto)
  pricing?: PricingDto;

  @ApiPropertyOptional({ example: 'active' })
  @IsOptional()
  @IsString()
  status?: string;
}
