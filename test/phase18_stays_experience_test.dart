import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/data/plaza_global_state.dart';
import 'package:plaza/core/data/stay_mock_data.dart';
import 'package:plaza/core/models/stay.dart';
import 'package:plaza/core/models/unified_booking.dart';
import 'package:plaza/core/network/api_client.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/core/network/environment_config.dart';
import 'package:plaza/core/repositories/api_stay_repository.dart';
import 'package:plaza/core/repositories/local_stay_repository.dart';
import 'package:plaza/features/stays/hotel_confirmation_screen.dart';
import 'package:plaza/features/stays/hotel_details_screen.dart';
import 'package:plaza/features/stays/room_booking_screen.dart';
import 'package:plaza/features/stays/stays_screen.dart';
import 'package:plaza/features/stays/widgets/stay_card.dart';

void main() {
  setUp(() {
    EnvironmentConfig.reset();
    EnvironmentConfig.setEnvironment(AppEnvironment.dev);
    PlazaGlobalState.instance.setSelectedCity('Hyderabad');
  });

  group('Phase 18: Stays Discovery Experience', () {
    testWidgets('StaysScreen renders header, city selector, search, and sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: StaysScreen(repository: LocalStayRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Top Header & City
      expect(find.text('Stays & Luxury Escapes'), findsOneWidget);
      expect(find.text('HYDERABAD'), findsOneWidget);

      // Search & Quick Filters
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('Favorites'), findsOneWidget);
      expect(find.textContaining('Featured'), findsOneWidget);
      expect(find.text('All Stays'), findsOneWidget);

      // Categories
      expect(find.textContaining('Luxury'), findsWidgets);
      expect(find.textContaining('Resorts'), findsWidgets);

      // Signature Carousel & Curated List
      expect(find.text('Signature Palaces & 5★ Stays 👑'), findsOneWidget);
      expect(find.textContaining('All Curated Stays in Hyderabad'), findsOneWidget);
    });

    testWidgets('StaysScreen filters by category and quick chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: StaysScreen(repository: LocalStayRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Filter by Resorts
      final resortChip = find.textContaining('Resorts').first;
      await tester.tap(resortChip);
      await tester.pumpAndSettle();

      expect(find.textContaining('Resorts & Spas'), findsWidgets);

      // Reset category filter by tapping All Stays
      await tester.tap(find.text('All Stays'));
      await tester.pumpAndSettle();

      // Tap on Featured quick filter
      await tester.tap(find.textContaining('Featured'));
      await tester.pumpAndSettle();

      expect(find.byType(StayCard), findsWidgets);
    });

    testWidgets('StaysScreen search bar filters stays with debounce and handles empty state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: StaysScreen(repository: LocalStayRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Search for Falaknuma
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Falaknuma');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Taj Falaknuma Palace'), findsWidgets);

      // Search for non-existing stay
      await tester.enterText(searchField, 'NonExistentHotelXYZ');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('No Stays Found'), findsOneWidget);
      expect(find.text('Reset All Filters'), findsOneWidget);

      // Reset filters
      await tester.tap(find.text('Reset All Filters'));
      await tester.pumpAndSettle();

      expect(find.text('No Stays Found'), findsNothing);
      expect(find.text('Taj Falaknuma Palace'), findsWidgets);
    });

    testWidgets('City selector bottom sheet switches global city in StaysScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: StaysScreen(repository: LocalStayRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on City Header
      await tester.tap(find.text('HYDERABAD'));
      await tester.pumpAndSettle();

      // Bottom sheet should be visible
      expect(find.text('Select Stays City'), findsOneWidget);
      expect(find.text('Bengaluru'), findsOneWidget);

      // Select Bengaluru
      await tester.tap(find.text('Bengaluru'));
      await tester.pumpAndSettle();

      // Global state must be updated
      expect(PlazaGlobalState.instance.selectedCity, 'Bengaluru');
      expect(find.text('BENGALURU'), findsOneWidget);
    });
  });

  group('Phase 18: Hotel Details & Room Selection Experience', () {
    final testHotel = StayMockData.hotels.first;

    testWidgets('HotelDetailsScreen renders hero gallery, info, amenities, and room cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: HotelDetailsScreen(hotel: testHotel),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(testHotel.name), findsOneWidget);
      expect(find.text(testHotel.tagline), findsOneWidget);
      expect(find.text('World-Class Amenities'), findsOneWidget);
      expect(find.text('Select Your Room'), findsOneWidget);
      expect(find.text(testHotel.roomTypes.first.name), findsWidgets);
      expect(find.text('Select Room 🏨'), findsOneWidget);
    });

    testWidgets('Favorite button toggles favorite in PlazaGlobalState on HotelDetailsScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final hotelId = testHotel.id;
      final initialFav = PlazaGlobalState.instance.favoriteIds.contains(hotelId);

      await tester.pumpWidget(
        MaterialApp(
          home: HotelDetailsScreen(hotel: testHotel),
        ),
      );
      await tester.pumpAndSettle();

      // Tap favorite button in SliverAppBar
      final favFinder = find.byIcon(
        initialFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      );
      expect(favFinder, findsOneWidget);

      await tester.tap(favFinder);
      await tester.pumpAndSettle();

      expect(PlazaGlobalState.instance.favoriteIds.contains(hotelId), !initialFav);
    });
  });

  group('Phase 18: Room Booking & Digital Stay Pass Flow', () {
    final testHotel = StayMockData.hotels.first;
    final testRoom = testHotel.roomTypes.first;

    testWidgets('RoomBookingScreen displays dates, room selection, add-ons, and calculates server price', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: RoomBookingScreen(
            hotel: testHotel,
            initialRoom: testRoom,
            repository: const LocalStayRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stay Duration & Dates'), findsOneWidget);
      expect(find.text('Selected Room Type'), findsOneWidget);
      expect(find.text('Primary Guest Information'), findsOneWidget);
      expect(find.text('Book Stay 🏨'), findsOneWidget);

      // Verify initial price calculations
      expect(find.text('Luxury & Hospitality GST (18%)'), findsOneWidget);
      expect(find.text('Grand Total'), findsOneWidget);
    });

    testWidgets('RoomBookingScreen books stay and navigates to HotelConfirmationScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final initialBookingsCount = PlazaGlobalState.instance.bookings.length;

      await tester.pumpWidget(
        MaterialApp(
          home: RoomBookingScreen(
            hotel: testHotel,
            initialRoom: testRoom,
            repository: const LocalStayRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Book Stay button
      final bookBtn = find.text('Book Stay 🏨');
      expect(bookBtn, findsOneWidget);

      await tester.tap(bookBtn);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Must be on HotelConfirmationScreen
      expect(find.text('Stay Reserved!'), findsOneWidget);
      expect(find.text('Payment Status'), findsOneWidget);
      expect(find.text('Pay at Check-in / Pending Verification'), findsOneWidget);
      expect(find.text('Apple Wallet'), findsOneWidget);
      expect(find.text('Share Pass'), findsOneWidget);

      // Global state must contain new booking
      expect(PlazaGlobalState.instance.bookings.length, initialBookingsCount + 1);
      final latest = PlazaGlobalState.instance.bookings.first;
      expect(latest.type, UnifiedBookingType.stay);
      expect(latest.title, testHotel.name);
      expect(latest.status, BookingStatus.upcoming);
    });

    testWidgets('HotelConfirmationScreen renders Apple Wallet style pass with QR code and truthful payment status', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dummyBooking = HotelBooking(
        bookingId: 'PLZ-STY-999888',
        hotel: testHotel,
        roomType: testRoom,
        checkInDate: DateTime.now().add(const Duration(days: 2)),
        checkOutDate: DateTime.now().add(const Duration(days: 4)),
        nights: 2,
        guestsCount: 2,
        roomsCount: 1,
        selectedAddOns: const [],
        roomTotal: 97000.0,
        addOnsTotal: 0.0,
        taxesAndFees: 17460.0,
        grandTotal: 114460.0,
        guestName: 'Gopi Ganesh',
        guestEmail: 'gopi.ganesh@plaza.club',
        guestPhone: '+91 98765 43210',
        specialRequests: 'High floor corner suite',
        qrCodeData: 'PLAZA://STAY/PLZ-STY-999888/${testHotel.id}',
        paymentMethod: 'Pay at Check-in',
        bookingTime: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HotelConfirmationScreen(booking: dummyBooking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stay Reserved!'), findsOneWidget);
      expect(find.text('PLZ-STY-999888'), findsOneWidget);
      expect(find.text('Payment Status'), findsOneWidget);
      expect(find.text('Pay at Check-in / Pending Verification'), findsOneWidget);
      expect(find.text('Estimated Payable Amount'), findsOneWidget);
      expect(find.text('₹114460'), findsOneWidget);
      expect(find.text('PRESENT AT FRONT DESK FOR EXPRESS CHECK-IN'), findsOneWidget);
      expect(find.text('Apple Wallet'), findsOneWidget);
      expect(find.text('Share Pass'), findsOneWidget);
    });
  });

  group('Phase 18: Customer Isolation & Security', () {
    testWidgets('Stays consumer screens contain zero admin controls or leaks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: StaysScreen(repository: LocalStayRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin'), findsNothing);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Unpublished'), findsNothing);
      expect(find.text('Delete Hotel'), findsNothing);
    });
  });

  group('Phase 18: Production Fallback Safety', () {
    test('ApiStayRepository rethrows error in production mode when mock data disabled', () async {
      EnvironmentConfig.setEnvironment(AppEnvironment.prod);
      EnvironmentConfig.useMockData = false;

      final failingClient = MockFailingApiClient();
      final repo = ApiStayRepository(
        client: failingClient,
        fallback: const LocalStayRepository(),
      );

      expect(
        () async => await repo.getHotels(),
        throwsA(isA<Exception>()),
      );
    });
  });
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
