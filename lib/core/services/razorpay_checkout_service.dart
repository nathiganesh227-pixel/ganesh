import '../models/booking_quote.dart';
import '../repositories/booking_repository.dart';

/// Checkout result from Razorpay payment flow.
enum RazorpayCheckoutStatus {
  success,
  failed,
  cancelled,
}

class RazorpayCheckoutResult {
  final RazorpayCheckoutStatus status;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorMessage;
  final bool serverVerified;

  const RazorpayCheckoutResult({
    required this.status,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorMessage,
    this.serverVerified = false,
  });

  factory RazorpayCheckoutResult.success({
    required String paymentId,
    required String orderId,
    required String signature,
    bool serverVerified = false,
  }) =>
      RazorpayCheckoutResult(
        status: RazorpayCheckoutStatus.success,
        paymentId: paymentId,
        orderId: orderId,
        signature: signature,
        serverVerified: serverVerified,
      );

  factory RazorpayCheckoutResult.failed(String errorMessage) =>
      RazorpayCheckoutResult(
        status: RazorpayCheckoutStatus.failed,
        errorMessage: errorMessage,
      );

  factory RazorpayCheckoutResult.cancelled() => const RazorpayCheckoutResult(
        status: RazorpayCheckoutStatus.cancelled,
        errorMessage: 'Checkout was dismissed by user',
      );
}

/// Razorpay Test Mode Checkout Service for PLAZA Flutter App.
/// 
/// Strictly adheres to security rules:
/// - Uses only public server-issued keyId and providerOrderId from PaymentOrderSession.
/// - Never marks payment confirmed locally without backend signature verification.
class RazorpayCheckoutService {
  final BookingRepository bookingRepository;

  RazorpayCheckoutService({required this.bookingRepository});

  /// Builds the safe client checkout options dictionary for Razorpay SDK / Web Checkout.
  /// Never includes server-side secrets.
  Map<String, dynamic> buildCheckoutOptions({
    required PaymentOrderSession session,
    String? customerEmail,
    String? customerPhone,
  }) {
    return {
      'key': session.keyId ?? '',
      'amount': session.amountInMinorUnits > 0
          ? session.amountInMinorUnits
          : (session.amount * 100).round(),
      'name': session.merchantName,
      'description': session.description,
      'order_id': session.providerOrderId,
      'currency': session.currency,
      'timeout': 300, // 5 minutes
      'prefill': {
        if (customerEmail != null && customerEmail.isNotEmpty)
          'email': customerEmail,
        if (customerPhone != null && customerPhone.isNotEmpty)
          'contact': customerPhone,
      },
      'theme': {
        'color': '#6366F1',
      },
    };
  }

  /// Verifies a completed checkout with PLAZA backend.
  Future<RazorpayCheckoutResult> verifyWithBackend({
    required String bookingId,
    required String orderId,
    required String paymentId,
    required String signature,
    String? quoteId,
  }) async {
    try {
      final verified = await bookingRepository.verifyPayment(
        bookingId: bookingId,
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        quoteId: quoteId,
      );

      if (verified) {
        return RazorpayCheckoutResult.success(
          paymentId: paymentId,
          orderId: orderId,
          signature: signature,
          serverVerified: true,
        );
      } else {
        return RazorpayCheckoutResult.failed(
          'Server cryptographic verification failed. Please check your payment status.',
        );
      }
    } catch (e) {
      final message = e.toString().replaceAll('Exception:', '').trim();
      return RazorpayCheckoutResult.failed(message);
    }
  }
}
