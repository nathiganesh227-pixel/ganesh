import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/event.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/plaza_image.dart';
import 'event_confirmation_screen.dart';

class EventTicketScreen extends StatefulWidget {
  final PlazaEvent event;

  const EventTicketScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventTicketScreen> createState() => _EventTicketScreenState();
}

class _EventTicketScreenState extends State<EventTicketScreen> {
  late EventTicketTier _selectedTier;
  int _quantity = 1;
  final TextEditingController _couponController = TextEditingController();
  String? _appliedCoupon;
  double _discountAmount = 0;
  String _selectedPaymentMethod = 'UPI / Google Pay';
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.event.ticketTiers.first;
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  double get _subtotal => _selectedTier.price * _quantity;
  double get _platformFee => _quantity * 40.0;
  double get _taxes => (_subtotal + _platformFee) * 0.18; // 18% GST

  double get _grandTotal {
    final total = (_subtotal + _platformFee + _taxes) - _discountAmount;
    return total > 0 ? total : 0;
  }

  void _applyCoupon(String code) {
    if (code.toUpperCase() == 'PLAZAVIP') {
      setState(() {
        _appliedCoupon = 'PLAZAVIP';
        _discountAmount = 250.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Coupon PLAZAVIP applied: ₹250 discount!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coupon code. Try PLAZAVIP'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  void _handlePayment() async {
    setState(() {
      _isProcessingPayment = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final booking = EventBooking(
      bookingId: 'EVT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      event: widget.event,
      date: widget.event.eventDate,
      ticketTier: _selectedTier,
      quantity: _quantity,
      subtotal: _subtotal,
      platformFee: _platformFee,
      taxes: _taxes,
      discountAmount: _discountAmount,
      grandTotal: _grandTotal,
      paymentMethod: _selectedPaymentMethod,
      bookedAt: DateTime.now(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EventConfirmationScreen(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(widget.event.eventDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.glassFillMedium,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorderSubtle),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: Text('Select Event Tickets', style: AppTypography.headingMedium),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Event Overview Card
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      PlazaImage(
                        imageUrl: widget.event.posterUrl,
                        width: 70,
                        height: 90,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.event.title, style: AppTypography.labelLarge.copyWith(fontSize: 15)),
                            const SizedBox(height: 2),
                            Text(
                              '$dateStr • ${widget.event.time}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.event.venue,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 1. Select Ticket Category
                Text('1. Select Ticket Category', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                ...widget.event.ticketTiers.map((tier) {
                  final isSelected = _selectedTier.id == tier.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTier = tier),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        borderColor: isSelected ? AppColors.secondaryViolet : AppColors.glassBorderSubtle,
                        backgroundColor: isSelected ? const Color(0x308B5CF6) : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tier.name,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '₹${tier.price.toInt()}',
                                  style: AppTypography.priceTag.copyWith(
                                    color: AppColors.accentAmber,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tier.description,
                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                            ),
                            if (tier.perks.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: tier.perks
                                    .map(
                                      (p) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0x15FFFFFF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          p,
                                          style: AppTypography.bodySmall.copyWith(
                                            fontSize: 9,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // 2. Select Quantity
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PASSES QUANTITY', style: AppTypography.labelSmall),
                          const SizedBox(height: 2),
                          Text('$_quantity x ${_selectedTier.name}', style: AppTypography.labelLarge),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                              }
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0x20FFFFFF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.remove, size: 16, color: Colors.white),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('$_quantity', style: AppTypography.headingMedium),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_quantity < 10) {
                                setState(() => _quantity++);
                              }
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: AppGradients.royalViolet,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.add, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Apply Promo Code
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.glassFillMedium,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorderSubtle),
                          ),
                          child: TextField(
                            controller: _couponController,
                            textCapitalization: TextCapitalization.characters,
                            style: AppTypography.labelMedium,
                            decoration: InputDecoration(
                              hintText: 'Enter PLAZAVIP',
                              hintStyle: AppTypography.bodySmall,
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GlassButton(
                        text: _appliedCoupon != null ? 'Applied ✓' : 'Apply',
                        variant: _appliedCoupon != null
                            ? GlassButtonVariant.secondary
                            : GlassButtonVariant.primary,
                        height: 44,
                        onPressed: () => _applyCoupon(_couponController.text.trim()),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bill Breakdown
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Breakdown', style: AppTypography.headingSmall),
                      const SizedBox(height: 12),
                      _buildBillRow('Ticket Total ($_quantity passes)', '₹${_subtotal.toInt()}'),
                      const SizedBox(height: 8),
                      _buildBillRow('Convenience & Platform Fee', '₹${_platformFee.toInt()}'),
                      const SizedBox(height: 8),
                      _buildBillRow('Integrated GST (18%)', '₹${_taxes.toStringAsFixed(2)}'),
                      if (_discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        _buildBillRow(
                          'Promo Discount ($_appliedCoupon)',
                          '-₹${_discountAmount.toInt()}',
                          isDiscount: true,
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: Color(0x20FFFFFF), height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand Total', style: AppTypography.headingMedium),
                          Text(
                            '₹${_grandTotal.toStringAsFixed(2)}',
                            style: AppTypography.priceTag.copyWith(
                              fontSize: 20,
                              color: AppColors.accentAmber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Selector
                Text('Select Payment Method', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                _buildPaymentOption('UPI / Google Pay', Icons.account_balance_wallet_outlined),
                _buildPaymentOption('PhonePe / Paytm', Icons.phone_android_rounded),
                _buildPaymentOption('Credit / Debit Card', Icons.credit_card_rounded),
                _buildPaymentOption('Apple Pay', Icons.apple_rounded),

                const SizedBox(height: 130),
              ],
            ),
          ),

          // Bottom Pay Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 14,
                    bottom: MediaQuery.of(context).padding.bottom > 0
                        ? MediaQuery.of(context).padding.bottom + 8
                        : 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xF0090D18),
                    border: const Border(
                      top: BorderSide(color: AppColors.glassBorder, width: 1.0),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 24,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$_quantity PASS${_quantity > 1 ? 'ES' : ''}', style: AppTypography.labelSmall),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_grandTotal.toStringAsFixed(2)}',
                            style: AppTypography.priceTag.copyWith(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: GlassButton(
                          text: _isProcessingPayment ? 'Authorizing...' : 'Pay ₹${_grandTotal.toInt()}',
                          icon: Icons.lock_outline_rounded,
                          variant: GlassButtonVariant.primary,
                          height: 52,
                          isLoading: _isProcessingPayment,
                          onPressed: _isProcessingPayment ? null : _handlePayment,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderColor: isSelected ? AppColors.secondaryViolet : AppColors.glassBorderSubtle,
          backgroundColor: isSelected ? const Color(0x258B5CF6) : null,
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.secondaryViolet : AppColors.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.secondaryViolet : AppColors.textMuted,
                    width: isSelected ? 5 : 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDiscount ? AppColors.liveGreen : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            color: isDiscount ? AppColors.liveGreen : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
