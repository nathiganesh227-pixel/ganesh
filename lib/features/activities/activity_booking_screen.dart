import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/activity.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/plaza_image.dart';
import 'activity_confirmation_screen.dart';

class ActivityBookingScreen extends StatefulWidget {
  final PlazaActivity activity;

  const ActivityBookingScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ActivityBookingScreen> createState() => _ActivityBookingScreenState();
}

class _ActivityBookingScreenState extends State<ActivityBookingScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _dates;
  late String _selectedTimeSlot;
  late ActivityPackage _selectedPackage;
  int _numberOfPeople = 2;
  bool _isSharedGroupBooking = false;
  late List<ActivityAddOn> _addOns;
  final TextEditingController _couponController = TextEditingController();
  String? _appliedCoupon;
  double _discountAmount = 0;
  String _selectedPaymentMethod = 'UPI / Google Pay';
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _dates = List.generate(7, (i) => _selectedDate.add(Duration(days: i)));
    _selectedTimeSlot = widget.activity.availableSlots.first.time;
    _selectedPackage = widget.activity.packages.first;

    _addOns = [
      ActivityAddOn(
        id: 'addon_1',
        name: 'Extra 15-Min Extension',
        description: 'Extend your slot time seamlessly',
        price: 250,
      ),
      ActivityAddOn(
        id: 'addon_2',
        name: 'Hydration & Energy Pack',
        description: 'Red Bull / Gatorade + Mineral water',
        price: 150,
      ),
      ActivityAddOn(
        id: 'addon_3',
        name: 'Pro Grip Gloves / Socks',
        description: 'High-grip anti-skid safety pair',
        price: 100,
      ),
    ];
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  double get _packageTotal => _selectedPackage.pricePerPerson * _numberOfPeople;
  double get _addOnsTotal => _addOns.fold(0, (sum, a) => sum + (a.price * a.quantity));
  double get _platformFee => _numberOfPeople * 25.0;
  double get _taxes => (_packageTotal + _addOnsTotal + _platformFee) * 0.18; // 18% GST

  double get _grandTotal {
    final subtotal = _packageTotal + _addOnsTotal + _platformFee + _taxes;
    final total = subtotal - _discountAmount;
    return total > 0 ? total : 0;
  }

  void _applyCoupon(String code) {
    if (code.toUpperCase() == 'PLAZASQUAD') {
      setState(() {
        _appliedCoupon = 'PLAZASQUAD';
        _discountAmount = 150.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Coupon PLAZASQUAD applied: ₹150 discount!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coupon code. Try PLAZASQUAD'),
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

    final booking = ActivityBooking(
      bookingId: 'ACT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      activity: widget.activity,
      date: _selectedDate,
      timeSlot: _selectedTimeSlot,
      numberOfPeople: _numberOfPeople,
      package: _selectedPackage,
      addOns: _addOns.where((a) => a.quantity > 0).toList(),
      subtotal: _packageTotal + _addOnsTotal,
      platformFee: _platformFee,
      taxes: _taxes,
      discountAmount: _discountAmount,
      grandTotal: _grandTotal,
      paymentMethod: _selectedPaymentMethod,
      isSharedGroupBooking: _isSharedGroupBooking,
      bookedAt: DateTime.now(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityConfirmationScreen(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Book Activity Slot', style: AppTypography.headingMedium),
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

                // Activity Mini Header
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      PlazaImage(
                        imageUrl: widget.activity.coverImageUrl,
                        width: 65,
                        height: 65,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.activity.title, style: AppTypography.labelLarge),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.activity.venueName} • ${widget.activity.location}',
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

                const SizedBox(height: 20),

                // 1. Select Date
                Text('1. Select Date', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                SizedBox(
                  height: 84,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _dates.length,
                    itemBuilder: (context, index) {
                      final date = _dates[index];
                      final isSelected = date.day == _selectedDate.day &&
                          date.month == _selectedDate.month;
                      final isToday = index == 0;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = date),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 62,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppGradients.sunsetPrimary : null,
                            color: isSelected ? null : AppColors.glassFillMedium,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0x80FFFFFF) : AppColors.glassBorderSubtle,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isToday ? 'TODAY' : DateFormat('EEE').format(date).toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 10,
                                  color: isSelected ? Colors.white : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('d').format(date),
                                style: AppTypography.headingLarge.copyWith(
                                  fontSize: 17,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                DateFormat('MMM').format(date),
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 9,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Select Time Slot
                Text('2. Select Slot Time', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.activity.availableSlots.map((slot) {
                    final isSelected = _selectedTimeSlot == slot.time;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTimeSlot = slot.time),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.glassFillMedium,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              slot.time,
                              style: AppTypography.labelLarge.copyWith(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${slot.availableSlots} slots left',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 9,
                                color: slot.isFillingFast ? AppColors.accentAmber : AppColors.liveGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 3. Group / Party Size Selector
                Text('3. Group Size & Booking Mode', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NUMBER OF PLAYERS', style: AppTypography.labelSmall),
                              const SizedBox(height: 2),
                              Text('$_numberOfPeople People', style: AppTypography.headingMedium),
                            ],
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_numberOfPeople > 1) {
                                    setState(() => _numberOfPeople--);
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
                                child: Text('$_numberOfPeople', style: AppTypography.headingMedium),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (_numberOfPeople < 14) {
                                    setState(() => _numberOfPeople++);
                                  }
                                },
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.sunsetPrimary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0x15FFFFFF), height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.groups_rounded, size: 20, color: AppColors.primaryLight),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Shared Squad Booking', style: AppTypography.labelMedium),
                                  Text(
                                    'Split pass / group coordinator pass',
                                    style: AppTypography.bodySmall.copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: _isSharedGroupBooking,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) => setState(() => _isSharedGroupBooking = val),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 4. Select Package
                Text('4. Choose Package', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                ...widget.activity.packages.map((pkg) {
                  final isSelected = _selectedPackage.id == pkg.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPackage = pkg),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        borderColor: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                        backgroundColor: isSelected ? const Color(0x25FF5E36) : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pkg.name,
                                    style: AppTypography.labelLarge.copyWith(
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pkg.description,
                                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '₹${pkg.pricePerPerson.toInt()}',
                              style: AppTypography.priceTag.copyWith(
                                color: AppColors.accentAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // 5. Add-Ons
                Text('5. Optional Add-ons', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                ..._addOns.map(
                  (addon) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(addon.name, style: AppTypography.labelMedium),
                                Text('₹${addon.price.toInt()}', style: AppTypography.bodySmall.copyWith(color: AppColors.accentAmber)),
                              ],
                            ),
                          ),
                          if (addon.quantity > 0) ...[
                            GestureDetector(
                              onTap: () => setState(() => addon.quantity--),
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
                              child: Text('${addon.quantity}', style: AppTypography.labelLarge),
                            ),
                          ],
                          GestureDetector(
                            onTap: () => setState(() => addon.quantity++),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: addon.quantity > 0 ? null : AppGradients.sunsetPrimary,
                                color: addon.quantity > 0 ? const Color(0x20FFFFFF) : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                addon.quantity > 0 ? '+' : 'Add',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Coupon Code
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
                              hintText: 'Enter PLAZASQUAD',
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
                      _buildBillRow('Package (${_selectedPackage.name} x $_numberOfPeople)', '₹${_packageTotal.toInt()}'),
                      if (_addOnsTotal > 0) ...[
                        const SizedBox(height: 8),
                        _buildBillRow('Add-ons Total', '₹${_addOnsTotal.toInt()}'),
                      ],
                      const SizedBox(height: 8),
                      _buildBillRow('Platform & Arena Fee', '₹${_platformFee.toInt()}'),
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
                          Text('$_numberOfPeople PLAYERS • $_selectedTimeSlot', style: AppTypography.labelSmall),
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
