import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/sports.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import '../movies/widgets/qr_code_widget.dart';

class SportsConfirmationScreen extends StatelessWidget {
  final SportsBooking booking;

  const SportsConfirmationScreen({
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
          // Background Atmospheric Glows
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
                    AppColors.liveGreen.withValues(alpha: 0.25),
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
                        colors: [AppColors.liveGreen, AppColors.liveGreen.withValues(alpha: 0.6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.liveGreen.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.sports_cricket_rounded, color: Colors.white, size: 38),
                  ),

                  const SizedBox(height: 16),
                  Text('Turf Slot Confirmed!', style: AppTypography.headingLarge),
                  const SizedBox(height: 4),
                  Text(
                    booking.isSquadBooking
                        ? 'Squad match pass is live for "${booking.squadName}"'
                        : 'Your court access pass is ready to scan',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Truthful Payment Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pending_actions_rounded, size: 16, color: AppColors.accentGold),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Status: Pay at Venue / Pending Verification',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sports Pass Card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 24.0,
                    borderColor: AppColors.glassBorder,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Venue & Sport Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlazaImage(
                              imageUrl: booking.venue.coverImageUrl,
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
                                    booking.venue.name,
                                    style: AppTypography.headingSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking.venue.location,
                                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      GlassPill(
                                        label: booking.sport.label,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                        textColor: AppColors.primaryLight,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      ),
                                      if (booking.isSquadBooking) ...[
                                        const SizedBox(width: 6),
                                        GlassPill(
                                          label: 'Squad Mode ⚔️',
                                          backgroundColor: AppColors.secondaryViolet.withValues(alpha: 0.3),
                                          textColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Slot & Court Details
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
                                  Text('MATCH DATE', style: AppTypography.bodySmall.copyWith(fontSize: 10, letterSpacing: 1.1)),
                                  const SizedBox(height: 4),
                                  Text(_formatDate(booking.date), style: AppTypography.labelLarge),
                                  Text(booking.slot.courtName, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.primaryLight)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('SLOT TIME', style: AppTypography.bodySmall.copyWith(fontSize: 10, letterSpacing: 1.1)),
                                  const SizedBox(height: 4),
                                  Text(booking.slot.time, style: AppTypography.labelLarge.copyWith(color: AppColors.liveGreen)),
                                  Text('${booking.durationMinutes} Minutes', style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Players & Squad Split
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Players Confirmed', style: AppTypography.bodySmall),
                            Text('${booking.playersCount} Players', style: AppTypography.labelMedium),
                          ],
                        ),

                        if (booking.isSquadBooking) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Split Bill (Per Player)', style: AppTypography.bodySmall),
                              Text(
                                '₹${booking.perPersonCost.toInt()} / player',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.accentGold, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Perforated Divider
                        CustomPaint(
                          size: const Size(double.infinity, 1),
                          painter: _SportsDividerPainter(),
                        ),

                        const SizedBox(height: 16),

                        // Entry QR Code
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'SCAN AT TURF ENTRANCE CONCIERGE',
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
                                  color: AppColors.accentAmber,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(color: AppColors.glassBorder, height: 1),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total (Pay at Venue)', style: AppTypography.labelMedium),
                            Text(
                              '₹${booking.grandTotal.toInt()}',
                              style: AppTypography.headingSmall.copyWith(color: AppColors.primaryLight),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Apple Wallet Pass CTA Button
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sports Match Pass added to Apple Wallet 🎟️'),
                          backgroundColor: AppColors.liveGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wallet_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add to Apple Wallet',
                            style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                                content: Text('Directions to ${booking.venue.name}...'),
                                backgroundColor: AppColors.surfaceElevated,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassButton(
                          text: booking.isSquadBooking ? 'Invite Squad 📲' : 'Share Pass 📤',
                          variant: GlassButtonVariant.secondary,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  booking.isSquadBooking
                                      ? 'Squad invite link copied! Share with your team.'
                                      : 'Match pass link copied!',
                                ),
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

class _SportsDividerPainter extends CustomPainter {
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
