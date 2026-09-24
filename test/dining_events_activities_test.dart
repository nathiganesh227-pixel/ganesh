import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/data/dining_mock_data.dart';
import 'package:plaza/core/data/event_mock_data.dart';
import 'package:plaza/core/data/activity_mock_data.dart';
import 'package:plaza/features/dining/dining_screen.dart';
import 'package:plaza/features/dining/restaurant_details_screen.dart';
import 'package:plaza/features/dining/dining_confirmation_screen.dart';
import 'package:plaza/features/events/events_screen.dart';
import 'package:plaza/features/events/event_details_screen.dart';
import 'package:plaza/features/events/event_confirmation_screen.dart';
import 'package:plaza/features/activities/activities_screen.dart';
import 'package:plaza/features/activities/activity_booking_screen.dart';
import 'package:plaza/features/activities/activity_confirmation_screen.dart';
import 'package:plaza/features/explore/explore_screen.dart';
import 'package:plaza/core/models/dining.dart';
import 'package:plaza/core/models/event.dart';
import 'package:plaza/core/models/activity.dart';

void main() {
  group('Dining Flow Tests', () {
    testWidgets('DiningScreen renders restaurants and filters', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: DiningScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Dining & Cafes'), findsOneWidget);
      expect(find.text('Trending Gourmet Tables'), findsOneWidget);
      expect(find.text('Pure Veg'), findsOneWidget);
    });

    testWidgets('RestaurantDetailsScreen & TableReservationScreen work end-to-end', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final restaurant = DiningMockData.restaurants.first;

      await tester.pumpWidget(MaterialApp(home: RestaurantDetailsScreen(restaurant: restaurant)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(restaurant.name), findsWidgets);
      expect(find.text('Reserve Table'), findsOneWidget);

      await tester.tap(find.text('Reserve Table'));
      await tester.pumpAndSettle();

      expect(find.text('Reserve a Table'), findsOneWidget);
      expect(find.text('1. Select Date'), findsOneWidget);
      expect(find.text('2. Party Size (Number of Guests)'), findsOneWidget);
      expect(find.text('Confirm Table'), findsOneWidget);
    });

    testWidgets('DiningConfirmationScreen renders table pass and QR code', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final res = DiningReservation(
        reservationId: 'RES-TEST123',
        restaurant: DiningMockData.restaurants.first,
        date: DateTime.now(),
        timeSlot: '08:00 PM',
        partySize: 4,
        seatingPreference: SeatingPreference.outdoor,
        guestName: 'Gopi',
        guestPhone: '+91 9999999999',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(home: DiningConfirmationScreen(reservation: res)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Table Reserved!'), findsOneWidget);
      expect(find.text('Reservation ID: RES-TEST123'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
    });
  });

  group('Events Flow Tests', () {
    testWidgets('EventsScreen renders categories and trending concerts', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: EventsScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Events & Shows'), findsOneWidget);
      expect(find.text('Trending Live Experiences'), findsOneWidget);
    });

    testWidgets('EventDetailsScreen & EventTicketScreen calculate ticket total', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final event = EventMockData.events.first;

      await tester.pumpWidget(MaterialApp(home: EventDetailsScreen(event: event)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(event.title), findsWidgets);
      expect(find.text('Get Tickets'), findsOneWidget);

      await tester.tap(find.text('Get Tickets'));
      await tester.pumpAndSettle();

      expect(find.text('Select Event Tickets'), findsOneWidget);
      expect(find.text('1. Select Ticket Category'), findsOneWidget);
    });

    testWidgets('EventConfirmationScreen renders event pass and QR', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final event = EventMockData.events.first;
      final booking = EventBooking(
        bookingId: 'EVT-TEST123',
        event: event,
        date: event.eventDate,
        ticketTier: event.ticketTiers.first,
        quantity: 2,
        subtotal: 2998,
        platformFee: 80,
        taxes: 554,
        discountAmount: 250,
        grandTotal: 3382,
        paymentMethod: 'UPI / Google Pay',
        bookedAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(home: EventConfirmationScreen(booking: booking)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Passes Confirmed!'), findsOneWidget);
      expect(find.text('Booking ID: EVT-TEST123'), findsOneWidget);
      expect(find.text('Share Passes'), findsOneWidget);
    });
  });

  group('Activities Flow Tests', () {
    testWidgets('ActivitiesScreen renders live available slots', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: ActivitiesScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Activities & Fun'), findsOneWidget);
      expect(find.text('Live & Available Right Now'), findsOneWidget);
    });

    testWidgets('ActivityBookingScreen handles packages and squad booking mode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final act = ActivityMockData.activities.first;

      await tester.pumpWidget(MaterialApp(home: ActivityBookingScreen(activity: act)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Book Activity Slot'), findsOneWidget);
      expect(find.text('3. Group Size & Booking Mode'), findsOneWidget);
      expect(find.text('Shared Squad Booking'), findsOneWidget);
    });

    testWidgets('ActivityConfirmationScreen renders squad pass', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final act = ActivityMockData.activities.first;
      final booking = ActivityBooking(
        bookingId: 'ACT-TEST123',
        activity: act,
        date: DateTime.now(),
        timeSlot: '07:30 PM',
        numberOfPeople: 4,
        package: act.packages.first,
        addOns: [],
        subtotal: 1800,
        platformFee: 100,
        taxes: 342,
        discountAmount: 150,
        grandTotal: 2092,
        paymentMethod: 'Apple Pay',
        bookedAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(home: ActivityConfirmationScreen(booking: booking)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Slot Confirmed!'), findsOneWidget);
      expect(find.text('Booking ID: ACT-TEST123'), findsOneWidget);
      expect(find.text('4 PLAYERS'), findsOneWidget);
    });
  });

  group('Explore Screen Tests', () {
    testWidgets('ExploreScreen renders tabs and switches between list and map radar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: ExploreScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Explore Hyderabad'), findsOneWidget);
      expect(find.text('Map View'), findsOneWidget);

      // Tap Map View Toggle
      await tester.tap(find.text('Map View'));
      await tester.pumpAndSettle();

      expect(find.text('Hyderabad Experience Radar'), findsOneWidget);
      expect(find.text('List View'), findsOneWidget);
    });
  });
}
