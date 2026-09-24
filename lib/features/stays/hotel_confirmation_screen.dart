import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/stay.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import '../movies/widgets/qr_code_widget.dart';

class HotelConfirmationScreen extends StatelessWidget {
  final HotelBooking booking;

  const HotelConfirmationScreen({
    super.key,
    required this.booking,
  });

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Atmospheric Ambient Glow
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentGold.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Animated Checkmark
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.accentGold, AppColors.accentGold.withValues(alpha: 0.6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGold.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                  ),

                  const SizedBox(height: 16),
                  Text('Stay Reserved!', style: AppTypography.headingLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Your luxury stay pass is confirmed with the concierge',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Apple Wallet-Style Hotel Stay Pass
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 24.0,
                    borderColor: AppColors.glassBorder,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hotel Banner
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlazaImage(
                              imageUrl: booking.hotel.coverImageUrl,
                              width: 60,
                              height: 60,
                              borderRadius: 14,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.hotel.name,
                                    style: AppTypography.headingSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking.hotel.location,
                                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  GlassPill(
                                    label: booking.roomType.name,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                    textColor: AppColors.primaryLight,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Check-in & Check-out Dates Grid
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.glassFillMedium,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.glassBorderSubtle),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CHECK-IN', style: AppTypography.bodySmall.copyWith(fontSize: 10, letterSpacing: 1.1)),
                                  const SizedBox(height: 4),
                                  Text(_formatDate(booking.checkInDate), style: AppTypography.labelLarge),
                                  Text(booking.hotel.checkInTime, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.primaryLight)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${booking.nights} ${booking.nights == 1 ? "Night" : "Nights"}',
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('CHECK-OUT', style: AppTypography.bodySmall.copyWith(fontSize: 10, letterSpacing: 1.1)),
                                  const SizedBox(height: 4),
                                  Text(_formatDate(booking.checkOutDate), style: AppTypography.labelLarge),
                                  Text(booking.hotel.checkOutTime, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.primaryLight)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Guests & Rooms
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reserved For', style: AppTypography.bodySmall),
                            Text(
                              '${booking.guestsCount} Guests • ${booking.roomsCount} Room',
                              style: AppTypography.labelMedium,
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Primary Guest', style: AppTypography.bodySmall),
                            Text(booking.guestName, style: AppTypography.labelSmall),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Perforated Line
                        CustomPaint(
                          size: const Size(double.infinity, 1),
                          painter: _StayDividerPainter(),
                        ),

                        const SizedBox(height: 16),

                        // QR Code Concierge Pass
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'PRESENT AT FRONT DESK FOR EXPRESS CHECK-IN',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 9,
                                  letterSpacing: 1.2,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              PlazaQRCodeWidget(
                                data: booking.qrCodeData,
                                size: 140,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                booking.bookingId,
                                style: AppTypography.labelMedium.copyWith(
                                  letterSpacing: 2,
                                  color: AppColors.accentGold,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: AppColors.glassBorder, height: 1),
                        const SizedBox(height: 12),

                        // Grand Total Paid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount Paid', style: AppTypography.labelMedium),
                            Text(
                              '₹${booking.grandTotal.toInt()}',
                              style: AppTypography.headingSmall.copyWith(color: AppColors.accentAmber),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  GlassButton(
                    text: 'Back to Home',
                    variant: GlassButtonVariant.primary,
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          text: 'Directions 📍',
                          variant: GlassButtonVariant.secondary,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Directions to ${booking.hotel.name}...'),
                                backgroundColor: AppColors.surfaceElevated,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassButton(
                          text: 'Calendar 📅',
                          variant: GlassButtonVariant.secondary,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added reservation to calendar!'),
                                backgroundColor: AppColors.liveGreen,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StayDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.glassBorder
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
