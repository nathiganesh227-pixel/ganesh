import '../models/activity.dart';

abstract class ActivityRepository {
  Future<List<PlazaActivity>> getActivities({String? category});
  Future<PlazaActivity?> getActivityById(String id);
  Future<bool> createBooking(ActivityBooking booking);
}
