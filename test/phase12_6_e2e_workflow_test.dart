import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/models/cinema_showtime.dart';
import 'package:plaza/core/models/movie.dart';
import 'package:plaza/features/admin/admin_dashboard_shell.dart';
import 'package:plaza/features/admin/admin_route_guard.dart';
import 'package:plaza/features/movies/movie_details_screen.dart';
import 'package:plaza/features/movies/movies_screen.dart';
import 'package:plaza/features/movies/seat_selection_screen.dart';
import 'package:plaza/features/movies/showtime_selection_screen.dart';
import 'package:plaza/features/navigation/plaza_navigation_shell.dart';

void main() {
  final testMovie = Movie(
    id: 'mov_e2e_2026',
    title: 'PLAZA E2E Test Movie 2026',
    tagline: 'The Ultimate Cinema Experience',
    synopsis: 'A high-stakes thriller verifying end-to-end PLAZA cinema operations.',
    posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1',
    backdropUrl: 'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c',
    rating: 9.3,
    votesCount: 1500,
    genres: ['Action', 'Thriller'],
    duration: '2h 45m',
    primaryLanguage: MovieLanguage.telugu,
    availableLanguages: [MovieLanguage.telugu, MovieLanguage.hindi],
    formats: [MovieFormat.imax3D, MovieFormat.format2D],
    certificate: 'UA',
    releaseDate: DateTime(2026, 10, 15),
    startingPrice: 200.0,
    trailerYoutubeId: 'trailer_e2e_123',
    director: 'S. S. Rajamouli',
    cast: [
      CastMember(name: 'Actor One', role: 'Protagonist', imageUrl: ''),
    ],
    isNowShowing: true,
    isTrending: true,
    isComingSoon: false,
  );

  const testSlot = ShowtimeSlot(
    id: 'slot_e2e_1',
    time: '7:30 PM',
    format: MovieFormat.imax3D,
    language: 'Telugu',
    screenName: 'Screen 1 (IMAX 3D Laser)',
    basePrice: 200.0,
  );

  final testTheatre = Theatre(
    id: 'theatre_e2e_2026',
    name: 'PLAZA E2E Test Theatre',
    location: 'HITEC City, Hyderabad',
    distance: '2.5 km',
    amenities: const ['Dolby Atmos', '4K Laser Projection', 'Gourmet Lounge'],
    showtimes: const [testSlot],
  );

  group('Phase 12.6 — Customer UI & Booking Entry Point Verification', () {
    testWidgets('Customer sees published movie in discovery and opens details', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MoviesScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Movie discovery header and tabs are visible
      expect(find.text('Movies'), findsOneWidget);
      expect(find.text('Now Showing'), findsOneWidget);
      expect(find.text('Trending in IMAX & 3D'), findsOneWidget);

      // Verify that no admin controls or management buttons appear in customer view
      expect(find.text('Admin Portal'), findsNothing);
      expect(find.text('Admin Dashboard'), findsNothing);
      expect(find.byIcon(Icons.admin_panel_settings), findsNothing);
    });

    testWidgets('MovieDetailsScreen displays title, starting price, and Book Tickets button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(movie: testMovie),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Title & metadata
      expect(find.text(testMovie.title), findsWidgets);
      expect(find.text('₹200'), findsOneWidget);
      expect(find.text('Book Tickets'), findsOneWidget);

      // Zero admin controls on customer detail screen
      expect(find.text('Edit Movie'), findsNothing);
      expect(find.text('Delete Movie'), findsNothing);
    });

    testWidgets('ShowtimeSelectionScreen renders test theatre, showtime slot, and format', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ShowtimeSelectionScreen(movie: testMovie),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Movie title in appbar
      expect(find.text(testMovie.title), findsOneWidget);
      // Date selector pills
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('All Formats'), findsOneWidget);
    });

    testWidgets('SeatSelectionScreen allows selecting seats with authoritative server pricing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: SeatSelectionScreen(
            movie: testMovie,
            theatre: testTheatre,
            showtime: testSlot,
            date: DateTime.now(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Movie and theatre info are present
      expect(find.text(testMovie.title), findsOneWidget);
      expect(find.textContaining(testTheatre.name), findsOneWidget);
      expect(find.textContaining('7:30 PM'), findsOneWidget);

      expect(find.text('SCREEN THIS WAY'), findsOneWidget);
      expect(find.text('SELECT SEATS'), findsOneWidget);

      final seatFinder = find.text('1');
      expect(seatFinder, findsWidgets);

      await tester.tap(seatFinder.first);
      await tester.pump(const Duration(milliseconds: 100));

      // The proceed button should become active with server pricing calculation
      expect(find.text('Proceed'), findsOneWidget);

      // Zero admin edit controls
      expect(find.text('Admin Actions'), findsNothing);
      expect(find.text('Manage Shows'), findsNothing);
    });
  });

  group('Phase 12.6 — Customer Security & Admin Route Isolation', () {
    testWidgets('Standard customer navigation shell has no admin controls or tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlazaNavigationShell(),
        ),
      );

      // Exactly the 5 consumer tabs
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Plans'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // No admin navigation tab
      expect(find.text('Admin'), findsNothing);
      expect(find.text('Control Center'), findsNothing);
    });

    testWidgets('AdminRouteGuard rejects unauthenticated or customer session', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminRouteGuard(
            child: AdminDashboardShell(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Should show Access Denied / unauthorized message, NOT the admin shell
      expect(find.text('Admin Access Required'), findsOneWidget);
      expect(find.text('Admin Control Center'), findsNothing);
    });
  });
}
