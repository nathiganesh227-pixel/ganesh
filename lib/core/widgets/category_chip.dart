import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/category.dart';

class CategoryChip extends StatelessWidget {
  final PlazaCategory category;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? category.accentColor.withValues(alpha: 0.22)
                    : AppColors.glassFillMedium,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? category.accentColor.withValues(alpha: 0.6)
                      : AppColors.glassBorderSubtle,
                  width: isSelected ? 1.4 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: category.accentColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: category.accentColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category.icon,
                      size: 16,
                      color: category.accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.title,
                    style: AppTypography.labelLarge.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
