import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/event.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import 'event_ticket_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  final PlazaEvent event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(event.eventDate);

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

                    // Top Bar
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

                // Title & Info
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

                      // Event Key Logistics Card
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
                              '${event.location} • ${event.distance}',
                            ),
                            const Divider(color: Color(0x15FFFFFF), height: 20),
                            _buildLogisticsRow(
                              Icons.verified_user_outlined,
                              'Age Requirement: ${event.ageRestriction}',
                              'Language: ${event.language} • Duration: ${event.duration}',
                            ),
                          ],
                        ),
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
                        Text('About The Event', style: AppTypography.headingSmall),
                        const SizedBox(height: 8),
                        Text(
                          event.description,
                          style: AppTypography.bodyMedium.copyWith(
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (event.highlights.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text('Event Highlights', style: AppTypography.labelLarge),
                          const SizedBox(height: 6),
                          ...event.highlights.map(
                            (h) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: AppColors.accentAmber),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      h,
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
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

                // Performer / Artist Lineup
                if (event.artists.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Artist Lineup', style: AppTypography.headingSmall),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: event.artists.length,
                      itemBuilder: (context, index) {
                        final artist = event.artists[index];
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 14),
                          child: Column(
                            children: [
                              PlazaImage(
                                imageUrl: artist.imageUrl,
                                width: 64,
                                height: 64,
                                borderRadius: 32,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                artist.name,
                                style: AppTypography.labelSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                artist.role,
                                style: AppTypography.bodySmall.copyWith(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Ticket Tiers Preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available Ticket Categories', style: AppTypography.headingSmall),
                      const SizedBox(height: 10),
                      ...event.ticketTiers.map(
                        (tier) => Container(
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
                                      Text(tier.name, style: AppTypography.labelLarge),
                                      const SizedBox(height: 2),
                                      Text(
                                        tier.description,
                                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '₹${tier.price.toInt()}',
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

          // Bottom Fixed CTA Bar
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
                          Text('PASSES FROM', style: AppTypography.labelSmall),
                          const SizedBox(height: 2),
                          Text(
                            '₹${event.startingPrice.toInt()}',
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
                          text: 'Get Tickets',
                          icon: Icons.confirmation_number_rounded,
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
  }

  Widget _buildLogisticsRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondaryViolet.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.secondaryViolet, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelLarge.copyWith(fontSize: 13)),
              Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
