import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/cinema_showtime.dart';
import '../../core/models/movie.dart';
import '../../core/repositories/api_movie_repository.dart';
import '../../core/repositories/movie_repository.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import 'seat_selection_screen.dart';

class ShowtimeSelectionScreen extends StatefulWidget {
  final Movie movie;
  final MovieRepository? repository;

  const ShowtimeSelectionScreen({
    super.key,
    required this.movie,
    this.repository,
  });

  @override
  State<ShowtimeSelectionScreen> createState() => _ShowtimeSelectionScreenState();
}

class _ShowtimeSelectionScreenState extends State<ShowtimeSelectionScreen> {
  late final MovieRepository _repository;
  late DateTime _selectedDate;
  late List<DateTime> _dates;
  MovieFormat? _selectedFormatFilter;

  List<Theatre> _theatres = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiMovieRepository();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _dates = List.generate(7, (i) => _selectedDate.add(Duration(days: i)));
    _loadShowtimes();
  }

  Future<void> _loadShowtimes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final city = PlazaGlobalState.instance.selectedCity;
      final results = await _repository.getTheatresForMovie(
        widget.movie.id,
        date: dateStr,
        city: city,
      );

      if (mounted) {
        setState(() {
          _theatres = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load showtimes. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final currentCity = PlazaGlobalState.instance.selectedCity;

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
              '$currentCity • ${movie.primaryLanguage.label} • ${movie.certificate} • ${movie.duration}',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
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
                    date.month == _selectedDate.month &&
                    date.year == _selectedDate.year;
                final isToday = index == 0;

                return GestureDetector(
                  onTap: () {
                    if (!isSelected) {
                      setState(() {
                        _selectedDate = date;
                      });
                      _loadShowtimes();
                    }
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

          // Theatres and Showtimes Content Area
          Expanded(
            child: _buildShowtimesContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildShowtimesContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Finding best theatres & showtimes...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.alertRed),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GlassButton(
                text: 'Try Again',
                icon: Icons.refresh_rounded,
                variant: GlassButtonVariant.secondary,
                onPressed: _loadShowtimes,
              ),
            ],
          ),
        ),
      );
    }

    final filteredTheatres = _theatres.where((theatre) {
      final availableShowtimes = theatre.showtimes.where((st) {
        if (_selectedFormatFilter != null && st.format != _selectedFormatFilter) {
          return false;
        }
        return true;
      }).toList();
      return availableShowtimes.isNotEmpty;
    }).toList();

    if (filteredTheatres.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadShowtimes,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceElevated,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.glassFillMedium,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.glassBorderSubtle),
                ),
                child: const Icon(
                  Icons.theaters_outlined,
                  size: 44,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Shows Scheduled',
              style: AppTypography.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'No screenings available on ${DateFormat('EEE, d MMM').format(_selectedDate)} in ${PlazaGlobalState.instance.selectedCity}. Try another date or city.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: GlassButton(
                text: 'Refresh Showtimes',
                icon: Icons.refresh_rounded,
                variant: GlassButtonVariant.secondary,
                onPressed: _loadShowtimes,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShowtimes,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemCount: filteredTheatres.length,
        itemBuilder: (context, index) {
          final theatre = filteredTheatres[index];
          final availableShowtimes = theatre.showtimes.where((st) {
            if (_selectedFormatFilter != null && st.format != _selectedFormatFilter) {
              return false;
            }
            return true;
          }).toList();

          return _buildTheatreCard(theatre, availableShowtimes);
        },
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
    final isSoldOut = slot.isSoldOut;
    final isAlmostFull = slot.isAlmostFull;
    final isFillingFast = slot.isFillingFast;

    Color borderColor = AppColors.glassBorderSubtle;
    Color timeColor = AppColors.textPrimary;
    String statusNote = '';
    Color statusColor = AppColors.textMuted;

    if (isSoldOut) {
      borderColor = AppColors.alertRed.withValues(alpha: 0.35);
      timeColor = AppColors.textMuted;
      statusNote = 'Sold Out';
      statusColor = AppColors.alertRed;
    } else if (isAlmostFull) {
      borderColor = AppColors.warningOrange.withValues(alpha: 0.6);
      statusNote = 'Almost Full';
      statusColor = AppColors.warningOrange;
    } else if (isFillingFast) {
      borderColor = AppColors.accentAmber.withValues(alpha: 0.6);
      statusNote = 'Filling Fast';
      statusColor = AppColors.accentAmber;
    }

    // Server pricing lowest display
    final lowestPrice = slot.pricing?['gold']?.toInt() ??
        slot.pricing?['standard']?.toInt() ??
        slot.basePrice.toInt();

    return GestureDetector(
      onTap: () {
        if (isSoldOut) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This show is sold out. Please select another showtime.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSoldOut ? const Color(0x0CFFFFFF) : const Color(0x20FFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: isSoldOut
              ? null
              : const [
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slot.format.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSoldOut ? AppColors.textMuted : AppColors.primaryLight,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '• ₹$lowestPrice',
                  style: AppTypography.labelSmall.copyWith(
                    color: isSoldOut ? AppColors.textMuted : AppColors.accentGold,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (statusNote.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                statusNote,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 8,
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
