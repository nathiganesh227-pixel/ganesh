import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

class CinemaScreenCurve extends StatelessWidget {
  const CinemaScreenCurve({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomPaint(
          size: const Size(double.infinity, 32),
          painter: _ScreenCurvePainter(),
        ),
        const SizedBox(height: 6),
        Text(
          'SCREEN THIS WAY',
          style: AppTypography.labelSmall.copyWith(
            letterSpacing: 2.0,
            fontSize: 10,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ScreenCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Screen Glow Gradient
    final glowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x5538BDF8), // Cyan-blue glow
          Colors.transparent,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    // Curved Path
    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.85);
    path.quadraticBezierTo(
      size.width * 0.5,
      0,
      size.width * 0.9,
      size.height * 0.85,
    );

    final glowPath = Path.from(path)
      ..lineTo(size.width * 0.9, size.height)
      ..lineTo(size.width * 0.1, size.height)
      ..close();

    canvas.drawPath(glowPath, glowPaint);

    // Screen Line Stroke with specular shine
    final strokePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x2038BDF8),
          Color(0xFF38BDF8),
          Color(0xFFFFFFFF),
          Color(0xFF38BDF8),
          Color(0x2038BDF8),
        ],
        stops: [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
