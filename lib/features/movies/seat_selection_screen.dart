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
import '../../core/widgets/glass_button.dart';
import 'order_summary_screen.dart';
import 'widgets/screen_curve_painter.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Movie movie;
  final Theatre theatre;
  final ShowtimeSlot showtime;
  final DateTime date;

  const SeatSelectionScreen({
    super.key,
    required this.movie,
    required this.theatre,
    required this.showtime,
    required this.date,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  late List<CinemaSeat> _seats;
  final List<CinemaSeat> _selectedSeats = [];
  static const int maxSeats = 8;

  @override
  void initState() {
    super.initState();
    _seats = MovieMockData.generateSeatGrid(widget.showtime);
  }

  double get _totalPrice {
    return _selectedSeats.fold(0, (sum, seat) => sum + seat.price);
  }

  void _toggleSeat(CinemaSeat seat) {
    if (seat.status == SeatStatus.occupied) return;

    setState(() {
      if (seat.status == SeatStatus.selected) {
        seat.status = SeatStatus.available;
        _selectedSeats.removeWhere((s) => s.id == seat.id);
      } else {
        if (_selectedSeats.length >= maxSeats) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You can select a maximum of $maxSeats seats at a time.'),
              backgroundColor: AppColors.surfaceElevated,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        seat.status = SeatStatus.selected;
        _selectedSeats.add(seat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, d MMM').format(widget.date);

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
            Text(
              widget.movie.title,
              style: AppTypography.headingMedium.copyWith(fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.theatre.name} • $dateStr • ${widget.showtime.time}',
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main Interactive Seat Canvas
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 14),

                // Screen Curve Graphic
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: CinemaScreenCurve(),
                ),

                const SizedBox(height: 24),

                // Seat Matrix grouped by tier
                InteractiveViewer(
                  maxScale: 2.5,
                  minScale: 0.8,
                  boundaryMargin: const EdgeInsets.all(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildTierSection('VIP RECLINERS', SeatTier.vip, ['A', 'B']),
                        const SizedBox(height: 20),
                        _buildTierSection('PREMIUM', SeatTier.premium, ['C', 'D', 'E', 'F']),
                        const SizedBox(height: 20),
                        _buildTierSection('EXECUTIVE', SeatTier.executive, ['G', 'H']),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Seat Legend
                _buildLegend(),

                const SizedBox(height: 140), // Padding for bottom floating bar
              ],
            ),
          ),

          // Bottom Liquid Glass Summary Dock
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedSeats.isEmpty
                                  ? 'SELECT SEATS'
                                  : '${_selectedSeats.length} SEAT${_selectedSeats.length > 1 ? 'S' : ''} (${_selectedSeats.map((s) => s.displayName).join(', ')})',
                              style: AppTypography.labelSmall.copyWith(
                                color: _selectedSeats.isEmpty
                                    ? AppColors.textMuted
                                    : AppColors.primaryLight,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${_totalPrice.toInt()}',
                              style: AppTypography.priceTag.copyWith(
                                fontSize: 24,
                                color: _selectedSeats.isEmpty
                                    ? AppColors.textSecondary
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      GlassButton(
                        text: 'Proceed',
                        icon: Icons.arrow_forward_rounded,
                        variant: GlassButtonVariant.primary,
                        height: 50,
                        onPressed: _selectedSeats.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderSummaryScreen(
                                      movie: widget.movie,
                                      theatre: widget.theatre,
                                      showtime: widget.showtime,
                                      date: widget.date,
                                      selectedSeats: _selectedSeats,
                                    ),
                                  ),
                                );
                              },
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

  Widget _buildTierSection(String title, SeatTier tier, List<String> rows) {
    final tierPrice = tier == SeatTier.vip
        ? (widget.showtime.basePrice + 155)
        : (tier == SeatTier.premium
            ? widget.showtime.basePrice
            : (widget.showtime.basePrice * 0.7).roundToDouble());

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 1,
              width: 30,
              color: const Color(0x20FFFFFF),
            ),
            const SizedBox(width: 8),
            Text(
              '$title • ₹${tierPrice.toInt()}',
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 1.2,
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 1,
              width: 30,
              color: const Color(0x20FFFFFF),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...rows.map((rowLabel) {
          final rowSeats = _seats.where((s) => s.rowLabel == rowLabel).toList();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Row Letter
                SizedBox(
                  width: 20,
                  child: Text(
                    rowLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Left Block
                ...rowSeats.take(rowSeats.length ~/ 2).map((s) => _buildSeatWidget(s)),

                // Aisle Gap
                const SizedBox(width: 20),

                // Right Block
                ...rowSeats.skip(rowSeats.length ~/ 2).map((s) => _buildSeatWidget(s)),

                const SizedBox(width: 6),
                SizedBox(
                  width: 20,
                  child: Text(
                    rowLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSeatWidget(CinemaSeat seat) {
    Color bgColor;
    Color borderColor;
    Color textColor = Colors.white;

    switch (seat.status) {
      case SeatStatus.available:
        bgColor = const Color(0x18FFFFFF);
        borderColor = AppColors.glassBorderSubtle;
        textColor = AppColors.textSecondary;
        break;
      case SeatStatus.selected:
        bgColor = AppColors.primary;
        borderColor = const Color(0xFFFFA07A);
        textColor = Colors.white;
        break;
      case SeatStatus.occupied:
        bgColor = const Color(0x12FFFFFF);
        borderColor = Colors.transparent;
        textColor = const Color(0x20FFFFFF);
        break;
    }

    return GestureDetector(
      onTap: () => _toggleSeat(seat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 26,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: seat.status == SeatStatus.selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '${seat.seatNumber}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.glassFillMedium,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0x20FFFFFF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.glassBorderSubtle),
              ),
            ),
            'Available',
          ),
          _buildLegendItem(
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                gradient: AppGradients.sunsetPrimary,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.primary,
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            'Selected',
          ),
          _buildLegendItem(
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0x15FFFFFF),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            'Occupied',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Widget indicator, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
