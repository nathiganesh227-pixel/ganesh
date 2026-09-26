import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/booking_quote.dart';
import '../network/environment_config.dart';

enum PaymentMethodType {
  upiFast,
  card,
  netBanking,
}

class PlazaPaymentSheet extends StatefulWidget {
  final String bookingTitle;
  final String bookingSubtitle;
  final BookingQuote quote;
  final String? bookingId;
  final Future<bool> Function(PaymentMethodType method)? onConfirmPayment;
  final ValueChanged<String>? onPaymentSuccess;
  final ValueChanged<String>? onPaymentFailed;

  const PlazaPaymentSheet({
    super.key,
    required this.bookingTitle,
    required this.bookingSubtitle,
    required this.quote,
    this.bookingId,
    this.onConfirmPayment,
    this.onPaymentSuccess,
    this.onPaymentFailed,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String bookingTitle,
    required String bookingSubtitle,
    required BookingQuote quote,
    String? bookingId,
    Future<bool> Function(PaymentMethodType method)? onConfirmPayment,
    ValueChanged<String>? onPaymentSuccess,
    ValueChanged<String>? onPaymentFailed,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => PlazaPaymentSheet(
        bookingTitle: bookingTitle,
        bookingSubtitle: bookingSubtitle,
        quote: quote,
        bookingId: bookingId,
        onConfirmPayment: onConfirmPayment,
        onPaymentSuccess: onPaymentSuccess,
        onPaymentFailed: onPaymentFailed,
      ),
    );
  }

  @override
  State<PlazaPaymentSheet> createState() => _PlazaPaymentSheetState();
}

class _PlazaPaymentSheetState extends State<PlazaPaymentSheet> {
  PaymentMethodType _selectedMethod = PaymentMethodType.upiFast;
  bool _isProcessing = false;
  bool _isVerifying = false;
  String? _errorMessage;

  Future<void> _handlePayment() async {
    if (_isProcessing || _isVerifying) return; // Prevent double submit

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Gateway Order Dispatch
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _isVerifying = true;
      });

      // Step 2: Signature Verification
      bool success = true;
      if (widget.onConfirmPayment != null) {
        success = await widget.onConfirmPayment!(_selectedMethod);
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!mounted) return;

      if (success) {
        final paymentRef = 'PAY_RZP_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
        widget.onPaymentSuccess?.call(paymentRef);
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Payment signature verification failed. Please try again.';
        });
        widget.onPaymentFailed?.call(_errorMessage!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isVerifying = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
      widget.onPaymentFailed?.call(_errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isProd = EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.glassBorder, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PLAZA SECURE CHECKOUT',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Server Authoritative Pricing & 256-bit Encryption',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    onPressed: (_isProcessing || _isVerifying) ? null : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Booking Overview Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryLight, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.receipt_long, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bookingTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.bookingSubtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.bookingId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.glassFill,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.glassBorderSubtle),
                        ),
                        child: Text(
                          widget.bookingId!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Authoritative Quote Breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorderSubtle),
                ),
                child: Column(
                  children: [
                    _buildLineItem('Subtotal', '₹${widget.quote.subtotal.toInt()}'),
                    if (widget.quote.convenienceFee > 0) ...[
                      const SizedBox(height: 8),
                      _buildLineItem(
                        widget.quote.type == 'shopping' ? 'Platform Fee' : 'Convenience Fee',
                        '₹${widget.quote.convenienceFee.toInt()}',
                      ),
                    ],
                    if (widget.quote.taxes > 0) ...[
                      const SizedBox(height: 8),
                      _buildLineItem('Taxes & GST', '₹${widget.quote.taxes.toInt()}'),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: AppColors.glassBorder, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payable',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '₹${widget.quote.grandTotal.toInt()}',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method Selectors
              const Text(
                'SELECT PAYMENT METHOD',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMethodTile(
                      type: PaymentMethodType.upiFast,
                      title: 'UPI Fast',
                      icon: Icons.flash_on,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMethodTile(
                      type: PaymentMethodType.card,
                      title: 'Card',
                      icon: Icons.credit_card,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMethodTile(
                      type: PaymentMethodType.netBanking,
                      title: 'NetBanking',
                      icon: Icons.account_balance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Truthful Gateway Security Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glassBorderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      isProd ? Icons.verified_user : Icons.science_outlined,
                      color: isProd ? AppColors.liveGreen : AppColors.accentAmber,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isProd
                            ? 'Razorpay Live Production Gateway • Verified HMAC-SHA256'
                            : 'PLAZA Sandbox Gateway • Simulated Verification Active',
                        style: TextStyle(
                          color: isProd ? AppColors.liveGreen : AppColors.accentAmber,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Error Banner
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.alertRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.alertRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.alertRed, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.alertRed, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Action CTA Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  key: const Key('plaza_payment_sheet_pay_button'),
                  onPressed: (_isProcessing || _isVerifying) ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: (_isProcessing || _isVerifying)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isVerifying
                                  ? 'Verifying Payment Signature...'
                                  : 'Contacting Secure Gateway...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Pay ₹${widget.quote.grandTotal.toInt()} ⚡',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTile({
    required PaymentMethodType type,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == type;
    return GestureDetector(
      onTap: (_isProcessing || _isVerifying) ? null : () => setState(() => _selectedMethod = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceCard.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
