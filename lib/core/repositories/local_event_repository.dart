import '../models/event.dart';
import '../data/event_mock_data.dart';
import 'event_repository.dart';

class LocalEventRepository implements EventRepository {
  const LocalEventRepository();

  @override
  Future<List<PlazaEvent>> getEvents({String? category, String? q, String? city}) async {
    var list = List<PlazaEvent>.from(EventMockData.events);

    if (category != null && category.isNotEmpty) {
      final cat = category.toLowerCase();
      list = list.where((e) => e.category.label.toLowerCase().contains(cat)).toList();
    }

    if (city != null && city.isNotEmpty) {
      final c = city.toLowerCase();
      list = list.where((e) {
        final loc = '${e.location} ${e.venue}'.toLowerCase();
        if (loc.contains(c)) return true;
        if (c == 'hyderabad' &&
            (loc.contains('hitec') ||
                loc.contains('gachibowli') ||
                loc.contains('jubilee') ||
                loc.contains('hitex') ||
                loc.contains('shilpakala') ||
                loc.contains('resorts'))) {
          return true;
        }
        return false;
      }).toList();
    }

    if (q != null && q.isNotEmpty) {
      final query = q.toLowerCase();
      list = list.where((e) {
        return e.title.toLowerCase().contains(query) ||
            e.tagline.toLowerCase().contains(query) ||
            e.description.toLowerCase().contains(query) ||
            e.venue.toLowerCase().contains(query) ||
            e.location.toLowerCase().contains(query) ||
            e.category.label.toLowerCase().contains(query) ||
            e.artists.any((a) => a.name.toLowerCase().contains(query));
      }).toList();
    }

    return list;
  }

  @override
  Future<PlazaEvent?> getEventById(String id) async {
    try {
      return EventMockData.events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> bookTickets(EventBooking booking) async {
    return true;
  }
}
