import '../models/event.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/environment_config.dart';
import 'event_repository.dart';
import 'local_event_repository.dart';

class ApiEventRepository implements EventRepository {
  final ApiClient _client;
  final LocalEventRepository _fallback;

  ApiEventRepository({
    ApiClient? client,
    LocalEventRepository? fallback,
  })  : _client = client ?? ApiClient(),
        _fallback = fallback ?? const LocalEventRepository();

  @override
  Future<List<PlazaEvent>> getEvents({String? category, String? q, String? city}) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty) queryParams['category'] = category;
    if (q != null && q.isNotEmpty) queryParams['q'] = q;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;

    try {
      final response = await _client.get<List<PlazaEvent>>(
        ApiEndpoints.events,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => PlazaEvent.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      if (response.success && response.data != null) {
        return response.data!;
      }

      // If response is not successful in prod, do not mask with mock data
      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        throw Exception(response.message ?? 'Failed to load events from server');
      }
    } catch (e) {
      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        rethrow;
      }
    }
    return _fallback.getEvents(category: category, q: q, city: city);
  }

  @override
  Future<PlazaEvent?> getEventById(String id) async {
    try {
      final response = await _client.get<PlazaEvent?>(
        ApiEndpoints.eventDetails(id),
        fromJson: (json) => json != null ? PlazaEvent.fromJson(json as Map<String, dynamic>) : null,
      );

      if (response.success && response.data != null) {
        return response.data;
      }

      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        throw Exception(response.message ?? 'Failed to load event details');
      }
    } catch (e) {
      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        rethrow;
      }
    }
    return _fallback.getEventById(id);
  }

  @override
  Future<bool> bookTickets(EventBooking booking) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/bookings/event',
        body: {
          'eventId': booking.event.id,
          'tierId': booking.ticketTier.id,
          'ticketCount': booking.quantity,
          'paymentMethod': booking.paymentMethod,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (response.success) {
        await _fallback.bookTickets(booking);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
