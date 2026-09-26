import '../data/stay_mock_data.dart';
import '../models/stay.dart';
import 'stay_repository.dart';

class LocalStayRepository implements StayRepository {
  const LocalStayRepository();

  @override
  Future<List<Hotel>> getHotels({String? category, String? q, String? city}) async {
    var list = StayMockData.hotels;
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      list = list.where((h) =>
        h.category.label.toLowerCase() == category.toLowerCase() ||
        h.category.name.toLowerCase() == category.toLowerCase(),
      ).toList();
    }
    if (city != null && city.trim().isNotEmpty) {
      final c = city.toLowerCase();
      list = list.where((h) =>
        h.location.toLowerCase().contains(c) ||
        h.address.toLowerCase().contains(c) ||
        (c == 'hyderabad' &&
          (h.location.toLowerCase().contains('falaknuma') ||
            h.location.toLowerCase().contains('banjara') ||
            h.location.toLowerCase().contains('hitec') ||
            h.location.toLowerCase().contains('gachibowli'))),
      ).toList();
    }
    if (q != null && q.trim().isNotEmpty) {
      final query = q.toLowerCase();
      list = list.where((h) =>
        h.name.toLowerCase().contains(query) ||
        h.tagline.toLowerCase().contains(query) ||
        h.description.toLowerCase().contains(query) ||
        h.location.toLowerCase().contains(query) ||
        h.category.label.toLowerCase().contains(query),
      ).toList();
    }
    return list;
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
