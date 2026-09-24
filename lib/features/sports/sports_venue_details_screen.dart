import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/sports.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import 'sports_slot_booking_screen.dart';

class SportsVenueDetailsScreen extends StatefulWidget {
  final SportsVenue venue;

  const SportsVenueDetailsScreen({
    super.key,
    required this.venue,
  });

  @override
  State<SportsVenueDetailsScreen> createState() => _SportsVenueDetailsScreenState();
}

class _SportsVenueDetailsScreenState extends State<SportsVenueDetailsScreen> {
  int _selectedImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final allImages = widget.venue.galleryImages.isNotEmpty
        ? widget.venue.galleryImages
        : [widget.venue.coverImageUrl];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero Image Gallery
              SliverAppBar(
                expandedHeight: 340,
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
                                  width: _selectedImageIndex == idx ? 22 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: _selectedImageIndex == idx ? AppColors.primary : Colors.white38,
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

              // Venue Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Supported Sports Pills
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.venue.supportedSports.map((sport) {
                          return GlassPill(
                            label: '${sport.emoji} ${sport.label}',
                            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                            textColor: AppColors.primaryLight,
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),
                      Text(widget.venue.name, style: AppTypography.headingLarge),

                      const SizedBox(height: 8),

                      // Location & Rating
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${widget.venue.address} (${widget.venue.distance})',
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                                  widget.venue.rating.toStringAsFixed(2),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.accentGold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('(${widget.venue.reviewCount} player reviews)', style: AppTypography.bodySmall),
                          if (widget.venue.isLiveNow) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.liveGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.liveGreen, shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  Text('Open Today', style: AppTypography.labelSmall.copyWith(color: AppColors.liveGreen, fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // About Venue
                      Text('About Venue', style: AppTypography.labelLarge),
                      const SizedBox(height: 8),
                      Text(
                        widget.venue.description,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                      ),

                      const SizedBox(height: 24),

                      // Facilities
                      Text('Turf Facilities', style: AppTypography.labelLarge),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.venue.facilities.map((facility) {
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
                                const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.liveGreen),
                                const SizedBox(width: 6),
                                Text(facility, style: AppTypography.labelSmall),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Rules & Footwear Guidelines
                      Text('Ground Rules & Footwear', style: AppTypography.labelLarge),
                      const SizedBox(height: 10),
                      GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: widget.venue.rules.map((rule) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('⚠️', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(rule, style: AppTypography.bodySmall)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Available Slots Live Peek
                      Text('Upcoming Slots Today', style: AppTypography.headingMedium),
                      const SizedBox(height: 12),
                      ...widget.venue.availableSlots.take(3).map((slot) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(slot.time, style: AppTypography.labelLarge),
                                    Text(slot.courtName, style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('₹${slot.price.toInt()} / hr', style: AppTypography.labelMedium.copyWith(color: AppColors.accentAmber)),
                                    const SizedBox(width: 12),
                                    GlassPill(
                                      label: slot.isBookable ? 'Available' : 'Booked',
                                      backgroundColor: slot.isBookable ? AppColors.liveGreen.withValues(alpha: 0.2) : Colors.white10,
                                      textColor: slot.isBookable ? AppColors.liveGreen : AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Bottom CTA
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
                          '₹${widget.venue.startingPricePerHour.toInt()} / hr',
                          style: AppTypography.headingMedium.copyWith(color: AppColors.accentAmber),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: GlassButton(
                      text: 'Book Slot 🏏',
                      variant: GlassButtonVariant.primary,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SportsSlotBookingScreen(
                              venue: widget.venue,
                              initialSport: widget.venue.supportedSports.first,
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
