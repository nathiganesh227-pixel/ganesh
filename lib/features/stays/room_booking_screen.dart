import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/data/stay_mock_data.dart';
import '../../core/models/stay.dart';
import '../../core/models/unified_booking.dart';
import '../../core/repositories/repository_provider.dart';
import '../../core/repositories/stay_repository.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/plaza_image.dart';
import 'hotel_confirmation_screen.dart';

class RoomBookingScreen extends StatefulWidget {
  final Hotel hotel;
  final RoomType initialRoom;
  final StayRepository? repository;

  const RoomBookingScreen({
    super.key,
    required this.hotel,
    required this.initialRoom,
    this.repository,
  });

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  late RoomType _selectedRoom;
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 2));
  int _guestsCount = 2;
  int _roomsCount = 1;
  final Set<String> _selectedAddOnIds = {};
  String _selectedPayment = 'UPI / Google Pay';

  final TextEditingController _nameController = TextEditingController(text: 'Nathi Gopi Ganesh');
  final TextEditingController _emailController = TextEditingController(text: 'gopi.ganesh@example.com');
  final TextEditingController _phoneController = TextEditingController(text: '+91 98765 43210');
  final TextEditingController _specialRequestsController = TextEditingController();

  bool _isProcessing = false;

  late final StayRepository _stayRepo;

  @override
  void initState() {
    super.initState();
    _stayRepo = widget.repository ?? RepositoryProvider.instance.stayRepo;
    _selectedRoom = widget.initialRoom;
    _selectedAddOnIds.add('addon_breakfast');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  int get _nightsCount {
    final diff = _checkOutDate.difference(_checkInDate).inDays;
    return diff > 0 ? diff : 1;
  }

  double get _roomTotal => _selectedRoom.pricePerNight * _nightsCount * _roomsCount;

  double get _addOnsTotal {
    double sum = 0;
    for (final addon in StayMockData.defaultAddOns) {
      if (_selectedAddOnIds.contains(addon.id)) {
        if (addon.isPerNight) {
          sum += addon.price * _nightsCount * _guestsCount;
        } else {
          sum += addon.price;
        }
      }
    }
    return sum;
  }

  double get _taxesAndFees => ((_roomTotal + _addOnsTotal) * 0.12).roundToDouble();

  double get _grandTotal => _roomTotal + _addOnsTotal + _taxesAndFees;

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  void _confirmStay() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final random = Random();
    final bookingId = 'PLZ-STY-${random.nextInt(899999) + 100000}';

    final selectedAddOnsList = StayMockData.defaultAddOns
        .where((a) => _selectedAddOnIds.contains(a.id))
        .toList();

    final booking = HotelBooking(
      bookingId: bookingId,
      hotel: widget.hotel,
      roomType: _selectedRoom,
      checkInDate: _checkInDate,
      checkOutDate: _checkOutDate,
      nights: _nightsCount,
      guestsCount: _guestsCount,
      roomsCount: _roomsCount,
      selectedAddOns: selectedAddOnsList,
      roomTotal: _roomTotal,
      addOnsTotal: _addOnsTotal,
      taxesAndFees: _taxesAndFees,
      grandTotal: _grandTotal,
      guestName: _nameController.text.trim().isEmpty ? 'Guest' : _nameController.text.trim(),
      guestEmail: _emailController.text.trim(),
      guestPhone: _phoneController.text.trim(),
      specialRequests: _specialRequestsController.text.trim(),
      qrCodeData: 'PLAZA://STAY/$bookingId/${widget.hotel.id}',
      paymentMethod: _selectedPayment,
      bookingTime: DateTime.now(),
    );

    await _stayRepo.createBooking(booking);

    // Sync with PlazaGlobalState for Unified Bookings tab
    PlazaGlobalState.instance.addBooking(
      UnifiedBooking(
        id: bookingId,
        type: UnifiedBookingType.stay,
        title: widget.hotel.name,
        subtitle: '${_selectedRoom.name} ($_nightsCount Nights)',
        location: widget.hotel.location,
        date: _checkInDate,
        time: 'Check-in: ${widget.hotel.checkInTime}',
        imageUrl: widget.hotel.coverImageUrl,
        status: BookingStatus.upcoming,
        totalAmount: _grandTotal,
        confirmationCode: 'QR-$bookingId',
        seatOrSlotInfo: '${_selectedRoom.name} • $_roomsCount Room • $_guestsCount Guests',
        hotelBooking: booking,
      ),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HotelConfirmationScreen(booking: booking),
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
        title: Text('Reserve Room', style: AppTypography.headingSmall),
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
                // Hotel Summary Card
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      PlazaImage(
                        imageUrl: widget.hotel.coverImageUrl,
                        width: 70,
                        height: 70,
                        borderRadius: 14,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.hotel.name,
                              style: AppTypography.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.hotel.location,
                              style: AppTypography.bodySmall.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.hotel.rating.toStringAsFixed(1)} ★ (${widget.hotel.reviewCount} reviews)',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.accentGold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Stay Dates Selector
                Text('Stay Duration & Dates', style: AppTypography.labelLarge),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Check-in
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _checkInDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setState(() {
                              _checkInDate = picked;
                              if (_checkOutDate.isBefore(_checkInDate.add(const Duration(days: 1)))) {
                                _checkOutDate = _checkInDate.add(const Duration(days: 1));
                              }
                            });
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CHECK-IN', style: AppTypography.bodySmall.copyWith(fontSize: 10, letterSpacing: 1.1)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(_formatDate(_checkInDate), style: AppTypography.labelLarge),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Nights Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '$_nightsCount Night${_nightsCount == 1 ? '' : 's'}',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w700),
                        ),
                      ),

                      // Check-out
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _checkOutDate,
                            firstDate: _checkInDate.add(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setState(() => _checkOutDate = picked);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('CHECK-OUT', style: AppTypography.bodySmall.copyWith(fontSize: 10, letterSpacing: 1.1)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(_formatDate(_checkOutDate), style: AppTypography.labelLarge),
                                const SizedBox(width: 6),
                                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Guests & Rooms Stepper Controls
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GUESTS', style: AppTypography.bodySmall.copyWith(fontSize: 9)),
                                Text('$_guestsCount Adults', style: AppTypography.labelMedium),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_guestsCount > 1) setState(() => _guestsCount--);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.glassFillMedium,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.remove, size: 14, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    final maxGuests = _selectedRoom.maxGuests * _roomsCount;
                                    if (_guestsCount < maxGuests) {
                                      setState(() => _guestsCount++);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Selected room allows max $maxGuests guests for $_roomsCount room(s)'),
                                          backgroundColor: AppColors.surfaceElevated,
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.glassFillMedium,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ROOMS', style: AppTypography.bodySmall.copyWith(fontSize: 9)),
                                Text('$_roomsCount Room', style: AppTypography.labelMedium),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_roomsCount > 1) setState(() => _roomsCount--);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.glassFillMedium,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.remove, size: 14, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    if (_roomsCount < 4) setState(() => _roomsCount++);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.glassFillMedium,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Room Type Selector
                Text('Selected Room Type', style: AppTypography.labelLarge),
                const SizedBox(height: 10),
                ...widget.hotel.roomTypes.map((room) {
                  final isSelected = _selectedRoom.id == room.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRoom = room),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.all(12),
                        borderColor: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlazaImage(
                              imageUrl: room.imageUrl,
                              width: 80,
                              height: 80,
                              borderRadius: 14,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          room.name,
                                          style: AppTypography.labelLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${room.bedType} • ${room.roomSize}',
                                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${room.pricePerNight.toInt()} / night',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.accentAmber,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 20),

                // Luxury Add-ons Checklist
                Text('Enhance Your Stay (Add-ons)', style: AppTypography.labelLarge),
                const SizedBox(height: 10),
                ...StayMockData.defaultAddOns.map((addon) {
                  final isAdded = _selectedAddOnIds.contains(addon.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isAdded) {
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
                        color: isAdded ? AppColors.primary.withValues(alpha: 0.15) : AppColors.glassFillMedium,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isAdded ? AppColors.primary : AppColors.glassBorderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isAdded ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            color: isAdded ? AppColors.primary : AppColors.textMuted,
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

                const SizedBox(height: 20),

                // Guest Details Card
                Text('Primary Guest Information', style: AppTypography.labelLarge),
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Full Name (as on Govt ID)',
                          labelStyle: AppTypography.bodySmall,
                          isDense: true,
                          border: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        style: AppTypography.bodyMedium,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Mobile Phone Number',
                          labelStyle: AppTypography.bodySmall,
                          isDense: true,
                          border: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _specialRequestsController,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Special Requests (e.g. High floor, quiet room)',
                          labelStyle: AppTypography.bodySmall,
                          isDense: true,
                          border: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.glassBorder)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Method
                Text('Payment Mode', style: AppTypography.labelLarge),
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
                          color: _selectedPayment == method ? AppColors.primary : AppColors.glassBorderSubtle,
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

                // Billing Summary
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPriceRow(
                        '${_selectedRoom.name} ($_nightsCount night${_nightsCount == 1 ? '' : 's'}, $_roomsCount room)',
                        '₹${_roomTotal.toInt()}',
                      ),
                      if (_addOnsTotal > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow('Curated Add-ons', '₹${_addOnsTotal.toInt()}'),
                      ],
                      const SizedBox(height: 8),
                      _buildPriceRow('Luxury & Hospitality GST (12%)', '₹${_taxesAndFees.toInt()}'),
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
                              color: AppColors.accentAmber,
                              fontSize: 20,
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

          // Bottom Bar
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
                        Text('TOTAL FOR $_nightsCount NIGHTS', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
                        Text(
                          '₹${_grandTotal.toInt()}',
                          style: AppTypography.headingMedium.copyWith(color: AppColors.accentAmber),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: GlassButton(
                      text: _isProcessing ? 'Confirming...' : 'Book Stay 🏨',
                      variant: GlassButtonVariant.primary,
                      onPressed: _isProcessing ? null : _confirmStay,
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

  Widget _buildPriceRow(String label, String value) {
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
