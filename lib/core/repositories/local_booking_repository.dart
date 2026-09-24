import '../data/plaza_global_state.dart';
import '../models/unified_booking.dart';
import 'booking_repository.dart';

class LocalBookingRepository implements BookingRepository {
  const LocalBookingRepository();

  @override
  Future<List<UnifiedBooking>> getBookings({String? status}) async {
    final list = PlazaGlobalState.instance.bookings;
    if (status == null || status.isEmpty || status.toLowerCase() == 'all') {
      return list;
    }
    return list.where((b) => b.status.name.toLowerCase() == status.toLowerCase() || b.status.label.toLowerCase() == status.toLowerCase()).toList();
  }

  @override
  Future<UnifiedBooking?> getBookingById(String id) async {
    try {
      return PlazaGlobalState.instance.bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> cancelBooking(String id) async {
    PlazaGlobalState.instance.cancelBooking(id);
    return true;
  }
}
