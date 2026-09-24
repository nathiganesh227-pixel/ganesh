import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_gradients.dart';
import '../constants/app_typography.dart';
import '../models/deal.dart';
import 'plaza_image.dart';

class DealCard extends StatelessWidget {
  final DealItem deal;
  final VoidCallback? onTap;

  const DealCard({
    super.key,
    required this.deal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 310,
        margin: const EdgeInsets.only(right: 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x28FF5E36),
                    Color(0x10FF8B3D),
                    Color(0x180D121F),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Thumbnail
                  PlazaImage(
                    imageUrl: deal.imageUrl,
                    width: 78,
                    height: 78,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 14),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppGradients.sunsetPrimary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            deal.discount,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          deal.title,
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 14,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          deal.partnerName,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              deal.validTill,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.accentAmber,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x20FFFFFF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0x30FFFFFF),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                deal.code,
                                style: AppTypography.labelSmall.copyWith(
                                  letterSpacing: 0.8,
                                  fontSize: 9,
                                ),
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
        ),
      ),
    );
  }
}
