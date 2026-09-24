import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// PLAZA Design System - Typography
/// Clean, geometric Apple-inspired typography using Plus Jakarta Sans.
class AppTypography {
  AppTypography._();

  static TextStyle get logoText => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 4.0,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.15,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingLarge => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingMedium => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get headingSmall => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: AppColors.textPrimary,
      );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get priceTag => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );
}
