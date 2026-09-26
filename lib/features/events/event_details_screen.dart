import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/event.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import 'event_ticket_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final PlazaEvent event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isDescriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(event.eventDate);

    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final isFav = PlazaGlobalState.instance.favoriteIds.contains(event.id);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Banner & Poster
                    Stack(
                      children: [
                        SizedBox(
                          height: 400,
                          width: double.infinity,
                          child: PlazaImage(
                            imageUrl: event.bannerUrl,
                            fit: BoxFit.cover,
                          ),
                        ),

                        Container(
                          height: 400,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x70070A11),
                                Color(0x30070A11),
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
                                        PlazaGlobalState.instance.toggleFavorite(event.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isFav ? 'Removed from favorites' : 'Saved to event favorites ❤️',
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
                                            content: Text('Sharing ${event.title} link...'),
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

                        // Category Pill
                        Positioned(
                          bottom: 16,
                          left: 20,
                          child: GlassPill(
                            label: event.category.label,
                            backgroundColor: AppColors.secondaryViolet.withValues(alpha: 0.8),
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    // Title & Tagline
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title, style: AppTypography.displayMedium.copyWith(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            event.tagline,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primaryLight,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Event Logistics Card
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildLogisticsRow(
                                  Icons.calendar_today_rounded,
                                  dateStr,
                                  event.time,
                                ),
                                const Divider(color: Color(0x15FFFFFF), height: 20),
                                _buildLogisticsRow(
                                  Icons.location_on_rounded,
                                  event.venue,
                                  '${event.location} (${event.distance})',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Metadata Badges (Age, Language, Duration)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              GlassPill(
                                label: event.ageRestriction,
                                icon: Icons.verified_user_outlined,
                                iconColor: AppColors.primary,
                                backgroundColor: AppColors.glassFillMedium,
                              ),
                              GlassPill(
                                label: event.language,
                                icon: Icons.translate_rounded,
                                iconColor: AppColors.secondaryViolet,
                                backgroundColor: AppColors.glassFillMedium,
                              ),
                              GlassPill(
                                label: event.duration,
                                icon: Icons.timer_outlined,
                                iconColor: AppColors.accentAmber,
                                backgroundColor: AppColors.glassFillMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // About the Event
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('About the Event', style: AppTypography.headingSmall),
                            const SizedBox(height: 8),
                            Text(
                              event.description,
                              style: AppTypography.bodyMedium.copyWith(
                                height: 1.5,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: _isDescriptionExpanded ? null : 4,
                              overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            ),
                            if (event.description.length > 200) ...[
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                                child: Text(
                                  _isDescriptionExpanded ? 'Read Less' : 'Read More',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.secondaryViolet,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Performers / Artists Section
                    if (event.artists.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Artists & Performers', style: AppTypography.headingSmall),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: event.artists.length,
                          itemBuilder: (context, index) {
                            final artist = event.artists[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 16),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: PlazaImage(
                                      imageUrl: artist.imageUrl,
                                      width: 60,
                                      height: 60,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        artist.name,
                                        style: AppTypography.labelLarge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        artist.role,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Available Ticket Tiers Preview
                    if (event.ticketTiers.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ticket Categories', style: AppTypography.headingSmall),
                            Text(
                              '${event.ticketTiers.length} categories',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: event.ticketTiers.map((tier) {
                            final isFewLeft = tier.remainingCount > 0 && tier.remainingCount <= 20;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(tier.name, style: AppTypography.labelLarge),
                                        Text(
                                          '₹${tier.price.toInt()}',
                                          style: AppTypography.priceTag.copyWith(
                                            color: AppColors.accentAmber,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      tier.description,
                                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          tier.remainingCount > 0
                                              ? '${tier.remainingCount} passes remaining'
                                              : 'Sold Out',
                                          style: AppTypography.bodySmall.copyWith(
                                            fontSize: 10,
                                            color: isFewLeft
                                                ? AppColors.alertRed
                                                : (tier.remainingCount > 0
                                                    ? AppColors.liveGreen
                                                    : AppColors.textMuted),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (tier.perks.isNotEmpty)
                                          Text(
                                            '${tier.perks.length} perks included',
                                            style: AppTypography.bodySmall.copyWith(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 120),
                  ],
                ),
              ),

              // Bottom Docked Booking CTA Bar
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
                              Text('PASSES FROM', style: AppTypography.labelSmall),
                              const SizedBox(height: 2),
                              Text(
                                event.startingPrice > 0
                                    ? '₹${event.startingPrice.toInt()}'
                                    : 'Free Entry',
                                style: AppTypography.priceTag.copyWith(
                                  fontSize: 18,
                                  color: AppColors.accentAmber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: GlassButton(
                              text: 'Get Tickets',
                              icon: Icons.confirmation_number_outlined,
                              variant: GlassButtonVariant.primary,
                              height: 52,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventTicketScreen(event: event),
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

  Widget _buildLogisticsRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondaryViolet.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.secondaryViolet),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelLarge),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
