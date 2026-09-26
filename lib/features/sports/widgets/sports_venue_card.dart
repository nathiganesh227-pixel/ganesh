import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/data/plaza_global_state.dart';
import '../../../core/models/sports.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_pill.dart';
import '../../../core/widgets/plaza_image.dart';
import '../sports_venue_details_screen.dart';

enum SportsVenueCardVariant {
  standard,
  horizontal,
  compact,
}

class SportsVenueCard extends StatelessWidget {
  final SportsVenue venue;
  final SportsVenueCardVariant variant;
  final VoidCallback? onTap;

  const SportsVenueCard({
    super.key,
    required this.venue,
    this.variant = SportsVenueCardVariant.standard,
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
        builder: (context) => SportsVenueDetailsScreen(venue: venue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case SportsVenueCardVariant.compact:
        return _buildCompactCard(context);
      case SportsVenueCardVariant.horizontal:
        return _buildHorizontalCard(context);
      case SportsVenueCardVariant.standard:
        return _buildStandardCard(context);
    }
  }

  Widget _buildStandardCard(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(venue.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Image with Overlays
                Stack(
                  children: [
                    PlazaImage(
                      imageUrl: venue.coverImageUrl,
                      height: 170,
                      width: double.infinity,
                      borderRadius: 16,
                    ),

                    // Live Now / Badge
                    if (venue.isLiveNow || venue.badge != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xCC000000),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.liveGreen.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.liveGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                venue.badge ?? 'LIVE SLOTS',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.liveGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Favorite Button
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => PlazaGlobalState.instance.toggleFavorite(venue.id),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xB3000000),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.glassBorderSubtle),
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? AppColors.alertRed : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),

                    // Distance Badge
                    if (venue.distance.isNotEmpty)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xB3000000),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.near_me_rounded, size: 10, color: AppColors.secondaryCyan),
                              const SizedBox(width: 3),
                              Text(
                                venue.distance,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Details Content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Supported sports badges
                      if (venue.supportedSports.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: venue.supportedSports.take(3).map((sport) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.glassFillMedium,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.glassBorderSubtle),
                                ),
                                child: Text(
                                  '${sport.emoji} ${sport.label}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Venue Name
                      Text(
                        venue.name,
                        style: AppTypography.headingSmall.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              venue.location,
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
                      const SizedBox(height: 10),

                      // Rating & Price Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Rating
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
                              const SizedBox(width: 3),
                              Text(
                                venue.rating.toStringAsFixed(1),
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '(${venue.reviewCount})',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),

                          // Starting Price
                          RichText(
                            text: TextSpan(
                              text: 'From ',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                              children: [
                                TextSpan(
                                  text: '₹${venue.startingPricePerHour.toInt()}',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: '/hr',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
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
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(venue.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: Container(
            width: 250,
            margin: const EdgeInsets.only(right: 14),
            child: GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      PlazaImage(
                        imageUrl: venue.coverImageUrl,
                        height: 130,
                        width: double.infinity,
                        borderRadius: 16,
                      ),
                      if (venue.badge != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: GlassPill(
                            label: venue.badge!,
                            backgroundColor: const Color(0xB3000000),
                            textColor: AppColors.accentGold,
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => PlazaGlobalState.instance.toggleFavorite(venue.id),
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
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue.name,
                          style: AppTypography.headingSmall.copyWith(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          venue.location,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: AppColors.accentGold),
                                const SizedBox(width: 2),
                                Text(
                                  venue.rating.toStringAsFixed(1),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '₹${venue.startingPricePerHour.toInt()}/hr',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.bold,
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
          ),
        );
      },
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(venue.id);

        return GestureDetector(
          onTap: () => _navigateToDetails(context),
          child: GlassCard(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                PlazaImage(
                  imageUrl: venue.coverImageUrl,
                  width: 76,
                  height: 76,
                  borderRadius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.name,
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        venue.location,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 12, color: AppColors.accentGold),
                              const SizedBox(width: 2),
                              Text(
                                venue.rating.toStringAsFixed(1),
                                style: AppTypography.bodySmall.copyWith(color: Colors.white),
                              ),
                            ],
                          ),
                          Text(
                            '₹${venue.startingPricePerHour.toInt()}/hr',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => PlazaGlobalState.instance.toggleFavorite(venue.id),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? AppColors.alertRed : AppColors.textMuted,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
