import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/dining.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import 'table_reservation_screen.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurant,
  });

  @override
  State<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  int _activePhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image Gallery
                Stack(
                  children: [
                    SizedBox(
                      height: 380,
                      width: double.infinity,
                      child: PageView.builder(
                        itemCount: r.galleryImages.length,
                        onPageChanged: (i) => setState(() => _activePhotoIndex = i),
                        itemBuilder: (context, index) {
                          return PlazaImage(
                            imageUrl: r.galleryImages[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),

                    // Cinematic Gradient Overlay
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

                    // Top Navigation Bar
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
                                      border: Border.all(
                                        color: AppColors.glassBorderSubtle,
                                      ),
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
                                ClipRRect(
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
                                        Icons.favorite_border_rounded,
                                        size: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ClipRRect(
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
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Photo Carousel Indicator dots
                    Positioned(
                      bottom: 16,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0x80000000),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_activePhotoIndex + 1}/${r.galleryImages.length}',
                          style: AppTypography.labelSmall.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),

                // Restaurant Info Header
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
                                Text(r.name, style: AppTypography.displayMedium.copyWith(fontSize: 24)),
                                const SizedBox(height: 4),
                                Text(
                                  r.tagline,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primaryLight,
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
                                const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${r.rating.toStringAsFixed(1)} ★',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.accentGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Quick Stats Row
                      Row(
                        children: [
                          _buildStatPill(Icons.restaurant_outlined, r.cuisines.map((c) => c.label).join(', ')),
                          const SizedBox(width: 8),
                          _buildStatPill(Icons.currency_rupee_rounded, '₹${r.priceForTwo.toInt()} for two'),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _buildStatPill(Icons.location_on_outlined, '${r.location} (${r.distance})'),
                          const SizedBox(width: 8),
                          _buildStatPill(Icons.access_time_rounded, r.openingHours),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // About Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About ${r.name}', style: AppTypography.headingSmall),
                        const SizedBox(height: 8),
                        Text(
                          r.about,
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

                // Popular Dishes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Chef’s Recommended Dishes', style: AppTypography.headingSmall),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: r.popularDishes.length,
                    itemBuilder: (context, index) {
                      final dish = r.popularDishes[index];
                      return Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 14),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: PlazaImage(
                                  imageUrl: dish.imageUrl,
                                  height: 90,
                                  width: double.infinity,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      dish.name,
                                      style: AppTypography.labelMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: dish.isVeg ? AppColors.liveGreen : AppColors.alertRed,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${dish.price.toInt()}',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.accentAmber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Amenities
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amenities & Highlights', style: AppTypography.headingSmall),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: r.amenities
                            .map(
                              (a) => GlassPill(
                                label: a,
                                icon: Icons.check_circle_outline_rounded,
                                iconColor: AppColors.primary,
                                backgroundColor: AppColors.glassFillMedium,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Reviews Preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Guest Reviews (${r.reviewCount})', style: AppTypography.headingSmall),
                          Text(
                            '${r.rating.toStringAsFixed(1)} / 5.0',
                            style: AppTypography.labelLarge.copyWith(color: AppColors.accentGold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...r.reviews.map(
                        (rev) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(rev.userName, style: AppTypography.labelMedium),
                                    Text(rev.date, style: AppTypography.bodySmall.copyWith(fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(rev.comment, style: AppTypography.bodySmall),
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

          // Bottom Reserve Table Floating Bar
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
                  decoration: BoxDecoration(
                    color: const Color(0xF0090D18),
                    border: const Border(
                      top: BorderSide(color: AppColors.glassBorder, width: 1.0),
                    ),
                    boxShadow: const [
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
                          Text('INSTANT TABLE BOOKING', style: AppTypography.labelSmall),
                          const SizedBox(height: 2),
                          Text(
                            'Free Reservation',
                            style: AppTypography.priceTag.copyWith(
                              fontSize: 18,
                              color: AppColors.liveGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: GlassButton(
                          text: 'Reserve Table',
                          icon: Icons.table_restaurant_rounded,
                          variant: GlassButtonVariant.primary,
                          height: 52,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TableReservationScreen(restaurant: r),
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
  }

  Widget _buildStatPill(IconData icon, String label) {
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
