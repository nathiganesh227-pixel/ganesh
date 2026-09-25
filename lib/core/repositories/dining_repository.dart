import '../models/dining.dart';

abstract class DiningRepository {
  Future<List<Restaurant>> getRestaurants({String? cuisine, String? q, String? city});
  Future<Restaurant?> getRestaurantById(String id);
  Future<bool> createReservation(DiningReservation reservation);
}
