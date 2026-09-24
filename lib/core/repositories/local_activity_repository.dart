import '../data/activity_mock_data.dart';
import '../models/activity.dart';
import 'activity_repository.dart';

class LocalActivityRepository implements ActivityRepository {
  const LocalActivityRepository();

  @override
  Future<List<PlazaActivity>> getActivities({String? category}) async {
    final list = ActivityMockData.activities;
    if (category == null || category.isEmpty || category.toLowerCase() == 'all') {
      return list;
    }
    return list.where((a) => a.category.label.toLowerCase() == category.toLowerCase() || a.category.name.toLowerCase() == category.toLowerCase()).toList();
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
