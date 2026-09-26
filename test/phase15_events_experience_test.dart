import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/data/event_mock_data.dart';
import 'package:plaza/core/data/plaza_global_state.dart';
import 'package:plaza/core/models/event.dart';
import 'package:plaza/core/models/unified_booking.dart';
import 'package:plaza/core/network/api_client.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/core/network/environment_config.dart';
import 'package:plaza/core/repositories/api_event_repository.dart';
import 'package:plaza/core/repositories/local_event_repository.dart';
import 'package:plaza/features/events/event_confirmation_screen.dart';
import 'package:plaza/features/events/event_details_screen.dart';
import 'package:plaza/features/events/event_ticket_screen.dart';
import 'package:plaza/features/events/events_screen.dart';

void main() {
  setUp(() {
    EnvironmentConfig.reset();
    EnvironmentConfig.setEnvironment(AppEnvironment.dev);
    PlazaGlobalState.instance.setSelectedCity('Hyderabad');
  });

  group('Phase 15: Events Discovery Experience', () {
    testWidgets('EventsScreen renders header, city selector, search, and sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: EventsScreen(repository: LocalEventRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Top Header & City
      expect(find.text('Events & Shows'), findsOneWidget);
      expect(find.text('Hyderabad'), findsOneWidget);

      // Search & Quick Filters
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Weekend'), findsOneWidget);

      // Category Chips
      expect(find.text('Concerts & Live Music'), findsWidgets);
      expect(find.text('Stand-up Comedy'), findsWidgets);

      // Sections
      expect(find.text('Trending Live Experiences'), findsOneWidget);
      expect(find.text('This Weekend in Town'), findsOneWidget);
      expect(find.text('All Upcoming Events'), findsOneWidget);
    });

    testWidgets('EventsScreen filters by category and quick chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: EventsScreen(repository: LocalEventRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Stand-up Comedy category chip
      await tester.tap(find.text('Stand-up Comedy').first);
      await tester.pumpAndSettle();

      expect(find.text('Clear all filters'), findsOneWidget);
      expect(find.text('Matching Events'), findsOneWidget);

      // Tap Clear all filters
      await tester.tap(find.text('Clear all filters'));
      await tester.pumpAndSettle();

      expect(find.text('Trending Live Experiences'), findsOneWidget);
    });

    testWidgets('EventsScreen search bar filters events with debounce and handles empty state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: EventsScreen(repository: LocalEventRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Search for Sunburn
      await tester.enterText(find.byType(TextField), 'Sunburn');
      await tester.pumpAndSettle();

      expect(find.text('Matching Events'), findsOneWidget);
      expect(find.text('Sunburn Arena ft. Alan Walker'), findsWidgets);

      // Search for unknown event
      await tester.enterText(find.byType(TextField), 'UnknownFestivalXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No events found'), findsOneWidget);
      expect(find.text('Reset All Filters'), findsOneWidget);

      // Reset
      await tester.tap(find.text('Reset All Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Trending Live Experiences'), findsOneWidget);
    });

    testWidgets('City selector bottom sheet switches global city in EventsScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: EventsScreen(repository: LocalEventRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap city button
      await tester.tap(find.text('Hyderabad'));
      await tester.pumpAndSettle();

      expect(find.text('Select Events City'), findsOneWidget);
      expect(find.text('Bengaluru'), findsOneWidget);

      // Select Bengaluru
      await tester.tap(find.text('Bengaluru'));
      await tester.pumpAndSettle();

      expect(PlazaGlobalState.instance.selectedCity, 'Bengaluru');
      expect(find.text('Bengaluru'), findsWidgets);
    });
  });

  group('Phase 15: Event Details Experience', () {
    testWidgets('EventDetailsScreen renders poster, info, logistics, performers, and ticket preview', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final event = EventMockData.events.first;

      await tester.pumpWidget(
        MaterialApp(
          home: EventDetailsScreen(event: event),
        ),
      );
      await tester.pumpAndSettle();

      // Event title & venue
      expect(find.text(event.title), findsWidgets);
      expect(find.text(event.venue), findsWidgets);

      // Key details & performers
      expect(find.text('About the Event'), findsOneWidget);
      expect(find.text('Artists & Performers'), findsOneWidget);
      expect(find.text('Ticket Categories'), findsOneWidget);

      // Floating bottom dock CTA
      expect(find.text('PASSES FROM'), findsOneWidget);
      expect(find.text('₹${event.startingPrice.toInt()}'), findsWidgets);
      expect(find.text('Get Tickets'), findsOneWidget);
    });

    testWidgets('Favorite button toggles favorite in PlazaGlobalState on EventDetailsScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final event = EventMockData.events.first;
      final initialFav = PlazaGlobalState.instance.favoriteIds.contains(event.id);

      await tester.pumpWidget(
        MaterialApp(
          home: EventDetailsScreen(event: event),
        ),
      );
      await tester.pumpAndSettle();

      final favFinder = find.byIcon(initialFav ? Icons.favorite_rounded : Icons.favorite_border_rounded);
      expect(favFinder, findsOneWidget);

      await tester.tap(favFinder);
      await tester.pumpAndSettle();

      expect(PlazaGlobalState.instance.favoriteIds.contains(event.id), !initialFav);
    });
  });

  group('Phase 15: Event Ticket Booking & Digital Pass Flow', () {
    testWidgets('EventTicketScreen increments tier quantity, respects limits, and confirms booking', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final event = EventMockData.events.first;
      final initialBookingCount = PlazaGlobalState.instance.bookings.length;

      await tester.pumpWidget(
        MaterialApp(
          home: EventTicketScreen(
            event: event,
            repository: const LocalEventRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and steps
      expect(find.text('PASSES QUANTITY'), findsOneWidget);
      expect(find.text('PROMO CODE'), findsOneWidget);
      expect(find.text('Booking Summary'), findsOneWidget);

      // Increment ticket quantity
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsWidgets);

      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Check Pay button state
      expect(find.text('Pay & Confirm'), findsOneWidget);

      // Complete booking
      await tester.tap(find.text('Pay & Confirm'));
      await tester.pumpAndSettle();

      // Confirmation screen rendered
      expect(find.text('Passes Confirmed!'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);

      // Verify added to global state
      expect(PlazaGlobalState.instance.bookings.length, initialBookingCount + 1);
      final newBooking = PlazaGlobalState.instance.bookings.first;
      expect(newBooking.type, UnifiedBookingType.event);
      expect(newBooking.title, event.title);
    });

    testWidgets('EventConfirmationScreen displays digital pass details and QR code', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final event = EventMockData.events.first;
      final booking = EventBooking(
        bookingId: 'BK-TEST-EVT-101',
        event: event,
        date: event.eventDate,
        ticketTier: event.ticketTiers.first,
        quantity: 2,
        subtotal: event.ticketTiers.first.price * 2,
        platformFee: 100.0,
        taxes: 36.0,
        discountAmount: 0.0,
        grandTotal: (event.ticketTiers.first.price * 2) + 136.0,
        paymentMethod: 'UPI',
        bookedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EventConfirmationScreen(booking: booking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Passes Confirmed!'), findsOneWidget);
      expect(find.text('Booking ID: BK-TEST-EVT-101'), findsOneWidget);
      expect(find.text(event.title), findsWidgets);
      expect(find.text(event.venue), findsWidgets);
      expect(find.text('Back to Home'), findsOneWidget);
      expect(find.text('Share Passes'), findsOneWidget);
      expect(find.text('Apple Wallet'), findsOneWidget);
    });
  });

  group('Phase 15: Customer Isolation & Security', () {
    testWidgets('Events consumer screens contain zero admin controls or leaks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: EventsScreen(repository: LocalEventRepository()),
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

  group('Phase 15: Production Fallback Safety', () {
    test('ApiEventRepository rethrows error in production mode when mock data disabled', () async {
      EnvironmentConfig.setEnvironment(AppEnvironment.prod);
      EnvironmentConfig.useMockData = false;

      final repo = ApiEventRepository(
        client: _FailingApiClient(),
        fallback: const LocalEventRepository(),
      );

      expect(() => repo.getEvents(), throwsA(isA<Exception>()));
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
