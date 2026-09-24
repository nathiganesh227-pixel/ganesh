import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/plan_summary.dart';
import '../../../core/widgets/glass_button.dart';

class BuildMyDayCard extends StatelessWidget {
  final DayPlan plan;
  final VoidCallback? onCustomizeTap;
  final VoidCallback? onBookPlanTap;

  const BuildMyDayCard({
    super.key,
    required this.plan,
    this.onCustomizeTap,
    this.onBookPlanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x308B5CF6), // Royal violet ambient
                  Color(0x20FF5E36), // Sunset warm touch
                  Color(0x15070A11),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0x358B5CF6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge & title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppGradients.royalViolet,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Build My Day',
                              style: AppTypography.headingMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'AI-curated end-to-end plan',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0x20FFFFFF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0x30FFFFFF),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        plan.vibe,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Parameter Pills: People, Budget, Duration
                Row(
                  children: [
                    _buildParamPill(
                      Icons.people_outline_rounded,
                      '${plan.peopleCount} People',
                    ),
                    const SizedBox(width: 8),
                    _buildParamPill(
                      Icons.currency_rupee_rounded,
                      '₹${plan.budget.toInt()} Budget',
                    ),
                    const SizedBox(width: 8),
                    _buildParamPill(
                      Icons.schedule_rounded,
                      '${plan.durationHours} Hours',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Suggested Route/Flow Visualizer (Movie → Dinner → Activity)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0x25070A11),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.glassBorderSubtle,
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStepPill(
                            Icons.movie_creation_outlined,
                            'Movie',
                            const Color(0xFFFF5E36),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          _buildStepPill(
                            Icons.restaurant_outlined,
                            'Dinner',
                            const Color(0xFFFF8B3D),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          _buildStepPill(
                            Icons.sports_esports_outlined,
                            'Activity',
                            const Color(0xFF06B6D4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(
                        color: Color(0x15FFFFFF),
                        height: 1,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kalki 2898 AD → Ci Gusta → Bowling',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Begins at 04:00 PM • Total ~₹3,200',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
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

                const SizedBox(height: 16),

                // CTA Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        text: 'Customize Plan',
                        variant: GlassButtonVariant.secondary,
                        height: 44,
                        onPressed: onCustomizeTap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassButton(
                        text: 'Book Whole Day',
                        variant: GlassButtonVariant.primary,
                        height: 44,
                        icon: Icons.bolt_rounded,
                        onPressed: onBookPlanTap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParamPill(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x18FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0x15FFFFFF),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
