import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/data/shopping_cart_manager.dart';
import '../../core/models/shopping.dart';
import '../../core/models/unified_booking.dart';
import '../../core/repositories/repository_provider.dart';
import '../../core/repositories/shopping_repository.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/plaza_image.dart';
import 'shopping_confirmation_screen.dart';

class CartScreen extends StatefulWidget {
  final ShoppingRepository? repository;
  const CartScreen({super.key, this.repository});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ShoppingCartManager _cart = ShoppingCartManager.instance;
  late final ShoppingRepository _shoppingRepo;
  ShoppingFulfillmentType _fulfillment = ShoppingFulfillmentType.inStorePickup;
  String _selectedPayment = 'UPI / Google Pay';
  final TextEditingController _couponController = TextEditingController();
  bool _couponApplied = false;
  double _couponDiscount = 0.0;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _shoppingRepo = widget.repository ?? RepositoryProvider.instance.shoppingRepo;
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    _couponController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code == 'PLAZASHOP' || code == 'PLAZA10') {
      setState(() {
        _couponApplied = true;
        _couponDiscount = 500.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon Applied! ₹500 discount saved 🎉'),
          backgroundColor: AppColors.liveGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid code. Try PLAZASHOP'),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }

  void _checkout() async {
    if (_cart.items.isEmpty) return;

    setState(() => _isCheckingOut = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final random = Random();
    final orderId = 'ORD-PLZ-${random.nextInt(899999) + 100000}';
    final pickupCode = '${random.nextInt(8999) + 1000}';

    final totalDiscount = _cart.discountAmount + _couponDiscount;
    const platformFee = 29.0;
    final gstAmount = ((_cart.itemsTotal - totalDiscount) * 0.05).roundToDouble();
    final finalGrandTotal = max(0.0, _cart.itemsTotal - totalDiscount + platformFee + gstAmount);

    final order = ShoppingOrder(
      orderId: orderId,
      items: List.from(_cart.items),
      itemsTotal: _cart.itemsTotal,
      discountAmount: totalDiscount,
      platformFee: platformFee,
      gstAmount: gstAmount,
      grandTotal: finalGrandTotal,
      fulfillmentType: _fulfillment,
      storeName: _cart.items.first.product.storeName,
      storeLocation: _cart.items.first.product.storeLocation,
      orderTime: DateTime.now(),
      qrCodeData: 'PLAZA-ORDER:$orderId:$pickupCode',
      paymentMethod: _selectedPayment,
      pickupCode: pickupCode,
    );

    await _shoppingRepo.createOrder(order);

    PlazaGlobalState.instance.addBooking(
      UnifiedBooking(
        id: orderId,
        title: order.storeName,
        subtitle: '${_cart.totalItemCount} items • ${order.fulfillmentType.label}',
        type: UnifiedBookingType.shopping,
        location: order.storeLocation,
        date: DateTime.now(),
        time: 'Express Pickup',
        totalAmount: finalGrandTotal,
        status: BookingStatus.upcoming,
        imageUrl: _cart.items.first.product.coverImageUrl,
        confirmationCode: order.pickupCode,
        shoppingOrder: order,
      ),
    );

    _cart.clearCart();
    if (!mounted) return;
    setState(() => _isCheckingOut = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ShoppingConfirmationScreen(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDiscount = _cart.discountAmount + _couponDiscount;
    final finalGrandTotal = max(0.0, _cart.itemsTotal - totalDiscount + _cart.platformFee + _cart.gstAmount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Shopping Bag (${_cart.totalItemCount})', style: AppTypography.headingSmall),
        centerTitle: true,
      ),
      body: _cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text('Your shopping bag is empty', style: AppTypography.headingSmall),
                  const SizedBox(height: 6),
                  Text('Discover luxury brands and boutique collections', style: AppTypography.bodySmall),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: GlassButton(
                      text: 'Start Shopping',
                      variant: GlassButtonVariant.primary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fulfillment Selector
                      Text('Delivery / Pickup Preference', style: AppTypography.labelLarge),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFulfillmentOption(
                              ShoppingFulfillmentType.inStorePickup,
                              'Store Pickup',
                              'Ready in 2h',
                              Icons.storefront_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFulfillmentOption(
                              ShoppingFulfillmentType.standardDelivery,
                              'Express Delivery',
                              'Same day',
                              Icons.bolt_rounded,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Cart Items List
                      Text('Order Items', style: AppTypography.labelLarge),
                      const SizedBox(height: 12),
                      ..._cart.items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                PlazaImage(
                                  imageUrl: item.product.coverImageUrl,
                                  width: 72,
                                  height: 72,
                                  borderRadius: 14,
                                ),
                                const SizedBox(width: 14),
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
                                      const SizedBox(height: 2),
                                      Text(
                                        item.selectedVariant != null
                                            ? item.selectedVariant!.name
                                            : item.product.brand,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.primaryLight,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${item.unitPrice.toInt()}',
                                        style: AppTypography.labelMedium.copyWith(
                                          color: AppColors.accentAmber,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Quantity Controls
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.glassFillMedium,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.glassBorderSubtle),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _cart.updateQuantity(idx, -1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(Icons.remove, size: 14, color: Colors.white),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text(
                                          '${item.quantity}',
                                          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _cart.updateQuantity(idx, 1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(Icons.add, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Coupon Code Input
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.confirmation_num_outlined, color: AppColors.primaryLight, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                style: AppTypography.bodyMedium,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: _couponApplied ? 'PLAZASHOP applied' : 'Promo Code (PLAZASHOP)',
                                  hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _couponApplied ? null : _applyCoupon,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _couponApplied
                                      ? AppColors.liveGreen.withValues(alpha: 0.2)
                                      : AppColors.primary.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _couponApplied ? AppColors.liveGreen : AppColors.primary,
                                  ),
                                ),
                                child: Text(
                                  _couponApplied ? 'Applied ✓' : 'Apply',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: _couponApplied ? AppColors.liveGreen : AppColors.primaryLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Payment Method Selector
                      Text('Payment Method', style: AppTypography.labelLarge),
                      const SizedBox(height: 10),
                      ...['UPI / Google Pay', 'Credit / Debit Card', 'Apple Pay '].map(
                        (method) => GestureDetector(
                          onTap: () => setState(() => _selectedPayment = method),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedPayment == method
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.glassFillMedium,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _selectedPayment == method
                                    ? AppColors.primary
                                    : AppColors.glassBorderSubtle,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(method, style: AppTypography.labelMedium),
                                Icon(
                                  _selectedPayment == method
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: _selectedPayment == method ? AppColors.primary : AppColors.textMuted,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Itemized Bill Breakdown
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildBillRow('Bag Subtotal', '₹${_cart.itemsTotal.toInt()}'),
                            const SizedBox(height: 8),
                            _buildBillRow('Member / Promo Discount', '-₹${totalDiscount.toInt()}', isDiscount: true),
                            const SizedBox(height: 8),
                            _buildBillRow('Express Handling Fee', '₹${_cart.platformFee.toInt()}'),
                            const SizedBox(height: 8),
                            _buildBillRow('Applicable GST (18%)', '₹${_cart.gstAmount.toInt()}'),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: AppColors.glassBorder, height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Grand Total', style: AppTypography.headingSmall),
                                Text(
                                  '₹${finalGrandTotal.toInt()}',
                                  style: AppTypography.headingSmall.copyWith(
                                    color: AppColors.primaryLight,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Bottom Checkout Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard.withValues(alpha: 0.95),
                      border: const Border(top: BorderSide(color: AppColors.glassBorder)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('FINAL AMOUNT', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
                              Text(
                                '₹${finalGrandTotal.toInt()}',
                                style: AppTypography.headingMedium.copyWith(color: AppColors.accentAmber),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: GlassButton(
                            text: _isCheckingOut ? 'Authorizing...' : 'Place Order 🛍️',
                            variant: GlassButtonVariant.primary,
                            onPressed: _isCheckingOut ? null : _checkout,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFulfillmentOption(
    ShoppingFulfillmentType type,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _fulfillment == type;
    return GestureDetector(
      onTap: () => setState(() => _fulfillment = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.glassFillMedium,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall),
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            color: isDiscount ? AppColors.liveGreen : AppColors.textPrimary,
            fontWeight: isDiscount ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
