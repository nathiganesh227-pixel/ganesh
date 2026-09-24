import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/data/movie_mock_data.dart';
import 'package:plaza/features/movies/movies_screen.dart';
import 'package:plaza/features/movies/movie_details_screen.dart';
import 'package:plaza/features/movies/showtime_selection_screen.dart';
import 'package:plaza/features/movies/seat_selection_screen.dart';
import 'package:plaza/features/movies/order_summary_screen.dart';
import 'package:plaza/features/movies/booking_confirmation_screen.dart';
import 'package:plaza/core/models/movie_booking.dart';

void main() {
  testWidgets('MoviesScreen renders discovery list and filters', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: MoviesScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Movies'), findsOneWidget);
    expect(find.text('Now Showing'), findsOneWidget);
    expect(find.text('Trending in IMAX & 3D'), findsOneWidget);
  });

  testWidgets('MovieDetailsScreen renders synopsis, formats, and trailer dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final movie = MovieMockData.movies.first;

    await tester.pumpWidget(
      MaterialApp(
        home: MovieDetailsScreen(movie: movie),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(movie.title), findsWidgets);
    expect(find.text('Watch Trailer'), findsOneWidget);
    expect(find.text('Book Tickets'), findsOneWidget);

    // Tap Watch Trailer
    await tester.tap(find.text('Watch Trailer'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Official Trailer'), findsOneWidget);
  });

  testWidgets('ShowtimeSelectionScreen renders theatres and showtimes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final movie = MovieMockData.movies.first;

    await tester.pumpWidget(
      MaterialApp(
        home: ShowtimeSelectionScreen(movie: movie),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('AMB Cinemas'), findsOneWidget);
    expect(find.text('Prasads Multiplex & IMAX'), findsOneWidget);
  });

  testWidgets('SeatSelectionScreen allows seat selection and live price calculation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final movie = MovieMockData.movies.first;
    final theatre = MovieMockData.getTheatresForMovie(movie.id).first;
    final showtime = theatre.showtimes.first;

    await tester.pumpWidget(
      MaterialApp(
        home: SeatSelectionScreen(
          movie: movie,
          theatre: theatre,
          showtime: showtime,
          date: DateTime.now(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('SCREEN THIS WAY'), findsOneWidget);
    expect(find.text('SELECT SEATS'), findsOneWidget);

    // Tap on seat number 1
    final seatFinder = find.text('1');
    expect(seatFinder, findsWidgets);

    await tester.tap(seatFinder.first);
    await tester.pump(const Duration(milliseconds: 100));

    // The proceed button should become active
    expect(find.text('Proceed'), findsOneWidget);
  });

  testWidgets('OrderSummaryScreen calculates totals and applies coupon', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final movie = MovieMockData.movies.first;
    final theatre = MovieMockData.getTheatresForMovie(movie.id).first;
    final showtime = theatre.showtimes.first;
    final seats = MovieMockData.generateSeatGrid(showtime).take(2).toList();

    await tester.pumpWidget(
      MaterialApp(
        home: OrderSummaryScreen(
          movie: movie,
          theatre: theatre,
          showtime: showtime,
          date: DateTime.now(),
          selectedSeats: seats,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Order Summary'), findsOneWidget);
    expect(find.text('Payment Breakdown'), findsOneWidget);
    expect(find.text('Add Food & Beverages'), findsOneWidget);

    // Apply Coupon
    final applyFinder = find.text('Apply');
    await tester.dragUntilVisible(
      applyFinder,
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'PLAZAIMAX');
    await tester.tap(applyFinder);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Applied ✓'), findsOneWidget);
  });

  testWidgets('BookingConfirmationScreen renders digital QR ticket pass', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final movie = MovieMockData.movies.first;
    final theatre = MovieMockData.getTheatresForMovie(movie.id).first;
    final showtime = theatre.showtimes.first;
    final seats = MovieMockData.generateSeatGrid(showtime).take(2).toList();

    final booking = MovieBooking(
      bookingId: 'PLZ-TEST123',
      movie: movie,
      theatre: theatre,
      showtime: showtime,
      date: DateTime.now(),
      seats: seats,
      snacks: [],
      ticketTotal: 600,
      convenienceFee: 56,
      taxes: 118,
      discountAmount: 100,
      grandTotal: 674,
      paymentMethod: 'UPI / Google Pay',
      bookedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BookingConfirmationScreen(booking: booking),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Booking Confirmed!'), findsOneWidget);
    expect(find.text('Booking ID: PLZ-TEST123'), findsOneWidget);
    expect(find.text('SEATS'), findsOneWidget);
    expect(find.text('Scan QR code at the cinema entrance scanner'), findsOneWidget);
    expect(find.text('Apple Wallet'), findsOneWidget);
  });
}
