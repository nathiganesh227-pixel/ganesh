import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_gradients.dart';
import '../constants/app_typography.dart';

enum GlassButtonVariant {
  primary, // Sunset gradient with glowing shadow
  secondary, // Translucent frosted glass
  ghost, // Ultra-subtle border
}

class GlassButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final double height;
  final double? width;
  final double borderRadius;
  final bool isLoading;

  const GlassButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.height = 48.0,
    this.width,
    this.borderRadius = 999.0,
    this.isLoading = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    Decoration decoration;
    TextStyle textStyle;

    switch (widget.variant) {
      case GlassButtonVariant.primary:
        decoration = BoxDecoration(
          gradient: isEnabled
              ? (_isPressed ? AppGradients.sunsetSubtle : AppGradients.sunsetPrimary)
              : const LinearGradient(
                  colors: [Color(0x33475569), Color(0x33334155)],
                ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: isEnabled ? const Color(0x45FFFFFF) : const Color(0x15FFFFFF),
            width: 1.0,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF5E36).withValues(alpha: _isPressed ? 0.2 : 0.4),
                    blurRadius: _isPressed ? 10 : 18,
                    offset: const Offset(0, 4),
                    spreadRadius: _isPressed ? -2 : 0,
                  ),
                ]
              : null,
        );
        textStyle = AppTypography.labelLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        );
        break;

      case GlassButtonVariant.secondary:
        decoration = BoxDecoration(
          color: _isPressed ? AppColors.glassFillHeavy : AppColors.glassFillMedium,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: _isPressed ? AppColors.glassBorder : AppColors.glassBorderSubtle,
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x20000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        );
        textStyle = AppTypography.labelLarge.copyWith(
          color: AppColors.textPrimary,
        );
        break;

      case GlassButtonVariant.ghost:
        decoration = BoxDecoration(
          color: _isPressed ? const Color(0x15FFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: AppColors.glassBorderSubtle,
            width: 1.0,
          ),
        );
        textStyle = AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        );
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: textStyle.color),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.text,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onPressed,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: widget.height,
              width: widget.width,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: decoration,
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
