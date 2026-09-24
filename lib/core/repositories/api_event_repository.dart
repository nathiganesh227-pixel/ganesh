import '../models/event.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
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
  Future<List<PlazaEvent>> getEvents({String? category}) async {
    try {
      final response = await _client.get<List<PlazaEvent>>(
        ApiEndpoints.events,
        queryParams: category != null ? {'category': category} : null,
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => PlazaEvent.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }
    } catch (_) {}
    return _fallback.getEvents(category: category);
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
    } catch (_) {}
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
