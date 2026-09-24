import 'package:flutter/material.dart';

/// PLAZA Design System - Gradients
/// Dynamic sunset gradients, specular glass sheen, and radial ambient backdrop glows.
class AppGradients {
  AppGradients._();

  // Signature Sunset Brand Gradient
  static const LinearGradient sunsetPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF5E36), // Sunset Coral
      Color(0xFFFF8B3D), // Warm Tangerine
      Color(0xFFFFB300), // Amber Glow
    ],
  );

  // Subtle button press / accent gradient
  static const LinearGradient sunsetSubtle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FF5E36),
      Color(0x22FF8B3D),
    ],
  );

  // Violet-Indigo secondary gradient (for exclusive events/VIP badges)
  static const LinearGradient royalViolet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B5CF6),
      Color(0xFF6366F1),
      Color(0xFF3B82F6),
    ],
  );

  // Liquid Glass Specular Gradient (Simulates light catching edge of glass)
  static const LinearGradient glassSpecular = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x35FFFFFF),
      Color(0x0FFFFFFF),
      Color(0x05FFFFFF),
      Color(0x18FFFFFF),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  // Liquid Glass Subtle Fill
  static const LinearGradient glassFill = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1FFFFFFF),
      Color(0x0CFFFFFF),
    ],
  );

  // Card Overlay Gradient for cinematic posters
  static const LinearGradient cardImageOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0x30070A11),
      Color(0xCC070A11),
      Color(0xFB070A11),
    ],
    stops: [0.0, 0.45, 0.8, 1.0],
  );

  // Ambient Background Glows
  static const RadialGradient heroAmbientGlow = RadialGradient(
    center: Alignment(0.4, -0.6),
    radius: 1.2,
    colors: [
      Color(0x35FF5E36), // Sunset glow
      Color(0x157C3AED), // Indigo violet spread
      Colors.transparent,
    ],
    stops: [0.0, 0.5, 1.0],
  );
}
