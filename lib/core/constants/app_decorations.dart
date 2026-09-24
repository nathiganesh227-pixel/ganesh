import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_gradients.dart';

/// PLAZA Design System - Glass Decorations & Shadows
class AppDecorations {
  AppDecorations._();

  // Standard Border Radius
  static const double radiusS = 12.0;
  static const double radiusM = 18.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;
  static const double radiusPill = 999.0;

  // Liquid Glass Box Decoration - Subtle
  static BoxDecoration glassSubtle({
    double radius = radiusM,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: AppColors.glassFill,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? AppColors.glassBorderSubtle,
        width: 1.0,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x25000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  // Liquid Glass Box Decoration - Elevated & Specular
  static BoxDecoration glassElevated({
    double radius = radiusL,
    Color? borderColor,
    bool showGlow = false,
  }) {
    return BoxDecoration(
      gradient: AppGradients.glassSpecular,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? AppColors.glassBorder,
        width: 1.2,
      ),
      boxShadow: [
        const BoxShadow(
          color: Color(0x40000000),
          blurRadius: 24,
          offset: Offset(0, 8),
          spreadRadius: -2,
        ),
        if (showGlow)
          const BoxShadow(
            color: Color(0x30FF5E36),
            blurRadius: 28,
            offset: Offset(0, 0),
            spreadRadius: 2,
          ),
      ],
    );
  }

  // Primary Sunset Glowing Button Decoration
  static BoxDecoration sunsetButton({
    double radius = radiusPill,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      gradient: isPressed ? AppGradients.sunsetSubtle : AppGradients.sunsetPrimary,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: const Color(0x40FFFFFF),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFF5E36).withValues(alpha: isPressed ? 0.2 : 0.45),
          blurRadius: isPressed ? 12 : 20,
          offset: const Offset(0, 6),
          spreadRadius: isPressed ? -2 : 0,
        ),
      ],
    );
  }

  // Live indicator pulsing border
  static BoxDecoration livePill({double radius = radiusPill}) {
    return BoxDecoration(
      color: const Color(0x2010B981),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: const Color(0x6010B981),
        width: 1.0,
      ),
    );
  }
}
