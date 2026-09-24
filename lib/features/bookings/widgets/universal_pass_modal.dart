import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/unified_booking.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/plaza_image.dart';
import '../../movies/widgets/qr_code_widget.dart';

class UniversalPassModal extends StatelessWidget {
  final UnifiedBooking booking;
  final VoidCallback? onCancelBooking;

  const UniversalPassModal({
    super.key,
    required this.booking,
    this.onCancelBooking,
  });

  static void show(BuildContext context, UnifiedBooking booking, {VoidCallback? onCancel}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UniversalPassModal(
        booking: booking,
        onCancelBooking: onCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(booking.date);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1.2),
        ),
      ),
      child: Column(
        children: [
          // Drag indicator bar
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.glassBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PLAZA DIGITAL PASS', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2)),
                    Text(booking.type.displayName, style: AppTypography.headingLarge),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Boarding / Entry Pass Glass Card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Experience hero
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: PlazaImage(
                                  imageUrl: booking.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.title,
                                    style: AppTypography.headingMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.subtitle,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Perforation cut line
                        Row(
                          children: List.generate(
                            28,
                            (index) => Expanded(
                              child: Container(
                                height: 2,
                                color: index % 2 == 0
                                    ? AppColors.glassBorder
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // QR Code Scanner Box
                        Center(
                          child: PlazaQRCodeWidget(
                            data: booking.confirmationCode ?? booking.id,
                            size: 160,
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          'Scan at turnstile / concierge gate',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          booking.confirmationCode ?? booking.id,
                          style: AppTypography.labelMedium.copyWith(
                            fontFamily: 'monospace',
                            color: AppColors.accentGold,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Pass Details Table
                        _buildPassDetailRow('DATE', formattedDate),
                        const SizedBox(height: 10),
                        _buildPassDetailRow('TIME', booking.time),
                        const SizedBox(height: 10),
                        _buildPassDetailRow('LOCATION', booking.location),
                        if (booking.seatOrSlotInfo != null) ...[
                          const SizedBox(height: 10),
                          _buildPassDetailRow('SEATS / DETAILS', booking.seatOrSlotInfo!),
                        ],
                        const SizedBox(height: 10),
                        _buildPassDetailRow(
                          'AMOUNT',
                          booking.totalAmount > 0 ? '₹${booking.totalAmount.toInt()}' : 'Free / Complimentary',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Smart Contextual Suggestion Banner
                  _buildContextualRecommendation(context),

                  const SizedBox(height: 20),

                  // Actions
                  if (booking.status == BookingStatus.upcoming && onCancelBooking != null) ...[
                    GlassButton(
                      text: 'Cancel Booking',
                      icon: Icons.cancel_outlined,
                      variant: GlassButtonVariant.ghost,
                      onPressed: () {
                        Navigator.pop(context);
                        onCancelBooking!();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  GlassButton(
                    text: 'Add to Apple Wallet',
                    icon: Icons.account_balance_wallet_outlined,
                    variant: GlassButtonVariant.secondary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${booking.title} added to Apple Wallet!'),
                          backgroundColor: AppColors.surfaceCard,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildContextualRecommendation(BuildContext context) {
    String recTitle = 'Discover Nearby Experiences';
    String recSubtitle = 'Pair this with fine dining & activities';
    IconData recIcon = Icons.auto_awesome_rounded;

    if (booking.type == UnifiedBookingType.movie) {
      recTitle = 'Reserve Dinner Nearby';
      recSubtitle = 'Farzi Café Jubilee Hills is 10 mins away • 25% OFF';
      recIcon = Icons.restaurant_rounded;
    } else if (booking.type == UnifiedBookingType.dining) {
      recTitle = 'Catch a Movie After Dinner';
      recSubtitle = 'Dune: Part Two at AMB Cinemas IMAX starts 9:45 PM';
      recIcon = Icons.movie_filter_rounded;
    } else if (booking.type == UnifiedBookingType.activity) {
      recTitle = 'Post-Activity Chill & Drinks';
      recSubtitle = 'Olive Bistro & Bar nearby has rooftop seating open';
      recIcon = Icons.local_bar_rounded;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppGradients.sunsetPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(recIcon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recTitle,
                  style: AppTypography.headingSmall.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  recSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryLight),
        ],
      ),
    );
  }
}
