import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/dining.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import '../movies/widgets/qr_code_widget.dart';

class DiningConfirmationScreen extends StatelessWidget {
  final DiningReservation reservation;

  const DiningConfirmationScreen({
    super.key,
    required this.reservation,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(reservation.date);

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
                      Color(0x3510B981),
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
                        Icons.restaurant_menu_rounded,
                        color: AppColors.liveGreen,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Table Reserved!', style: AppTypography.displayMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Reservation ID: ${reservation.reservationId}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.accentAmber,
                        letterSpacing: 1.0,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Apple-inspired Digital Dining Pass
                    _buildDiningPass(context, dateStr),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GlassButton(
                            text: 'Directions',
                            icon: Icons.directions_outlined,
                            variant: GlassButtonVariant.secondary,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Opening Google Maps to ${reservation.restaurant.name}...'),
                                  backgroundColor: AppColors.surfaceElevated,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassButton(
                            text: 'Add to Calendar',
                            icon: Icons.calendar_today_outlined,
                            variant: GlassButtonVariant.secondary,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reservation added to Apple Calendar 📅'),
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

  Widget _buildDiningPass(BuildContext context, String dateStr) {
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
                // Restaurant Header
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      PlazaImage(
                        imageUrl: reservation.restaurant.coverImageUrl,
                        width: 65,
                        height: 65,
                        borderRadius: 14,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GlassPill(
                              label: reservation.seatingPreference.label,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              borderColor: AppColors.primary.withValues(alpha: 0.4),
                              textColor: AppColors.primaryLight,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              reservation.restaurant.name,
                              style: AppTypography.headingMedium.copyWith(fontSize: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reservation.restaurant.location,
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

                // Table Details
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoCol('DATE', dateStr),
                          _buildInfoCol('TIME SLOT', reservation.timeSlot, isRightAligned: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoCol('TABLE SIZE', '${reservation.partySize} Guests'),
                          _buildInfoCol('SEATING', reservation.seatingPreference.label, isRightAligned: true),
                        ],
                      ),
                      if (reservation.specialRequest != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0x20FFFFFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Special Request: "${reservation.specialRequest}"',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accentAmber,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(color: Color(0x15FFFFFF), height: 1),

                // QR Code
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      PlazaQRCodeWidget(
                        data: 'PLAZA://DINING/${reservation.reservationId}/${reservation.restaurant.id}',
                        size: 150,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Show this QR pass to the restaurant host on arrival',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tables held for 15 minutes past reservation time',
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
