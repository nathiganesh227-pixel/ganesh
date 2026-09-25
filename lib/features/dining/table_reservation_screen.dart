import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/dining.dart';
import '../../core/models/unified_booking.dart';
import '../../core/repositories/dining_repository.dart';
import '../../core/repositories/repository_provider.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/plaza_image.dart';
import 'dining_confirmation_screen.dart';

class TableReservationScreen extends StatefulWidget {
  final Restaurant restaurant;
  final DiningRepository? repository;

  const TableReservationScreen({
    super.key,
    required this.restaurant,
    this.repository,
  });

  @override
  State<TableReservationScreen> createState() => _TableReservationScreenState();
}

class _TableReservationScreenState extends State<TableReservationScreen> {
  late final DiningRepository _diningRepo;
  late DateTime _selectedDate;
  late List<DateTime> _dates;
  int _selectedPartySize = 2;
  SeatingPreference _selectedSeating = SeatingPreference.indoor;
  String _selectedTimeSlot = '07:30 PM';
  bool _isSubmitting = false;

  final TextEditingController _specialRequestController = TextEditingController();
  final TextEditingController _guestNameController = TextEditingController(text: 'Gopi Ganesh');
  final TextEditingController _guestPhoneController = TextEditingController(text: '+91 98765 43210');

  @override
  void initState() {
    super.initState();
    _diningRepo = widget.repository ?? RepositoryProvider.instance.diningRepo;
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _dates = List.generate(7, (i) => _selectedDate.add(Duration(days: i)));
    if (widget.restaurant.availableSlots.isNotEmpty) {
      _selectedTimeSlot = widget.restaurant.availableSlots.first.time;
    }
  }

  @override
  void dispose() {
    _specialRequestController.dispose();
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    super.dispose();
  }

  Future<void> _confirmReservation() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final reservationId = 'RES-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final reservation = DiningReservation(
      reservationId: reservationId,
      restaurant: widget.restaurant,
      date: _selectedDate,
      timeSlot: _selectedTimeSlot,
      partySize: _selectedPartySize,
      seatingPreference: _selectedSeating,
      specialRequest: _specialRequestController.text.trim().isNotEmpty
          ? _specialRequestController.text.trim()
          : null,
      guestName: _guestNameController.text.trim().isNotEmpty
          ? _guestNameController.text.trim()
          : PlazaGlobalState.instance.userName,
      guestPhone: _guestPhoneController.text.trim().isNotEmpty
          ? _guestPhoneController.text.trim()
          : PlazaGlobalState.instance.userPhone,
      createdAt: DateTime.now(),
    );

    try {
      await _diningRepo.createReservation(reservation);
    } catch (_) {}

    // Add to Global user bookings
    PlazaGlobalState.instance.addBooking(
      UnifiedBooking(
        id: reservationId,
        type: UnifiedBookingType.dining,
        title: widget.restaurant.name,
        subtitle: '${reservation.partySize} Guests • ${reservation.seatingPreference.label}',
        location: widget.restaurant.location,
        date: reservation.date,
        time: reservation.timeSlot,
        imageUrl: widget.restaurant.coverImageUrl,
        status: BookingStatus.upcoming,
        totalAmount: 0.0,
        confirmationCode: reservationId,
        seatOrSlotInfo: '${reservation.partySize} Guests',
        diningReservation: reservation,
      ),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DiningConfirmationScreen(reservation: reservation),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = widget.restaurant.availableSlots.isNotEmpty
        ? widget.restaurant.availableSlots
        : [
            const DiningTimeSlot(time: '12:30 PM', status: SlotAvailabilityStatus.available, tablesLeft: 4),
            const DiningTimeSlot(time: '01:30 PM', status: SlotAvailabilityStatus.available, tablesLeft: 3),
            const DiningTimeSlot(time: '07:00 PM', status: SlotAvailabilityStatus.fillingFast, tablesLeft: 2),
            const DiningTimeSlot(time: '08:00 PM', status: SlotAvailabilityStatus.fewTablesLeft, tablesLeft: 1),
            const DiningTimeSlot(time: '09:00 PM', status: SlotAvailabilityStatus.available, tablesLeft: 5),
          ];

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reserve a Table', style: AppTypography.headingMedium),
            Text(
              widget.restaurant.name,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primaryLight,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // Mini Restaurant Banner
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      PlazaImage(
                        imageUrl: widget.restaurant.coverImageUrl,
                        width: 60,
                        height: 60,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.restaurant.name, style: AppTypography.labelLarge),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.restaurant.cuisines.map((c) => c.label).join(', ')} • ${widget.restaurant.location}',
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

                // 2. Party Size
                Text('2. Party Size (Number of Guests)', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                Row(
                  children: [2, 3, 4, 5, 6, 8].map((size) {
                    final isSelected = _selectedPartySize == size;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPartySize = size),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppGradients.sunsetPrimary : null,
                            color: isSelected ? null : AppColors.glassFillMedium,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0x80FFFFFF) : AppColors.glassBorderSubtle,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 16,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                size == 8 ? '8+' : '$size',
                                style: AppTypography.labelLarge.copyWith(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 3. Seating Preference
                Text('3. Seating Area Preference', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: SeatingPreference.values.map((pref) {
                    final isSelected = _selectedSeating == pref;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSeating = pref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.glassFillMedium,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          pref.label,
                          style: AppTypography.labelMedium.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 4. Select Time Slot
                Text('4. Available Table Time Slots', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: slots.map((slot) {
                    final isSelected = _selectedTimeSlot == slot.time;
                    Color badgeColor = AppColors.liveGreen;
                    String statusText = '${slot.tablesLeft} tables';

                    if (slot.status == SlotAvailabilityStatus.fewTablesLeft) {
                      badgeColor = AppColors.alertRed;
                      statusText = 'Few left';
                    } else if (slot.status == SlotAvailabilityStatus.fillingFast) {
                      badgeColor = AppColors.accentAmber;
                      statusText = 'Filling fast';
                    }

                    return GestureDetector(
                      onTap: () => setState(() => _selectedTimeSlot = slot.time),
                      child: Container(
                        width: 105,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.glassFillMedium,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              slot.time,
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statusText,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 9,
                                color: badgeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // 5. Guest Details
                Text('5. Contact & Guest Details', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.glassFillMedium,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.glassBorderSubtle),
                        ),
                        child: TextField(
                          controller: _guestNameController,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.glassFillMedium,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.glassBorderSubtle),
                        ),
                        child: TextField(
                          controller: _guestPhoneController,
                          style: AppTypography.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 6. Special Requests
                Text('6. Special Requests (Optional)', style: AppTypography.headingSmall),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.glassFillMedium,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorderSubtle),
                  ),
                  child: TextField(
                    controller: _specialRequestController,
                    maxLines: 2,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'e.g. Birthday cake arrangement, anniversary candlelight, quiet corner table...',
                      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 140),
              ],
            ),
          ),

          // Bottom Confirmation Bar
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
                          Text('$_selectedPartySize GUESTS • $_selectedTimeSlot', style: AppTypography.labelSmall),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('EEE, d MMM').format(_selectedDate),
                            style: AppTypography.priceTag.copyWith(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassButton(
                          text: _isSubmitting ? 'Reserving...' : 'Confirm Table',
                          icon: _isSubmitting ? null : Icons.check_rounded,
                          variant: GlassButtonVariant.primary,
                          height: 52,
                          onPressed: _isSubmitting ? null : _confirmReservation,
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
}
