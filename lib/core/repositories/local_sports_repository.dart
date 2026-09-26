import '../models/sports.dart';
import '../data/sports_mock_data.dart';
import 'sports_repository.dart';

class LocalSportsRepository implements SportsRepository {
  const LocalSportsRepository();

  @override
  Future<List<SportsVenue>> getVenues({String? sport, String? q, String? city}) async {
    var venues = List<SportsVenue>.from(SportsMockData.venues);

    if (city != null && city.isNotEmpty) {
      final cityLower = city.toLowerCase();
      venues = venues.where((v) {
        return v.location.toLowerCase().contains(cityLower) ||
            v.address.toLowerCase().contains(cityLower);
      }).toList();
    }

    if (sport != null && sport.isNotEmpty) {
      final sportLower = sport.toLowerCase();
      venues = venues.where((v) {
        return v.supportedSports.any((s) =>
            s.label.toLowerCase().contains(sportLower) ||
            s.name.toLowerCase().contains(sportLower));
      }).toList();
    }

    if (q != null && q.trim().isNotEmpty) {
      final query = q.trim().toLowerCase();
      venues = venues.where((v) {
        final matchesName = v.name.toLowerCase().contains(query);
        final matchesLocation = v.location.toLowerCase().contains(query);
        final matchesAddress = v.address.toLowerCase().contains(query);
        final matchesDesc = v.description.toLowerCase().contains(query);
        final matchesSports = v.supportedSports.any((s) => s.label.toLowerCase().contains(query));
        return matchesName || matchesLocation || matchesAddress || matchesDesc || matchesSports;
      }).toList();
    }

    return venues;
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
