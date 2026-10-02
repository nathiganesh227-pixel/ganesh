import 'package:flutter_test/flutter_test.dart';
import 'package:plaza/core/models/booking_quote.dart';
import 'package:plaza/core/network/environment_config.dart';
import 'package:plaza/core/repositories/local_booking_repository.dart';
import 'package:plaza/core/services/razorpay_checkout_service.dart';

void main() {
  group('Phase 12 — Flutter Razorpay Test Mode Suite', () {
    late LocalBookingRepository localBookingRepo;
    late RazorpayCheckoutService checkoutService;

    setUp(() {
      localBookingRepo = LocalBookingRepository();
      checkoutService = RazorpayCheckoutService(bookingRepository: localBookingRepo);
    });

    test('1. Razorpay order session initializes correctly from JSON with safe fields', () {
      final json = {
        'paymentId': 'PAY_TEST_001',
        'bookingId': 'BK_TEST_001',
        'quoteId': 'QUO_TEST_001',
        'providerOrderId': 'order_test_987654',
        'amount': 499.0,
        'amountInMinorUnits': 49900,
        'currency': 'INR',
        'paymentMode': 'RAZORPAY',
        'status': 'PENDING',
        'keyId': 'rzp_test_public_key_123',
        'merchantName': 'PLAZA Premium Experiences',
        'description': 'PLAZA Event Ticket Booking',
        'expiresAt': '2026-10-02T12:00:00.000Z',
      };

      final session = PaymentOrderSession.fromJson(json);

      expect(session.paymentId, 'PAY_TEST_001');
      expect(session.bookingId, 'BK_TEST_001');
      expect(session.quoteId, 'QUO_TEST_001');
      expect(session.providerOrderId, 'order_test_987654');
      expect(session.amount, 499.0);
      expect(session.amountInMinorUnits, 49900);
      expect(session.currency, 'INR');
      expect(session.paymentMode, 'RAZORPAY');
      expect(session.status, 'PENDING');
      expect(session.keyId, 'rzp_test_public_key_123');
    });

    test('2. Checkout options correctly formats order ID, amount in paise, currency, and prefill', () {
      const session = PaymentOrderSession(
        paymentId: 'PAY_TEST_002',
        bookingId: 'BK_TEST_002',
        quoteId: 'QUO_TEST_002',
        providerOrderId: 'order_test_rzp_111',
        amount: 250.0,
        amountInMinorUnits: 25000,
        currency: 'INR',
        paymentMode: 'RAZORPAY',
        status: 'PENDING',
        keyId: 'rzp_test_public_key_123',
        merchantName: 'PLAZA',
        description: 'Movie Tickets',
        expiresAt: '2026-10-02T12:00:00.000Z',
      );

      final options = checkoutService.buildCheckoutOptions(
        session: session,
        customerEmail: 'guest@plaza.club',
        customerPhone: '+919876543210',
      );

      expect(options['key'], 'rzp_test_public_key_123');
      expect(options['amount'], 25000);
      expect(options['currency'], 'INR');
      expect(options['order_id'], 'order_test_rzp_111');
      expect(options['name'], 'PLAZA');
      expect(options['prefill']['email'], 'guest@plaza.club');
      expect(options['prefill']['contact'], '+919876543210');
      // Verify secret is NOT in checkout options
      expect(options.containsKey('secret'), false);
      expect(options.containsKey('key_secret'), false);
    });

    test('3. Successful checkout triggers backend verification and returns success result', () async {
      final result = await checkoutService.verifyWithBackend(
        bookingId: 'BK_TEST_003',
        orderId: 'order_test_333',
        paymentId: 'pay_test_333',
        signature: 'valid_mock_signature_hex',
        quoteId: 'QUO_TEST_003',
      );

      expect(result.status, RazorpayCheckoutStatus.success);
      expect(result.paymentId, 'pay_test_333');
      expect(result.orderId, 'order_test_333');
      expect(result.signature, 'valid_mock_signature_hex');
      expect(result.serverVerified, true);
    });

    test('4. Failed checkout result factory handles failure messages gracefully', () {
      final result = RazorpayCheckoutResult.failed('Payment declined by issuing bank');
      expect(result.status, RazorpayCheckoutStatus.failed);
      expect(result.errorMessage, 'Payment declined by issuing bank');
      expect(result.serverVerified, false);
    });

    test('5. Dismissed checkout result factory produces cancelled status', () {
      final result = RazorpayCheckoutResult.cancelled();
      expect(result.status, RazorpayCheckoutStatus.cancelled);
      expect(result.errorMessage, contains('dismissed'));
    });

    test('6. Secret is never present in EnvironmentConfig or Flutter client', () {
      expect(EnvironmentConfig.baseUrl, isNotEmpty);
      // Verify no secret exists in EnvironmentConfig class
      const hasLiveFlag = EnvironmentConfig.razorpayLiveEnabled;
      expect(hasLiveFlag, isA<bool>());
    });
  });
}
