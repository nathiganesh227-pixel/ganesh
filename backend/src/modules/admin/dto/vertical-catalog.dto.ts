import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsInt,
  Min,
  IsArray,
  IsOptional,
  IsBoolean,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

// ==========================================
// 1. DINING / RESTAURANT DTOs
// ==========================================
export class CreateDiningDto {
  @ApiProperty({ example: 'Jewel of Nizam' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'The Minar - Royal Fine Dining' })
  @IsString()
  @IsNotEmpty()
  tagline: string;

  @ApiProperty({ example: 'Iconic Nizami flavours suspended 100ft above the city.' })
  @IsString()
  @IsNotEmpty()
  about: string;

  @ApiProperty({ example: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4' })
  @IsString()
  @IsNotEmpty()
  coverImageUrl: string;

  @ApiPropertyOptional({ example: ['https://images.unsplash.com/photo-1517248135467-4c7edcad34c4'] })
  @IsOptional()
  @IsArray()
  galleryImages?: string[];

  @ApiPropertyOptional({ example: 4.8, default: 4.5 })
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional({ example: 1250, default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  reviewCount?: number;

  @ApiProperty({ example: ['Nizami', 'Hyderabadi', 'Mughlai'] })
  @IsArray()
  cuisines: string[];

  @ApiProperty({ example: 2500 })
  @IsNumber()
  @Min(0)
  priceForTwo: number;

  @ApiProperty({ example: 'The Golkonda Resort, Gandipet' })
  @IsString()
  @IsNotEmpty()
  location: string;

  @ApiPropertyOptional({ example: '8.2 km' })
  @IsOptional()
  @IsString()
  distance?: string;

  @ApiPropertyOptional({ example: '12:30 PM - 11:30 PM' })
  @IsOptional()
  @IsString()
  openingHours?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isPureVeg?: boolean;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  hasOutdoor?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isOpenNow?: boolean;

  @ApiPropertyOptional({ example: 'Flat 15% OFF' })
  @IsOptional()
  @IsString()
  offerBadge?: string;

  @ApiPropertyOptional({ example: ['Valet Parking', 'Full Bar', 'Live Music'] })
  @IsOptional()
  @IsArray()
  amenities?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  popularDishes?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  reviews?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  availableSlots?: any[];

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isFineDining?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class UpdateDiningDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  tagline?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  about?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  coverImageUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  galleryImages?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  reviewCount?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  cuisines?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  priceForTwo?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  distance?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  openingHours?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPureVeg?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  hasOutdoor?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isOpenNow?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  offerBadge?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  amenities?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  popularDishes?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  reviews?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  availableSlots?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isFineDining?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

// ==========================================
// 2. EVENTS DTOs
// ==========================================
export class CreateEventDto {
  @ApiProperty({ example: 'Sunburn Arena ft. Alan Walker' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ example: 'Walkerworld India Tour 2026' })
  @IsString()
  @IsNotEmpty()
  tagline: string;

  @ApiProperty({ example: 'Experience the electric beats of global EDM icon Alan Walker...' })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiProperty({ example: 'Music Festivals' })
  @IsString()
  @IsNotEmpty()
  category: string;

  @ApiProperty({ example: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745' })
  @IsString()
  @IsNotEmpty()
  posterUrl: string;

  @ApiProperty({ example: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745' })
  @IsString()
  @IsNotEmpty()
  bannerUrl: string;

  @ApiProperty({ example: '2026-10-18' })
  @IsString()
  @IsNotEmpty()
  eventDate: string;

  @ApiProperty({ example: '5:00 PM onwards' })
  @IsString()
  @IsNotEmpty()
  time: string;

  @ApiProperty({ example: 'GMR Arena' })
  @IsString()
  @IsNotEmpty()
  venue: string;

  @ApiProperty({ example: 'Shamshabad, Hyderabad' })
  @IsString()
  @IsNotEmpty()
  location: string;

  @ApiPropertyOptional({ example: '18.4 km' })
  @IsOptional()
  @IsString()
  distance?: string;

  @ApiPropertyOptional({ example: 4.9, default: 4.5 })
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional({ example: 34200, default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  interestedCount?: number;

  @ApiPropertyOptional({ example: '16+ Only', default: 'All Ages' })
  @IsOptional()
  @IsString()
  ageRestriction?: string;

  @ApiPropertyOptional({ example: 'English', default: 'English & Telugu' })
  @IsOptional()
  @IsString()
  languages?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  ticketTiers?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  performers?: any[];

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isFeatured?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class UpdateEventDto {
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
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  posterUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  bannerUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  eventDate?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  time?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  venue?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  distance?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  interestedCount?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  ageRestriction?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  languages?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  ticketTiers?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  performers?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isFeatured?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

// ==========================================
// 3. ACTIVITIES DTOs
// ==========================================
export class CreateActivityDto {
  @ApiProperty({ example: 'Pitstop Go-Karting Championship' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiProperty({ example: 'High-speed professional track' })
  @IsString()
  @IsNotEmpty()
  tagline: string;

  @ApiProperty({ example: 'Race on an international-standard asphalt track...' })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiProperty({ example: 'Motorsports' })
  @IsString()
  @IsNotEmpty()
  category: string;

  @ApiProperty({ example: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7' })
  @IsString()
  @IsNotEmpty()
  coverImageUrl: string;

  @ApiPropertyOptional({ example: ['https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7'] })
  @IsOptional()
  @IsArray()
  galleryImages?: string[];

  @ApiPropertyOptional({ example: 4.7, default: 4.5 })
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional({ example: 340, default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  reviewCount?: number;

  @ApiProperty({ example: 'Necklace Road, Hyderabad' })
  @IsString()
  @IsNotEmpty()
  location: string;

  @ApiPropertyOptional({ example: '4.1 km' })
  @IsOptional()
  @IsString()
  distance?: string;

  @ApiPropertyOptional({ example: ['900m Asphalt Track', '270cc Honda Karts'] })
  @IsOptional()
  @IsArray()
  highlights?: string[];

  @ApiPropertyOptional({ example: ['Helmets mandatory', 'Closed shoes required'] })
  @IsOptional()
  @IsArray()
  safetyGuidelines?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  packages?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  addOns?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  timeSlots?: any[];

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isPopular?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class UpdateActivityDto {
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
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  coverImageUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  galleryImages?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  reviewCount?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  distance?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  highlights?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  safetyGuidelines?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  packages?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  addOns?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  timeSlots?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPopular?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

// ==========================================
// 4. SHOPPING / PRODUCT DTOs
// ==========================================
export class CreateProductDto {
  @ApiProperty({ example: 'Raw Mango Handwoven Chanderi Sari' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'Raw Mango' })
  @IsString()
  @IsNotEmpty()
  brand: string;

  @ApiProperty({ example: 'Luxury Apparel' })
  @IsString()
  @IsNotEmpty()
  category: string;

  @ApiProperty({ example: 48500 })
  @IsNumber()
  @Min(0)
  price: number;

  @ApiPropertyOptional({ example: 55000 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  originalPrice?: number;

  @ApiPropertyOptional({ example: 4.9, default: 4.5 })
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional({ example: 88, default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  reviewCount?: number;

  @ApiProperty({ example: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c' })
  @IsString()
  @IsNotEmpty()
  coverImageUrl: string;

  @ApiPropertyOptional({ example: ['https://images.unsplash.com/photo-1610030469983-98e550d6193c'] })
  @IsOptional()
  @IsArray()
  galleryImages?: string[];

  @ApiProperty({ example: 'Handwoven pure silk chanderi sari with gold zari border...' })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiPropertyOptional()
  @IsOptional()
  specifications?: Record<string, string>;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  variants?: any[];

  @ApiProperty({ example: 'store_bjt_01' })
  @IsString()
  @IsNotEmpty()
  storeId: string;

  @ApiProperty({ example: 'Banjara Hills Flagship Store' })
  @IsString()
  @IsNotEmpty()
  storeName: string;

  @ApiProperty({ example: 'Road No. 10, Banjara Hills' })
  @IsString()
  @IsNotEmpty()
  storeLocation: string;

  @ApiPropertyOptional({ example: '3.4 km' })
  @IsOptional()
  @IsString()
  distance?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isDealOfTheDay?: boolean;

  @ApiPropertyOptional({ example: '12% OFF' })
  @IsOptional()
  @IsString()
  discountBadge?: string;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  inStock?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class UpdateProductDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  brand?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  price?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  originalPrice?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  reviewCount?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  coverImageUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  galleryImages?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  specifications?: Record<string, string>;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  variants?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  storeId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  storeName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  storeLocation?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  distance?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isDealOfTheDay?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  discountBadge?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  inStock?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

// ==========================================
// 5. STAYS / HOTEL DTOs
// ==========================================
export class CreateHotelDto {
  @ApiProperty({ example: 'Taj Falaknuma Palace' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'Mirror of the Sky - Nizam Heritage' })
  @IsString()
  @IsNotEmpty()
  tagline: string;

  @ApiProperty({ example: 'Heritage Palace' })
  @IsString()
  @IsNotEmpty()
  category: string;

  @ApiProperty({ example: 45000 })
  @IsNumber()
  @Min(0)
  startingPricePerNight: number;

  @ApiPropertyOptional({ example: 52000 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  originalPricePerNight?: number;

  @ApiPropertyOptional({ example: 4.9, default: 4.5 })
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional({ example: 2150, default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  reviewCount?: number;

  @ApiProperty({ example: 'https://images.unsplash.com/photo-1566073771259-6a8506099945' })
  @IsString()
  @IsNotEmpty()
  coverImageUrl: string;

  @ApiPropertyOptional({ example: ['https://images.unsplash.com/photo-1566073771259-6a8506099945'] })
  @IsOptional()
  @IsArray()
  galleryImages?: string[];

  @ApiProperty({ example: 'Perched 2000 feet above Hyderabad, this 1894 palace hotel features...' })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiProperty({ example: 'Engine Bowli, Falaknuma, Hyderabad' })
  @IsString()
  @IsNotEmpty()
  location: string;

  @ApiPropertyOptional({ example: '14.5 km' })
  @IsOptional()
  @IsString()
  distance?: string;

  @ApiPropertyOptional({ example: ['Palace Library', 'Outdoor Pool', 'Heritage Walk'] })
  @IsOptional()
  @IsArray()
  amenities?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  rooms?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  addOns?: any[];

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isFeatured?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class UpdateHotelDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  tagline?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  startingPricePerNight?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  originalPricePerNight?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  reviewCount?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  coverImageUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  galleryImages?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  location?: string;

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
  @IsArray()
  rooms?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  addOns?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isFeatured?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

// ==========================================
// 6. SPORTS / VENUE DTOs
// ==========================================
export class CreateSportsVenueDto {
  @ApiProperty({ example: 'Gamepoint Gachibowli' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: ['Badminton', 'Box Cricket', 'Table Tennis'] })
  @IsArray()
  supportedSports: string[];

  @ApiProperty({ example: 'https://images.unsplash.com/photo-1546519638-68e109498ffc' })
  @IsString()
  @IsNotEmpty()
  coverImageUrl: string;

  @ApiPropertyOptional({ example: ['https://images.unsplash.com/photo-1546519638-68e109498ffc'] })
  @IsOptional()
  @IsArray()
  galleryImages?: string[];

  @ApiPropertyOptional({ example: 4.8, default: 4.5 })
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional({ example: 680, default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  reviewCount?: number;

  @ApiProperty({ example: 'Near Bio-Diversity Park, Gachibowli' })
  @IsString()
  @IsNotEmpty()
  location: string;

  @ApiPropertyOptional({ example: '3.1 km' })
  @IsOptional()
  @IsString()
  distance?: string;

  @ApiPropertyOptional({ example: ['Changing Rooms', 'Pro Shop', 'Floodlights'] })
  @IsOptional()
  @IsArray()
  amenities?: string[];

  @ApiPropertyOptional({ example: 'Non-marking shoes mandatory on wooden badminton courts.' })
  @IsOptional()
  @IsString()
  rules?: string;

  @ApiProperty({ example: 400 })
  @IsNumber()
  @Min(0)
  startingPricePerHour: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  slots?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  addOns?: any[];

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isPopular?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class UpdateSportsVenueDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  supportedSports?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  coverImageUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  galleryImages?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  rating?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  reviewCount?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  location?: string;

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
  @IsString()
  rules?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  startingPricePerHour?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  slots?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  addOns?: any[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isTrending?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPopular?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}
