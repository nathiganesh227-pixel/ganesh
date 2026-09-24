import '../models/dining.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'dining_repository.dart';
import 'local_dining_repository.dart';

class ApiDiningRepository implements DiningRepository {
  final ApiClient _client;
  final LocalDiningRepository _fallback;

  ApiDiningRepository({
    ApiClient? client,
    LocalDiningRepository? fallback,
  })  : _client = client ?? ApiClient(),
        _fallback = fallback ?? const LocalDiningRepository();

  @override
  Future<List<Restaurant>> getRestaurants({String? cuisine}) async {
    try {
      final response = await _client.get<List<Restaurant>>(
        ApiEndpoints.dining,
        queryParams: cuisine != null ? {'cuisine': cuisine} : null,
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => Restaurant.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }
    } catch (_) {}
    return _fallback.getRestaurants(cuisine: cuisine);
  }

  @override
  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      final response = await _client.get<Restaurant?>(
        ApiEndpoints.restaurantDetails(id),
        fromJson: (json) => json != null ? Restaurant.fromJson(json as Map<String, dynamic>) : null,
      );

      if (response.success && response.data != null) {
        return response.data;
      }
    } catch (_) {}
    return _fallback.getRestaurantById(id);
  }

  @override
  Future<bool> createReservation(DiningReservation reservation) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/bookings/dining',
        body: {
          'restaurantId': reservation.restaurant.id,
          'date': reservation.date.toIso8601String(),
          'timeSlot': reservation.timeSlot,
          'partySize': reservation.partySize,
          'seatingPreference': reservation.seatingPreference.label,
          'guestName': reservation.guestName,
          'guestPhone': reservation.guestPhone,
          'specialRequest': reservation.specialRequest,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (response.success) {
        await _fallback.createReservation(reservation);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
