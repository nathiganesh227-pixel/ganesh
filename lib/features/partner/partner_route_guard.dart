import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../navigation/plaza_navigation_shell.dart';
import 'onboarding/partner_onboarding_sheet.dart';

/// Guard widget protecting Partner portal screens against unauthorized access
class PartnerRouteGuard extends StatelessWidget {
  final Widget child;

  const PartnerRouteGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final canAccess = user?.canAccessPartnerPortal == true;

    if (canAccess) {
      return child;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_rounded,
                    color: AppColors.accentGold,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Partner Access Required',
                  style: AppTypography.headingLarge.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This portal requires an active Partner account (Partner Owner, Manager, or Staff). You are currently authenticated as a standard customer or unverified user.',
                  style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const PlazaNavigationShell()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back to App'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        PartnerOnboardingSheet.show(context);
                      },
                      icon: const Icon(Icons.app_registration_rounded, size: 18),
                      label: const Text('Onboard as Partner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
}
