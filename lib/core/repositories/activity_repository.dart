import '../models/activity.dart';

abstract class ActivityRepository {
  Future<List<PlazaActivity>> getActivities({String? category, String? q, String? city});
  Future<PlazaActivity?> getActivityById(String id);
  Future<bool> createBooking(ActivityBooking booking);
}
