import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/activity.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import 'activity_booking_screen.dart';

class ActivityDetailsScreen extends StatelessWidget {
  final PlazaActivity activity;

  const ActivityDetailsScreen({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(activity.id);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Banner
                    Stack(
                      children: [
                        SizedBox(
                          height: 380,
                          width: double.infinity,
                          child: PlazaImage(
                            imageUrl: activity.coverImageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),

                        Container(
                          height: 380,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x70070A11),
                                Color(0x20070A11),
                                Color(0xD0070A11),
                                AppColors.background,
                              ],
                              stops: [0.0, 0.4, 0.8, 1.0],
                            ),
                          ),
                        ),

                        // Top Bar Actions
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.glassFillMedium,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: AppColors.glassBorderSubtle),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          size: 18,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        PlazaGlobalState.instance.toggleFavorite(activity.id);
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.glassFillMedium,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: AppColors.glassBorderSubtle),
                                            ),
                                            child: Icon(
                                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                              size: 18,
                                              color: isFav ? AppColors.alertRed : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Activity details link copied!'),
                                            backgroundColor: AppColors.surfaceElevated,
                                          ),
                                        );
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.glassFillMedium,
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: AppColors.glassBorderSubtle),
                                            ),
                                            child: const Icon(
                                              Icons.share_outlined,
                                              size: 18,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Category Pill
                        Positioned(
                          bottom: 16,
                          left: 20,
                          child: GlassPill(
                            label: activity.category.label,
                            backgroundColor: const Color(0x3506B6D4),
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // Title & Highlights
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(activity.title, style: AppTypography.displayMedium.copyWith(fontSize: 22)),
                                    const SizedBox(height: 4),
                                    Text(
                                      activity.venueName,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.primaryLight,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0x30FFB300),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0x60FFB300)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 16, color: AppColors.accentGold),
                                    const SizedBox(width: 4),
                                    Text(
                                      activity.rating.toStringAsFixed(1),
                                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      ' (${activity.reviewCount})',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Quick Logistics Badges
                          Row(
                            children: [
                              _buildQuickPill(Icons.timer_outlined, activity.duration),
                              const SizedBox(width: 10),
                              _buildQuickPill(
                                Icons.location_on_outlined,
                                activity.distance.isNotEmpty ? '${activity.location} • ${activity.distance}' : activity.location,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Venue & Location Logistics Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0x2006B6D4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.location_on_rounded, color: Color(0xFF06B6D4), size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(activity.venueName, style: AppTypography.labelLarge),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${activity.location}${activity.distance.isNotEmpty ? ' (${activity.distance})' : ''}',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Opening directions to ${activity.venueName}...'),
                                    backgroundColor: AppColors.surfaceElevated,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.directions_rounded, size: 16, color: Color(0xFF06B6D4)),
                              label: Text('Directions', style: AppTypography.labelSmall.copyWith(color: const Color(0xFF06B6D4))),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // About Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('About the Experience', style: AppTypography.headingSmall),
                            const SizedBox(height: 8),
                            Text(
                              activity.about,
                              style: AppTypography.bodyMedium.copyWith(
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // What's Included & Requirements
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('What’s Included in Booking', style: AppTypography.headingSmall),
                            const SizedBox(height: 10),
                            ...activity.whatIsIncluded.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.liveGreen),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(item, style: AppTypography.bodySmall)),
                                  ],
                                ),
                              ),
                            ),
                            if (activity.requirements.isNotEmpty) ...[
                              const Divider(color: Color(0x15FFFFFF), height: 20),
                              Text('Important Guidelines', style: AppTypography.headingSmall.copyWith(fontSize: 14)),
                              const SizedBox(height: 8),
                              ...activity.requirements.map(
                                (req) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.accentAmber),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          req,
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Available Time Slots Preview
                    if (activity.availableSlots.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Live Session Slots', style: AppTypography.headingSmall),
                                Text(
                                  '${activity.availableSlots.length} slots today',
                                  style: AppTypography.labelSmall.copyWith(color: const Color(0xFF06B6D4)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: activity.availableSlots.map((slot) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.glassFillMedium,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: slot.isFillingFast ? AppColors.alertRed.withValues(alpha: 0.5) : AppColors.glassBorderSubtle,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(slot.time, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(
                                        slot.availableSlots > 0 ? '${slot.availableSlots} spots left' : 'Sold Out',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontSize: 10,
                                          color: slot.isFillingFast ? AppColors.alertRed : AppColors.liveGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Available Packages Preview
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Packages', style: AppTypography.headingSmall),
                          const SizedBox(height: 10),
                          ...activity.packages.map(
                            (pkg) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(pkg.name, style: AppTypography.labelLarge),
                                          const SizedBox(height: 2),
                                          Text(
                                            pkg.description,
                                            style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '₹${pkg.pricePerPerson.toInt()}',
                                      style: AppTypography.priceTag.copyWith(
                                        color: AppColors.accentAmber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),

              // Bottom Dock
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 14,
                        bottom: MediaQuery.of(context).padding.bottom > 0
                            ? MediaQuery.of(context).padding.bottom + 8
                            : 18,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xF0090D18),
                        border: Border(
                          top: BorderSide(color: AppColors.glassBorder, width: 1.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x80000000),
                            blurRadius: 24,
                            offset: Offset(0, -6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('SLOTS FROM', style: AppTypography.labelSmall),
                              const SizedBox(height: 2),
                              Text(
                                '₹${activity.startingPrice.toInt()}',
                                style: AppTypography.priceTag.copyWith(
                                  fontSize: 22,
                                  color: AppColors.accentAmber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: GlassButton(
                              text: 'Book Activity',
                              icon: Icons.sports_esports_rounded,
                              variant: GlassButtonVariant.primary,
                              height: 52,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ActivityBookingScreen(activity: activity),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickPill(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.glassFillMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primaryLight),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
