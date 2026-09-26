import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/stay.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import 'room_booking_screen.dart';

class HotelDetailsScreen extends StatefulWidget {
  final Hotel hotel;

  const HotelDetailsScreen({
    super.key,
    required this.hotel,
  });

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
  int _selectedImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final allImages = widget.hotel.galleryImages.isNotEmpty
        ? widget.hotel.galleryImages
        : [widget.hotel.coverImageUrl];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Gallery App Bar
              SliverAppBar(
                expandedHeight: 360,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x95000000),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.glassBorderSubtle),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sharing ${widget.hotel.name}...'),
                          backgroundColor: AppColors.surfaceElevated,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0x95000000),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.glassBorderSubtle),
                      ),
                      child: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: ListenableBuilder(
                      listenable: PlazaGlobalState.instance,
                      builder: (context, _) {
                        final isFav = PlazaGlobalState.instance.favoriteIds.contains(widget.hotel.id);
                        return GestureDetector(
                          onTap: () => PlazaGlobalState.instance.toggleFavorite(widget.hotel.id),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0x95000000),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.glassBorderSubtle),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFav ? AppColors.alertRed : Colors.white,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PlazaImage(
                        imageUrl: allImages[_selectedImageIndex % allImages.length],
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x99070A11),
                              Colors.transparent,
                              Color(0xDD070A11),
                              AppColors.background,
                            ],
                            stops: [0.0, 0.4, 0.85, 1.0],
                          ),
                        ),
                      ),
                      // Carousel Indicator
                      if (allImages.length > 1)
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: allImages.asMap().entries.map((entry) {
                              final idx = entry.key;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedImageIndex = idx),
                                child: Container(
                                  width: _selectedImageIndex == idx ? 24 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: _selectedImageIndex == idx ? AppColors.accentGold : Colors.white38,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge & Category
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GlassPill(
                            label: widget.hotel.category.label,
                            backgroundColor: AppColors.accentGold.withValues(alpha: 0.2),
                            textColor: AppColors.accentGold,
                          ),
                          if (widget.hotel.dealBadge != null)
                            GlassPill(
                              label: widget.hotel.dealBadge!,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              textColor: AppColors.primaryLight,
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Text(widget.hotel.name, style: AppTypography.headingLarge),
                      const SizedBox(height: 4),
                      Text(
                        widget.hotel.tagline,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                      ),

                      const SizedBox(height: 12),

                      // Location & Rating
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${widget.hotel.address} (${widget.hotel.distance})',
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
                                const SizedBox(width: 4),
                                Text(
                                  widget.hotel.rating.toStringAsFixed(2),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.accentGold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('(${widget.hotel.reviewCount} guest reviews)', style: AppTypography.bodySmall),
                          const Spacer(),
                          Text(
                            'Check-in: ${widget.hotel.checkInTime} • Out: ${widget.hotel.checkOutTime}',
                            style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Luxury Amenities Grid
                      Text('World-Class Amenities', style: AppTypography.labelLarge),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.hotel.amenities.map((amenity) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.glassFillMedium,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.glassBorderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(amenity.icon, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 6),
                                Text(amenity.label, style: AppTypography.labelSmall),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // About Hotel
                      Text('About the Stay', style: AppTypography.labelLarge),
                      const SizedBox(height: 8),
                      Text(
                        widget.hotel.description,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                      ),

                      const SizedBox(height: 24),

                      // Available Rooms Section
                      Text('Select Your Room', style: AppTypography.headingMedium),
                      const SizedBox(height: 12),
                      ...widget.hotel.roomTypes.map((room) => Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: GlassCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PlazaImage(
                                    imageUrl: room.imageUrl,
                                    height: 150,
                                    width: double.infinity,
                                    borderRadius: 20,
                                  ),
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
                                                room.name,
                                                style: AppTypography.headingSmall.copyWith(fontSize: 16),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              '₹${room.pricePerNight.toInt()}/night',
                                              style: AppTypography.labelMedium.copyWith(
                                                color: AppColors.accentAmber,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${room.bedType} • Up to ${room.maxGuests} Guests • ${room.roomSize}',
                                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          room.description,
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: room.highlights.map((h) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '• $h',
                                                style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.primaryLight),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 14),
                                        GlassButton(
                                          text: 'Select ${room.name.split(" ").first} Room',
                                          variant: GlassButtonVariant.primary,
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => RoomBookingScreen(
                                                  hotel: widget.hotel,
                                                  initialRoom: room,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard.withValues(alpha: 0.95),
                border: const Border(top: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('STARTING FROM', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
                        Text(
                          '₹${widget.hotel.startingPricePerNight.toInt()} / night',
                          style: AppTypography.headingMedium.copyWith(color: AppColors.accentAmber),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: GlassButton(
                      text: 'Select Room 🏨',
                      variant: GlassButtonVariant.primary,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RoomBookingScreen(
                              hotel: widget.hotel,
                              initialRoom: widget.hotel.roomTypes.first,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
