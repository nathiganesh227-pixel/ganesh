import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/models/booking_quote.dart';
import 'package:plaza/core/widgets/plaza_payment_sheet.dart';
import 'package:plaza/core/repositories/api_booking_repository.dart';
import 'package:plaza/core/repositories/local_booking_repository.dart';
import 'package:plaza/core/network/environment_config.dart';

void main() {
  group('Phase 20: Payments & Booking Hardening Tests', () {
    const testQuote = BookingQuote(
      type: 'movie',
      subtotal: 900.0,
      convenienceFee: 70.0,
      taxes: 45.0,
      grandTotal: 1015.0,
      currency: 'INR',
      breakdown: {
        'seatPrice': 450.0,
        'seatCount': 2,
        'taxRate': '5% GST',
      },
    );

    testWidgets('PlazaPaymentSheet renders server quote breakdown, payment methods and security badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlazaPaymentSheet(
              bookingTitle: 'Kalki 2898 AD',
              bookingSubtitle: 'Prasads IMAX • 2 Seats',
              quote: testQuote,
              bookingId: 'PLZ-MOV-TEST',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header & Security
      expect(find.text('PLAZA SECURE CHECKOUT'), findsOneWidget);
      expect(find.text('Server Authoritative Pricing & 256-bit Encryption'), findsOneWidget);

      // Booking info
      expect(find.text('Kalki 2898 AD'), findsOneWidget);
      expect(find.text('Prasads IMAX • 2 Seats'), findsOneWidget);
      expect(find.text('PLZ-MOV-TEST'), findsOneWidget);

      // Line items breakdown
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('₹900'), findsOneWidget);
      expect(find.text('Convenience Fee'), findsOneWidget);
      expect(find.text('₹70'), findsOneWidget);
      expect(find.text('Taxes & GST'), findsOneWidget);
      expect(find.text('₹45'), findsOneWidget);
      expect(find.text('Total Payable'), findsOneWidget);
      expect(find.text('₹1015'), findsOneWidget);

      // Payment methods
      expect(find.text('UPI Fast'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('NetBanking'), findsOneWidget);

      // Action button
      expect(find.text('Pay ₹1015 ⚡'), findsOneWidget);
    });

    testWidgets('PlazaPaymentSheet switches payment methods on tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlazaPaymentSheet(
              bookingTitle: 'Taj Falaknuma Palace',
              bookingSubtitle: 'Palace Suite • 2 Nights',
              quote: const BookingQuote(
                type: 'stay',
                subtotal: 70000,
                convenienceFee: 0,
                taxes: 8400,
                grandTotal: 78400,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Card
      await tester.tap(find.text('Card'));
      await tester.pumpAndSettle();

      // Select NetBanking
      await tester.tap(find.text('NetBanking'));
      await tester.pumpAndSettle();

      expect(find.text('NetBanking'), findsOneWidget);
    });

    testWidgets('PlazaPaymentSheet locks against double submission and shows verification states', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int submissionCount = 0;
      String? completedRef;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlazaPaymentSheet(
              bookingTitle: 'Hyderabad Rock Fest',
              bookingSubtitle: 'VIP Pass',
              quote: const BookingQuote(
                type: 'event',
                subtotal: 5000,
                convenienceFee: 250,
                taxes: 0,
                grandTotal: 5250,
              ),
              onConfirmPayment: (method) async {
                submissionCount++;
                await Future.delayed(const Duration(milliseconds: 500));
                return true;
              },
              onPaymentSuccess: (ref) {
                completedRef = ref;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // First tap
      await tester.tap(find.byKey(const Key('plaza_payment_sheet_pay_button')));
      await tester.pump(const Duration(milliseconds: 100));

      // Attempt second tap while in-flight
      await tester.tap(find.byKey(const Key('plaza_payment_sheet_pay_button')));
      await tester.pump(const Duration(milliseconds: 300));

      // Check verifying text
      expect(find.text('Verifying Payment Signature...'), findsOneWidget);

      // Finish flow
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Only one submission occurred
      expect(submissionCount, 1);
      expect(completedRef, isNotNull);
      expect(completedRef!.startsWith('PAY_RZP_'), isTrue);
    });

    testWidgets('PlazaPaymentSheet displays error banner and allows retry when payment verification fails', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int callAttempts = 0;
      String? reportedError;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlazaPaymentSheet(
              bookingTitle: 'Go-Karting Adventure',
              bookingSubtitle: 'Pro Laps',
              quote: const BookingQuote(
                type: 'activity',
                subtotal: 3000,
                convenienceFee: 0,
                taxes: 540,
                grandTotal: 3540,
              ),
              onConfirmPayment: (method) async {
                callAttempts++;
                if (callAttempts == 1) {
                  return false; // First attempt fails
                }
                return true; // Second attempt succeeds
              },
              onPaymentFailed: (err) {
                reportedError = err;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pay
      await tester.tap(find.byKey(const Key('plaza_payment_sheet_pay_button')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Error message is displayed
      expect(find.text('Payment signature verification failed. Please try again.'), findsOneWidget);
      expect(reportedError, isNotNull);

      // Retry tap
      await tester.tap(find.byKey(const Key('plaza_payment_sheet_pay_button')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(callAttempts, 2);
    });

    test('LocalBookingRepository calculates server quote for Stays with 12% GST', () async {
      const repo = LocalBookingRepository();
      final quote = await repo.getQuote(
        type: 'stay',
        payload: {
          'nights': 2,
          'roomsCount': 1,
        },
      );

      expect(quote, isNotNull);
      expect(quote!.type, 'stay');
      // 3500 * 2 = 7000, 12% GST = 840 => 7840
      expect(quote.subtotal, 7000.0);
      expect(quote.taxes, 840.0);
      expect(quote.grandTotal, 7840.0);
    });

    test('ApiBookingRepository rethrows error in production mode when mock data is disabled', () async {
      EnvironmentConfig.setEnvironment(AppEnvironment.prod);
      EnvironmentConfig.useMockData = false;
      addTearDown(EnvironmentConfig.reset);

      final repo = ApiBookingRepository();

      // In production mode with invalid base url, getQuote should rethrow
      expect(
        () async => await repo.getQuote(type: 'invalid_prod_type', payload: {}),
        throwsA(anything),
      );
    });
  });
}
