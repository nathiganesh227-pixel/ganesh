import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/unified_booking.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/plaza_image.dart';

class ExperienceTimelineView extends StatelessWidget {
  final List<UnifiedBooking> bookings;
  final Function(UnifiedBooking) onBookingTap;

  const ExperienceTimelineView({
    super.key,
    required this.bookings,
    required this.onBookingTap,
  });

  String _getTimelineGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDay = DateTime(date.year, date.month, date.day);

    final diff = bookingDay.difference(today).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'TOMORROW';
    if (diff > 1 && diff <= 5) return 'THIS WEEKEND';
    return 'UPCOMING';
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timeline_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'No upcoming experiences in timeline',
                style: AppTypography.headingSmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    // Group items
    final Map<String, List<UnifiedBooking>> grouped = {};
    for (final b in bookings) {
      final group = _getTimelineGroup(b.date);
      grouped.putIfAbsent(group, () => []).add(b);
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: grouped.keys.length,
      itemBuilder: (context, groupIdx) {
        final groupTitle = grouped.keys.elementAt(groupIdx);
        final items = grouped[groupTitle]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Header with glowing node
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12, top: 16),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    groupTitle,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.glassBorder.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Timeline Items
            ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final booking = entry.value;
              final isLast = idx == items.length - 1 && groupIdx == grouped.keys.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vertical Timeline Line
                    SizedBox(
                      width: 20,
                      child: Column(
                        children: [
                          Container(
                            width: 2,
                            height: 24,
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.accentGold,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 1.5),
                            ),
                          ),
                          Expanded(
                            child: isLast
                                ? const SizedBox.shrink()
                                : Container(
                                    width: 2,
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Event Card
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () => onBookingTap(booking),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: PlazaImage(
                                      imageUrl: booking.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              booking.time,
                                              style: AppTypography.labelSmall.copyWith(
                                                color: AppColors.accentGold,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '• ${DateFormat('d MMM').format(booking.date)}',
                                            style: AppTypography.bodySmall.copyWith(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        booking.title,
                                        style: AppTypography.headingSmall.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        booking.location,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: AppColors.textMuted,
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
            }),
          ],
        );
      },
    );
  }
}
