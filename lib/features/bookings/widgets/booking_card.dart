import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/unified_booking.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_pill.dart';
import '../../../core/widgets/plaza_image.dart';

class BookingCard extends StatelessWidget {
  final UnifiedBooking booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onCancel,
  });

  Color _getVerticalColor(UnifiedBookingType type) {
    switch (type) {
      case UnifiedBookingType.movie:
        return AppColors.primary;
      case UnifiedBookingType.dining:
        return const Color(0xFFFF8B3D);
      case UnifiedBookingType.event:
        return const Color(0xFF8B5CF6);
      case UnifiedBookingType.activity:
        return const Color(0xFF06B6D4);
      case UnifiedBookingType.shopping:
        return const Color(0xFFEC4899);
      case UnifiedBookingType.stay:
        return const Color(0xFF3B82F6);
      case UnifiedBookingType.sports:
        return const Color(0xFF10B981);
    }
  }

  IconData _getVerticalIcon(UnifiedBookingType type) {
    switch (type) {
      case UnifiedBookingType.movie:
        return Icons.movie_filter_rounded;
      case UnifiedBookingType.dining:
        return Icons.restaurant_rounded;
      case UnifiedBookingType.event:
        return Icons.confirmation_number_rounded;
      case UnifiedBookingType.activity:
        return Icons.sports_esports_rounded;
      case UnifiedBookingType.shopping:
        return Icons.shopping_bag_rounded;
      case UnifiedBookingType.stay:
        return Icons.hotel_rounded;
      case UnifiedBookingType.sports:
        return Icons.sports_cricket_rounded;
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return const Color(0xFF60A5FA);
      case BookingStatus.active:
        return AppColors.liveGreen;
      case BookingStatus.completed:
        return AppColors.textMuted;
      case BookingStatus.cancelled:
        return AppColors.alertRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final verticalColor = _getVerticalColor(booking.type);
    final statusColor = _getStatusColor(booking.status);
    final formattedDate = DateFormat('EEE, d MMM').format(booking.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassCard(
          padding: EdgeInsets.zero,
          borderColor: booking.status == BookingStatus.active
              ? AppColors.liveGreen.withValues(alpha: 0.5)
              : AppColors.glassBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top banner / image section
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: PlazaImage(
                        imageUrl: booking.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Dark gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            AppColors.background.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Top badge bar
                  Positioned(
                    top: 12,
                    left: 14,
                    right: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category Pill
                        GlassPill(
                          label: booking.type.displayName.toUpperCase(),
                          icon: _getVerticalIcon(booking.type),
                          iconColor: verticalColor,
                          textColor: Colors.white,
                        ),
                        // Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.4),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (booking.status == BookingStatus.active) ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: statusColor.withValues(alpha: 0.8),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Text(
                                booking.status.label.toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Title overlay at bottom of image
                  Positioned(
                    bottom: 10,
                    left: 14,
                    right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.title,
                          style: AppTypography.headingMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.subtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Card details body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Info Row: Date/Time + Seat/Slot Info
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$formattedDate • ${booking.time}',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (booking.seatOrSlotInfo != null) ...[
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              booking.seatOrSlotInfo!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.accentGold,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Info Row: Location & Total
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            booking.location,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          booking.totalAmount > 0
                              ? '₹${booking.totalAmount.toInt()}'
                              : 'Reserved',
                          style: AppTypography.headingSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Divider line with dotted perforation look
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.glassBorder.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Footer: ID & View Pass Action
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PASS CODE',
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 9,
                                letterSpacing: 0.6,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              booking.id,
                              style: AppTypography.labelMedium.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: AppGradients.sunsetPrimary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.qr_code_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Digital Pass',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
