import '../models/stay.dart';

abstract class StayRepository {
  Future<List<Hotel>> getHotels({String? category, String? q, String? city});
  Future<Hotel?> getHotelById(String id);
  Future<bool> createBooking(HotelBooking booking);
}
