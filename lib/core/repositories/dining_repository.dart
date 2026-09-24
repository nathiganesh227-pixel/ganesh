import '../models/dining.dart';

abstract class DiningRepository {
  Future<List<Restaurant>> getRestaurants({String? cuisine});
  Future<Restaurant?> getRestaurantById(String id);
  Future<bool> createReservation(DiningReservation reservation);
}
