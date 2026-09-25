import '../models/movie.dart';
import '../models/cinema_showtime.dart';
import '../models/cinema_seat.dart';
import '../models/movie_booking.dart';

class MovieMockData {
  MovieMockData._();

  static final List<Movie> movies = [
    Movie(
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
      primaryLanguage: MovieLanguage.english,
      availableLanguages: [MovieLanguage.english, MovieLanguage.telugu, MovieLanguage.hindi],
      formats: [MovieFormat.imax3D, MovieFormat.format3D, MovieFormat.fourDX, MovieFormat.dolbyAtmos, MovieFormat.format2D],
      certificate: 'UA',
      releaseDate: DateTime(2024, 3, 1),
      startingPrice: 350,
      trailerYoutubeId: 'Way9Dexny3w',
      director: 'Denis Villeneuve',
      isNowShowing: true,
      isTrending: true,
      cast: const [
        CastMember(
          name: 'Timothée Chalamet',
          role: 'Paul Atreides',
          imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=300&auto=format&fit=crop',
        ),
        CastMember(
          name: 'Zendaya',
          role: 'Chani',
          imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop',
        ),
        CastMember(
          name: 'Rebecca Ferguson',
          role: 'Lady Jessica',
          imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=300&auto=format&fit=crop',
        ),
        CastMember(
          name: 'Javier Bardem',
          role: 'Stilgar',
          imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300&auto=format&fit=crop',
        ),
      ],
    ),
    Movie(
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
      primaryLanguage: MovieLanguage.telugu,
      availableLanguages: [MovieLanguage.telugu, MovieLanguage.hindi, MovieLanguage.tamil, MovieLanguage.english],
      formats: [MovieFormat.imax3D, MovieFormat.format3D, MovieFormat.dolbyAtmos, MovieFormat.format2D],
      certificate: 'UA',
      releaseDate: DateTime(2024, 6, 27),
      startingPrice: 295,
      trailerYoutubeId: 'kQDd1AhGIHk',
      director: 'Nag Ashwin',
      isNowShowing: true,
      isTrending: true,
      cast: const [
        CastMember(
          name: 'Prabhas',
          role: 'Bhairava',
          imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=300&auto=format&fit=crop',
        ),
        CastMember(
          name: 'Amitabh Bachchan',
          role: 'Ashwatthama',
          imageUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=300&auto=format&fit=crop',
        ),
        CastMember(
          name: 'Deepika Padukone',
          role: 'SUM-80',
          imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop',
        ),
        CastMember(
          name: 'Kamal Haasan',
          role: 'Supreme Yaskin',
          imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?q=80&w=300&auto=format&fit=crop',
        ),
      ],
    ),
    Movie(
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
      primaryLanguage: MovieLanguage.telugu,
      availableLanguages: [MovieLanguage.telugu, MovieLanguage.hindi, MovieLanguage.tamil],
      formats: [MovieFormat.dolbyAtmos, MovieFormat.format2D, MovieFormat.imax3D],
      certificate: 'UA',
      releaseDate: DateTime(2024, 9, 27),
      startingPrice: 250,
      trailerYoutubeId: 'lc0_Pq9fGpg',
      director: 'Koratala Siva',
      isNowShowing: true,
      isTrending: true,
      cast: const [
        CastMember(
          name: 'N. T. Rama Rao Jr.',
          role: 'Devara / Vara',
          imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=300&auto=format&fit=crop',
        ),
        CastMember(
          name: 'Janhvi Kapoor',
          role: 'Thangam',
          imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=300&auto=format&fit=crop',
        ),
        CastMember(
          name: 'Saif Ali Khan',
          role: 'Bhaira',
          imageUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?q=80&w=300&auto=format&fit=crop',
        ),
      ],
    ),
    Movie(
      id: 'mov_4',
      title: 'Deadpool & Wolverine',
      tagline: 'Come together.',
      synopsis:
          'Wolverine is recovering from his injuries when he crosses paths with the loudmouth, Deadpool. They team up to defeat a common enemy in a multiverse-shattering adventure.',
      posterUrl:
          'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?q=80&w=800&auto=format&fit=crop',
      backdropUrl:
          'https://images.unsplash.com/photo-1563089145-599997674d42?q=80&w=1200&auto=format&fit=crop',
      rating: 4.8,
      votesCount: 78000,
      genres: ['Action', 'Comedy', 'Superhero'],
      duration: '2h 08m',
      primaryLanguage: MovieLanguage.english,
      availableLanguages: [MovieLanguage.english, MovieLanguage.hindi, MovieLanguage.telugu],
      formats: [MovieFormat.imax3D, MovieFormat.fourDX, MovieFormat.format3D, MovieFormat.format2D],
      certificate: 'A',
      releaseDate: DateTime(2024, 7, 26),
      startingPrice: 320,
      trailerYoutubeId: '73_1biulkYk',
      director: 'Shawn Levy',
      isNowShowing: true,
      isTrending: false,
      cast: const [
        CastMember(
          name: 'Ryan Reynolds',
          role: 'Wade Wilson / Deadpool',
          imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300&auto=format&fit=crop',
        ),
        CastMember(
          name: 'Hugh Jackman',
          role: 'Logan / Wolverine',
          imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=300&auto=format&fit=crop',
        ),
      ],
    ),
    Movie(
      id: 'mov_5',
      title: 'Interstellar (10th Anniversary IMAX Re-Release)',
      tagline: 'Mankind was born on Earth. It was never meant to die here.',
      synopsis:
          'When Earth becomes uninhabitable in the future, a farmer and ex-NASA pilot, Joseph Cooper, is tasked to pilot a spacecraft along with a team of researchers to find a new planet for humans.',
      posterUrl:
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=800&auto=format&fit=crop',
      backdropUrl:
          'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?q=80&w=1200&auto=format&fit=crop',
      rating: 5.0,
      votesCount: 154000,
      genres: ['Sci-Fi', 'Adventure', 'Drama'],
      duration: '2h 49m',
      primaryLanguage: MovieLanguage.english,
      availableLanguages: [MovieLanguage.english],
      formats: [MovieFormat.imax3D, MovieFormat.dolbyAtmos],
      certificate: 'UA',
      releaseDate: DateTime(2024, 11, 15),
      startingPrice: 400,
      trailerYoutubeId: 'zSWdZVtXT7E',
      director: 'Christopher Nolan',
      isNowShowing: true,
      isTrending: true,
      cast: const [
        CastMember(
          name: 'Matthew McConaughey',
          role: 'Cooper',
          imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=300&auto=format&fit=crop',
        ),
        CastMember(
          name: 'Anne Hathaway',
          role: 'Brand',
          imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=300&auto=format&fit=crop',
        ),
      ],
    ),
    Movie(
      id: 'mov_6',
      title: 'Pushpa 2: The Rule',
      tagline: 'The wildfire spreads across borders.',
      synopsis:
          'Pushpa Raj expands his red sandalwood empire beyond frontiers while facing intensifying vengeance from Bhanwar Singh Shekhawat in an explosive showdown.',
      posterUrl:
          'https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=800&auto=format&fit=crop',
      backdropUrl:
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=1200&auto=format&fit=crop',
      rating: 4.9,
      votesCount: 110000,
      genres: ['Action', 'Crime', 'Drama'],
      duration: '3h 15m',
      primaryLanguage: MovieLanguage.telugu,
      availableLanguages: [MovieLanguage.telugu, MovieLanguage.hindi, MovieLanguage.tamil],
      formats: [MovieFormat.dolbyAtmos, MovieFormat.format3D, MovieFormat.format2D, MovieFormat.imax3D],
      certificate: 'UA',
      releaseDate: DateTime(2024, 12, 6),
      startingPrice: 300,
      trailerYoutubeId: 'g3JUbgDXg24',
      director: 'Sukumar',
      isNowShowing: false,
      isComingSoon: true,
      cast: const [
        CastMember(
          name: 'Allu Arjun',
          role: 'Pushpa Raj',
          imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=300&auto=format&fit=crop',
        ),
        CastMember(
          name: 'Rashmika Mandanna',
          role: 'Srivalli',
          imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop',
        ),
        CastMember(
          name: 'Fahadh Faasil',
          role: 'SP Bhanwar Singh Shekhawat',
          imageUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?q=80&w=300&auto=format&fit=crop',
        ),
      ],
    ),
  ];

  static List<Theatre> getTheatresForMovie(String movieId) {
    return [
      const Theatre(
        id: 'theatre_amb',
        name: 'AMB Cinemas',
        location: 'Sarath City Capital Mall, Gachibowli',
        distance: '2.4 km',
        amenities: ['Laser IMAX', 'Dolby Atmos', 'VIP Recliner Lounge', 'Valet Parking'],
        showtimes: [
          ShowtimeSlot(
            id: 'amb_st_1',
            time: '10:15 AM',
            format: MovieFormat.imax3D,
            language: 'English',
            screenName: 'Audi 1 (Laser IMAX)',
            basePrice: 450,
            isFillingFast: true,
          ),
          ShowtimeSlot(
            id: 'amb_st_2',
            time: '01:45 PM',
            format: MovieFormat.dolbyAtmos,
            language: 'Telugu',
            screenName: 'Audi 4 (Dolby Atmos)',
            basePrice: 295,
          ),
          ShowtimeSlot(
            id: 'amb_st_3',
            time: '05:30 PM',
            format: MovieFormat.imax3D,
            language: 'English',
            screenName: 'Audi 1 (Laser IMAX)',
            basePrice: 450,
            isAlmostFull: true,
          ),
          ShowtimeSlot(
            id: 'amb_st_4',
            time: '09:15 PM',
            format: MovieFormat.fourDX,
            language: 'Hindi',
            screenName: 'Audi 5 (4DX)',
            basePrice: 380,
            isFillingFast: true,
          ),
          ShowtimeSlot(
            id: 'amb_st_5',
            time: '11:45 PM',
            format: MovieFormat.dolbyAtmos,
            language: 'English',
            screenName: 'Audi 2',
            basePrice: 250,
          ),
        ],
      ),
      const Theatre(
        id: 'theatre_prasads',
        name: 'Prasads Multiplex & IMAX',
        location: 'NTR Gardens, Necklace Road',
        distance: '4.8 km',
        amenities: ['Dual 4K Laser IMAX Screen', 'Dolby Atmos', 'Large Food Court'],
        showtimes: [
          ShowtimeSlot(
            id: 'prs_st_1',
            time: '11:00 AM',
            format: MovieFormat.imax3D,
            language: 'English',
            screenName: 'Large Screen 6 (Laser IMAX)',
            basePrice: 400,
          ),
          ShowtimeSlot(
            id: 'prs_st_2',
            time: '02:30 PM',
            format: MovieFormat.dolbyAtmos,
            language: 'Telugu',
            screenName: 'Screen 4',
            basePrice: 250,
          ),
          ShowtimeSlot(
            id: 'prs_st_3',
            time: '06:45 PM',
            format: MovieFormat.imax3D,
            language: 'English',
            screenName: 'Large Screen 6 (Laser IMAX)',
            basePrice: 400,
            isAlmostFull: true,
          ),
          ShowtimeSlot(
            id: 'prs_st_4',
            time: '10:30 PM',
            format: MovieFormat.format3D,
            language: 'Telugu',
            screenName: 'Screen 2',
            basePrice: 220,
          ),
        ],
      ),
      const Theatre(
        id: 'theatre_pvr_inorbit',
        name: 'PVR INOX Superplex',
        location: 'Inorbit Mall, Hitec City',
        distance: '3.1 km',
        amenities: ['P[XL] Large Screen', '4DX Motion', 'Gourmet In-Seat Dining'],
        showtimes: [
          ShowtimeSlot(
            id: 'pvr_st_1',
            time: '12:00 PM',
            format: MovieFormat.fourDX,
            language: 'English',
            screenName: 'Audi 3 (4DX)',
            basePrice: 390,
          ),
          ShowtimeSlot(
            id: 'pvr_st_2',
            time: '03:45 PM',
            format: MovieFormat.dolbyAtmos,
            language: 'Telugu',
            screenName: 'Audi 1 (P[XL])',
            basePrice: 280,
            isFillingFast: true,
          ),
          ShowtimeSlot(
            id: 'pvr_st_3',
            time: '07:30 PM',
            format: MovieFormat.fourDX,
            language: 'English',
            screenName: 'Audi 3 (4DX)',
            basePrice: 390,
            isAlmostFull: true,
          ),
          ShowtimeSlot(
            id: 'pvr_st_4',
            time: '10:50 PM',
            format: MovieFormat.format2D,
            language: 'Hindi',
            screenName: 'Audi 2',
            basePrice: 220,
          ),
        ],
      ),
      const Theatre(
        id: 'theatre_aaa',
        name: 'AAA Cinemas (Allu Arjun Arena)',
        location: 'Asian Satyam Mall, Ameerpet',
        distance: '5.6 km',
        amenities: ['Barco Laser Projection', 'Dolby Atmos Sound', 'Luxury Loungers'],
        showtimes: [
          ShowtimeSlot(
            id: 'aaa_st_1',
            time: '01:15 PM',
            format: MovieFormat.dolbyAtmos,
            language: 'Telugu',
            screenName: 'Screen 1 (Laser)',
            basePrice: 295,
          ),
          ShowtimeSlot(
            id: 'aaa_st_2',
            time: '04:45 PM',
            format: MovieFormat.dolbyAtmos,
            language: 'Telugu',
            screenName: 'Screen 1 (Laser)',
            basePrice: 295,
            isFillingFast: true,
          ),
          ShowtimeSlot(
            id: 'aaa_st_3',
            time: '08:15 PM',
            format: MovieFormat.dolbyAtmos,
            language: 'Telugu',
            screenName: 'Screen 1 (Laser)',
            basePrice: 295,
            isAlmostFull: true,
          ),
        ],
      ),
    ];
  }

  /// Generates a realistic cinema seat grid with VIP, Premium, and Executive rows.
  static List<CinemaSeat> generateSeatGrid(ShowtimeSlot showtime) {
    final List<CinemaSeat> seats = [];

    final reclinerPrice = showtime.pricing?['recliner'] ??
        showtime.pricing?['vip'] ??
        (showtime.basePrice + 155);
    final premiumPrice = showtime.pricing?['premium'] ??
        showtime.basePrice;
    final goldPrice = showtime.pricing?['gold'] ??
        showtime.pricing?['standard'] ??
        (showtime.basePrice * 0.7).roundToDouble();

    // VIP Rows (A, B) - Recliner (Top/Back of theatre)
    final vipRows = ['A', 'B'];
    for (final row in vipRows) {
      for (int num = 1; num <= 10; num++) {
        final id = '${row}_$num';
        final isOccupied = (row == 'A' && (num == 4 || num == 5 || num == 6)) ||
            (row == 'B' && (num == 2 || num == 3 || num == 8));
        seats.add(
          CinemaSeat(
            id: id,
            rowLabel: row,
            seatNumber: num,
            tier: SeatTier.vip,
            price: reclinerPrice,
            status: isOccupied ? SeatStatus.occupied : SeatStatus.available,
          ),
        );
      }
    }

    // Premium Rows (C, D, E, F) - Center & Best Viewing
    final premiumRows = ['C', 'D', 'E', 'F'];
    for (final row in premiumRows) {
      for (int num = 1; num <= 12; num++) {
        final id = '${row}_$num';
        final isOccupied = (row == 'D' && (num >= 4 && num <= 8)) ||
            (row == 'E' && (num == 1 || num == 2 || num == 11 || num == 12)) ||
            (row == 'F' && (num >= 5 && num <= 7));
        seats.add(
          CinemaSeat(
            id: id,
            rowLabel: row,
            seatNumber: num,
            tier: SeatTier.premium,
            price: premiumPrice,
            status: isOccupied ? SeatStatus.occupied : SeatStatus.available,
          ),
        );
      }
    }

    // Executive Rows (G, H) - Front Rows
    final executiveRows = ['G', 'H'];
    for (final row in executiveRows) {
      for (int num = 1; num <= 12; num++) {
        final id = '${row}_$num';
        final isOccupied = (row == 'G' && (num == 6 || num == 7));
        seats.add(
          CinemaSeat(
            id: id,
            rowLabel: row,
            seatNumber: num,
            tier: SeatTier.executive,
            price: goldPrice,
            status: isOccupied ? SeatStatus.occupied : SeatStatus.available,
          ),
        );
      }
    }

    return seats;
  }

  static List<FandBItem> getSnackMenu() {
    return [
      FandBItem(
        id: 'fnb_1',
        name: 'Gourmet Cheese Popcorn (Large)',
        description: 'Warm, freshly popped artisanal cheddar tub',
        price: 240,
        imageUrl: 'https://images.unsplash.com/photo-1585647347483-22b66260dfff?q=80&w=400&auto=format&fit=crop',
      ),
      FandBItem(
        id: 'fnb_2',
        name: 'Loaded Mexican Nachos & Salsa',
        description: 'Crispy corn tortilla with warm jalapeño cheese dip',
        price: 220,
        imageUrl: 'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?q=80&w=400&auto=format&fit=crop',
      ),
      FandBItem(
        id: 'fnb_3',
        name: 'Chilled Pepsi Zero (600ml)',
        description: 'Ice cold fountain drink',
        price: 120,
        imageUrl: 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?q=80&w=400&auto=format&fit=crop',
      ),
      FandBItem(
        id: 'fnb_4',
        name: 'PLAZA Blockbuster Combo',
        description: 'Large Popcorn + 2 Sodas + Nachos with Dip',
        price: 499,
        imageUrl: 'https://images.unsplash.com/photo-1578849278619-e73505e9610f?q=80&w=400&auto=format&fit=crop',
      ),
    ];
  }
}
