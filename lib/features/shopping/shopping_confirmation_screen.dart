import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/shopping.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import '../movies/widgets/qr_code_widget.dart';

class ShoppingConfirmationScreen extends StatelessWidget {
  final ShoppingOrder order;

  const ShoppingConfirmationScreen({
    super.key,
    required this.order,
  });

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

                  // Animated Success Tick Badge
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
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                  ),

                  const SizedBox(height: 16),
                  Text('Order Confirmed!', style: AppTypography.headingLarge),
                  const SizedBox(height: 4),
                  Text(
                    order.fulfillmentType == ShoppingFulfillmentType.inStorePickup
                        ? 'Your express in-store pickup pass is ready'
                        : 'Your order is placed and being prepared',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Apple-Wallet Style Glass Pass
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderRadius: 24.0,
                    borderColor: AppColors.glassBorder,
                    child: Column(
                      children: [
                        // Store & Pickup Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.storeName,
                                    style: AppTypography.headingSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.storeLocation,
                                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GlassPill(
                              label: order.orderId,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                              textColor: AppColors.primaryLight,
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Purchased Items Mini List
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                PlazaImage(
                                  imageUrl: item.product.coverImageUrl,
                                  width: 48,
                                  height: 48,
                                  borderRadius: 12,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: AppTypography.labelMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.selectedVariant != null)
                                        Text(
                                          item.selectedVariant!.name,
                                          style: AppTypography.bodySmall.copyWith(fontSize: 10),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${item.quantity} × ₹${item.unitPrice.toInt()}',
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.accentAmber),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Perforated Divider
                        CustomPaint(
                          size: const Size(double.infinity, 1),
                          painter: _PerforatedDividerPainter(),
                        ),

                        const SizedBox(height: 18),

                        // Store Pickup QR Code & Code
                        if (order.fulfillmentType == ShoppingFulfillmentType.inStorePickup) ...[
                          Text(
                            'SHOW TO STORE CONCIERGE',
                            style: AppTypography.labelSmall.copyWith(
                              letterSpacing: 1.5,
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 12),
                          PlazaQRCodeWidget(
                            data: order.qrCodeData,
                            size: 150,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.glassFillMedium,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.glassBorderSubtle),
                            ),
                            child: Text(
                              'PICKUP CODE: ${order.pickupCode}',
                              style: AppTypography.labelMedium.copyWith(
                                letterSpacing: 2,
                                color: AppColors.accentGold,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Billing Summary Breakdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Payment Mode', style: AppTypography.bodySmall),
                            Text(order.paymentMethod, style: AppTypography.labelSmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Grand Total Paid', style: AppTypography.labelMedium),
                            Text(
                              '₹${order.grandTotal.toInt()}',
                              style: AppTypography.headingSmall.copyWith(color: AppColors.primaryLight),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  GlassButton(
                    text: 'Back to Home',
                    variant: GlassButtonVariant.primary,
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                  const SizedBox(height: 12),
                  GlassButton(
                    text: 'View Store Directions 📍',
                    variant: GlassButtonVariant.secondary,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening directions to ${order.storeName}...'),
                          backgroundColor: AppColors.surfaceElevated,
                        ),
                      );
                    },
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

class _PerforatedDividerPainter extends CustomPainter {
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
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
