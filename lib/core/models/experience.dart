import 'category.dart';

class ExperienceItem {
  final String id;
  final String title;
  final String subtitle;
  final PlazaCategoryType category;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String location;
  final String distance;
  final String priceLabel;
  final double startingPrice;
  final String? badge;
  final List<String> tags;
  final bool isTrending;
  final bool isLive;

  const ExperienceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.distance,
    required this.priceLabel,
    required this.startingPrice,
    this.badge,
    this.tags = const [],
    this.isTrending = false,
    this.isLive = false,
  });
}
