import 'category.dart';

class LiveSlotItem {
  final String id;
  final String title;
  final String venue;
  final String statusText;
  final int availableUnits;
  final String unitType; // 'slots', 'tables', 'courts', 'rooms'
  final String timeLabel; // 'Available Now', '7:00 PM available', 'In 20 mins'
  final PlazaCategoryType category;
  final String imageUrl;
  final String priceLabel;
  final String location;

  const LiveSlotItem({
    required this.id,
    required this.title,
    required this.venue,
    required this.statusText,
    required this.availableUnits,
    required this.unitType,
    required this.timeLabel,
    required this.category,
    required this.imageUrl,
    required this.priceLabel,
    required this.location,
  });
}
