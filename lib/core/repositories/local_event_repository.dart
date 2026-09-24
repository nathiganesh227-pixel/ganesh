import '../models/event.dart';
import '../data/event_mock_data.dart';
import 'event_repository.dart';

class LocalEventRepository implements EventRepository {
  const LocalEventRepository();

  @override
  Future<List<PlazaEvent>> getEvents({String? category}) async {
    if (category != null && category.isNotEmpty) {
      return EventMockData.events.where((e) {
        return e.category.label.toLowerCase().contains(category.toLowerCase());
      }).toList();
    }
    return List.from(EventMockData.events);
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
