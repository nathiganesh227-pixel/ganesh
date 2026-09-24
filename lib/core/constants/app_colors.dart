import 'package:flutter/material.dart';

/// PLAZA Design System - Core Color Palette
/// Premium Apple-inspired Liquid Glass aesthetic on dark cinematic canvas.
class AppColors {
  AppColors._();

  // Dark Canvas & Backgrounds
  static const Color background = Color(0xFF070A11);
  static const Color surfaceDark = Color(0xFF0D121F);
  static const Color surfaceCard = Color(0xFF131B2E);
  static const Color surfaceElevated = Color(0xFF1B243B);

  // Liquid Glass Tints
  static const Color glassFill = Color(0x14FFFFFF); // 8% white
  static const Color glassFillMedium = Color(0x22FFFFFF); // 13% white
  static const Color glassFillHeavy = Color(0x35FFFFFF); // 21% white
  static const Color glassBorder = Color(0x28FFFFFF); // 16% white specular border
  static const Color glassBorderSubtle = Color(0x15FFFFFF); // 8% white subtle border
  static const Color glassBorderAccent = Color(0x60FF6A3D); // Warm specular border

  // Sunset & Brand Warm Accents
  static const Color primary = Color(0xFFFF5E36); // Sunset warm coral orange
  static const Color primaryLight = Color(0xFFFF824C);
  static const Color primaryDark = Color(0xFFE54A23);
  static const Color accentAmber = Color(0xFFFFB300); // Warm sunset amber
  static const Color accentGold = Color(0xFFFFC107);

  // Secondary Accents
  static const Color secondaryViolet = Color(0xFF8B5CF6);
  static const Color secondaryIndigo = Color(0xFF6366F1);
  static const Color secondaryBlue = Color(0xFF38BDF8);
  static const Color secondaryCyan = Color(0xFF06B6D4);

  // Live / Status / Badges
  static const Color liveGreen = Color(0xFF10B981);
  static const Color liveGreenGlow = Color(0x4010B981);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF97316);

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDark = Color(0xFF0F172A);

  // Shadows
  static const Color shadowGlow = Color(0x40FF5E36);
  static const Color shadowGlass = Color(0x60000000);
}
