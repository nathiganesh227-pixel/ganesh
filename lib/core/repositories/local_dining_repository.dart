import '../models/dining.dart';
import '../data/dining_mock_data.dart';
import 'dining_repository.dart';

class LocalDiningRepository implements DiningRepository {
  const LocalDiningRepository();

  @override
  Future<List<Restaurant>> getRestaurants({String? cuisine, String? q, String? city}) async {
    var list = List<Restaurant>.from(DiningMockData.restaurants);
    if (city != null && city.isNotEmpty) {
      final c = city.toLowerCase();
      list = list.where((r) => r.location.toLowerCase().contains(c)).toList();
    }
    if (cuisine != null && cuisine.isNotEmpty) {
      final cu = cuisine.toLowerCase();
      list = list.where((r) => r.cuisines.any((c) => c.label.toLowerCase().contains(cu))).toList();
    }
    if (q != null && q.isNotEmpty) {
      final query = q.toLowerCase();
      list = list.where((r) {
        final matchesName = r.name.toLowerCase().contains(query);
        final matchesTagline = r.tagline.toLowerCase().contains(query);
        final matchesAbout = r.about.toLowerCase().contains(query);
        final matchesLoc = r.location.toLowerCase().contains(query);
        final matchesCuisine = r.cuisines.any((c) => c.label.toLowerCase().contains(query));
        final matchesDish = r.popularDishes.any((d) => d.name.toLowerCase().contains(query));
        return matchesName || matchesTagline || matchesAbout || matchesLoc || matchesCuisine || matchesDish;
      }).toList();
    }
    return list;
  }

  @override
  Future<Restaurant?> getRestaurantById(String id) async {
    try {
      return DiningMockData.restaurants.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> createReservation(DiningReservation reservation) async {
    return true;
  }
}
