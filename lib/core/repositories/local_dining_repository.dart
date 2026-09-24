import '../models/dining.dart';
import '../data/dining_mock_data.dart';
import 'dining_repository.dart';

class LocalDiningRepository implements DiningRepository {
  const LocalDiningRepository();

  @override
  Future<List<Restaurant>> getRestaurants({String? cuisine}) async {
    if (cuisine != null && cuisine.isNotEmpty) {
      return DiningMockData.restaurants.where((r) {
        return r.cuisines.any((c) => c.label.toLowerCase().contains(cuisine.toLowerCase()));
      }).toList();
    }
    return List.from(DiningMockData.restaurants);
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
