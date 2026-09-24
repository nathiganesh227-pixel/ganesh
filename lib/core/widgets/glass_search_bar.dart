import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class GlassSearchBar extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onTap;
  final bool readOnly;

  const GlassSearchBar({
    super.key,
    this.hintText = "Search movies, food, events, activities...",
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.glassFillMedium,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x20000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  onTap: onTap,
                  onChanged: onChanged,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (onFilterTap != null) ...[
                Container(
                  width: 1,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: AppColors.glassBorderSubtle,
                ),
                GestureDetector(
                  onTap: onFilterTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
