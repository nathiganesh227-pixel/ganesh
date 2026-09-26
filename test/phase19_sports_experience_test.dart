import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/data/plaza_global_state.dart';
import 'package:plaza/core/data/sports_mock_data.dart';
import 'package:plaza/core/models/sports.dart';
import 'package:plaza/core/models/unified_booking.dart';
import 'package:plaza/core/network/api_client.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/core/network/environment_config.dart';
import 'package:plaza/core/repositories/api_sports_repository.dart';
import 'package:plaza/core/repositories/local_sports_repository.dart';
import 'package:plaza/core/repositories/sports_repository.dart';
import 'package:plaza/features/sports/sports_confirmation_screen.dart';
import 'package:plaza/features/sports/sports_screen.dart';
import 'package:plaza/features/sports/sports_slot_booking_screen.dart';
import 'package:plaza/features/sports/sports_venue_details_screen.dart';
import 'package:plaza/features/sports/widgets/sports_venue_card.dart';

void main() {
  setUp(() {
    EnvironmentConfig.reset();
    EnvironmentConfig.setEnvironment(AppEnvironment.dev);
    PlazaGlobalState.instance.setSelectedCity('Hyderabad');
  });

  group('Phase 19: Sports Discovery Experience', () {
    testWidgets('SportsScreen renders header, city selector, search, and sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SportsScreen(repository: LocalSportsRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Top Header & City
      expect(find.text('Sports & Turfs'), findsOneWidget);
      expect(find.text('HYDERABAD'), findsOneWidget);

      // Search & Quick Filters
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All Sports'), findsOneWidget);
      expect(find.text('Favorites ❤️'), findsOneWidget);
      expect(find.text('Available Right Now ⚡'), findsOneWidget);

      // Categories
      expect(find.textContaining('Cricket'), findsWidgets);
      expect(find.textContaining('Football'), findsWidgets);

      // Signature Carousel & Curated List
      expect(find.text('Live & Trending Arenas 🔥'), findsOneWidget);
      expect(find.textContaining('All Curated Venues in Hyderabad'), findsOneWidget);
    });

    testWidgets('SportsScreen filters by category and quick chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SportsScreen(repository: LocalSportsRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Filter by Football
      final footballChip = find.textContaining('Football').first;
      await tester.tap(footballChip);
      await tester.pumpAndSettle();

      expect(find.byType(SportsVenueCard), findsWidgets);

      // Reset category filter by tapping All Sports
      await tester.tap(find.text('All Sports'));
      await tester.pumpAndSettle();

      // Tap on Available Right Now quick filter
      await tester.tap(find.text('Available Right Now ⚡'));
      await tester.pumpAndSettle();

      expect(find.byType(SportsVenueCard), findsWidgets);
    });

    testWidgets('SportsScreen search bar filters venues with debounce and handles empty state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SportsScreen(repository: LocalSportsRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Search for Gachibowli
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Gachibowli');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gachibowli'), findsWidgets);

      // Search for non-existing venue
      await tester.enterText(searchField, 'NonExistentTurfXYZ');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('No Sports Venues Found'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);

      // Reset filters
      await tester.tap(find.text('Reset Filters'));
      await tester.pumpAndSettle();

      expect(find.text('No Sports Venues Found'), findsNothing);
    });

    testWidgets('City selector bottom sheet switches global city in SportsScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SportsScreen(repository: LocalSportsRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on City Header
      await tester.tap(find.text('HYDERABAD'));
      await tester.pumpAndSettle();

      // Bottom sheet should be visible
      expect(find.text('Select Sports City'), findsOneWidget);
      expect(find.text('Bengaluru'), findsOneWidget);

      // Select Bengaluru
      await tester.tap(find.text('Bengaluru'));
      await tester.pumpAndSettle();

      // Global state must be updated
      expect(PlazaGlobalState.instance.selectedCity, 'Bengaluru');
      expect(find.text('BENGALURU'), findsOneWidget);
    });
  });

  group('Phase 19: Venue Details Experience', () {
    final testVenue = SportsMockData.venues.first;

    testWidgets('SportsVenueDetailsScreen renders hero gallery, info, amenities, and slots', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SportsVenueDetailsScreen(venue: testVenue),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(testVenue.name), findsOneWidget);
      expect(find.text('About Venue'), findsOneWidget);
      expect(find.text('Turf Facilities'), findsOneWidget);
      expect(find.text('Ground Rules & Footwear'), findsOneWidget);
      expect(find.text('Upcoming Slots Today'), findsOneWidget);
      expect(find.text('Book Slot 🏏'), findsOneWidget);
    });

    testWidgets('Favorite button toggles favorite in PlazaGlobalState on SportsVenueDetailsScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SportsVenueDetailsScreen(venue: testVenue),
        ),
      );
      await tester.pumpAndSettle();

      expect(PlazaGlobalState.instance.favoriteIds.contains(testVenue.id), isFalse);

      final favButton = find.byIcon(Icons.favorite_border_rounded);
      expect(favButton, findsOneWidget);
      await tester.tap(favButton);
      await tester.pumpAndSettle();

      expect(PlazaGlobalState.instance.favoriteIds.contains(testVenue.id), isTrue);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });

  group('Phase 19: Slot Booking & Squad Mode Experience', () {
    final testVenue = SportsMockData.venues.first;

    testWidgets('SportsSlotBookingScreen renders date, duration, player count, and payment notice', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SportsSlotBookingScreen(
            venue: testVenue,
            initialSport: testVenue.supportedSports.first,
            repository: const LocalSportsRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Book Turf / Slot'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget); // 7-day date picker with TODAY
      expect(find.text('Match Date'), findsOneWidget);
      expect(find.text('Payment Method: Pay at Venue'), findsOneWidget);
      expect(find.text('Book Turf Slot ⚡'), findsOneWidget);
    });

    testWidgets('Squad mode switch updates bill split and per-player share', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SportsSlotBookingScreen(
            venue: testVenue,
            initialSport: testVenue.supportedSports.first,
            repository: const LocalSportsRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Toggle squad mode
      final squadSwitch = find.byType(Switch);
      expect(squadSwitch, findsOneWidget);
      await tester.tap(squadSwitch);
      await tester.pumpAndSettle();

      expect(find.text('Squad / Team Name'), findsOneWidget);
      expect(find.text('PER PLAYER SHARE'), findsOneWidget);
    });

    testWidgets('Successful slot booking adds unified booking and navigates to confirmation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final initialBookingsCount = PlazaGlobalState.instance.bookings.length;

      await tester.pumpWidget(
        MaterialApp(
          home: SportsSlotBookingScreen(
            venue: testVenue,
            initialSport: testVenue.supportedSports.first,
            repository: const LocalSportsRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Confirm Booking
      final bookButton = find.text('Book Turf Slot ⚡');
      await tester.tap(bookButton);
      await tester.pumpAndSettle();

      // Should navigate to confirmation screen
      expect(find.text('Turf Slot Confirmed!'), findsOneWidget);
      expect(find.text('Payment Status: Pay at Venue / Pending Verification'), findsOneWidget);
      expect(find.text('Total (Pay at Venue)'), findsOneWidget);
      expect(find.text('Add to Apple Wallet'), findsOneWidget);

      // PlazaGlobalState should contain the new unified booking
      expect(PlazaGlobalState.instance.bookings.length, initialBookingsCount + 1);
      final latestBooking = PlazaGlobalState.instance.bookings.first;
      expect(latestBooking.type, UnifiedBookingType.sports);
      expect(latestBooking.status, BookingStatus.upcoming);
    });

    testWidgets('Slot conflict / failure displays error message', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final failingRepo = MockConflictSportsRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: SportsSlotBookingScreen(
            venue: testVenue,
            initialSport: testVenue.supportedSports.first,
            repository: failingRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Confirm Booking
      final bookButton = find.text('Book Turf Slot ⚡');
      await tester.tap(bookButton);
      await tester.pumpAndSettle();

      // Should show SnackBar with conflict error
      expect(find.text('That court slot is already booked or unavailable. Please choose another slot.'), findsOneWidget);
      expect(find.text('Turf Slot Confirmed!'), findsNothing);
    });
  });

  group('Phase 19: Confirmation Screen & Truthful Payment', () {
    final testVenue = SportsMockData.venues.first;
    final dummyBooking = SportsBooking(
      bookingId: 'PLZ-SPT-888999',
      venue: testVenue,
      sport: testVenue.supportedSports.first,
      date: DateTime.now().add(const Duration(days: 1)),
      slot: testVenue.availableSlots.first,
      durationMinutes: 60,
      playersCount: 10,
      addOns: [],
      isSquadBooking: true,
      squadName: 'Hyderabad Strikers',
      courtPrice: 1200.0,
      addOnsTotal: 0.0,
      convenienceFee: 50.0,
      grandTotal: 1250.0,
      perPersonCost: 125.0,
      bookerName: 'Gopi Ganesh',
      bookerPhone: '+91 98765 43210',
      qrCodeData: 'PLAZA://SPORTS/PLZ-SPT-888999',
      paymentMethod: 'Pay at Venue (Cash/UPI)',
      bookingTime: DateTime.now(),
    );

    testWidgets('SportsConfirmationScreen renders digital match pass without fake paid claims', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SportsConfirmationScreen(booking: dummyBooking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Turf Slot Confirmed!'), findsOneWidget);
      expect(find.text('PLZ-SPT-888999'), findsOneWidget);
      expect(find.text('Payment Status: Pay at Venue / Pending Verification'), findsOneWidget);
      expect(find.text('Total (Pay at Venue)'), findsOneWidget);
      expect(find.text('Total Paid'), findsNothing); // ZERO fake paid claims
      expect(find.text('Add to Apple Wallet'), findsOneWidget);
      expect(find.text('Directions 📍'), findsOneWidget);

      // Tap Add to Apple Wallet
      await tester.tap(find.text('Add to Apple Wallet'));
      await tester.pumpAndSettle();
      expect(find.text('Sports Match Pass added to Apple Wallet 🎟️'), findsOneWidget);
    });
  });

  group('Phase 19: Customer Isolation & Security', () {
    testWidgets('Sports consumer screens contain zero admin controls or leaks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: SportsScreen(repository: LocalSportsRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin'), findsNothing);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Unpublished'), findsNothing);
      expect(find.text('Edit Venue'), findsNothing);
      expect(find.text('Delete Venue'), findsNothing);
    });
  });

  group('Phase 19: Production Fallback Safety', () {
    test('ApiSportsRepository rethrows error in production mode when mock data disabled', () async {
      EnvironmentConfig.setEnvironment(AppEnvironment.prod);
      EnvironmentConfig.useMockData = false;

      final failingClient = MockFailingApiClient();
      final repo = ApiSportsRepository(
        client: failingClient,
        fallback: const LocalSportsRepository(),
      );

      expect(
        () async => await repo.getVenues(),
        throwsA(isA<Exception>()),
      );
    });

    test('ApiSportsRepository falls back to local data in dev mode', () async {
      EnvironmentConfig.setEnvironment(AppEnvironment.dev);
      EnvironmentConfig.useMockData = true;

      final failingClient = MockFailingApiClient();
      final repo = ApiSportsRepository(
        client: failingClient,
        fallback: const LocalSportsRepository(),
      );

      final venues = await repo.getVenues();
      expect(venues.isNotEmpty, isTrue);
    });
  });
}

class MockConflictSportsRepository implements SportsRepository {
  @override
  Future<List<SportsVenue>> getVenues({String? sport, String? q, String? city}) async {
    return SportsMockData.venues;
  }

  @override
  Future<SportsVenue?> getVenueById(String id) async {
    return SportsMockData.venues.first;
  }

  @override
  Future<bool> bookSlot({
    required String venueId,
    required String sportName,
    required String slotId,
    required String date,
    required int playersCount,
    String? squadName,
    List<String>? addOnIds,
  }) async {
    // Simulate slot conflict / double booking rejection
    return false;
  }
}

class MockFailingApiClient extends ApiClient {
  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    required T Function(dynamic json) fromJson,
  }) async {
    return ApiResponse<T>.failure('Failed to reach production backend', statusCode: 503);
  }
}
