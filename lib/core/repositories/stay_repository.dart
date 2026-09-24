import '../models/stay.dart';

abstract class StayRepository {
  Future<List<Hotel>> getHotels({String? category});
  Future<Hotel?> getHotelById(String id);
  Future<bool> createBooking(HotelBooking booking);
}
