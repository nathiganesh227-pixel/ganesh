import '../models/sports.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'sports_repository.dart';
import 'local_sports_repository.dart';

class ApiSportsRepository implements SportsRepository {
  final ApiClient _client;
  final LocalSportsRepository _fallback;

  ApiSportsRepository({
    ApiClient? client,
    LocalSportsRepository? fallback,
  })  : _client = client ?? ApiClient(),
        _fallback = fallback ?? const LocalSportsRepository();

  @override
  Future<List<SportsVenue>> getVenues({String? sport}) async {
    try {
      final response = await _client.get<List<SportsVenue>>(
        ApiEndpoints.sports,
        queryParams: sport != null ? {'sport': sport} : null,
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => SportsVenue.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }
    } catch (_) {}
    return _fallback.getVenues(sport: sport);
  }

  @override
  Future<SportsVenue?> getVenueById(String id) async {
    try {
      final response = await _client.get<SportsVenue?>(
        ApiEndpoints.sportsVenueDetails(id),
        fromJson: (json) => json != null ? SportsVenue.fromJson(json as Map<String, dynamic>) : null,
      );

      if (response.success && response.data != null) {
        return response.data;
      }
    } catch (_) {}
    return _fallback.getVenueById(id);
  }

  @override
  Future<bool> bookSlot({
    required String venueId,
    required String sportName,
    required String slotId,
    required String date,
    required int playersCount,
    String? squadName,
    List<String>? addOnIds,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/bookings/sports',
        body: {
          'venueId': venueId,
          'sportName': sportName,
          'slotId': slotId,
          'date': date,
          'playersCount': playersCount,
          'squadName': squadName,
          'addOnIds': addOnIds,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (response.success) {
        await _fallback.bookSlot(
          venueId: venueId,
          sportName: sportName,
          slotId: slotId,
          date: date,
          playersCount: playersCount,
          squadName: squadName,
          addOnIds: addOnIds,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
