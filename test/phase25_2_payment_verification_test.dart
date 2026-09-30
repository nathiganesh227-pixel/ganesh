import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/models/booking_quote.dart';
import 'package:plaza/core/network/api_client.dart';
import 'package:plaza/core/network/api_endpoints.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/core/repositories/api_booking_repository.dart';
import 'package:plaza/core/repositories/local_booking_repository.dart';

class _RecordingApiClient extends ApiClient {
  String? lastPath;
  Map<String, dynamic>? lastBody;
  Map<String, dynamic> mockResponseJson;

  _RecordingApiClient({this.mockResponseJson = const {}});

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    T Function(dynamic json)? fromJson,
  }) async {
    lastPath = path;
    if (body is Map<String, dynamic>) {
      lastBody = Map<String, dynamic>.from(body);
    }
    final parsed = fromJson != null ? fromJson(mockResponseJson) : null;
    return ApiResponse<T>.success(parsed as T);
  }
}

void main() {
  group('Phase 25.2 — Payment Order & Server-Side Verification Contract', () {
    test('BookingQuote computes integer minor units (paise) from grandTotal and preserves server minor units', () {
      final quote = BookingQuote.fromJson({
        'quoteId': 'QUO_252_MOVIE_1',
        'expiresAt': '2026-10-01T12:15:00.000Z',
        'type': 'movie',
        'subtotal': 900.0,
        'convenienceFee': 70.0,
        'taxes': 45.0,
        'grandTotal': 1015.0,
        'amountInMinorUnits': 101500,
        'currency': 'INR',
      });

      expect(quote.quoteId, 'QUO_252_MOVIE_1');
      expect(quote.grandTotal, 1015.0);
      expect(quote.amountInMinorUnits, 101500);
      expect(quote.currency, 'INR');

      final serialized = quote.toJson();
      expect(serialized['amountInMinorUnits'], 101500);
      expect(serialized['grandTotal'], 1015.0);
    });

    test('PaymentOrderSession parses server order response safely without secret fields', () {
      final session = PaymentOrderSession.fromJson({
        'paymentId': 'PAY_252_1001',
        'bookingId': 'PLZ-MOV-25201',
        'quoteId': 'QUO_252_MOVIE_1',
        'orderId': 'order_test_252_xyz',
        'amount': 1015.0,
        'amountInMinorUnits': 101500,
        'currency': 'INR',
        'paymentMode': 'RAZORPAY',
        'status': 'PENDING',
        'keyId': 'rzp_test_public_id_only',
        'merchantName': 'PLAZA',
        'description': 'PLAZA MOVIE Booking',
        'expiresAt': '2026-10-01T12:15:00.000Z',
        'idempotentReplay': false,
      });

      expect(session.paymentId, 'PAY_252_1001');
      expect(session.bookingId, 'PLZ-MOV-25201');
      expect(session.quoteId, 'QUO_252_MOVIE_1');
      expect(session.providerOrderId, 'order_test_252_xyz');
      expect(session.amount, 1015.0);
      expect(session.amountInMinorUnits, 101500);
      expect(session.currency, 'INR');
      expect(session.paymentMode, 'RAZORPAY');
      expect(session.status, 'PENDING');
      expect(session.keyId, 'rzp_test_public_id_only');
      expect(session.idempotentReplay, isFalse);

      final jsonMap = session.toJson();
      expect(jsonMap.containsKey('keySecret'), isFalse);
      expect(jsonMap.containsKey('webhookSecret'), isFalse);
    });

    test('ApiBookingRepository.createPaymentOrder sends only quoteId/bookingId/paymentMethod and never client amount or currency', () async {
      final fakeClient = _RecordingApiClient(
        mockResponseJson: {
          'paymentId': 'PAY_252_2002',
          'bookingId': 'PLZ-MOV-25202',
          'quoteId': 'QUO_252_MOVIE_2',
          'providerOrderId': 'order_sim_252_2002',
          'amount': 543.0,
          'amountInMinorUnits': 54300,
          'currency': 'INR',
          'paymentMode': 'SIMULATED',
          'status': 'PENDING',
          'merchantName': 'PLAZA',
          'description': 'PLAZA MOVIE Booking',
          'expiresAt': '2026-10-01T12:30:00.000Z',
          'idempotentReplay': false,
        },
      );

      final repo = ApiBookingRepository(client: fakeClient);
      final order = await repo.createPaymentOrder(
        quoteId: 'QUO_252_MOVIE_2',
        bookingId: 'PLZ-MOV-25202',
        paymentMethod: 'UPI_FAST',
      );

      expect(fakeClient.lastPath, ApiEndpoints.paymentOrders);
      expect(fakeClient.lastBody, isNotNull);
      expect(fakeClient.lastBody!['quoteId'], 'QUO_252_MOVIE_2');
      expect(fakeClient.lastBody!['bookingId'], 'PLZ-MOV-25202');
      expect(fakeClient.lastBody!['paymentMethod'], 'UPI_FAST');

      // Client must NEVER send financial fields as authoritative input
      expect(fakeClient.lastBody!.containsKey('amount'), isFalse);
      expect(fakeClient.lastBody!.containsKey('price'), isFalse);
      expect(fakeClient.lastBody!.containsKey('total'), isFalse);
      expect(fakeClient.lastBody!.containsKey('subtotal'), isFalse);
      expect(fakeClient.lastBody!.containsKey('discount'), isFalse);
      expect(fakeClient.lastBody!.containsKey('tax'), isFalse);
      expect(fakeClient.lastBody!.containsKey('fee'), isFalse);
      expect(fakeClient.lastBody!.containsKey('currency'), isFalse);

      expect(order, isNotNull);
      expect(order!.amountInMinorUnits, 54300);
      expect(order.providerOrderId, 'order_sim_252_2002');
    });

    test('ApiBookingRepository.verifyPayment sends orderId, paymentId, signature, bookingId, quoteId and never client amount', () async {
      final fakeClient = _RecordingApiClient(
        mockResponseJson: {
          'success': true,
          'bookingId': 'PLZ-MOV-25202',
          'status': 'CAPTURED',
        },
      );

      final repo = ApiBookingRepository(client: fakeClient);
      final verified = await repo.verifyPayment(
        bookingId: 'PLZ-MOV-25202',
        orderId: 'order_sim_252_2002',
        paymentId: 'pay_sim_252_2002',
        signature: 'a' * 64,
        quoteId: 'QUO_252_MOVIE_2',
      );

      expect(verified, isTrue);
      expect(fakeClient.lastPath, ApiEndpoints.paymentVerify);
      expect(fakeClient.lastBody!['bookingId'], 'PLZ-MOV-25202');
      expect(fakeClient.lastBody!['razorpayOrderId'], 'order_sim_252_2002');
      expect(fakeClient.lastBody!['razorpayPaymentId'], 'pay_sim_252_2002');
      expect(fakeClient.lastBody!['razorpaySignature'], 'a' * 64);
      expect(fakeClient.lastBody!['quoteId'], 'QUO_252_MOVIE_2');
      expect(fakeClient.lastBody!.containsKey('amount'), isFalse);
      expect(fakeClient.lastBody!.containsKey('currency'), isFalse);
    });

    test('LocalBookingRepository supports simulated createPaymentOrder and verifyPayment', () async {
      const localRepo = LocalBookingRepository();
      final session = await localRepo.createPaymentOrder(
        quoteId: 'QUO_SIM_LOCAL_1',
        bookingId: 'PLZ-SIM-LOCAL-1',
        paymentMethod: 'UPI_FAST',
      );

      expect(session, isNotNull);
      expect(session!.quoteId, 'QUO_SIM_LOCAL_1');
      expect(session.bookingId, 'PLZ-SIM-LOCAL-1');
      expect(session.paymentMode, 'SIMULATED');
      expect(session.currency, 'INR');

      final verified = await localRepo.verifyPayment(
        bookingId: 'PLZ-SIM-LOCAL-1',
        orderId: session.providerOrderId,
        paymentId: 'pay_sim_local_1',
        signature: 'sig_sim_local_1',
        quoteId: 'QUO_SIM_LOCAL_1',
      );
      expect(verified, isTrue);
    });

    test('Flutter lib/ contains zero Razorpay live keys or server secrets', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      expect(dartFiles, isNotEmpty);
      final liveKeyPattern = RegExp(r'rzp_live_[A-Za-z0-9]{8,}');
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(liveKeyPattern.hasMatch(content), isFalse, reason: 'Found live key in ${file.path}');
      }
    });
  });
}
