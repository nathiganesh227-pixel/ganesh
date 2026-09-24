import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/data/mock_data.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;

  const HomeHeader({
    super.key,
    this.onLocationTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Location Pill & Notification Bell
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Liquid Glass Location Pill
              GestureDetector(
                onTap: onLocationTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.glassFillMedium,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.glassBorderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary,
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            MockData.currentCity,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Notification Glass Button with unread indicator
              GestureDetector(
                onTap: onNotificationTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.glassFillMedium,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.glassBorderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
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

          const SizedBox(height: 18),

          // PLAZA Branding & Tagline
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppGradients.sunsetPrimary.createShader(bounds),
                child: Text(
                  'PLAZA',
                  style: AppTypography.logoText.copyWith(
                    color: Colors.white,
                    letterSpacing: 5.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '•  Your city. Your plans.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
