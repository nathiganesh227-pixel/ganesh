import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/movie_booking.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import 'widgets/qr_code_widget.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final MovieBooking booking;

  const BookingConfirmationScreen({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(booking.date);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Background Success Glow
            Positioned(
              top: -60,
              left: -40,
              right: -40,
              child: Container(
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x3510B981), // Emerald green glow
                      Color(0x20FF5E36),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Success Icon & Badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0x2510B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x3010B981),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.liveGreen,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Booking Confirmed!', style: AppTypography.displayMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Booking ID: ${booking.bookingId}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.accentAmber,
                        letterSpacing: 1.0,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Apple Wallet-inspired Liquid Glass Pass
                    _buildDigitalPass(context, dateStr),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GlassButton(
                            text: 'Share Ticket',
                            icon: Icons.share_outlined,
                            variant: GlassButtonVariant.secondary,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ticket link copied to clipboard!'),
                                  backgroundColor: AppColors.surfaceElevated,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassButton(
                            text: 'Apple Wallet',
                            icon: Icons.account_balance_wallet_outlined,
                            variant: GlassButtonVariant.secondary,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pass saved to Apple Wallet '),
                                  backgroundColor: AppColors.surfaceElevated,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    GlassButton(
                      text: 'Back to Home',
                      icon: Icons.home_filled,
                      variant: GlassButtonVariant.primary,
                      width: double.infinity,
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalPass(BuildContext context, String dateStr) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x35FFFFFF),
                  Color(0x15FFFFFF),
                  Color(0x100D121F),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                // Pass Top Header: Poster + Title
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      PlazaImage(
                        imageUrl: booking.movie.posterUrl,
                        width: 65,
                        height: 90,
                        borderRadius: 14,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GlassPill(
                              label: booking.showtime.format.label,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              borderColor: AppColors.primary.withValues(alpha: 0.4),
                              textColor: AppColors.primaryLight,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              booking.movie.title,
                              style: AppTypography.headingMedium.copyWith(fontSize: 18),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${booking.movie.certificate} • ${booking.movie.duration} • ${booking.showtime.language}',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Perforated Ticket Divider with side notches
                _buildPerforatedDivider(),

                // Showtime Details Grid
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTicketInfoCol('DATE', dateStr),
                          _buildTicketInfoCol('TIME', booking.showtime.time, isRightAligned: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTicketInfoCol('THEATRE', booking.theatre.name),
                          _buildTicketInfoCol('SCREEN', booking.showtime.screenName, isRightAligned: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Prominent Seats Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          gradient: AppGradients.sunsetPrimary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x35FF5E36),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SEATS',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  booking.seatsFormatted,
                                  style: AppTypography.headingMedium.copyWith(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0x30000000),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${booking.seats.length} PASSES',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Color(0x15FFFFFF), height: 1),

                // QR Code Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      PlazaQRCodeWidget(
                        data: 'PLAZA://${booking.bookingId}/${booking.movie.id}/${booking.seatsFormatted}',
                        size: 160,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Scan QR code at the cinema entrance scanner',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gates open 15 minutes prior to showtime',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          color: AppColors.liveGreen,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerforatedDivider() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dashed horizontal line
        CustomPaint(
          size: const Size(double.infinity, 1),
          painter: _DashedLinePainter(),
        ),
      ],
    );
  }

  Widget _buildTicketInfoCol(String label, String value, {bool isRightAligned = false}) {
    return Column(
      crossAxisAlignment: isRightAligned ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x30FFFFFF)
      ..strokeWidth = 1;

    const dashWidth = 5.0;
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
