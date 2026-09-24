import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/event.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import '../movies/widgets/qr_code_widget.dart';

class EventConfirmationScreen extends StatelessWidget {
  final EventBooking booking;

  const EventConfirmationScreen({
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
            // Background Glow
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
                      Color(0x3510B981),
                      Color(0x208B5CF6),
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
                        Icons.confirmation_number_rounded,
                        color: AppColors.liveGreen,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Passes Confirmed!', style: AppTypography.displayMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Booking ID: ${booking.bookingId}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.accentAmber,
                        letterSpacing: 1.0,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Apple Wallet Digital Pass
                    _buildDigitalPass(context, dateStr),

                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: GlassButton(
                            text: 'Share Passes',
                            icon: Icons.share_outlined,
                            variant: GlassButtonVariant.secondary,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Event passes link copied!'),
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
                // Event Header
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      PlazaImage(
                        imageUrl: booking.event.posterUrl,
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
                              label: booking.event.category.label.split('&').first.trim(),
                              backgroundColor: AppColors.secondaryViolet.withValues(alpha: 0.25),
                              borderColor: AppColors.secondaryViolet.withValues(alpha: 0.4),
                              textColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              booking.event.title,
                              style: AppTypography.headingMedium.copyWith(fontSize: 18),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.event.venue,
                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Color(0x20FFFFFF), height: 1),

                // Event Logistics
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoCol('DATE', dateStr),
                          _buildInfoCol('TIMING', booking.event.time, isRightAligned: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Prominent Tier & Quantity Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          gradient: AppGradients.royalViolet,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x358B5CF6),
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
                                  'TICKET TIER',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  booking.ticketTier.name,
                                  style: AppTypography.headingMedium.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
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
                                '${booking.quantity} PASS${booking.quantity > 1 ? 'ES' : ''}',
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

                // QR Matrix
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      PlazaQRCodeWidget(
                        data: 'PLAZA://EVENT/${booking.bookingId}/${booking.event.id}/${booking.quantity}',
                        size: 150,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Present barcode at venue gate for wristband exchange',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Entry allowed only with valid Government Photo ID (${booking.event.ageRestriction})',
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

  Widget _buildInfoCol(String label, String value, {bool isRightAligned = false}) {
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
