import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/data/dining_mock_data.dart';
import 'package:plaza/core/data/plaza_global_state.dart';
import 'package:plaza/core/models/dining.dart';
import 'package:plaza/core/models/unified_booking.dart';
import 'package:plaza/core/network/api_client.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/core/network/environment_config.dart';
import 'package:plaza/core/repositories/api_dining_repository.dart';
import 'package:plaza/core/repositories/local_dining_repository.dart';
import 'package:plaza/features/dining/dining_confirmation_screen.dart';
import 'package:plaza/features/dining/dining_screen.dart';
import 'package:plaza/features/dining/restaurant_details_screen.dart';
import 'package:plaza/features/dining/table_reservation_screen.dart';

void main() {
  setUp(() {
    EnvironmentConfig.reset();
    EnvironmentConfig.setEnvironment(AppEnvironment.dev);
    PlazaGlobalState.instance.setSelectedCity('Hyderabad');
  });

  group('Phase 14: Dining Discovery Experience', () {
    testWidgets('DiningScreen renders header, city selector, search, and filters', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DiningScreen(repository: LocalDiningRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Top Header & City
      expect(find.text('Dining & Cafes'), findsOneWidget);
      expect(find.text('Hyderabad'), findsOneWidget);

      // Search & Quick Filters
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Pure Veg'), findsOneWidget);
      expect(find.text('Rooftop / Outdoor'), findsOneWidget);
      expect(find.text('Fine Dining'), findsOneWidget);

      // Sections
      expect(find.text('Trending Gourmet Tables'), findsOneWidget);
      expect(find.text('Fine Dining & Chef Experiences'), findsOneWidget);
      expect(find.text('All Restaurants Near You'), findsOneWidget);
    });

    testWidgets('DiningScreen filters by Pure Veg and Rooftop toggles', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DiningScreen(repository: LocalDiningRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pure Veg toggle
      await tester.tap(find.text('Pure Veg'));
      await tester.pumpAndSettle();

      expect(find.text('Clear all filters'), findsOneWidget);

      // Reset filters
      await tester.tap(find.text('Clear all filters'));
      await tester.pumpAndSettle();

      expect(find.text('Trending Gourmet Tables'), findsOneWidget);
    });

    testWidgets('DiningScreen search bar queries restaurants dynamically', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DiningScreen(repository: LocalDiningRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Search for Biryani
      await tester.enterText(find.byType(TextField), 'Biryani');
      await tester.pumpAndSettle();

      expect(find.text('Matching Restaurants'), findsOneWidget);
      expect(find.text('Clear all filters'), findsOneWidget);

      // Search for non-existent restaurant
      await tester.enterText(find.byType(TextField), 'NonExistentDishXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No restaurants match your search'), findsOneWidget);
      expect(find.text('Reset All Filters'), findsOneWidget);

      await tester.tap(find.text('Reset All Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Trending Gourmet Tables'), findsOneWidget);
    });

    testWidgets('City selector bottom sheet switches global city', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DiningScreen(repository: LocalDiningRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap city pill
      await tester.tap(find.text('Hyderabad'));
      await tester.pumpAndSettle();

      expect(find.text('Select Dining City'), findsOneWidget);
      expect(find.text('Bengaluru'), findsOneWidget);

      // Select Bengaluru
      await tester.tap(find.text('Bengaluru'));
      await tester.pumpAndSettle();

      expect(PlazaGlobalState.instance.selectedCity, 'Bengaluru');
      expect(find.text('Bengaluru'), findsWidgets);
    });
  });

  group('Phase 14: Restaurant Details & Menu Experience', () {
    testWidgets('RestaurantDetailsScreen renders cover, details, dishes, and truthful disclaimer', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final restaurant = DiningMockData.restaurants.first;

      await tester.pumpWidget(
        MaterialApp(
          home: RestaurantDetailsScreen(restaurant: restaurant),
        ),
      );
      await tester.pumpAndSettle();

      // Info
      expect(find.text(restaurant.name), findsWidgets);
      expect(find.text(restaurant.tagline), findsOneWidget);
      expect(find.text('About ${restaurant.name}'), findsOneWidget);

      // Dishes
      expect(find.text('Chef’s Recommended Dishes'), findsOneWidget);
      expect(
        find.text('Full digital à la carte menu coming soon to PLAZA Dining. Above dishes are verified house specialties.'),
        findsOneWidget,
      );

      // Reserve Table CTA
      expect(find.text('Reserve Table'), findsOneWidget);
      expect(find.text('Free Reservation'), findsOneWidget);
    });

    testWidgets('Favorite button toggles favorite in PlazaGlobalState', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final restaurant = DiningMockData.restaurants.first;
      final initialFavState = PlazaGlobalState.instance.favoriteIds.contains(restaurant.id);

      await tester.pumpWidget(
        MaterialApp(
          home: RestaurantDetailsScreen(restaurant: restaurant),
        ),
      );
      await tester.pumpAndSettle();

      // Tap favorite button
      final favButton = find.byIcon(initialFavState ? Icons.favorite_rounded : Icons.favorite_border_rounded);
      expect(favButton, findsOneWidget);
      await tester.tap(favButton);
      await tester.pumpAndSettle();

      expect(PlazaGlobalState.instance.favoriteIds.contains(restaurant.id), !initialFavState);
    });
  });

  group('Phase 14: Table Reservation & Digital Pass Flow', () {
    testWidgets('TableReservationScreen renders date, party size, slots, and creates booking', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final restaurant = DiningMockData.restaurants.first;
      final initialBookingsCount = PlazaGlobalState.instance.bookings.length;

      await tester.pumpWidget(
        MaterialApp(
          home: TableReservationScreen(
            restaurant: restaurant,
            repository: const LocalDiningRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step headings
      expect(find.text('1. Select Date'), findsOneWidget);
      expect(find.text('2. Party Size (Number of Guests)'), findsOneWidget);
      expect(find.text('3. Seating Area Preference'), findsOneWidget);
      expect(find.text('4. Available Table Time Slots'), findsOneWidget);
      expect(find.text('5. Contact & Guest Details'), findsOneWidget);

      // Select party size 4
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      // Select Rooftop / Outdoor seating
      await tester.tap(find.text('Outdoor / Rooftop'));
      await tester.pumpAndSettle();

      // Tap Confirm Table
      await tester.tap(find.text('Confirm Table'));
      await tester.pumpAndSettle();

      // Verified navigation to DiningConfirmationScreen
      expect(find.text('Table Reserved!'), findsOneWidget);
      expect(find.text('Show this QR pass to the restaurant host on arrival'), findsOneWidget);
      expect(find.text('Outdoor / Rooftop'), findsWidgets);

      // Verify booking added to PlazaGlobalState
      expect(PlazaGlobalState.instance.bookings.length, initialBookingsCount + 1);
      final latestBooking = PlazaGlobalState.instance.bookings.first;
      expect(latestBooking.type, UnifiedBookingType.dining);
      expect(latestBooking.title, restaurant.name);
      expect(latestBooking.subtitle.contains('4 Guests'), isTrue);
    });

    testWidgets('DiningConfirmationScreen displays digital pass details and QR code', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final restaurant = DiningMockData.restaurants.first;
      final reservation = DiningReservation(
        reservationId: 'RES-TEST-998877',
        restaurant: restaurant,
        date: DateTime.now(),
        timeSlot: '08:30 PM',
        partySize: 3,
        seatingPreference: SeatingPreference.window,
        specialRequest: 'Window table with city skyline view',
        guestName: 'Gopi Ganesh',
        guestPhone: '+91 98765 43210',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DiningConfirmationScreen(reservation: reservation),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Table Reserved!'), findsOneWidget);
      expect(find.text('Reservation ID: RES-TEST-998877'), findsOneWidget);
      expect(find.text('3 Guests'), findsOneWidget);
      expect(find.text('08:30 PM'), findsOneWidget);
      expect(find.text('Window View'), findsWidgets);
      expect(find.text('Special Request: "Window table with city skyline view"'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });
  });

  group('Phase 14: Customer Isolation & Security', () {
    testWidgets('Dining screens contain zero admin controls or administrative actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DiningScreen(repository: LocalDiningRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Confirm no admin words or triggers appear anywhere
      expect(find.text('Admin'), findsNothing);
      expect(find.text('Publish'), findsNothing);
      expect(find.text('Unpublish'), findsNothing);
      expect(find.text('Audit Logs'), findsNothing);
      expect(find.text('Console'), findsNothing);
    });
  });

  group('Phase 14: Production Fallback Safety', () {
    test('ApiDiningRepository rethrows error in production mode when mock data disabled', () async {
      EnvironmentConfig.setEnvironment(AppEnvironment.prod);
      EnvironmentConfig.useMockData = false;

      // Create dummy failing client
      final repo = ApiDiningRepository(
        client: _FailingApiClient(),
        fallback: const LocalDiningRepository(),
      );

      expect(() => repo.getRestaurants(), throwsA(isA<Exception>()));
    });
  });
}

class _FailingApiClient extends ApiClient {
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
