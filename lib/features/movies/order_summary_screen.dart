import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/movie_mock_data.dart';
import '../../core/models/cinema_seat.dart';
import '../../core/models/cinema_showtime.dart';
import '../../core/models/movie.dart';
import '../../core/models/movie_booking.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/plaza_image.dart';
import 'booking_confirmation_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  final Movie movie;
  final Theatre theatre;
  final ShowtimeSlot showtime;
  final DateTime date;
  final List<CinemaSeat> selectedSeats;

  const OrderSummaryScreen({
    super.key,
    required this.movie,
    required this.theatre,
    required this.showtime,
    required this.date,
    required this.selectedSeats,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  late List<FandBItem> _snacks;
  final TextEditingController _couponController = TextEditingController();
  String? _appliedCoupon;
  double _discountAmount = 0;
  String _selectedPaymentMethod = 'UPI / Google Pay';
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _snacks = MovieMockData.getSnackMenu();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  double get _ticketTotal =>
      widget.selectedSeats.fold(0, (sum, seat) => sum + seat.price);

  double get _snacksTotal => _snacks.fold(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

  double get _convenienceFee => widget.selectedSeats.length * 28.0;
  double get _taxes => (_ticketTotal + _convenienceFee) * 0.18; // 18% GST

  double get _grandTotal {
    final subtotal = _ticketTotal + _snacksTotal + _convenienceFee + _taxes;
    final total = subtotal - _discountAmount;
    return total > 0 ? total : 0;
  }

  void _applyCoupon(String code) {
    if (code.toUpperCase() == 'PLAZAIMAX') {
      setState(() {
        _appliedCoupon = 'PLAZAIMAX';
        _discountAmount = 100.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Coupon PLAZAIMAX applied: ₹100 discount!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coupon code. Try PLAZAIMAX'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  void _handlePayment() async {
    setState(() {
      _isProcessingPayment = true;
    });

    // Realistic processing animation simulation
    await Future.delayed(const Duration(milliseconds: 1600));

    if (!mounted) return;

    final booking = MovieBooking(
      bookingId: 'PLZ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      movie: widget.movie,
      theatre: widget.theatre,
      showtime: widget.showtime,
      date: widget.date,
      seats: widget.selectedSeats,
      snacks: _snacks.where((s) => s.quantity > 0).toList(),
      ticketTotal: _ticketTotal,
      convenienceFee: _convenienceFee,
      taxes: _taxes,
      discountAmount: _discountAmount,
      grandTotal: _grandTotal,
      paymentMethod: _selectedPaymentMethod,
      bookedAt: DateTime.now(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(widget.date);

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
        title: Text('Order Summary', style: AppTypography.headingMedium),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Movie & Showtime Info Card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PlazaImage(
                        imageUrl: widget.movie.posterUrl,
                        width: 72,
                        height: 100,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.movie.title, style: AppTypography.headingSmall),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.showtime.language} • ${widget.showtime.format.label}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.theatre.name,
                              style: AppTypography.labelMedium,
                            ),
                            Text(
                              '${widget.showtime.screenName} • $dateStr, ${widget.showtime.time}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Selected Seats Card
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SELECTED SEATS', style: AppTypography.labelSmall),
                          const SizedBox(height: 2),
                          Text(
                            widget.selectedSeats.map((s) => s.displayName).join(', '),
                            style: AppTypography.headingSmall.copyWith(
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      GlassPill(
                        label: '${widget.selectedSeats.length} Tickets',
                        backgroundColor: const Color(0x20FFFFFF),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Add F&B Snacks Section
                Text('Add Food & Beverages', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _snacks.length,
                    itemBuilder: (context, index) {
                      final item = _snacks[index];
                      return _buildSnackCard(item, index);
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Apply Promo Code
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_offer_outlined, size: 18, color: AppColors.accentAmber),
                          const SizedBox(width: 8),
                          Text('Offers & Promo Code', style: AppTypography.labelLarge),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
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
                                  hintText: 'Enter PLAZAIMAX',
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
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Price Breakdown Bill
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment Breakdown', style: AppTypography.headingSmall),
                      const SizedBox(height: 12),
                      _buildBillRow(
                        'Ticket Price (${widget.selectedSeats.length} seats)',
                        '₹${_ticketTotal.toInt()}',
                      ),
                      if (_snacksTotal > 0) ...[
                        const SizedBox(height: 8),
                        _buildBillRow('Food & Beverages', '₹${_snacksTotal.toInt()}'),
                      ],
                      const SizedBox(height: 8),
                      _buildBillRow('Convenience Fee', '₹${_convenienceFee.toInt()}'),
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
                        padding: EdgeInsets.symmetric(vertical: 12),
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

                // Payment Options Placeholder
                Text('Select Payment Method', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                _buildPaymentOption('UPI / Google Pay', Icons.account_balance_wallet_outlined),
                _buildPaymentOption('PhonePe / Paytm', Icons.phone_android_rounded),
                _buildPaymentOption('Credit / Debit Card', Icons.credit_card_rounded),
                _buildPaymentOption('Apple Pay', Icons.apple_rounded),

                const SizedBox(height: 120),
              ],
            ),
          ),

          // Bottom Fixed Pay Button
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
                          Text('TOTAL AMOUNT', style: AppTypography.labelSmall),
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
                          text: _isProcessingPayment
                              ? 'Authorizing...'
                              : 'Pay ₹${_grandTotal.toInt()}',
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

  Widget _buildSnackCard(FandBItem item, int index) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlazaImage(
                  imageUrl: item.imageUrl,
                  width: 50,
                  height: 50,
                  borderRadius: 10,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTypography.labelMedium.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${item.price.toInt()}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accentAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.quantity > 0) ...[
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        item.quantity--;
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0x20FFFFFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove, size: 14, color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${item.quantity}',
                      style: AppTypography.labelLarge,
                    ),
                  ),
                ],
                GestureDetector(
                  onTap: () {
                    setState(() {
                      item.quantity++;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: item.quantity > 0 ? null : AppGradients.sunsetPrimary,
                      color: item.quantity > 0 ? const Color(0x20FFFFFF) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.quantity > 0 ? '+' : 'Add',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderColor: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
          backgroundColor: isSelected ? const Color(0x25FF5E36) : null,
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
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
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
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
