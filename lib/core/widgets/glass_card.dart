import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_gradients.dart';

/// Apple-inspired Liquid Glass Card widget with backdrop blur,
/// specular border reflection, and optional glowing depth.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool hasGlow;
  final Color? glowColor;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 22.0,
    this.padding,
    this.margin,
    this.blurSigma = 16.0,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
    this.hasGlow = false,
    this.glowColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? AppColors.glassFill)
            : null,
        gradient: gradient ?? (backgroundColor == null ? AppGradients.glassFill : null),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    Widget blurredCard = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: cardContent,
      ),
    );

    Widget finalWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          if (hasGlow)
            BoxShadow(
              color: (glowColor ?? AppColors.primary).withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 0),
              spreadRadius: 1,
            ),
        ],
      ),
      child: blurredCard,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: finalWidget,
        ),
      );
    }

    return finalWidget;
  }
}
