import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/plan.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../movies/widgets/qr_code_widget.dart';

class PlanConfirmationModal extends StatelessWidget {
  final PlazaPlan plan;
  final String planBookingId;
  final VoidCallback onViewInWallet;

  const PlanConfirmationModal({
    super.key,
    required this.plan,
    required this.planBookingId,
    required this.onViewInWallet,
  });

  static void show(
    BuildContext context, {
    required PlazaPlan plan,
    required String planBookingId,
    required VoidCallback onViewInWallet,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlanConfirmationModal(
        plan: plan,
        planBookingId: planBookingId,
        onViewInWallet: onViewInWallet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.glassBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONCIERGE PASS', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2)),
                    Text('Plan Booked! 🎉', style: AppTypography.headingLarge),
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
                  // Plan Master Pass
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderColor: AppColors.primary.withValues(alpha: 0.4),
                    child: Column(
                      children: [
                        Text(
                          plan.title,
                          style: AppTypography.headingMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${plan.peopleCount} Guests • ${plan.items.length} Curated Sequences',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.accentGold),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: PlazaQRCodeWidget(
                            data: planBookingId,
                            size: 150,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          planBookingId,
                          style: AppTypography.labelMedium.copyWith(
                            fontFamily: 'monospace',
                            color: AppColors.accentGold,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.liveGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.liveGreen.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: AppColors.accentGold, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '+450 PLAZA Points awarded for booking full day sequence!',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Items list
                        ...plan.items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: idx < plan.items.length - 1
                                      ? AppColors.glassBorder.withValues(alpha: 0.4)
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${idx + 1}',
                                      style: AppTypography.labelSmall.copyWith(fontSize: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.title, style: AppTypography.labelLarge),
                                      Text(
                                        '${item.time} • ${item.venue}',
                                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.check_circle_rounded, color: AppColors.liveGreen, size: 18),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassButton(
                    text: 'View Passes in Central Wallet',
                    icon: Icons.confirmation_number_rounded,
                    variant: GlassButtonVariant.primary,
                    onPressed: () {
                      Navigator.pop(context);
                      onViewInWallet();
                    },
                  ),
                  const SizedBox(height: 12),
                  GlassButton(
                    text: 'Share Day Plan with Friends',
                    icon: Icons.share_rounded,
                    variant: GlassButtonVariant.secondary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Itinerary link copied for ${plan.title}!'),
                          backgroundColor: AppColors.surfaceCard,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
