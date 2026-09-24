import '../models/stay.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'stay_repository.dart';
import 'local_stay_repository.dart';

class ApiStayRepository implements StayRepository {
  final ApiClient _client;
  final LocalStayRepository _fallback;

  ApiStayRepository({
    ApiClient? client,
    LocalStayRepository? fallback,
  })  : _client = client ?? ApiClient(),
        _fallback = fallback ?? const LocalStayRepository();

  @override
  Future<List<Hotel>> getHotels({String? category}) async {
    try {
      final response = await _client.get<List<Hotel>>(
        ApiEndpoints.stays,
        queryParams: (category != null && category.isNotEmpty && category.toLowerCase() != 'all')
            ? {'category': category}
            : null,
        fromJson: (json) {
          if (json is List) {
            return json
                .map((item) => Hotel.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }
    } catch (_) {}
    return _fallback.getHotels(category: category);
  }

  @override
  Future<Hotel?> getHotelById(String id) async {
    try {
      final response = await _client.get<Hotel?>(
        ApiEndpoints.stayDetails(id),
        fromJson: (json) =>
            json != null ? Hotel.fromJson(json as Map<String, dynamic>) : null,
      );

      if (response.success && response.data != null) {
        return response.data;
      }
    } catch (_) {}
    return _fallback.getHotelById(id);
  }

  @override
  Future<bool> createBooking(HotelBooking booking) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/bookings/stays',
        body: {
          'hotelId': booking.hotel.id,
          'roomTypeId': booking.roomType.id,
          'checkInDate': booking.checkInDate.toIso8601String(),
          'checkOutDate': booking.checkOutDate.toIso8601String(),
          'nights': booking.nights,
          'guestsCount': booking.guestsCount,
          'roomsCount': booking.roomsCount,
          'addOnIds': booking.selectedAddOns.map((a) => a.id).toList(),
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (response.success) {
        await _fallback.createBooking(booking);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
