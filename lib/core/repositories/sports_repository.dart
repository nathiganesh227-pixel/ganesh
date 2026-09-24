import '../models/sports.dart';

abstract class SportsRepository {
  Future<List<SportsVenue>> getVenues({String? sport});
  Future<SportsVenue?> getVenueById(String id);
  Future<bool> bookSlot({
    required String venueId,
    required String sportName,
    required String slotId,
    required String date,
    required int playersCount,
    String? squadName,
    List<String>? addOnIds,
  });
}
