import 'category.dart';

class DealItem {
  final String id;
  final String title;
  final String discount;
  final String code;
  final String description;
  final String partnerName;
  final PlazaCategoryType category;
  final String validTill;
  final String imageUrl;

  const DealItem({
    required this.id,
    required this.title,
    required this.discount,
    required this.code,
    required this.description,
    required this.partnerName,
    required this.category,
    required this.validTill,
    required this.imageUrl,
  });
}
