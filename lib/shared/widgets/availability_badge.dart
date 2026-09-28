import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/integration_models.dart';

class AvailabilityBadge extends StatelessWidget {
  final AvailabilityStatus status;
  final AvailabilityFreshness freshness;
  final int? remainingQuantity;
  final bool showFreshness;

  const AvailabilityBadge({
    super.key,
    required this.status,
    this.freshness = AvailabilityFreshness.fresh,
    this.remainingQuantity,
    this.showFreshness = false,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case AvailabilityStatus.available:
        badgeColor = AppColors.liveGreen;
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
        label = remainingQuantity != null && remainingQuantity! <= 10
            ? 'Only $remainingQuantity left'
            : 'Available';
        break;
      case AvailabilityStatus.limited:
        badgeColor = AppColors.warningOrange;
        textColor = Colors.white;
        icon = Icons.timelapse_rounded;
        label = remainingQuantity != null
            ? 'Limited ($remainingQuantity left)'
            : 'Limited Slots';
        break;
      case AvailabilityStatus.soldOut:
        badgeColor = AppColors.alertRed;
        textColor = Colors.white;
        icon = Icons.cancel_rounded;
        label = 'Sold Out';
        break;
      case AvailabilityStatus.unavailable:
        badgeColor = AppColors.textMuted;
        textColor = Colors.white70;
        icon = Icons.block_rounded;
        label = 'Unavailable';
        break;
      case AvailabilityStatus.unknown:
        badgeColor = AppColors.secondaryIndigo;
        textColor = Colors.white70;
        icon = Icons.help_outline_rounded;
        label = 'Check Availability';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          if (showFreshness && freshness == AvailabilityFreshness.stale) ...[
            const SizedBox(width: 4),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.accentAmber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              'Stale',
              style: AppTypography.caption.copyWith(
                color: AppColors.accentAmber,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
