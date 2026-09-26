import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/data/plaza_global_state.dart';
import '../../../core/models/stay.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_pill.dart';
import '../../../core/widgets/plaza_image.dart';
import '../hotel_details_screen.dart';

enum StayCardVariant {
  standard,
  horizontal,
  compact,
}

class StayCard extends StatelessWidget {
  final Hotel hotel;
  final StayCardVariant variant;
  final VoidCallback? onTap;

  const StayCard({
    super.key,
    required this.hotel,
    this.variant = StayCardVariant.standard,
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
        builder: (context) => HotelDetailsScreen(hotel: hotel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case StayCardVariant.compact:
        return _buildCompactCard(context);
      case StayCardVariant.horizontal:
        return _buildHorizontalCard(context);
      case StayCardVariant.standard:
        return _buildStandardCard(context);
    }
  }

  Widget _buildStandardCard(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(hotel.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel Cover Image & Badges
                Stack(
                  children: [
                    PlazaImage(
                      imageUrl: hotel.coverImageUrl,
                      height: 180,
                      width: double.infinity,
                      borderRadius: 16,
                    ),

                    // Category Pill
                    Positioned(
                      top: 10,
                      left: 10,
                      child: GlassPill(
                        label: hotel.category.label,
                        backgroundColor: const Color(0xB3000000),
                        textColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      ),
                    ),

                    // Deal Badge
                    if (hotel.dealBadge != null)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xD0000000),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.7)),
                          ),
                          child: Text(
                            hotel.dealBadge!,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.accentGold,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                    // Reactive Favorite Button
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => PlazaGlobalState.instance.toggleFavorite(hotel.id),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Color(0xB3000000),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? AppColors.alertRed : Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Card Info
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
                              hotel.name,
                              style: AppTypography.headingSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 15, color: AppColors.accentGold),
                              const SizedBox(width: 3),
                              Text(
                                hotel.rating.toStringAsFixed(2),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.accentGold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${hotel.location} • ${hotel.distance}',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hotel.tagline,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('STARTING FROM', style: AppTypography.bodySmall.copyWith(fontSize: 9, letterSpacing: 0.8)),
                                Text(
                                  '₹${hotel.startingPricePerNight.toInt()} / night',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.accentAmber,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'View Rooms',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primaryLight,
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

  Widget _buildHorizontalCard(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(hotel.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Stack(
                    children: [
                      PlazaImage(
                        imageUrl: hotel.coverImageUrl,
                        width: 100,
                        height: 100,
                        borderRadius: 12,
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => PlazaGlobalState.instance.toggleFavorite(hotel.id),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xB3000000),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? AppColors.alertRed : Colors.white,
                              size: 14,
                            ),
                          ),
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
                                hotel.name,
                                style: AppTypography.labelLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
                                const SizedBox(width: 2),
                                Text(
                                  hotel.rating.toStringAsFixed(1),
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.accentGold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${hotel.location} • ${hotel.distance}',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${hotel.roomTypes.length} Room Types • ${hotel.checkInTime} Check-in',
                          style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${hotel.startingPricePerNight.toInt()} / night',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.accentAmber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Reserve ›',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(hotel.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: Container(
            width: 260,
            margin: const EdgeInsets.only(right: 14),
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      PlazaImage(
                        imageUrl: hotel.coverImageUrl,
                        height: 140,
                        width: 260,
                        borderRadius: 16,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => PlazaGlobalState.instance.toggleFavorite(hotel.id),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xB3000000),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? AppColors.alertRed : Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GlassPill(
                          label: hotel.category.label.split('&').first.trim(),
                          backgroundColor: const Color(0xB3000000),
                          textColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        ),
                      ),
                      if (hotel.dealBadge != null)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xD0000000),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.6)),
                            ),
                            child: Text(
                              hotel.dealBadge!,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.accentGold,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotel.name,
                          style: AppTypography.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${hotel.location} • ${hotel.distance}',
                          style: AppTypography.bodySmall.copyWith(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${hotel.startingPricePerNight.toInt()} / night',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.accentAmber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 13, color: AppColors.accentGold),
                                const SizedBox(width: 2),
                                Text(
                                  hotel.rating.toStringAsFixed(1),
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.accentGold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
