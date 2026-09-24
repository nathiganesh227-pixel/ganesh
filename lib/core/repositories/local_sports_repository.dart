import '../models/sports.dart';
import '../data/sports_mock_data.dart';
import 'sports_repository.dart';

class LocalSportsRepository implements SportsRepository {
  const LocalSportsRepository();

  @override
  Future<List<SportsVenue>> getVenues({String? sport}) async {
    if (sport != null && sport.isNotEmpty) {
      return SportsMockData.venues.where((v) {
        return v.supportedSports.any((s) => s.label.toLowerCase().contains(sport.toLowerCase()));
      }).toList();
    }
    return List.from(SportsMockData.venues);
  }

  @override
  Future<SportsVenue?> getVenueById(String id) async {
    try {
      return SportsMockData.venues.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
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
    return true;
  }
}
