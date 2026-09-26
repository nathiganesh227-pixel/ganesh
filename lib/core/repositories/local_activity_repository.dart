import '../data/activity_mock_data.dart';
import '../models/activity.dart';
import 'activity_repository.dart';

class LocalActivityRepository implements ActivityRepository {
  const LocalActivityRepository();

  @override
  Future<List<PlazaActivity>> getActivities({String? category, String? q, String? city}) async {
    var list = ActivityMockData.activities;

    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      list = list.where((a) =>
        a.category.label.toLowerCase() == category.toLowerCase() ||
        a.category.name.toLowerCase() == category.toLowerCase()
      ).toList();
    }

    if (city != null && city.trim().isNotEmpty) {
      final c = city.toLowerCase();
      list = list.where((a) {
        final loc = a.location.toLowerCase();
        final venue = a.venueName.toLowerCase();
        if (loc.contains(c) || venue.contains(c)) return true;
        if (c == 'hyderabad') {
          return loc.contains('hitec') ||
                 loc.contains('shamshabad') ||
                 loc.contains('inorbit') ||
                 loc.contains('gachibowli') ||
                 loc.contains('jubilee') ||
                 loc.contains('kondapur');
        }
        return false;
      }).toList();
    }

    if (q != null && q.trim().isNotEmpty) {
      final query = q.toLowerCase();
      list = list.where((a) {
        return a.title.toLowerCase().contains(query) ||
               a.venueName.toLowerCase().contains(query) ||
               a.location.toLowerCase().contains(query) ||
               a.about.toLowerCase().contains(query) ||
               a.category.label.toLowerCase().contains(query);
      }).toList();
    }

    return list;
  }

  @override
  Future<PlazaActivity?> getActivityById(String id) async {
    try {
      return ActivityMockData.activities.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> createBooking(ActivityBooking booking) async {
    return true;
  }
}
