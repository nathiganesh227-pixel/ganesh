import '../models/unified_booking.dart';
import '../models/booking_quote.dart';

abstract class BookingRepository {
  Future<List<UnifiedBooking>> getBookings({String? status});
  Future<UnifiedBooking?> getBookingById(String id);
  Future<bool> cancelBooking(String id);
  Future<BookingQuote?> getQuote({
    required String type,
    required Map<String, dynamic> payload,
  });
  Future<bool> verifyPayment({
    required String bookingId,
    required String orderId,
    required String paymentId,
    required String signature,
  });
}
