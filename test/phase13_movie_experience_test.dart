import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/data/plaza_global_state.dart';
import 'package:plaza/core/models/cinema_showtime.dart';
import 'package:plaza/core/models/movie.dart';
import 'package:plaza/core/repositories/movie_repository.dart';
import 'package:plaza/features/movies/movie_details_screen.dart';
import 'package:plaza/features/movies/movies_screen.dart';
import 'package:plaza/features/movies/seat_selection_screen.dart';
import 'package:plaza/features/movies/showtime_selection_screen.dart';

class MockTestMovieRepository implements MovieRepository {
  final List<Movie> testMovies;
  final List<Theatre> testTheatres;

  MockTestMovieRepository({required this.testMovies, required this.testTheatres});

  @override
  Future<List<Movie>> getMovies() async => testMovies;

  @override
  Future<Movie?> getMovieById(String id) async {
    return testMovies.firstWhere((m) => m.id == id);
  }

  @override
  Future<List<Movie>> searchMovies(String query) async {
    final q = query.toLowerCase();
    return testMovies.where((m) => m.title.toLowerCase().contains(q)).toList();
  }

  @override
  Future<List<Theatre>> getTheatresForMovie(String movieId, {String? date, String? city}) async {
    return testTheatres;
  }
}

void main() {
  final nowShowingMovie = Movie(
    id: 'test_mov_now',
    title: 'Project K - The Awakening',
    tagline: 'The future begins now',
    synopsis: 'An epic dystopian sci-fi spectacle spanning across centuries.',
    posterUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=600',
    backdropUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=1200',
    rating: 4.8,
    votesCount: 95000,
    genres: const ['Sci-Fi', 'Action'],
    duration: '2h 55m',
    primaryLanguage: MovieLanguage.telugu,
    availableLanguages: const [MovieLanguage.telugu, MovieLanguage.hindi],
    formats: const [MovieFormat.imax3D, MovieFormat.dolbyAtmos],
    certificate: 'U/A',
    releaseDate: DateTime.now().subtract(const Duration(days: 3)),
    startingPrice: 250,
    trailerYoutubeId: 'xyz123',
    cast: const [CastMember(name: 'Prabhas', role: 'Bhairava', imageUrl: '')],
    director: 'Nag Ashwin',
    isNowShowing: true,
    isTrending: true,
    isComingSoon: false,
  );

  final comingSoonMovie = Movie(
    id: 'test_mov_soon',
    title: 'Spirit Untamed',
    tagline: 'Power and redemption',
    synopsis: 'A gripping intense police drama.',
    posterUrl: 'https://images.unsplash.com/photo-1485846234645-a62644f84728?q=80&w=600',
    backdropUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?q=80&w=1200',
    rating: 0.0,
    votesCount: 0,
    genres: const ['Action', 'Thriller'],
    duration: '2h 40m',
    primaryLanguage: MovieLanguage.telugu,
    availableLanguages: const [MovieLanguage.telugu],
    formats: const [MovieFormat.format2D],
    certificate: 'A',
    releaseDate: DateTime.now().add(const Duration(days: 30)),
    startingPrice: 0,
    trailerYoutubeId: '', // Empty trailer to test conditional preview
    cast: const [CastMember(name: 'Prabhas', role: 'ACP Vikram', imageUrl: '')],
    director: 'Sandeep Reddy Vanga',
    isNowShowing: false,
    isTrending: false,
    isComingSoon: true,
  );

  final testTheatre = Theatre(
    id: 'theatre_test_1',
    name: 'AMB Cinemas: Gachibowli',
    location: 'Sarath City Capital Mall, Gachibowli',
    city: 'Hyderabad',
    distance: '2.4 km',
    amenities: const ['Dolby Atmos', 'Laser 4K', 'Gourmet Bar'],
    showtimes: [
      ShowtimeSlot(
        id: 'slot_1',
        time: '10:30 AM',
        format: MovieFormat.imax3D,
        language: 'Telugu',
        screenName: 'Screen 1 - IMAX Laser',
        basePrice: 250,
        pricing: {'gold': 250, 'premium': 350, 'recliner': 500},
        availableSeats: 80,
        totalSeats: 150,
      ),
      ShowtimeSlot(
        id: 'slot_2',
        time: '02:15 PM',
        format: MovieFormat.imax3D,
        language: 'Telugu',
        screenName: 'Screen 1 - IMAX Laser',
        basePrice: 250,
        pricing: {'gold': 250, 'premium': 350, 'recliner': 500},
        availableSeats: 12,
        totalSeats: 150,
        isAlmostFull: true,
      ),
      ShowtimeSlot(
        id: 'slot_3',
        time: '06:45 PM',
        format: MovieFormat.imax3D,
        language: 'Telugu',
        screenName: 'Screen 1 - IMAX Laser',
        basePrice: 250,
        pricing: {'gold': 250, 'premium': 350, 'recliner': 500},
        availableSeats: 0,
        totalSeats: 150,
        isSoldOut: true,
      ),
    ],
  );

  group('Phase 13: Public Movies Discovery Experience', () {
    testWidgets('MoviesScreen renders discovery list, city context, and customer elements', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockTestMovieRepository(
        testMovies: [nowShowingMovie, comingSoonMovie],
        testTheatres: [testTheatre],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MoviesScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app bar branding and city pill
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('Trending in IMAX & 3D'), findsOneWidget);
      expect(find.text('Now Showing'), findsOneWidget);

      // Verify customer movie card components
      expect(find.text('Project K - The Awakening'), findsWidgets);
      expect(find.text('₹250 onwards'), findsWidgets);

      // Verify strict isolation: NO admin controls in customer view
      expect(find.text('Admin Portal'), findsNothing);
      expect(find.text('Admin Dashboard'), findsNothing);
      expect(find.byIcon(Icons.admin_panel_settings), findsNothing);
    });

    testWidgets('MoviesScreen category filtering and search works seamlessly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockTestMovieRepository(
        testMovies: [nowShowingMovie, comingSoonMovie],
        testTheatres: [testTheatre],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MoviesScreen(repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Search bar interaction
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Spirit');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Filtered match
      expect(find.text('Spirit Untamed'), findsOneWidget);
      expect(find.text('Project K - The Awakening'), findsNothing);

      // Clear search
      final clearButton = find.text('Clear');
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('Project K - The Awakening'), findsWidgets);
    });
  });

  group('Phase 13: Movie Details Experience', () {
    testWidgets('MovieDetailsScreen renders now showing movie with Book Tickets CTA and Trailer', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(movie: nowShowingMovie),
        ),
      );
      await tester.pumpAndSettle();

      // Header and metadata
      expect(find.text('Project K - The Awakening'), findsWidgets);
      expect(find.text('Watch Trailer'), findsOneWidget); // Trailer exists
      expect(find.text('Book Tickets'), findsOneWidget);
      expect(find.text('₹250'), findsOneWidget);

      // Favorite toggle
      final favButton = find.byIcon(Icons.favorite_border_rounded);
      expect(favButton, findsOneWidget);
      await tester.tap(favButton);
      await tester.pumpAndSettle();
      expect(PlazaGlobalState.instance.isFavorite(nowShowingMovie.id), isTrue);
    });

    testWidgets('MovieDetailsScreen renders coming soon movie with truthful CTA and hides trailer when absent', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(movie: comingSoonMovie),
        ),
      );
      await tester.pumpAndSettle();

      // Metadata
      expect(find.text('Spirit Untamed'), findsWidgets);
      // Trailer button is NOT rendered when trailerYoutubeId is empty
      expect(find.text('Watch Trailer'), findsNothing);
      // Truthful coming soon state
      expect(find.text('Advance Booking Soon'), findsOneWidget);
      expect(find.text('Releasing Soon'), findsOneWidget);
    });
  });

  group('Phase 13: Showtime & Seat Selection Experience', () {
    testWidgets('ShowtimeSelectionScreen displays theatres, pricing, and truthful availability', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockTestMovieRepository(
        testMovies: [nowShowingMovie],
        testTheatres: [testTheatre],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShowtimeSelectionScreen(movie: nowShowingMovie, repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      // Theatre name and amenities
      expect(find.text('AMB Cinemas: Gachibowli'), findsOneWidget);
      expect(find.text('Dolby Atmos'), findsWidgets);

      // Showtime slots and pricing
      expect(find.text('10:30 AM'), findsOneWidget);
      expect(find.text('• ₹250'), findsWidgets);

      // Truthful badges
      expect(find.text('Almost Full'), findsOneWidget);
      expect(find.text('Sold Out'), findsOneWidget);

      // Tapping sold out show notifies user and does not enter booking
      final soldOutShow = find.text('Sold Out');
      await tester.tap(soldOutShow);
      await tester.pump();
      expect(find.text('This show is sold out. Please select another showtime.'), findsOneWidget);
    });

    testWidgets('SeatSelectionScreen calculates authoritative tiered pricing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final slot = testTheatre.showtimes.first;

      await tester.pumpWidget(
        MaterialApp(
          home: SeatSelectionScreen(
            movie: nowShowingMovie,
            theatre: testTheatre,
            showtime: slot,
            date: DateTime.now(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Authoritative pricing displayed in tier sections from slot.pricing
      expect(find.textContaining('VIP RECLINERS • ₹500'), findsOneWidget);
      expect(find.textContaining('PREMIUM • ₹350'), findsOneWidget);
      expect(find.textContaining('EXECUTIVE • ₹250'), findsOneWidget);

      // Selecting an available seat updates price
      final seat1 = find.text('1').first;
      await tester.tap(seat1);
      await tester.pumpAndSettle();

      // Total updates truthfully
      expect(find.text('1 SEAT (A1)'), findsOneWidget);
      expect(find.text('₹500'), findsOneWidget);
      expect(find.text('Proceed'), findsOneWidget);
    });
  });
}
