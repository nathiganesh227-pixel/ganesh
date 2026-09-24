import '../data/stay_mock_data.dart';
import '../models/stay.dart';
import 'stay_repository.dart';

class LocalStayRepository implements StayRepository {
  const LocalStayRepository();

  @override
  Future<List<Hotel>> getHotels({String? category}) async {
    final list = StayMockData.hotels;
    if (category == null || category.isEmpty || category.toLowerCase() == 'all') {
      return list;
    }
    return list.where((h) => h.category.label.toLowerCase() == category.toLowerCase() || h.category.name.toLowerCase() == category.toLowerCase()).toList();
  }

  @override
  Future<Hotel?> getHotelById(String id) async {
    try {
      return StayMockData.hotels.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> createBooking(HotelBooking booking) async {
    return true;
  }
}
