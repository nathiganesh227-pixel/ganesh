import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/models/booking_quote.dart';
import 'package:plaza/core/models/unified_booking.dart';
import 'package:plaza/core/widgets/plaza_payment_sheet.dart';

void main() {
  group('Phase 24: Real Booking & Order Completion Flutter Tests', () {
    test('BookingQuote.fromJson parses canonical quoteId, expiresAt, rewards, and flex keys', () {
      final json = {
        'quoteId': 'QUO_1790600000_xyz',
        'expiresAt': '2026-10-15T12:15:00.000Z',
        'type': 'movie',
        'subtotal': 900,
        'discount': 50,
        'fees': 70,
        'tax': 45,
        'total': 965,
        'rewardsUsed': 50,
        'rewardsEarned': 96,
        'currency': 'INR',
        'breakdown': {
          'seatPrice': 450,
          'seatCount': 2,
          'taxRate': '5% GST',
        },
      };

      final quote = BookingQuote.fromJson(json);

      expect(quote.quoteId, 'QUO_1790600000_xyz');
      expect(quote.expiresAt, '2026-10-15T12:15:00.000Z');
      expect(quote.type, 'movie');
      expect(quote.subtotal, 900.0);
      expect(quote.discount, 50.0);
      expect(quote.convenienceFee, 70.0);
      expect(quote.taxes, 45.0);
      expect(quote.grandTotal, 965.0);
      expect(quote.rewardsUsed, 50);
      expect(quote.rewardsEarned, 96);
      expect(quote.currency, 'INR');

      final serialized = quote.toJson();
      expect(serialized['quoteId'], 'QUO_1790600000_xyz');
      expect(serialized['expiresAt'], '2026-10-15T12:15:00.000Z');
      expect(serialized['grandTotal'], 965.0);
      expect(serialized['rewardsEarned'], 96);
    });

    test('UnifiedBooking parses all 7 vertical booking types with QR code pass and totalAmount', () {
      final verticals = [
        {
          'type': 'movie',
          'expectedType': UnifiedBookingType.movie,
          'id': 'PLZ-MOV-101',
          'qrCodeData': 'QR-MOV-PLZ-MOV-101',
        },
        {
          'type': 'dining',
          'expectedType': UnifiedBookingType.dining,
          'id': 'PLZ-DIN-102',
          'qrCodeData': 'QR-DIN-PLZ-DIN-102',
        },
        {
          'type': 'sports',
          'expectedType': UnifiedBookingType.sports,
          'id': 'PLZ-SPT-103',
          'qrCodeData': 'QR-SPT-PLZ-SPT-103',
        },
        {
          'type': 'event',
          'expectedType': UnifiedBookingType.event,
          'id': 'PLZ-EVT-104',
          'qrCodeData': 'QR-EVT-PLZ-EVT-104',
        },
        {
          'type': 'activity',
          'expectedType': UnifiedBookingType.activity,
          'id': 'PLZ-ACT-105',
          'qrCodeData': 'QR-ACT-PLZ-ACT-105',
        },
        {
          'type': 'stay',
          'expectedType': UnifiedBookingType.stay,
          'id': 'PLZ-STY-106',
          'qrCodeData': 'QR-STY-PLZ-STY-106',
        },
        {
          'type': 'shopping',
          'expectedType': UnifiedBookingType.shopping,
          'id': 'ORD-PLZ-107',
          'qrCodeData': 'QR-ORD-PLZ-107',
        },
      ];

      for (final v in verticals) {
        final booking = UnifiedBooking.fromJson({
          'id': v['id'],
          'type': v['type'],
          'title': 'Test ${v['type']} Title',
          'subtitle': 'Test Subtitle',
          'imageUrl': 'https://images.unsplash.com/photo-test',
          'date': '2026-10-20',
          'time': '07:00 PM',
          'location': 'Hyderabad',
          'status': 'upcoming',
          'totalPrice': 1250.0,
          'qrCodeData': v['qrCodeData'],
        });

        expect(booking.id, v['id']);
        expect(booking.type, v['expectedType']);
        expect(booking.status, BookingStatus.upcoming);
        expect(booking.confirmationCode, v['qrCodeData']);
        expect(booking.totalAmount, 1250.0);
      }
    });

    testWidgets('PlazaPaymentSheet displays server-authoritative quote with quoteId', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final canonicalQuote = BookingQuote.fromJson({
        'quoteId': 'QUO_PHASE24_999',
        'expiresAt': '2026-10-20T15:00:00Z',
        'type': 'event',
        'subtotal': 2999,
        'fees': 150,
        'tax': 0,
        'total': 3149,
        'rewardsEarned': 157,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlazaPaymentSheet(
              bookingTitle: 'Hyderabad Rock Festival 2026',
              bookingSubtitle: '1x VIP Pass',
              quote: canonicalQuote,
              bookingId: 'PLZ-EVT-999',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hyderabad Rock Festival 2026'), findsOneWidget);
      expect(find.text('₹2999'), findsOneWidget);
      expect(find.text('₹150'), findsOneWidget);
      expect(find.text('₹3149'), findsOneWidget);
      expect(find.text('Pay ₹3149 ⚡'), findsOneWidget);
    });
  });
}
