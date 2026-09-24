import '../models/unified_booking.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'booking_repository.dart';
import 'local_booking_repository.dart';

class ApiBookingRepository implements BookingRepository {
  final ApiClient _client;
  final LocalBookingRepository _fallback;

  ApiBookingRepository({
    ApiClient? client,
    LocalBookingRepository? fallback,
  })  : _client = client ?? ApiClient(),
        _fallback = fallback ?? const LocalBookingRepository();

  @override
  Future<List<UnifiedBooking>> getBookings({String? status}) async {
    try {
      final response = await _client.get<List<UnifiedBooking>>(
        ApiEndpoints.bookings,
        queryParams: (status != null && status.isNotEmpty && status.toLowerCase() != 'all')
            ? {'status': status.toLowerCase()}
            : null,
        fromJson: (json) {
          if (json is List) {
            return json
                .map((item) =>
                    UnifiedBooking.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }
    } catch (_) {}
    return _fallback.getBookings(status: status);
  }

  @override
  Future<UnifiedBooking?> getBookingById(String id) async {
    try {
      final response = await _client.get<UnifiedBooking?>(
        ApiEndpoints.bookingDetails(id),
        fromJson: (json) => json != null
            ? UnifiedBooking.fromJson(json as Map<String, dynamic>)
            : null,
      );

      if (response.success && response.data != null) {
        return response.data;
      }
    } catch (_) {}
    return _fallback.getBookingById(id);
  }

  @override
  Future<bool> cancelBooking(String id) async {
    try {
      final response = await _client.delete<Map<String, dynamic>>(
        ApiEndpoints.bookingDetails(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (response.success) {
        // Also update local state
        await _fallback.cancelBooking(id);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
