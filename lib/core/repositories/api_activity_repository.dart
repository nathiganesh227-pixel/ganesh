import '../models/activity.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/environment_config.dart';
import 'activity_repository.dart';
import 'local_activity_repository.dart';

class ApiActivityRepository implements ActivityRepository {
  final ApiClient _client;
  final LocalActivityRepository _fallback;

  ApiActivityRepository({
    ApiClient? client,
    LocalActivityRepository? fallback,
  })  : _client = client ?? ApiClient(),
        _fallback = fallback ?? const LocalActivityRepository();

  @override
  Future<List<PlazaActivity>> getActivities({String? category, String? q, String? city}) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      queryParams['category'] = category;
    }
    if (q != null && q.isNotEmpty) queryParams['q'] = q;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;

    try {
      final response = await _client.get<List<PlazaActivity>>(
        ApiEndpoints.activities,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          if (json is List) {
            return json
                .map((item) => PlazaActivity.fromJson(item as Map<String, dynamic>))
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
        throw Exception(response.message ?? 'Failed to load activities from server');
      }
    } catch (e) {
      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        rethrow;
      }
    }
    return _fallback.getActivities(category: category, q: q, city: city);
  }

  @override
  Future<PlazaActivity?> getActivityById(String id) async {
    try {
      final response = await _client.get<PlazaActivity?>(
        ApiEndpoints.activityDetails(id),
        fromJson: (json) => json != null
            ? PlazaActivity.fromJson(json as Map<String, dynamic>)
            : null,
      );

      if (response.success && response.data != null) {
        return response.data;
      }

      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        throw Exception(response.message ?? 'Failed to load activity details');
      }
    } catch (e) {
      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        rethrow;
      }
    }
    return _fallback.getActivityById(id);
  }

  @override
  Future<bool> createBooking(ActivityBooking booking) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/bookings/activity',
        body: {
          'activityId': booking.activity.id,
          'packageId': booking.package.id,
          'date': booking.date.toIso8601String(),
          'timeSlot': booking.timeSlot,
          'numberOfPeople': booking.numberOfPeople,
          'addOnIds': booking.addOns.map((a) => a.id).toList(),
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
