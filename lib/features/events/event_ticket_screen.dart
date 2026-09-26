import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/event.dart';
import '../../core/models/unified_booking.dart';
import '../../core/repositories/event_repository.dart';
import '../../core/repositories/repository_provider.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/plaza_image.dart';
import 'event_confirmation_screen.dart';

class EventTicketScreen extends StatefulWidget {
  final PlazaEvent event;
  final EventRepository? repository;

  const EventTicketScreen({
    super.key,
    required this.event,
    this.repository,
  });

  @override
  State<EventTicketScreen> createState() => _EventTicketScreenState();
}

class _EventTicketScreenState extends State<EventTicketScreen> {
  late final EventRepository _eventRepo;
  late EventTicketTier _selectedTier;
  int _quantity = 1;
  final TextEditingController _couponController = TextEditingController();
  String? _appliedCoupon;
  double _discountAmount = 0;
  final String _selectedPaymentMethod = 'UPI / Google Pay';
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _eventRepo = widget.repository ?? RepositoryProvider.instance.eventRepo;
    _selectedTier = widget.event.ticketTiers.isNotEmpty
        ? widget.event.ticketTiers.first
        : const EventTicketTier(
            id: 'tier_ga',
            name: 'General Admission',
            description: 'Standard access to the event',
            price: 999,
            remainingCount: 50,
          );
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  int get _maxAllowedQuantity {
    if (_selectedTier.remainingCount <= 0) return 1;
    return min(10, _selectedTier.remainingCount);
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

  Future<void> _handlePayment() async {
    if (_isProcessingPayment) return;

    setState(() {
      _isProcessingPayment = true;
    });

    final bookingId = 'EVT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final booking = EventBooking(
      bookingId: bookingId,
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

    try {
      await _eventRepo.bookTickets(booking);
    } catch (_) {}

    // Add to Global user bookings
    PlazaGlobalState.instance.addBooking(
      UnifiedBooking(
        id: bookingId,
        type: UnifiedBookingType.event,
        title: widget.event.title,
        subtitle: '${booking.quantity}x ${booking.ticketTier.name}',
        location: '${widget.event.venue}, ${widget.event.location}',
        date: booking.date,
        time: widget.event.time,
        imageUrl: widget.event.posterUrl,
        status: BookingStatus.upcoming,
        totalAmount: booking.grandTotal,
        confirmationCode: bookingId,
        seatOrSlotInfo: '${booking.quantity} Passes (${booking.ticketTier.name})',
        eventBooking: booking,
      ),
    );

    if (mounted) {
      setState(() {
        _isProcessingPayment = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EventConfirmationScreen(booking: booking),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM yyyy').format(widget.event.eventDate);
    final tiers = widget.event.ticketTiers.isNotEmpty
        ? widget.event.ticketTiers
        : [_selectedTier];

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
                ...tiers.map((tier) {
                  final isSelected = _selectedTier.id == tier.id;
                  final isSoldOut = tier.remainingCount == 0;

                  return GestureDetector(
                    onTap: isSoldOut
                        ? null
                        : () {
                            setState(() {
                              _selectedTier = tier;
                              if (_quantity > _maxAllowedQuantity) {
                                _quantity = _maxAllowedQuantity;
                              }
                            });
                          },
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
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tier.remainingCount > 0
                                      ? '${tier.remainingCount} tickets remaining'
                                      : 'Sold Out',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 10,
                                    color: tier.remainingCount > 0 && tier.remainingCount <= 20
                                        ? AppColors.alertRed
                                        : (tier.remainingCount > 0
                                            ? AppColors.liveGreen
                                            : AppColors.textMuted),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (tier.perks.isNotEmpty)
                                  Wrap(
                                    spacing: 4,
                                    children: tier.perks.take(2).map((p) => Container(
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
                                    )).toList(),
                                  ),
                              ],
                            ),
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
                              if (_quantity < _maxAllowedQuantity) {
                                setState(() => _quantity++);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Maximum $_maxAllowedQuantity passes allowed per transaction'),
                                    backgroundColor: AppColors.surfaceElevated,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
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

                // 3. Coupon Code Card
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROMO CODE', style: AppTypography.labelSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0x15FFFFFF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.glassBorderSubtle),
                              ),
                              child: TextField(
                                controller: _couponController,
                                style: AppTypography.labelMedium,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'Enter PLAZAVIP',
                                  hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GlassButton(
                            text: 'Apply',
                            variant: GlassButtonVariant.secondary,
                            height: 44,
                            width: 80,
                            onPressed: () => _applyCoupon(_couponController.text.trim()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Price Breakdown & Summary
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking Summary', style: AppTypography.headingSmall),
                      const SizedBox(height: 12),
                      _buildPriceRow('Ticket Subtotal ($_quantity passes)', '₹${_subtotal.toInt()}'),
                      const SizedBox(height: 8),
                      _buildPriceRow('Booking & Platform Fee', '₹${_platformFee.toInt()}'),
                      const SizedBox(height: 8),
                      _buildPriceRow('GST & Entertainment Tax (18%)', '₹${_taxes.toInt()}'),
                      if (_discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow(
                          'Promo Discount ($_appliedCoupon)',
                          '-₹${_discountAmount.toInt()}',
                          isDiscount: true,
                        ),
                      ],
                      const Divider(color: Color(0x20FFFFFF), height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand Total', style: AppTypography.labelLarge.copyWith(fontSize: 16)),
                          Text(
                            '₹${_grandTotal.toInt()}',
                            style: AppTypography.priceTag.copyWith(
                              fontSize: 22,
                              color: AppColors.accentAmber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 140),
              ],
            ),
          ),

          // Bottom Bar
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
                  decoration: const BoxDecoration(
                    color: Color(0xF0090D18),
                    border: Border(
                      top: BorderSide(color: AppColors.glassBorder, width: 1.0),
                    ),
                    boxShadow: [
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
                          Text('$_quantity PASSES • ${_selectedTier.name}', style: AppTypography.labelSmall),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_grandTotal.toInt()}',
                            style: AppTypography.priceTag.copyWith(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassButton(
                          text: _isProcessingPayment ? 'Processing...' : 'Pay & Confirm',
                          icon: _isProcessingPayment ? null : Icons.lock_outline_rounded,
                          variant: GlassButtonVariant.primary,
                          height: 52,
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

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            color: isDiscount ? AppColors.liveGreen : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
