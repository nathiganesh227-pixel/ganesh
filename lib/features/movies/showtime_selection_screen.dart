import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/movie_mock_data.dart';
import '../../core/models/cinema_showtime.dart';
import '../../core/models/movie.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import 'seat_selection_screen.dart';

class ShowtimeSelectionScreen extends StatefulWidget {
  final Movie movie;

  const ShowtimeSelectionScreen({
    super.key,
    required this.movie,
  });

  @override
  State<ShowtimeSelectionScreen> createState() => _ShowtimeSelectionScreenState();
}

class _ShowtimeSelectionScreenState extends State<ShowtimeSelectionScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _dates;
  MovieFormat? _selectedFormatFilter;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _dates = List.generate(7, (i) => _selectedDate.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final theatres = MovieMockData.getTheatresForMovie(movie.id);

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
              movie.title,
              style: AppTypography.headingMedium.copyWith(fontSize: 17),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${movie.primaryLanguage.label} • ${movie.certificate} • ${movie.duration}',
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // Horizontal Date Selector
          SizedBox(
            height: 84,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _dates.length,
              itemBuilder: (context, index) {
                final date = _dates[index];
                final isSelected = date.day == _selectedDate.day &&
                    date.month == _selectedDate.month;
                final isToday = index == 0;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 62,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFF5E36), Color(0xFFFF8B3D)],
                            )
                          : null,
                      color: isSelected ? null : AppColors.glassFillMedium,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0x80FFFFFF)
                            : AppColors.glassBorderSubtle,
                        width: 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF5E36).withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
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
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('d').format(date),
                          style: AppTypography.headingLarge.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(date),
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 9,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Format Quick Filter Pills
          SizedBox(
            height: 34,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildFormatPill(null, 'All Formats'),
                ...movie.formats.map((f) => _buildFormatPill(f, f.label)),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0x15FFFFFF), height: 1),

          // Theatres and Showtimes List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: theatres.length,
              itemBuilder: (context, index) {
                final theatre = theatres[index];
                final availableShowtimes = theatre.showtimes.where((st) {
                  if (_selectedFormatFilter != null &&
                      st.format != _selectedFormatFilter) {
                    return false;
                  }
                  return true;
                }).toList();

                if (availableShowtimes.isEmpty) {
                  return const SizedBox.shrink();
                }

                return _buildTheatreCard(theatre, availableShowtimes);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatPill(MovieFormat? format, String label) {
    final isSelected = _selectedFormatFilter == format;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFormatFilter = format;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.glassFillMedium,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTheatreCard(Theatre theatre, List<ShowtimeSlot> showtimes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theatre Name & Distance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(theatre.name, style: AppTypography.headingSmall),
                      const SizedBox(height: 2),
                      Text(
                        theatre.location,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                GlassPill(
                  label: theatre.distance,
                  icon: Icons.near_me_outlined,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Amenities
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: theatre.amenities
                  .take(3)
                  .map(
                    (a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x10FFFFFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        a,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 14),

            // Showtimes Grid
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: showtimes.map((st) => _buildShowtimePill(theatre, st)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowtimePill(Theatre theatre, ShowtimeSlot slot) {
    Color borderColor = AppColors.glassBorderSubtle;
    Color timeColor = AppColors.textPrimary;
    String statusNote = '';

    if (slot.isAlmostFull) {
      borderColor = const Color(0x60EF4444);
      statusNote = 'Almost Full';
    } else if (slot.isFillingFast) {
      borderColor = const Color(0x60F59E0B);
      statusNote = 'Filling Fast';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeatSelectionScreen(
              movie: widget.movie,
              theatre: theatre,
              showtime: slot,
              date: _selectedDate,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x20FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x15000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              slot.time,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: timeColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              slot.format.label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primaryLight,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (statusNote.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                statusNote,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 8,
                  color: slot.isAlmostFull ? AppColors.alertRed : AppColors.accentAmber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
