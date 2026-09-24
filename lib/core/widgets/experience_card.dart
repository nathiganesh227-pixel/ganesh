import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_gradients.dart';
import '../constants/app_typography.dart';
import '../models/experience.dart';
import 'plaza_image.dart';
import 'glass_pill.dart';

class ExperienceCard extends StatelessWidget {
  final ExperienceItem experience;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const ExperienceCard({
    super.key,
    required this.experience,
    this.onTap,
    this.width = 280,
    this.height = 360,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x60000000),
              blurRadius: 24,
              offset: Offset(0, 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              PlazaImage(
                imageUrl: experience.imageUrl,
                fit: BoxFit.cover,
              ),

              // Cinematic Gradient Overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.cardImageOverlay,
                ),
              ),

              // Specular Glass Border
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.glassBorder,
                    width: 1.2,
                  ),
                ),
              ),

              // Top Badges & Rating
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (experience.badge != null)
                      GlassPill(
                        label: experience.badge!,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.85),
                        borderColor: const Color(0x60FFFFFF),
                        textColor: Colors.white,
                      )
                    else
                      const SizedBox.shrink(),
                    GlassPill(
                      label: experience.rating.toStringAsFixed(1),
                      icon: Icons.star_rounded,
                      iconColor: AppColors.accentGold,
                      backgroundColor: const Color(0x800D121F),
                    ),
                  ],
                ),
              ),

              // Bottom Glass Info Panel
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x500B1120),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.glassBorderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            experience.title,
                            style: AppTypography.headingSmall.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            experience.subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    experience.distance,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                experience.priceLabel,
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.accentAmber,
                                  fontWeight: FontWeight.w700,
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
            ],
          ),
        ),
      ),
    );
  }
}
