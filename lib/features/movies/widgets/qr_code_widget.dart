import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PlazaQRCodeWidget extends StatelessWidget {
  final String data;
  final double size;

  const PlazaQRCodeWidget({
    super.key,
    required this.data,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size - 24, size - 24),
        painter: _QRPainter(data),
      ),
    );
  }
}

class _QRPainter extends CustomPainter {
  final String data;
  _QRPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final cellCount = 21;
    final cellSize = size.width / cellCount;

    // Deterministic pseudo-random pattern based on string hash for realistic visual QR matrix
    final hash = data.hashCode.abs();

    for (int r = 0; r < cellCount; r++) {
      for (int c = 0; c < cellCount; c++) {
        // Draw 3 standard corner finder patterns
        final isTopLeftCorner = (r < 7 && c < 7);
        final isTopRightCorner = (r < 7 && c >= cellCount - 7);
        final isBottomLeftCorner = (r >= cellCount - 7 && c < 7);

        if (isTopLeftCorner || isTopRightCorner || isBottomLeftCorner) {
          // Handled separately below
          continue;
        }

        // Timing patterns
        if (r == 6 || c == 6) {
          if ((r + c) % 2 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize * 0.9, cellSize * 0.9),
              paint,
            );
          }
          continue;
        }

        // Center matrix data cells
        final bit = ((hash * (r + 1) * 31 + c * 17) ^ (r * c)) % 10;
        if (bit < 5) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellSize, r * cellSize, cellSize * 0.88, cellSize * 0.88),
              Radius.circular(cellSize * 0.25),
            ),
            paint,
          );
        }
      }
    }

    // Draw the 3 QR Finder eyes
    _drawFinderEye(canvas, 0, 0, cellSize, paint);
    _drawFinderEye(canvas, (cellCount - 7) * cellSize, 0, cellSize, paint);
    _drawFinderEye(canvas, 0, (cellCount - 7) * cellSize, cellSize, paint);

    // Center PLAZA micro-logo
    final centerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cellSize * 4.5,
      height: cellSize * 4.5,
    );

    final centerBgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, const Radius.circular(6)),
      centerBgPaint,
    );

    final logoPaint = Paint()..color = AppColors.primary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: cellSize * 3.2,
          height: cellSize * 3.2,
        ),
        const Radius.circular(4),
      ),
      logoPaint,
    );
  }

  void _drawFinderEye(Canvas canvas, double x, double y, double cellSize, Paint paint) {
    // Outer square 7x7
    final outerRect = Rect.fromLTWH(x, y, 7 * cellSize, 7 * cellSize);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, Radius.circular(cellSize * 0.8)),
      paint,
    );

    // Inner white square 5x5
    final whiteRect = Rect.fromLTWH(x + cellSize, y + cellSize, 5 * cellSize, 5 * cellSize);
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(whiteRect, Radius.circular(cellSize * 0.4)),
      whitePaint,
    );

    // Inner black dot 3x3
    final innerRect = Rect.fromLTWH(x + 2 * cellSize, y + 2 * cellSize, 3 * cellSize, 3 * cellSize);
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(cellSize * 0.4)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
