import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
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
    final images = r.galleryImages.isNotEmpty ? r.galleryImages : [r.coverImageUrl];

    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(r.id);

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
                            itemCount: images.length,
                            onPageChanged: (i) => setState(() => _activePhotoIndex = i),
                            itemBuilder: (context, index) {
                              return PlazaImage(
                                imageUrl: images[index],
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
                                Color(0x80070A11),
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
                                    GestureDetector(
                                      onTap: () {
                                        PlazaGlobalState.instance.toggleFavorite(r.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isFav ? 'Removed from favorites' : 'Saved to dining favorites ❤️',
                                            ),
                                            backgroundColor: AppColors.surfaceElevated,
                                            duration: const Duration(seconds: 1),
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
                                          SnackBar(
                                            content: Text('Sharing ${r.name} table link...'),
                                            backgroundColor: AppColors.surfaceElevated,
                                            duration: const Duration(seconds: 1),
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

                        // Photo Carousel Indicator dots
                        if (images.length > 1)
                          Positioned(
                            bottom: 16,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0x99000000),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${_activePhotoIndex + 1}/${images.length}',
                                style: AppTypography.labelSmall.copyWith(fontSize: 10, color: Colors.white),
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

                          // Badges (Pure Veg, Outdoor, Offer)
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (r.isPureVeg)
                                GlassPill(
                                  label: 'Pure Veg',
                                  icon: Icons.eco_rounded,
                                  iconColor: AppColors.liveGreen,
                                  textColor: AppColors.liveGreen,
                                  backgroundColor: const Color(0x2010B981),
                                  borderColor: const Color(0x4010B981),
                                ),
                              if (r.hasOutdoor)
                                GlassPill(
                                  label: 'Rooftop / Outdoor Seating',
                                  icon: Icons.deck_outlined,
                                  iconColor: AppColors.secondaryCyan,
                                  textColor: AppColors.secondaryCyan,
                                  backgroundColor: const Color(0x2000E5FF),
                                  borderColor: const Color(0x4000E5FF),
                                ),
                              if (r.offerBadge != null && r.offerBadge!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.sunsetPrimary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    r.offerBadge!,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
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

                    // Chef's Recommended Dishes (Truthful menu items)
                    if (r.popularDishes.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Chef’s Recommended Dishes', style: AppTypography.headingSmall),
                            Text(
                              '${r.popularDishes.length} specialties',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: r.popularDishes.length,
                          itemBuilder: (context, index) {
                            final dish = r.popularDishes[index];
                            return Container(
                              width: 230,
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
                                        height: 100,
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
                                            style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
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
                                    const SizedBox(height: 3),
                                    Expanded(
                                      child: Text(
                                        dish.description,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                          fontSize: 10,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '₹${dish.price.toInt()}',
                                          style: AppTypography.labelMedium.copyWith(
                                            color: AppColors.accentAmber,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (dish.isChefSpecial)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0x30FFB300),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'CHEF SPECIAL',
                                              style: AppTypography.labelSmall.copyWith(
                                                color: AppColors.accentGold,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Truthful menu disclosure note
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.glassFillMedium,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorderSubtle),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primaryLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Full digital à la carte menu coming soon to PLAZA Dining. Above dishes are verified house specialties.',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Amenities
                    if (r.amenities.isNotEmpty) ...[
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
                      const SizedBox(height: 20),
                    ],

                    // Reviews Preview
                    if (r.reviews.isNotEmpty) ...[
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
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded, size: 13, color: AppColors.accentGold),
                                              const SizedBox(width: 3),
                                              Text(
                                                rev.rating.toStringAsFixed(1),
                                                style: AppTypography.labelSmall.copyWith(color: AppColors.accentGold),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(rev.date, style: AppTypography.bodySmall.copyWith(fontSize: 10)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        rev.comment,
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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
      },
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
