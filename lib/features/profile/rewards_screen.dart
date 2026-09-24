import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/rewards.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  void _redeemVoucher(BuildContext context, RewardVoucher voucher) {
    final state = PlazaGlobalState.instance;

    if (voucher.isRedeemed) {
      _showCopiedSnackBar(context, voucher.code);
      return;
    }

    if (state.rewardsBalance < voucher.pointsCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need ${voucher.pointsCost - state.rewardsBalance} more points to redeem "${voucher.title}".',
          ),
          backgroundColor: AppColors.surfaceCard,
        ),
      );
      return;
    }

    final success = state.redeemVoucher(voucher.id);
    if (success) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          title: Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: AppColors.accentGold),
              const SizedBox(width: 10),
              Text('Voucher Unlocked! 🎉', style: AppTypography.headingMedium),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Use this voucher code at checkout to get ₹${voucher.discountAmount.toInt()} off.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      voucher.code,
                      style: AppTypography.headingSmall.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Icon(Icons.copy_rounded, color: AppColors.accentGold, size: 20),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _showCopiedSnackBar(context, voucher.code);
              },
              child: const Text('Copy & Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  void _showCopiedSnackBar(BuildContext context, String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher code $code copied to clipboard!'),
        backgroundColor: AppColors.surfaceCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final state = PlazaGlobalState.instance;
        final balance = state.rewardsBalance;
        final redeemableValue = (balance * 0.1).toInt();
        final progress = (balance / 5000).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PLAZA CLUB', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2)),
                            Text('Rewards & Wallet', style: AppTypography.headingMedium),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Points Balance Hero Glass Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassCard(
                      padding: const EdgeInsets.all(22),
                      borderColor: AppColors.accentGold.withValues(alpha: 0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'POINTS BALANCE',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.accentGold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        NumberFormat('#,###').format(balance),
                                        style: AppTypography.displayLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'PTS',
                                        style: AppTypography.labelLarge.copyWith(
                                          color: AppColors.accentGold,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '₹$redeemableValue redeemable value',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.liveGreen),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.sunsetPrimary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'BLACK TIER',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Tier Progress Bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Next: Royal Diamond Tier',
                                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    '${(progress * 100).toInt()}% ($balance / 5,000 pts)',
                                    style: AppTypography.labelSmall.copyWith(color: AppColors.accentGold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: AppColors.surfaceElevated,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Referral Program Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      borderColor: AppColors.primary.withValues(alpha: 0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people_alt_rounded, color: AppColors.primaryLight, size: 22),
                              const SizedBox(width: 10),
                              Text('Give ₹250, Get 500 Pts', style: AppTypography.headingSmall),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share your exclusive referral code with friends in Hyderabad.',
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.glassBorder),
                                  ),
                                  child: Text(
                                    state.referralCode,
                                    style: AppTypography.labelMedium.copyWith(
                                      fontFamily: 'monospace',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onPressed: () {
                                  _showCopiedSnackBar(context, state.referralCode);
                                },
                                child: const Text(
                                  'Copy Code',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Earning Rules Guide
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionHeader(
                      title: 'How to Earn Points',
                      subtitle: 'Rewards on every experience',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildEarningRow(Icons.movie_filter_rounded, 'Movies & Dining', '10 pts per ₹100 spent'),
                          const Divider(color: AppColors.glassBorder, height: 18),
                          _buildEarningRow(Icons.sports_esports_rounded, 'Activities, Sports & Stays', '15 pts per ₹100 spent'),
                          const Divider(color: AppColors.glassBorder, height: 18),
                          _buildEarningRow(Icons.shopping_bag_rounded, 'Shopping & Squad Bookings', '20 pts per ₹100 spent'),
                          const Divider(color: AppColors.glassBorder, height: 18),
                          _buildEarningRow(Icons.auto_awesome_rounded, 'Build My Day Sequences', '+450 pts bonus per booked plan'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Redemption Voucher Catalog
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionHeader(
                      title: 'Redemption Catalog',
                      subtitle: 'Exchange points for real vouchers',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.vouchers.length,
                    itemBuilder: (context, index) {
                      final voucher = state.vouchers[index];
                      final canAfford = balance >= voucher.pointsCost;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          borderColor: voucher.isRedeemed
                              ? AppColors.liveGreen.withValues(alpha: 0.5)
                              : AppColors.glassBorder,
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: voucher.isRedeemed
                                      ? AppColors.liveGreen.withValues(alpha: 0.2)
                                      : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  voucher.isRedeemed ? Icons.check_circle_rounded : Icons.local_offer_rounded,
                                  color: voucher.isRedeemed ? AppColors.liveGreen : AppColors.accentGold,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(voucher.title, style: AppTypography.headingSmall),
                                    const SizedBox(height: 2),
                                    Text(voucher.description, style: AppTypography.bodySmall),
                                    const SizedBox(height: 6),
                                    Text(
                                      voucher.isRedeemed
                                          ? 'CODE: ${voucher.code}'
                                          : '${voucher.pointsCost} Points',
                                      style: AppTypography.labelSmall.copyWith(
                                        fontFamily: voucher.isRedeemed ? 'monospace' : null,
                                        color: voucher.isRedeemed ? AppColors.liveGreen : AppColors.accentGold,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: voucher.isRedeemed
                                      ? AppColors.surfaceElevated
                                      : canAfford
                                          ? AppColors.primary
                                          : AppColors.surfaceElevated,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                onPressed: () => _redeemVoucher(context, voucher),
                                child: Text(
                                  voucher.isRedeemed ? 'Copy' : 'Redeem',
                                  style: TextStyle(
                                    color: voucher.isRedeemed
                                        ? AppColors.liveGreen
                                        : canAfford
                                            ? Colors.white
                                            : AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Points History Ledger
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionHeader(
                      title: 'Points History',
                      subtitle: 'Recent activity and ledger',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.rewardTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = state.rewardTransactions[index];
                      final isCredit = tx.isCredit;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: isCredit ? AppColors.liveGreen : AppColors.alertRed,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tx.title, style: AppTypography.labelLarge),
                                    Text(tx.description, style: AppTypography.bodySmall),
                                  ],
                                ),
                              ),
                              Text(
                                '${isCredit ? '+' : '-'}${tx.pointsChange} pts',
                                style: AppTypography.labelLarge.copyWith(
                                  color: isCredit ? AppColors.liveGreen : AppColors.alertRed,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEarningRow(IconData icon, String title, String points) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryLight),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: AppTypography.bodySmall.copyWith(color: Colors.white)),
        ),
        Text(
          points,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.accentGold,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
