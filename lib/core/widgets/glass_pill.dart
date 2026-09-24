import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class GlassPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const GlassPill({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.glassFillMedium,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: borderColor ?? AppColors.glassBorderSubtle,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: iconColor ?? AppColors.primary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: textColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
