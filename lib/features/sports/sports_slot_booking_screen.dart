import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/sports.dart';
import '../../core/models/unified_booking.dart';
import '../../core/repositories/sports_repository.dart';
import '../../core/repositories/repository_provider.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/plaza_image.dart';
import 'sports_confirmation_screen.dart';

class SportsSlotBookingScreen extends StatefulWidget {
  final SportsVenue venue;
  final SportType initialSport;
  final SportsRepository? repository;

  const SportsSlotBookingScreen({
    super.key,
    required this.venue,
    required this.initialSport,
    this.repository,
  });

  @override
  State<SportsSlotBookingScreen> createState() => _SportsSlotBookingScreenState();
}

class _SportsSlotBookingScreenState extends State<SportsSlotBookingScreen> {
  late final SportsRepository _sportsRepo;
  late SportType _selectedSport;
  late SportsSlot _selectedSlot;
  int _selectedDateOffset = 0;
  int _durationMinutes = 60;
  int _playerCount = 10;
  final Set<String> _selectedAddOnIds = {};
  bool _isSquadBooking = false;
  final TextEditingController _squadNameController = TextEditingController(text: 'Hyderabadi Strikers');
  final TextEditingController _bookerNameController = TextEditingController(text: 'Nathi Gopi Ganesh');
  final TextEditingController _bookerPhoneController = TextEditingController(text: '+91 98765 43210');
  final String _selectedPayment = 'Pay at Venue (Cash/UPI)';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _sportsRepo = widget.repository ?? RepositoryProvider.instance.sportsRepo;
    _selectedSport = widget.initialSport;
    _selectedSlot = widget.venue.availableSlots.firstWhere(
      (s) => s.isBookable,
      orElse: () => widget.venue.availableSlots.first,
    );
  }

  @override
  void dispose() {
    _squadNameController.dispose();
    _bookerNameController.dispose();
    _bookerPhoneController.dispose();
    super.dispose();
  }

  double get _durationMultiplier => _durationMinutes / 60.0;

  double get _courtPrice => _selectedSlot.price * _durationMultiplier;

  double get _addOnsTotal {
    double sum = 0;
    for (final addOn in widget.venue.equipmentAddOns) {
      if (_selectedAddOnIds.contains(addOn.id)) {
        sum += addOn.price;
      }
    }
    return sum;
  }

  double get _convenienceFee => 50.0;

  double get _grandTotal => _courtPrice + _addOnsTotal + _convenienceFee;

  double get _perPersonCost => _playerCount > 0 ? _grandTotal / _playerCount : _grandTotal;

  DateTime get _selectedDate => DateTime.now().add(Duration(days: _selectedDateOffset));

  void _confirmBooking() async {
    setState(() => _isProcessing = true);

    final random = Random();
    final bookingId = 'PLZ-SPT-${random.nextInt(899999) + 100000}';
    final dateStr =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final success = await _sportsRepo.bookSlot(
      venueId: widget.venue.id,
      sportName: _selectedSport.label,
      slotId: _selectedSlot.id,
      date: dateStr,
      playersCount: _playerCount,
      squadName: _isSquadBooking ? _squadNameController.text.trim() : null,
      addOnIds: _selectedAddOnIds.toList(),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('That court slot is already booked or unavailable. Please choose another slot.'),
          backgroundColor: AppColors.alertRed,
        ),
      );
      return;
    }

    final selectedAddOnsList = widget.venue.equipmentAddOns
        .where((a) => _selectedAddOnIds.contains(a.id))
        .toList();

    final booking = SportsBooking(
      bookingId: bookingId,
      venue: widget.venue,
      sport: _selectedSport,
      date: _selectedDate,
      slot: _selectedSlot,
      durationMinutes: _durationMinutes,
      playersCount: _playerCount,
      addOns: selectedAddOnsList,
      isSquadBooking: _isSquadBooking,
      squadName: _isSquadBooking ? _squadNameController.text.trim() : '',
      courtPrice: _courtPrice,
      addOnsTotal: _addOnsTotal,
      convenienceFee: _convenienceFee,
      grandTotal: _grandTotal,
      perPersonCost: _perPersonCost,
      bookerName: _bookerNameController.text.trim(),
      bookerPhone: _bookerPhoneController.text.trim(),
      qrCodeData: 'PLAZA://SPORTS/$bookingId',
      paymentMethod: _selectedPayment,
      bookingTime: DateTime.now(),
    );

    PlazaGlobalState.instance.addBooking(
      UnifiedBooking(
        id: bookingId,
        type: UnifiedBookingType.sports,
        title: widget.venue.name,
        subtitle: '${_selectedSport.label} • ${_selectedSlot.time}',
        location: widget.venue.location,
        date: _selectedDate,
        time: _selectedSlot.time,
        imageUrl: widget.venue.coverImageUrl,
        status: BookingStatus.upcoming,
        totalAmount: _grandTotal,
        confirmationCode: bookingId,
        seatOrSlotInfo: '${_selectedSlot.courtName} ($_durationMinutes min)',
        sportsBooking: booking,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SportsConfirmationScreen(booking: booking),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Book Turf / Slot', style: AppTypography.headingSmall),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Venue Card
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      PlazaImage(
                        imageUrl: widget.venue.coverImageUrl,
                        width: 64,
                        height: 64,
                        borderRadius: 14,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.venue.name,
                              style: AppTypography.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.venue.location} • ${widget.venue.distance}',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.venue.rating.toStringAsFixed(1)} ★ (${widget.venue.reviewCount} matches hosted)',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.accentGold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Sport Selector
                if (widget.venue.supportedSports.length > 1) ...[
                  Text('Select Sport', style: AppTypography.labelLarge),
                  const SizedBox(height: 8),
                  Row(
                    children: widget.venue.supportedSports.map((sport) {
                      final isSelected = _selectedSport == sport;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSport = sport),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.glassFillMedium,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(sport.emoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(height: 4),
                                Text(
                                  sport.label.split('&').first.trim(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // 7-Day Date Picker
                Text('Match Date', style: AppTypography.labelLarge),
                const SizedBox(height: 10),
                SizedBox(
                  height: 64,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final date = DateTime.now().add(Duration(days: index));
                      final isSelected = _selectedDateOffset == index;
                      const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDateOffset = index),
                        child: Container(
                          width: 58,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppGradients.sunsetPrimary : null,
                            color: isSelected ? null : AppColors.glassFillMedium,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : AppColors.glassBorderSubtle,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                index == 0 ? 'TODAY' : dayNames[date.weekday - 1],
                                style: AppTypography.labelSmall.copyWith(
                                  color: isSelected ? Colors.white : AppColors.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${date.day}',
                                style: AppTypography.headingSmall.copyWith(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontSize: 16,
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

                // Match Duration
                Text('Duration', style: AppTypography.labelLarge),
                const SizedBox(height: 10),
                Row(
                  children: [30, 60, 90, 120].map((mins) {
                    final isSelected = _durationMinutes == mins;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _durationMinutes = mins),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.glassFillMedium,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Text(
                            '$mins min',
                            style: AppTypography.labelSmall.copyWith(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Time Slots Matrix
                Text('Available Time Slots', style: AppTypography.labelLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.venue.availableSlots.map((slot) {
                    final isSelected = _selectedSlot.id == slot.id;
                    final isBookable = slot.isBookable;

                    Color statusColor;
                    String statusLabel;
                    switch (slot.status) {
                      case SlotStatus.available:
                        statusColor = AppColors.liveGreen;
                        statusLabel = 'Available';
                        break;
                      case SlotStatus.fewSlotsLeft:
                        statusColor = AppColors.accentAmber;
                        statusLabel = 'Few Left';
                        break;
                      case SlotStatus.fillingFast:
                        statusColor = AppColors.primaryLight;
                        statusLabel = 'Filling Fast';
                        break;
                      case SlotStatus.soldOut:
                        statusColor = AppColors.textMuted;
                        statusLabel = 'Sold Out';
                        break;
                    }

                    return GestureDetector(
                      onTap: isBookable ? () => setState(() => _selectedSlot = slot) : null,
                      child: Opacity(
                        opacity: isBookable ? 1.0 : 0.4,
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 60) / 2,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : AppColors.glassFillMedium,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    slot.time,
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: AppTypography.labelSmall.copyWith(color: statusColor, fontSize: 8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                slot.courtName,
                                style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '₹${(slot.price * _durationMultiplier).toInt()}',
                                style: AppTypography.labelMedium.copyWith(color: AppColors.accentAmber),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Player Count Stepper
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NUMBER OF PLAYERS', style: AppTypography.bodySmall.copyWith(fontSize: 9, letterSpacing: 1.1)),
                          const SizedBox(height: 2),
                          Text('$_playerCount Players', style: AppTypography.labelLarge),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_playerCount > 2) setState(() => _playerCount--);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.glassFillMedium,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.remove, size: 16, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('$_playerCount', style: AppTypography.labelLarge),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              if (_playerCount < 26) setState(() => _playerCount++);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.glassFillMedium,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Equipment Add-ons
                if (widget.venue.equipmentAddOns.isNotEmpty) ...[
                  Text('Rental Gear & Equipment Add-ons', style: AppTypography.labelLarge),
                  const SizedBox(height: 10),
                  ...widget.venue.equipmentAddOns.map((addon) {
                    final isChecked = _selectedAddOnIds.contains(addon.id);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isChecked) {
                            _selectedAddOnIds.remove(addon.id);
                          } else {
                            _selectedAddOnIds.add(addon.id);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isChecked ? AppColors.primary.withValues(alpha: 0.15) : AppColors.glassFillMedium,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isChecked ? AppColors.primary : AppColors.glassBorderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                              color: isChecked ? AppColors.primary : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(addon.name, style: AppTypography.labelMedium),
                                  Text(
                                    addon.description,
                                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+₹${addon.price.toInt()}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.accentAmber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                ],

                // Squad Booking / Split Bill Mode Toggle
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderColor: _isSquadBooking ? AppColors.secondaryViolet : AppColors.glassBorderSubtle,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryViolet.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.group_work_rounded, color: AppColors.secondaryViolet, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Squad Booking & Split Bill ⚔️', style: AppTypography.labelMedium),
                                  Text('Auto-calculate per player share', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: _isSquadBooking,
                            activeTrackColor: AppColors.secondaryViolet,
                            onChanged: (val) => setState(() => _isSquadBooking = val),
                          ),
                        ],
                      ),
                      if (_isSquadBooking) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _squadNameController,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Squad / Team Name',
                            labelStyle: AppTypography.bodySmall,
                            isDense: true,
                            border: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryViolet.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Share Per Player:', style: AppTypography.labelSmall),
                              Text(
                                '₹${_perPersonCost.toInt()} / player',
                                style: AppTypography.labelMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Method Notice
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.liveGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.payment_rounded, color: AppColors.liveGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Method: Pay at Venue', style: AppTypography.labelMedium),
                            const SizedBox(height: 2),
                            Text(
                              'Cash / UPI accepted at the venue concierge upon match pass check-in.',
                              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bill Summary
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        'Turf Fee (${_selectedSlot.courtName}, $_durationMinutes min)',
                        '₹${_courtPrice.toInt()}',
                      ),
                      if (_addOnsTotal > 0) ...[
                        const SizedBox(height: 8),
                        _buildSummaryRow('Rental Equipment', '₹${_addOnsTotal.toInt()}'),
                      ],
                      const SizedBox(height: 8),
                      _buildSummaryRow('Floodlight & Booking Fee', '₹${_convenienceFee.toInt()}'),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: AppColors.glassBorder, height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Grand Total', style: AppTypography.headingSmall),
                          Text(
                            '₹${_grandTotal.toInt()}',
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

          // Bottom CTA
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
                        Text(
                          _isSquadBooking ? 'PER PLAYER SHARE' : 'SLOT TOTAL',
                          style: AppTypography.bodySmall.copyWith(fontSize: 10),
                        ),
                        Text(
                          _isSquadBooking ? '₹${_perPersonCost.toInt()}' : '₹${_grandTotal.toInt()}',
                          style: AppTypography.headingMedium.copyWith(color: AppColors.accentAmber),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: GlassButton(
                      text: _isProcessing ? 'Confirming...' : 'Book Turf Slot ⚡',
                      variant: GlassButtonVariant.primary,
                      onPressed: _isProcessing ? null : _confirmBooking,
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

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Text(value, style: AppTypography.labelSmall),
      ],
    );
  }
}
