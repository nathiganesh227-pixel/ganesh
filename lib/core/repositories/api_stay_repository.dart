import '../models/stay.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/environment_config.dart';
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
  Future<List<Hotel>> getHotels({String? category, String? q, String? city}) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      queryParams['category'] = category;
    }
    if (q != null && q.isNotEmpty) queryParams['q'] = q;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;

    try {
      final response = await _client.get<List<Hotel>>(
        ApiEndpoints.stays,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
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

      // If response is not successful in prod, do not mask with mock data
      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        throw Exception(response.message ?? 'Failed to load hotels from server');
      }
    } catch (e) {
      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        rethrow;
      }
    }
    return _fallback.getHotels(category: category, q: q, city: city);
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

      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        throw Exception(response.message ?? 'Failed to load hotel details from server');
      }
    } catch (e) {
      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        rethrow;
      }
    }
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
