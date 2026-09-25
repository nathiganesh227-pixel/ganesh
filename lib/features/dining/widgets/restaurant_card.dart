import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/data/plaza_global_state.dart';
import '../../../core/models/dining.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_pill.dart';
import '../../../core/widgets/plaza_image.dart';
import '../restaurant_details_screen.dart';

enum RestaurantCardVariant {
  standard,
  compact,
  horizontal,
}

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final RestaurantCardVariant variant;
  final VoidCallback? onTap;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    this.variant = RestaurantCardVariant.standard,
    this.onTap,
  });

  void _navigateToDetails(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantDetailsScreen(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case RestaurantCardVariant.compact:
        return _buildCompactCard(context);
      case RestaurantCardVariant.horizontal:
        return _buildHorizontalCard(context);
      case RestaurantCardVariant.standard:
        return _buildStandardCard(context);
    }
  }

  Widget _buildStandardCard(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(restaurant.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Image Stack
                Stack(
                  children: [
                    PlazaImage(
                      imageUrl: restaurant.coverImageUrl,
                      height: 175,
                      width: double.infinity,
                      borderRadius: 20,
                    ),
                    // Rating Pill
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GlassPill(
                        label: '${restaurant.rating.toStringAsFixed(1)} ★',
                        textColor: AppColors.accentGold,
                        backgroundColor: const Color(0xB3000000),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                    // Favorite Heart Button
                    Positioned(
                      top: 10,
                      left: 10,
                      child: GestureDetector(
                        onTap: () {
                          PlazaGlobalState.instance.toggleFavorite(restaurant.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0x99000000),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.glassBorderSubtle),
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 16,
                            color: isFav ? AppColors.alertRed : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Offer Badge
                    if (restaurant.offerBadge != null && restaurant.offerBadge!.isNotEmpty)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppGradients.sunsetPrimary,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x60FF5E36),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            restaurant.offerBadge!,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    // Veg indicator badge
                    if (restaurant.isPureVeg)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xD010B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.eco_rounded, size: 10, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                'PURE VEG',
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Card Details
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: AppTypography.headingSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${restaurant.priceForTwo.toInt()} for two',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.accentAmber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        restaurant.cuisines.map((c) => c.label).join(', '),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    '${restaurant.location.split(',').first} • ${restaurant.distance}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: AppGradients.sunsetPrimary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.table_restaurant_rounded, size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Book Table',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalCard(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(restaurant.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    PlazaImage(
                      imageUrl: restaurant.coverImageUrl,
                      width: 95,
                      height: 95,
                      borderRadius: 16,
                    ),
                    if (restaurant.isPureVeg)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xD010B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.eco_rounded, size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: AppTypography.headingSmall.copyWith(fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              GlassPill(
                                label: '${restaurant.rating.toStringAsFixed(1)} ★',
                                textColor: AppColors.accentGold,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => PlazaGlobalState.instance.toggleFavorite(restaurant.id),
                                child: Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 17,
                                  color: isFav ? AppColors.alertRed : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        restaurant.cuisines.map((c) => c.label).join(', '),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primaryLight,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${restaurant.location.split(',').first} • ${restaurant.distance}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${restaurant.priceForTwo.toInt()} for two',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.accentAmber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (restaurant.offerBadge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                restaurant.offerBadge!,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primaryLight,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlazaImage(
              imageUrl: restaurant.coverImageUrl,
              height: 120,
              width: double.infinity,
              borderRadius: 16,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: AppTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${restaurant.priceForTwo.toInt()} for two',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accentAmber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
