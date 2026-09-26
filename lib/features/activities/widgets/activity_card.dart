import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/data/plaza_global_state.dart';
import '../../../core/models/activity.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_pill.dart';
import '../../../core/widgets/plaza_image.dart';
import '../activity_details_screen.dart';

enum ActivityCardVariant {
  standard,
  horizontal,
  compact,
}

class ActivityCard extends StatelessWidget {
  final PlazaActivity activity;
  final ActivityCardVariant variant;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    this.variant = ActivityCardVariant.standard,
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
        builder: (context) => ActivityDetailsScreen(activity: activity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case ActivityCardVariant.compact:
        return _buildCompactCard(context);
      case ActivityCardVariant.horizontal:
        return _buildHorizontalCard(context);
      case ActivityCardVariant.standard:
        return _buildStandardCard(context);
    }
  }

  Widget _buildStandardCard(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(activity.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Activity Cover
                Stack(
                  children: [
                    PlazaImage(
                      imageUrl: activity.coverImageUrl,
                      height: 160,
                      width: double.infinity,
                      borderRadius: 16,
                    ),

                    // Top Badges (Category & Favorite)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: GlassPill(
                        label: activity.category.label,
                        backgroundColor: const Color(0xB3000000),
                        textColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      ),
                    ),

                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => PlazaGlobalState.instance.toggleFavorite(activity.id),
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

                    // Live Availability Label / Spots Left
                    if (activity.liveAvailabilityLabel.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xCC06B6D4), // Cyan glass
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                activity.liveAvailabilityLabel,
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Card Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              activity.title,
                              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
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
                                activity.rating.toStringAsFixed(1),
                                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${activity.venueName.isNotEmpty ? activity.venueName : activity.location}${activity.distance.isNotEmpty ? ' • ${activity.distance}' : ''}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    activity.duration,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
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
                          Text(
                            activity.startingPrice > 0
                                ? 'From ₹${activity.startingPrice.toInt()}'
                                : 'Free Entry',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.accentAmber,
                              fontWeight: FontWeight.w700,
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
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(activity.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: GlassCard(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Stack(
                  children: [
                    PlazaImage(
                      imageUrl: activity.coverImageUrl,
                      width: 100,
                      height: 100,
                      borderRadius: 12,
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xB3000000),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          activity.category.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              activity.title,
                              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => PlazaGlobalState.instance.toggleFavorite(activity.id),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? AppColors.alertRed : AppColors.textMuted,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activity.venueName.isNotEmpty ? activity.venueName : activity.location,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: AppColors.accentGold),
                          const SizedBox(width: 2),
                          Text(
                            activity.rating.toStringAsFixed(1),
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                          if (activity.distance.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '• ${activity.distance}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            activity.duration,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            activity.startingPrice > 0
                                ? 'From ₹${activity.startingPrice.toInt()}'
                                : 'Free Entry',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.accentAmber,
                              fontWeight: FontWeight.w700,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                PlazaImage(
                  imageUrl: activity.coverImageUrl,
                  height: 110,
                  width: double.infinity,
                  borderRadius: 16,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xB3000000),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activity.category.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (activity.liveAvailabilityLabel.isNotEmpty)
                  Positioned(
                    bottom: 6,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xB306B6D4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        activity.liveAvailabilityLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activity.title,
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.venueName.isNotEmpty ? activity.venueName : activity.location,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activity.duration,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.startingPrice > 0
                            ? 'From ₹${activity.startingPrice.toInt()}'
                            : 'Free Entry',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accentAmber,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
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
  }
}
