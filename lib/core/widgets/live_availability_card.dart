import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/live_slot.dart';
import 'plaza_image.dart';

class LiveAvailabilityCard extends StatefulWidget {
  final LiveSlotItem slot;
  final VoidCallback? onTap;

  const LiveAvailabilityCard({
    super.key,
    required this.slot,
    this.onTap,
  });

  @override
  State<LiveAvailabilityCard> createState() => _LiveAvailabilityCardState();
}

class _LiveAvailabilityCardState extends State<LiveAvailabilityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x18FFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.glassBorder,
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x30000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top thumbnail and live tag
                  Stack(
                    children: [
                      PlazaImage(
                        imageUrl: widget.slot.imageUrl,
                        height: 120,
                        width: double.infinity,
                        borderRadius: 14,
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xCC090D16),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.liveGreen.withValues(
                                    alpha: _pulseAnimation.value,
                                  ),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.liveGreen.withValues(
                                      alpha: _pulseAnimation.value * 0.5,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppColors.liveGreen,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.liveGreen,
                                          blurRadius: 4 * _pulseAnimation.value,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${widget.slot.availableUnits} ${widget.slot.unitType}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xDD000000),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.slot.timeLabel,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.slot.title,
                    style: AppTypography.headingSmall.copyWith(
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.slot.venue,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.slot.priceLabel,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.accentAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          'Reserve',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
