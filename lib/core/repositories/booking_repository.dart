import '../models/unified_booking.dart';

abstract class BookingRepository {
  Future<List<UnifiedBooking>> getBookings({String? status});
  Future<UnifiedBooking?> getBookingById(String id);
  Future<bool> cancelBooking(String id);
}
