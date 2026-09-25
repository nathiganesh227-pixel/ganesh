import { DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { AppDataSource } from '../data-source';
import { User, UserRole } from '../entities/user.entity';
import { MovieEntity } from '../entities/movie.entity';
import { TheatreEntity } from '../entities/theatre.entity';
import { RestaurantEntity } from '../entities/restaurant.entity';
import { EventEntity } from '../entities/event.entity';
import { ActivityEntity } from '../entities/activity.entity';
import { ProductEntity } from '../entities/product.entity';
import { HotelEntity } from '../entities/hotel.entity';
import { SportsVenueEntity } from '../entities/sports-venue.entity';
import { BookingEntity, BookingType, BookingStatus } from '../entities/booking.entity';
import { PlanEntity } from '../entities/plan.entity';
import { RewardEntity } from '../entities/reward.entity';
import { NotificationEntity } from '../entities/notification.entity';

let isSeedingActive = false;

export async function runSeed(customDataSource?: DataSource): Promise<void> {
  if (isSeedingActive) {
    console.warn('⚠️ Seeding is already in progress, skipping concurrent execution.');
    return;
  }
  isSeedingActive = true;
  const ds = customDataSource || AppDataSource;

  try {
    console.log('🌱 Connecting to database for comprehensive 7-vertical seed...');
    if (!ds.isInitialized) {
      await ds.initialize();
    }
    console.log('✅ Connected to database.');

    console.log('🔄 Checking and applying database migrations...');
    try {
      const migrations = await ds.runMigrations();
      console.log(`✅ Applied ${migrations.length} migration(s).`);
    } catch (err: any) {
      console.warn(`⚠️ Migration step notice: ${err?.message || err}`);
    }

  // 1. Users (Idempotent: preserves existing user if already created)
  const userRepo = ds.getRepository(User);
  const existingUser = await userRepo.findOne({
    where: [{ id: 'usr_default_1' }, { email: 'guest@plaza.app' }],
  });
  if (!existingUser) {
    const salt = await bcrypt.genSalt(10);
    const guestHash = await bcrypt.hash('PlazaGuest123!', salt);
    await userRepo.save([
      {
        id: 'usr_default_1',
        email: 'guest@plaza.app',
        passwordHash: guestHash,
        name: 'Gopi Ganesh',
        phone: '+91 98765 43210',
        city: 'Hyderabad',
        rewardPoints: 2480,
        role: UserRole.USER,
      },
    ]);
    console.log('  -> Seeded demo user: usr_default_1 (guest@plaza.app)');
  } else {
    console.log(`  -> Demo user already present (${existingUser.email}), preserved.`);
  }

  // 1b. Admin User (Idempotent: provisions admin@plaza.app with UserRole.ADMIN)
  const existingAdmin = await userRepo.findOne({
    where: [{ id: 'usr_admin_1' }, { email: 'admin@plaza.app' }],
  });

  const adminPassword = process.env.PLAZA_ADMIN_PASSWORD;

  if (!existingAdmin) {
    if (!adminPassword) {
      console.warn('⚠️ PLAZA_ADMIN_PASSWORD is not set. Skipping admin user creation to avoid insecure defaults.');
    } else {
      const salt = await bcrypt.genSalt(10);
      const adminHash = await bcrypt.hash(adminPassword, salt);
      await userRepo.save([
        {
          id: 'usr_admin_1',
          email: 'admin@plaza.app',
          passwordHash: adminHash,
          name: 'PLAZA Admin',
          phone: '+91 99999 00000',
          city: 'Hyderabad',
          rewardPoints: 0,
          role: UserRole.ADMIN,
        },
      ]);
      console.log('  -> Seeded admin user: usr_admin_1 (admin@plaza.app) with role: ADMIN');
    }
  } else {
    if (existingAdmin.role !== UserRole.ADMIN) {
      existingAdmin.role = UserRole.ADMIN;
      await userRepo.save(existingAdmin);
      console.log(`  -> Existing user (${existingAdmin.email}) upgraded to role: ADMIN.`);
    } else {
      console.log(`  -> Admin user already present (${existingAdmin.email}), preserved.`);
    }
  }

  // 2. Movies
  const movieRepo = ds.getRepository(MovieEntity);
  await movieRepo.save([
    {
      id: 'mov_1',
      title: 'Dune: Part Two',
      tagline: 'Long live the fighters.',
      synopsis:
        'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family. Facing a choice between the love of his life and the fate of the known universe, he endeavors to prevent a terrible future only he can foresee.',
      posterUrl:
        'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=800&auto=format&fit=crop',
      backdropUrl:
        'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?q=80&w=1200&auto=format&fit=crop',
      rating: 4.9,
      votesCount: 48200,
      genres: ['Sci-Fi', 'Adventure', 'Action', 'Drama'],
      duration: '2h 46m',
      primaryLanguage: 'English',
      availableLanguages: ['English', 'Telugu', 'Hindi'],
      formats: ['IMAX 3D', '3D', '4DX', 'Dolby Atmos', '2D'],
      certificate: 'UA',
      releaseDate: '2024-03-01',
      startingPrice: 350,
      trailerYoutubeId: 'Way9Dexny3w',
      director: 'Denis Villeneuve',
      isNowShowing: true,
      isTrending: true,
      isComingSoon: false,
      cast: [
        {
          name: 'Timothée Chalamet',
          role: 'Paul Atreides',
          imageUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=300&auto=format&fit=crop',
        },
        {
          name: 'Zendaya',
          role: 'Chani',
          imageUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop',
        },
      ],
    },
    {
      id: 'mov_2',
      title: 'Kalki 2898 AD',
      tagline: 'The future begins now.',
      synopsis:
        'Set in a dystopian post-apocalyptic future in the year 2898 AD, the story follows a chosen warrior Bhairava and the immortal Ashwatthama on an epic mytho-sci-fi quest to protect the supreme avatar from the forces of Darkness.',
      posterUrl:
        'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?q=80&w=800&auto=format&fit=crop',
      backdropUrl:
        'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=1200&auto=format&fit=crop',
      rating: 4.8,
      votesCount: 92400,
      genres: ['Sci-Fi', 'Mythology', 'Action', 'Epic'],
      duration: '3h 01m',
      primaryLanguage: 'Telugu',
      availableLanguages: ['Telugu', 'Hindi', 'Tamil', 'English'],
      formats: ['IMAX 3D', 'Dolby Atmos', '3D', '2D'],
      certificate: 'UA',
      releaseDate: '2024-06-27',
      startingPrice: 295,
      trailerYoutubeId: 'kQDd1AhGIHk',
      director: 'Nag Ashwin',
      isNowShowing: true,
      isTrending: true,
      isComingSoon: false,
      cast: [
        {
          name: 'Prabhas',
          role: 'Bhairava',
          imageUrl:
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=300&auto=format&fit=crop',
        },
      ],
    },
    {
      id: 'mov_3',
      title: 'Devara: Part 1',
      tagline: 'Fear will have a new face.',
      synopsis:
        'An epic coastal action drama depicting a fearless man who protects his sea-faring realm and battles corruption across treacherous waters, unleashing retribution against tyranny.',
      posterUrl:
        'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800&auto=format&fit=crop',
      backdropUrl:
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=1200&auto=format&fit=crop',
      rating: 4.7,
      votesCount: 65100,
      genres: ['Action', 'Drama', 'Thriller'],
      duration: '2h 58m',
      primaryLanguage: 'Telugu',
      availableLanguages: ['Telugu', 'Hindi', 'Tamil'],
      formats: ['Dolby Atmos', '2D', 'IMAX 3D'],
      certificate: 'UA',
      releaseDate: '2024-09-27',
      startingPrice: 250,
      trailerYoutubeId: 'lc0_Pq9fGpg',
      director: 'Koratala Siva',
      isNowShowing: true,
      isTrending: true,
      isComingSoon: false,
      cast: [
        {
          name: 'N. T. Rama Rao Jr.',
          role: 'Devara / Vara',
          imageUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=300&auto=format&fit=crop',
        },
      ],
    },
  ]);

  // 3. Theatres & Showtimes
  const theatreRepo = ds.getRepository(TheatreEntity);
  await theatreRepo.save([
    {
      id: 'theatre_amb',
      name: 'AMB Cinemas',
      location: 'Sarath City Capital Mall, Gachibowli',
      distance: '2.4 km',
      amenities: ['Laser IMAX', 'Dolby Atmos', 'VIP Recliner Lounge', 'Valet Parking'],
      showtimes: [
        {
          id: 'amb_st_1',
          time: '10:15 AM',
          format: 'IMAX 3D',
          language: 'English',
          screenName: 'Audi 1 (Laser IMAX)',
          basePrice: 450,
          isFillingFast: true,
        },
        {
          id: 'amb_st_2',
          time: '01:45 PM',
          format: 'Dolby Atmos',
          language: 'Telugu',
          screenName: 'Audi 4 (Dolby Atmos)',
          basePrice: 295,
        },
      ],
    },
    {
      id: 'theatre_prasads',
      name: 'Prasads Multiplex & IMAX',
      location: 'NTR Gardens, Necklace Road',
      distance: '4.8 km',
      amenities: ['Dual 4K Laser IMAX Screen', 'Dolby Atmos', 'Large Food Court'],
      showtimes: [
        {
          id: 'prs_st_1',
          time: '11:00 AM',
          format: 'IMAX 3D',
          language: 'English',
          screenName: 'Large Screen 6 (Laser IMAX)',
          basePrice: 400,
        },
      ],
    },
  ]);

  // 4. Dining (Synchronized with rest_1 to rest_5)
  const diningRepo = ds.getRepository(RestaurantEntity);
  await diningRepo.save([
    {
      id: 'rest_1',
      name: 'Farzi Café & Cocktail Lounge',
      tagline: 'Modern Indian culinary illusion & craft mixology',
      about:
        'Farzi Café brings a gourmet blend of authentic Indian flavors infused with contemporary molecular gastronomy techniques, sophisticated rooftop ambiance, and signature mixology cocktails in the heart of Jubilee Hills.',
      coverImageUrl:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=800&auto=format&fit=crop',
      galleryImages: [
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.8,
      reviewCount: 1850,
      cuisines: ['North Indian', 'Telugu & Andhra'],
      priceForTwo: 1800,
      location: 'Road No. 36, Jubilee Hills',
      distance: '2.1 km',
      openingHours: '12:00 PM – 11:30 PM',
      isPureVeg: false,
      hasOutdoor: true,
      isOpenNow: true,
      offerBadge: 'FLAT 25% OFF with PLAZA CLUB',
      amenities: ['Rooftop Seating', 'Live DJ & Music', 'Valet Parking', 'Cocktail Bar'],
      isFineDining: false,
      isTrending: true,
      popularDishes: [
        {
          name: 'Dal Chawal Arancini',
          description: 'Crispy lentil rice sphere with mint foam & papad roll',
          price: 420,
          isVeg: true,
          isChefSpecial: true,
          imageUrl:
            'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=400&auto=format&fit=crop',
        },
      ],
      reviews: [
        {
          userName: 'Aditi Rao',
          rating: 5.0,
          comment: 'Outstanding food presentation and lovely rooftop breeze. The Arancini is unforgettable.',
          date: '2 days ago',
        },
      ],
      availableSlots: [
        { time: '01:00 PM', status: 'available', tablesLeft: 6 },
        { time: '07:00 PM', status: 'fillingFast', tablesLeft: 3 },
        { time: '08:30 PM', status: 'fewTablesLeft', tablesLeft: 2 },
      ],
    },
    {
      id: 'rest_2',
      name: 'Olive Bistro & Secret Garden',
      tagline: 'Mediterranean lakefront dining overlooking Durgam Cheruvu',
      about:
        'Set against the picturesque Durgam Cheruvu lake, Olive Bistro is a white-walled rustic Mediterranean haven featuring handcrafted woodfire sourdough pizzas, fresh pastas, and sangrias in an open-air cobblestone courtyard.',
      coverImageUrl:
        'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?q=80&w=800&auto=format&fit=crop',
      galleryImages: [
        'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.9,
      reviewCount: 2420,
      cuisines: ['Italian & Continental', 'Café & Bakery'],
      priceForTwo: 2400,
      location: 'Road 46, Jubilee Hills Lakefront',
      distance: '3.2 km',
      openingHours: '12:30 PM – 11:00 PM',
      isPureVeg: false,
      hasOutdoor: true,
      isOpenNow: true,
      offerBadge: 'Complimentary Dessert on ₹2,000+',
      amenities: ['Lake View', 'Candlelight Seating', 'Pet Friendly', 'Valet'],
      isFineDining: true,
      isTrending: true,
      popularDishes: [
        {
          name: 'Truffle Funghi Woodfire Pizza',
          description: 'Wild forest mushrooms, buffalo mozzarella, black truffle oil',
          price: 795,
          isVeg: true,
          isChefSpecial: true,
          imageUrl:
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=400&auto=format&fit=crop',
        },
      ],
      reviews: [
        {
          userName: 'Kavya Sharma',
          rating: 5.0,
          comment: 'Magical sunset view by the lake! The pizza crust was authentic sourdough perfection.',
          date: 'Yesterday',
        },
      ],
      availableSlots: [
        { time: '01:30 PM', status: 'available', tablesLeft: 4 },
        { time: '06:30 PM', status: 'fewTablesLeft', tablesLeft: 1 },
      ],
    },
    {
      id: 'rest_4',
      name: 'Jewel of Nizam – The Minar',
      tagline: 'Fifth floor tower fine-dining overlooking Osmansagar lake',
      about:
        'Located in a 100-foot heritage tower at The Golkonda Resort, Jewel of Nizam serves regal Hyderabadi culinary heritage, fragrant saffron biryanis, and Nizam-era kebabs.',
      coverImageUrl:
        'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=800&auto=format&fit=crop',
      galleryImages: [
        'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.9,
      reviewCount: 3100,
      cuisines: ['Biryani & Mughlai', 'Telugu & Andhra'],
      priceForTwo: 3500,
      location: 'Golkonda Resorts, Gandipet',
      distance: '14 km',
      openingHours: '12:30 PM – 11:30 PM',
      isPureVeg: false,
      hasOutdoor: false,
      isOpenNow: true,
      offerBadge: 'VIP Chef’s Table Available',
      amenities: ['Panoramic Tower View', 'Royal Nizam Decor', 'Valet Parking', 'Live Sitar Music'],
      isFineDining: true,
      isTrending: true,
      popularDishes: [
        {
          name: 'Nizami Dum Biryani',
          description: 'Slow sealed earthen pot fragrant long grain rice with tender spiced mutton',
          price: 890,
          isVeg: false,
          isChefSpecial: true,
          imageUrl:
            'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=400&auto=format&fit=crop',
        },
      ],
      reviews: [
        {
          userName: 'Mirza Baig',
          rating: 5.0,
          comment: 'Authentic royal taste of old Hyderabad. Unbeatable ambiance at the top of the Minar.',
          date: '4 days ago',
        },
      ],
      availableSlots: [
        { time: '01:00 PM', status: 'available', tablesLeft: 3 },
        { time: '07:45 PM', status: 'fewTablesLeft', tablesLeft: 2 },
      ],
    },
  ]);

  // 5. Events (Synchronized with event_1 to event_4)
  const eventRepo = ds.getRepository(EventEntity);
  await eventRepo.save([
    {
      id: 'event_1',
      title: 'Sunburn Arena ft. Alan Walker',
      tagline: 'WalkerWorld India Tour 2024 • Hyderabad Edition',
      description:
        'Global electronic music phenomenon Alan Walker is taking over Hyderabad with a massive audio-visual production, immersive LED stages, and chart-topping anthems like Faded, Alone, and The Spectre.',
      category: 'Concerts & Live Music',
      posterUrl:
        'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=800&auto=format&fit=crop',
      bannerUrl:
        'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=1200&auto=format&fit=crop',
      eventDate: '2024-11-20',
      time: '05:00 PM – 10:30 PM',
      venue: 'Hitex Exhibition Center',
      location: 'Trade Fair Grounds, Hitec City',
      distance: '5.8 km',
      rating: 4.9,
      interestedCount: 14200,
      ageRestriction: '16+',
      languages: 'English',
      isTrending: true,
      isFeatured: true,
      ticketTiers: [
        {
          id: 'tier_ga',
          name: 'General Access (GA)',
          description: 'Access to main arena ground standing area and F&B village',
          price: 1499,
          remainingCount: 120,
          perks: ['Main arena entry', 'Food village access'],
        },
        {
          id: 'tier_vip',
          name: 'VIP Front Stage',
          description: 'Dedicated express entry gate, elevated front-stage deck, and separate bar access',
          price: 3299,
          remainingCount: 45,
          perks: ['Express Gate Entry', 'Elevated Viewing Deck', 'Dedicated Bar'],
        },
      ],
      performers: [
        {
          name: 'Alan Walker',
          role: 'Headliner DJ / Producer',
          imageUrl:
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=300&auto=format&fit=crop',
        },
      ],
    },
    {
      id: 'event_2',
      title: 'Zakir Khan Live: Tathastu & Beyond',
      tagline: 'The Rondu Sakht Launda returns with brand new unreleased jokes',
      description:
        'Zakir Khan is back on stage with his soul-stirring blend of humor, nostalgia, emotion, and relatable storytelling about friendship, middle-class quirks, and adulthood.',
      category: 'Stand-up Comedy',
      posterUrl:
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=800&auto=format&fit=crop',
      bannerUrl:
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=1200&auto=format&fit=crop',
      eventDate: '2024-11-25',
      time: '07:30 PM – 09:30 PM',
      venue: 'Shilpakala Vedika Auditorium',
      location: 'Hitec City Main Road',
      distance: '4.1 km',
      rating: 4.9,
      interestedCount: 8900,
      ageRestriction: '16+',
      languages: 'Hindi',
      isTrending: true,
      isFeatured: false,
      ticketTiers: [
        {
          id: 'zk_silver',
          name: 'Balcony Silver',
          description: 'Upper tier reserved seating with clear stage view',
          price: 999,
          remainingCount: 30,
        },
      ],
      performers: [
        {
          name: 'Zakir Khan',
          role: 'Stand-up Comedian',
          imageUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300&auto=format&fit=crop',
        },
      ],
    },
  ]);

  // 6. Activities (Synchronized with act_1 to act_4)
  const activityRepo = ds.getRepository(ActivityEntity);
  await activityRepo.save([
    {
      id: 'act_1',
      title: 'Smaaash Cosmic Bowling & VR Zone',
      tagline: 'State-of-the-art UV twilight bowling and arcade action',
      description:
        'State of the art UV twilight bowling alleys with computerized scoring, pulsing club music, arcade games, and dynamic pin lighting.',
      category: 'Bowling',
      coverImageUrl:
        'https://images.unsplash.com/photo-1538370965046-79c0d6907d47?q=80&w=800&auto=format&fit=crop',
      galleryImages: [
        'https://images.unsplash.com/photo-1538370965046-79c0d6907d47?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.8,
      reviewCount: 3200,
      location: 'Inorbit Mall, Level 5, Hitec City',
      distance: '3.1 km',
      highlights: ['Computerized scoring', 'Twilight LED Bowling', 'Arcade Games'],
      safetyGuidelines: ['Socks mandatory', 'Arrive 10 minutes before slot'],
      packages: [
        {
          id: 'pkg_std',
          name: 'Standard Game',
          description: '1 full bowling game with shoes included',
          pricePerPerson: 450,
          duration: '45 mins',
          includedFeatures: ['Bowling shoes included', 'Dedicated lane'],
        },
      ],
      addOns: [
        {
          id: 'addon_socks',
          name: 'Bowling Socks Pair',
          description: 'Required on lane',
          price: 50,
        },
      ],
      timeSlots: [
        { time: '05:00 PM', availableSlots: 4, isFillingFast: false },
        { time: '07:30 PM', availableSlots: 2, isFillingFast: true },
      ],
      isTrending: true,
      isPopular: true,
    },
  ]);

  // 7. Shopping (Synchronized with prod_macbook_pro, prod_jordan_retro, etc.)
  const shoppingRepo = ds.getRepository(ProductEntity);
  await shoppingRepo.save([
    {
      id: 'prod_macbook_pro',
      name: 'MacBook Pro 14" M3 Pro',
      brand: 'Apple',
      category: 'Electronics & Tech',
      price: 189900,
      originalPrice: 199900,
      rating: 4.9,
      reviewCount: 384,
      coverImageUrl:
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&auto=format&fit=crop&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&auto=format&fit=crop&q=80',
      ],
      description:
        'The ultimate pro laptop with Liquid Retina XDR display, 18-hour battery life, and staggering M3 Pro performance for creative professionals.',
      specifications: {
        Processor: 'Apple M3 Pro (12-core CPU, 18-core GPU)',
        Storage: '512 GB Ultra-fast SSD',
      },
      variants: [
        { id: 'v_mb_512', name: '512 GB SSD • Space Black', priceDelta: 0, inStock: true },
      ],
      storeId: 'store_sarath_apple',
      storeName: 'Aptronix Sarath City Mall',
      storeLocation: 'Kondapur, Hyderabad',
      distance: '3.1 km',
      isTrending: true,
      isDealOfTheDay: false,
      discountBadge: '₹10,000 OFF',
      inStock: true,
    },
    {
      id: 'prod_jordan_retro',
      name: 'Air Jordan 1 Retro High OG "Chicago"',
      brand: 'Nike / Jordan',
      category: 'Sneakers & Shoes',
      price: 16995,
      originalPrice: 19995,
      rating: 4.95,
      reviewCount: 512,
      coverImageUrl:
        'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800&auto=format&fit=crop&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800&auto=format&fit=crop&q=80',
      ],
      description:
        'The iconic 1985 silhouette reimagined with premium cracked leather, vintage sail midsole, and timeless varsity red accents.',
      specifications: {
        Material: 'Full-grain genuine leather',
        Sole: 'Encapsulated Nike Air-Sole unit',
      },
      variants: [
        { id: 'v_uk8', name: 'UK 8 (US 9)', priceDelta: 0, inStock: true },
      ],
      storeId: 'store_superkicks_banjara',
      storeName: 'Superkicks Banjara Hills',
      storeLocation: 'Road No. 12, Banjara Hills',
      distance: '5.2 km',
      isTrending: true,
      isDealOfTheDay: true,
      discountBadge: '15% OFF',
      inStock: true,
    },
  ]);

  // 8. Stays (Synchronized with stay_taj_falaknuma, stay_golkonda_resort, etc.)
  const hotelRepo = ds.getRepository(HotelEntity);
  await hotelRepo.save([
    {
      id: 'stay_taj_falaknuma',
      name: 'Taj Falaknuma Palace',
      tagline: 'The Mirror of the Sky — 2,000 ft above Hyderabad',
      category: 'Luxury Palaces & 5★',
      startingPricePerNight: 48500,
      originalPricePerNight: 55000,
      rating: 4.96,
      reviewCount: 1240,
      coverImageUrl:
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&auto=format&fit=crop&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&auto=format&fit=crop&q=80',
      ],
      description:
        'Perched 2,000 feet above Hyderabad, Taj Falaknuma Palace was the former residence of the Nizam. Experience royal Venetian chandeliers, horse-drawn carriage arrivals, and world-class Jiva Spa therapies.',
      location: 'Engine Bowli, Falaknuma',
      distance: '14.2 km',
      amenities: [
        'Infinity Pool',
        'Luxury Spa & Ayurvedic Wellness',
        'Fine Dining & Rooftop Bar',
        'Royal Butler Service',
      ],
      rooms: [
        {
          id: 'room_taj_palace_room',
          name: 'Palace Luxury Room',
          description:
            'Elegantly furnished with rich floral fabrics, antique timber beds, and panoramic palace garden views.',
          imageUrl:
            'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=800&auto=format&fit=crop&q=80',
          pricePerNight: 48500,
          originalPricePerNight: 55000,
          maxGuests: 2,
          bedType: '1 Royal King Bed',
          roomSize: '520 sq ft',
          highlights: ['High ceilings', 'Italian marble bath', 'Heritage courtyard view'],
          isAvailable: true,
        },
      ],
      addOns: [
        {
          id: 'addon_breakfast',
          name: 'Royal Champagne Buffet Breakfast',
          price: 1500,
          description: 'Lavish international and Nizami morning spread for all guests',
        },
      ],
      isTrending: true,
      isFeatured: true,
    },
  ]);

  // 9. Sports (Synchronized with sports_hotfut_gachibowli, sports_gamepoint_madhapur, etc.)
  const sportsRepo = ds.getRepository(SportsVenueEntity);
  await sportsRepo.save([
    {
      id: 'sports_hotfut_gachibowli',
      name: 'HotFut Arena Gachibowli',
      supportedSports: ['Box Cricket', 'Football & Futsal', 'Multi-Sport FIFA Turf'],
      coverImageUrl:
        'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&auto=format&fit=crop&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&auto=format&fit=crop&q=80',
      ],
      rating: 4.85,
      reviewCount: 420,
      location: 'Near SLN Terminus, Gachibowli',
      distance: '1.8 km',
      amenities: ['FIFA 2-Star Turf', 'HD Floodlights', 'Player Dugouts', 'Shower & Locker'],
      rules:
        'Only rubber studs or turf shoes permitted. Arrive 10 minutes prior to slot. No smoking.',
      startingPricePerHour: 1200,
      slots: [
        {
          id: 's_hf_1',
          time: '06:00 PM',
          duration: '60 min',
          price: 1400,
          status: 'fillingFast',
          courtName: 'Turf 1 (Main Pitch)',
        },
        {
          id: 's_hf_2',
          time: '07:00 PM',
          duration: '60 min',
          price: 1600,
          status: 'fewSlotsLeft',
          courtName: 'Turf 1 (Main Pitch)',
        },
        {
          id: 's_hf_3',
          time: '08:00 PM',
          duration: '60 min',
          price: 1800,
          status: 'available',
          courtName: 'Turf 1 (Main Pitch)',
        },
      ],
      addOns: [
        {
          id: 'ea_cricket_kit',
          name: 'SG English Willow Cricket Kit & Balls',
          price: 350,
          description: '2 Bats, Stumps, 4 Leather/Tennis balls',
        },
      ],
      isTrending: true,
      isPopular: true,
    },
  ]);

  // 10. Unified Bookings (Synchronized with PlazaGlobalState)
  const bookingRepo = ds.getRepository(BookingEntity);
  await bookingRepo.save([
    {
      id: 'PLZ-MOV-84920',
      userId: 'usr_default_1',
      type: BookingType.MOVIE,
      title: 'Dune: Part Two',
      subtitle: 'AMB Cinemas, Gachibowli • IMAX with Laser',
      imageUrl:
        'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=800&auto=format&fit=crop',
      date: 'Tomorrow, 25 Sep',
      time: '7:30 PM',
      location: 'Kondapur, Hyderabad',
      status: BookingStatus.UPCOMING,
      totalPrice: 988.0,
      qrCodeData: 'QR-MOV-84920-IMAX',
      metadata: { seats: ['K12', 'K13'] },
    },
    {
      id: 'PLZ-DIN-38102',
      userId: 'usr_default_1',
      type: BookingType.DINING,
      title: 'Farzi Café & Cocktail Lounge',
      subtitle: '2 Guests • Outdoor / Rooftop',
      imageUrl:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=800&auto=format&fit=crop',
      date: 'Sat, 28 Sep',
      time: '8:30 PM',
      location: 'Road No. 36, Jubilee Hills',
      status: BookingStatus.UPCOMING,
      totalPrice: 0.0,
      qrCodeData: 'QR-DIN-38102-TABLE',
      metadata: { partySize: 2 },
    },
    {
      id: 'PLZ-EVT-77201',
      userId: 'usr_default_1',
      type: BookingType.EVENT,
      title: 'Sunburn Arena ft. Alan Walker',
      subtitle: 'General Access (GA)',
      imageUrl:
        'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=800&auto=format&fit=crop',
      date: 'Sun, 29 Sep',
      time: '05:00 PM – 10:30 PM',
      location: 'Hitex Exhibition Center',
      status: BookingStatus.UPCOMING,
      totalPrice: 3123.0,
      qrCodeData: 'QR-EVT-77201-VIP',
      metadata: { quantity: 2 },
    },
  ]);

  // 11. Plans
  const planRepo = ds.getRepository(PlanEntity);
  await planRepo.save([
    {
      id: 'pln_sample_1',
      userId: 'usr_default_1',
      title: 'Jubilee Hills Weekend Escape',
      date: 'Saturday, 28 Sep',
      totalEstimatedCost: 2500,
      totalDurationHours: 6,
      slots: [
        {
          slotNumber: 1,
          time: '3:30 PM',
          vertical: 'Activities',
          title: 'High-Speed Go-Karting Championship',
          location: 'Runway 9 International Circuit',
          estimatedCost: 850,
        },
        {
          slotNumber: 2,
          time: '7:00 PM',
          vertical: 'Dining',
          title: 'Modern Indian Dinner & Molecular Cocktails',
          location: 'Farzi Café & Cocktail Lounge',
          estimatedCost: 1200,
        },
        {
          slotNumber: 3,
          time: '9:45 PM',
          vertical: 'Movies',
          title: 'Dune: Part Two (IMAX with Laser)',
          location: 'AMB Cinemas, Screen 1',
          estimatedCost: 450,
        },
      ],
    },
  ]);

  // 12. Rewards (Synchronized with vch_1 to vch_4)
  const rewardRepo = ds.getRepository(RewardEntity);
  await rewardRepo.save([
    {
      id: 'vch_1',
      title: '₹200 Off Movies',
      partnerName: 'AMB & PVR',
      pointsCost: 1500,
      discountValue: '₹200 OFF',
      category: 'Movies',
      code: 'PLZ-MOV200',
      expiryDate: '30 Oct 2026',
      isActive: true,
    },
    {
      id: 'vch_2',
      title: '₹500 Off Fine Dining',
      partnerName: 'Farzi & Olive',
      pointsCost: 3500,
      discountValue: '₹500 OFF',
      category: 'Dining',
      code: 'PLZ-DINE500',
      expiryDate: '15 Nov 2026',
      isActive: true,
    },
  ]);

  // 13. Notifications
  const notificationRepo = ds.getRepository(NotificationEntity);
  await notificationRepo.save([
    {
      id: 'notif_1',
      userId: 'usr_default_1',
      title: 'Movie Ticket Confirmed! 🍿',
      message: 'Your IMAX with Laser seats for Dune: Part Two are ready in your wallet.',
      type: 'movie',
      timeAgo: '10m ago',
      isRead: false,
      actionRoute: '/bookings',
    },
    {
      id: 'notif_2',
      userId: 'usr_default_1',
      title: 'Double Plaza Points Weekend! ⚡',
      message: 'Earn 2x points on all dining reservations booked this Saturday.',
      type: 'rewards',
      timeAgo: '2h ago',
      isRead: false,
      actionRoute: '/rewards',
    },
  ]);

  console.log('✅ PLAZA Complete 7-Vertical Database Seeding Completed Successfully!');
  } finally {
    isSeedingActive = false;
  }
}

if (require.main === module) {
  runSeed()
    .then(async () => {
      if (AppDataSource.isInitialized) {
        await AppDataSource.destroy();
      }
      process.exit(0);
    })
    .catch(async (err) => {
      console.error('❌ Seeding failed:', err);
      if (AppDataSource.isInitialized) {
        await AppDataSource.destroy();
      }
      process.exit(1);
    });
}
