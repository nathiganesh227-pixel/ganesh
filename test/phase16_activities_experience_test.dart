import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/data/activity_mock_data.dart';
import 'package:plaza/core/data/plaza_global_state.dart';
import 'package:plaza/core/models/activity.dart';
import 'package:plaza/core/models/unified_booking.dart';
import 'package:plaza/core/network/api_client.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/core/network/environment_config.dart';
import 'package:plaza/core/repositories/api_activity_repository.dart';
import 'package:plaza/core/repositories/local_activity_repository.dart';
import 'package:plaza/features/activities/activities_screen.dart';
import 'package:plaza/features/activities/activity_booking_screen.dart';
import 'package:plaza/features/activities/activity_confirmation_screen.dart';
import 'package:plaza/features/activities/activity_details_screen.dart';

void main() {
  setUp(() {
    EnvironmentConfig.reset();
    EnvironmentConfig.setEnvironment(AppEnvironment.dev);
    PlazaGlobalState.instance.setSelectedCity('Hyderabad');
  });

  group('Phase 16: Activities Discovery Experience', () {
    testWidgets('ActivitiesScreen renders header, city selector, search, and sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ActivitiesScreen(repository: LocalActivityRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Top Header & City
      expect(find.text('Activities & Fun'), findsOneWidget);
      expect(find.text('Hyderabad'), findsOneWidget);

      // Search & Quick Filters
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Available Now'), findsOneWidget);
      expect(find.text('Squad Picks'), findsOneWidget);

      // Category Chips
      expect(find.text('Bowling'), findsWidgets);
      expect(find.text('Go-Karting'), findsWidgets);

      // Sections
      expect(find.text('FEATURED ARENA'), findsOneWidget);
      expect(find.text('Live & Available Right Now'), findsOneWidget);
      expect(find.text('Trending Squad Picks'), findsOneWidget);
      expect(find.text('All Activities Near You'), findsOneWidget);
    });

    testWidgets('ActivitiesScreen filters by category and quick chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ActivitiesScreen(repository: LocalActivityRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Go-Karting category chip
      await tester.tap(find.text('Go-Karting').first);
      await tester.pumpAndSettle();

      expect(find.text('Clear all filters'), findsOneWidget);
      expect(find.text('Matching Activities'), findsOneWidget);

      // Tap Clear all filters
      await tester.tap(find.text('Clear all filters'));
      await tester.pumpAndSettle();

      expect(find.text('Live & Available Right Now'), findsOneWidget);
    });

    testWidgets('ActivitiesScreen search bar filters activities with debounce and handles empty state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ActivitiesScreen(repository: LocalActivityRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Search for Bowling
      await tester.enterText(find.byType(TextField), 'Bowling');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Matching Activities'), findsOneWidget);
      expect(find.text('Smaaash Cosmic Bowling & VR Zone'), findsWidgets);

      // Search for unknown activity
      await tester.enterText(find.byType(TextField), 'UnknownExtremeSportXYZ');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('No activities found'), findsOneWidget);
      expect(find.text('Reset All Filters'), findsOneWidget);

      // Reset
      await tester.tap(find.text('Reset All Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Live & Available Right Now'), findsOneWidget);
    });

    testWidgets('City selector bottom sheet switches global city in ActivitiesScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ActivitiesScreen(repository: LocalActivityRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap city button
      await tester.tap(find.text('Hyderabad'));
      await tester.pumpAndSettle();

      expect(find.text('Select Activities City'), findsOneWidget);
      expect(find.text('Bengaluru'), findsOneWidget);

      // Select Bengaluru
      await tester.tap(find.text('Bengaluru'));
      await tester.pumpAndSettle();

      expect(PlazaGlobalState.instance.selectedCity, 'Bengaluru');
      expect(find.text('Bengaluru'), findsWidgets);
    });
  });

  group('Phase 16: Activity Details Experience', () {
    testWidgets('ActivityDetailsScreen renders banner, logistics, what is included, slots, and packages', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final activity = ActivityMockData.activities.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityDetailsScreen(activity: activity),
        ),
      );
      await tester.pumpAndSettle();

      // Activity title & venue
      expect(find.text(activity.title), findsWidgets);
      expect(find.text(activity.venueName), findsWidgets);

      // Logistics & overview
      expect(find.text('Directions'), findsOneWidget);
      expect(find.text('About the Experience'), findsOneWidget);
      expect(find.text('What’s Included in Booking'), findsOneWidget);
      expect(find.text('Live Session Slots'), findsOneWidget);
      expect(find.text('Available Packages'), findsOneWidget);

      // Floating bottom dock CTA
      expect(find.text('SLOTS FROM'), findsOneWidget);
      expect(find.text('₹${activity.startingPrice.toInt()}'), findsWidgets);
      expect(find.text('Book Activity'), findsOneWidget);
    });

    testWidgets('Favorite button toggles favorite in PlazaGlobalState on ActivityDetailsScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final activity = ActivityMockData.activities.first;
      final initialFav = PlazaGlobalState.instance.favoriteIds.contains(activity.id);

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityDetailsScreen(activity: activity),
        ),
      );
      await tester.pumpAndSettle();

      final favFinder = find.byIcon(initialFav ? Icons.favorite_rounded : Icons.favorite_border_rounded);
      expect(favFinder, findsOneWidget);

      await tester.tap(favFinder);
      await tester.pumpAndSettle();

      expect(PlazaGlobalState.instance.favoriteIds.contains(activity.id), !initialFav);
    });
  });

  group('Phase 16: Activity Booking & Digital Pass Flow', () {
    testWidgets('ActivityBookingScreen handles slots, group size limits, add-ons, coupon, and completes booking', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final activity = ActivityMockData.activities.first;
      final initialBookingCount = PlazaGlobalState.instance.bookings.length;

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityBookingScreen(
            activity: activity,
            repository: const LocalActivityRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check step headers
      expect(find.text('Book Activity Slot'), findsOneWidget);
      expect(find.text('1. Select Date'), findsOneWidget);
      expect(find.text('2. Select Slot Time'), findsOneWidget);
      expect(find.text('3. Group Size & Booking Mode'), findsOneWidget);
      expect(find.text('Shared Squad Booking'), findsOneWidget);
      expect(find.text('4. Choose Package'), findsOneWidget);
      expect(find.text('5. Optional Add-ons'), findsOneWidget);
      expect(find.text('Payment Breakdown'), findsOneWidget);

      // Increment group size
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsWidgets);

      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Apply coupon code
      await tester.enterText(find.byType(TextField), 'PLAZASQUAD');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Applied ✓'), findsOneWidget);

      // Pay & confirm
      final payButton = find.textContaining('Pay ₹');
      expect(payButton, findsOneWidget);
      await tester.tap(payButton);
      await tester.pumpAndSettle();

      // Confirmation screen rendered
      expect(find.text('Slot Confirmed!'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);

      // Verify added to global state
      expect(PlazaGlobalState.instance.bookings.length, initialBookingCount + 1);
      final newBooking = PlazaGlobalState.instance.bookings.first;
      expect(newBooking.type, UnifiedBookingType.activity);
      expect(newBooking.title, activity.title);
    });

    testWidgets('ActivityConfirmationScreen displays digital squad pass and QR code', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final activity = ActivityMockData.activities.first;
      final booking = ActivityBooking(
        bookingId: 'ACT-TEST-9988',
        activity: activity,
        date: DateTime.now(),
        timeSlot: '07:30 PM',
        numberOfPeople: 4,
        package: activity.packages.first,
        addOns: [],
        subtotal: 1800.0,
        platformFee: 100.0,
        taxes: 342.0,
        discountAmount: 150.0,
        grandTotal: 2092.0,
        paymentMethod: 'UPI',
        isSharedGroupBooking: true,
        bookedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ActivityConfirmationScreen(booking: booking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Slot Confirmed!'), findsOneWidget);
      expect(find.text('Booking ID: ACT-TEST-9988'), findsOneWidget);
      expect(find.text(activity.title), findsWidgets);
      expect(find.text('Back to Home'), findsOneWidget);
      expect(find.text('Share Passes'), findsOneWidget);
      expect(find.text('Apple Wallet'), findsOneWidget);
    });
  });

  group('Phase 16: Customer Isolation & Security', () {
    testWidgets('Activities consumer screens contain zero admin controls or leaks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ActivitiesScreen(repository: LocalActivityRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no admin keywords or controls leaked
      expect(find.text('Admin'), findsNothing);
      expect(find.text('Publish'), findsNothing);
      expect(find.text('Unpublish'), findsNothing);
      expect(find.text('Audit Logs'), findsNothing);
      expect(find.text('Console'), findsNothing);
    });
  });

  group('Phase 16: Production Fallback Safety', () {
    test('ApiActivityRepository rethrows error in production mode when mock data disabled', () async {
      EnvironmentConfig.setEnvironment(AppEnvironment.prod);
      EnvironmentConfig.useMockData = false;

      final repo = ApiActivityRepository(
        client: _FailingApiClient(),
        fallback: const LocalActivityRepository(),
      );

      expect(() => repo.getActivities(), throwsA(isA<Exception>()));
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
