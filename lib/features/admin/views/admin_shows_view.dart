import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminShowsView extends StatefulWidget {
  final AdminRepository? repository;

  const AdminShowsView({super.key, this.repository});

  @override
  State<AdminShowsView> createState() => _AdminShowsViewState();
}

class _AdminShowsViewState extends State<AdminShowsView> {
  late final AdminRepository _repo;
  List<AdminShow> _shows = [];
  List<AdminMovie> _movies = [];
  List<AdminTheatre> _theatres = [];
  List<AdminScreen> _screens = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final results = await Future.wait([
      _repo.getShows(),
      _repo.getMovies(),
      _repo.getTheatres(),
      _repo.getScreens(),
    ]);

    if (!mounted) return;

    final showsRes = results[0] as dynamic;
    final moviesRes = results[1] as dynamic;
    final theatresRes = results[2] as dynamic;
    final screensRes = results[3] as dynamic;

    if (showsRes.success && showsRes.data != null) {
      setState(() {
        _shows = showsRes.data as List<AdminShow>;
        if (moviesRes.success && moviesRes.data != null) {
          _movies = moviesRes.data as List<AdminMovie>;
        }
        if (theatresRes.success && theatresRes.data != null) {
          _theatres = theatresRes.data as List<AdminTheatre>;
        }
        if (screensRes.success && screensRes.data != null) {
          _screens = screensRes.data as List<AdminScreen>;
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = showsRes.message ?? 'Failed to load showtimes.';
        _isLoading = false;
      });
    }
  }

  void _showAddShowDialog([AdminShow? existing]) {
    String? selectedMovieId = existing?.movieId ?? (_movies.isNotEmpty ? _movies.first.id : null);
    String? selectedTheatreId = existing?.theatreId ?? (_theatres.isNotEmpty ? _theatres.first.id : null);
    
    // Screens belonging to selected theatre
    List<AdminScreen> availableScreens = _screens.where((s) => s.theatreId == selectedTheatreId).toList();
    String? selectedScreenId = existing?.screenId ?? (availableScreens.isNotEmpty ? availableScreens.first.id : null);

    final dateController = TextEditingController(text: existing?.showDate ?? '2026-09-26');
    final timeController = TextEditingController(text: existing?.startTime ?? '10:15 AM');
    final formatController = TextEditingController(text: existing?.format ?? 'IMAX 3D');
    final langController = TextEditingController(text: existing?.language ?? 'Telugu');
    final goldController = TextEditingController(text: existing?.pricing.gold.toInt().toString() ?? '295');
    final premController = TextEditingController(text: existing?.pricing.premium.toInt().toString() ?? '350');
    final recController = TextEditingController(text: existing?.pricing.recliner.toInt().toString() ?? '450');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(existing == null ? 'Schedule Movie Show' : 'Edit Show Slot', style: AppTypography.headingMedium),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Movie selection
                  if (_movies.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedMovieId,
                      dropdownColor: AppColors.surfaceElevated,
                      style: AppTypography.bodyMedium,
                      decoration: const InputDecoration(labelText: 'Movie Release'),
                      items: _movies.map((m) {
                        return DropdownMenuItem(value: m.id, child: Text(m.title, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedMovieId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Step 2: Theatre selection
                  if (_theatres.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedTheatreId,
                      dropdownColor: AppColors.surfaceElevated,
                      style: AppTypography.bodyMedium,
                      decoration: const InputDecoration(labelText: 'Theatre Multiplex'),
                      items: _theatres.map((t) {
                        return DropdownMenuItem(value: t.id, child: Text(t.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDlgState(() {
                            selectedTheatreId = val;
                            availableScreens = _screens.where((s) => s.theatreId == val).toList();
                            selectedScreenId = availableScreens.isNotEmpty ? availableScreens.first.id : null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Step 3: Screen selection
                  DropdownButtonFormField<String>(
                    initialValue: selectedScreenId,
                    dropdownColor: AppColors.surfaceElevated,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(labelText: 'Screen / Audi'),
                    items: availableScreens.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.capacity} seats)'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedScreenId = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Step 4: Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateController,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: timeController,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'Start Time (e.g. 10:15 AM)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Step 5: Format & Language
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: formatController,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'Format (IMAX 3D, 2D)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: langController,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'Language (Telugu, etc.)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Step 6: Pricing Tiers
                  Text('Seat Tier Pricing (₹)', style: AppTypography.labelLarge.copyWith(color: AppColors.accentGold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: goldController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'Gold (₹)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: premController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'Premium (₹)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: recController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'Recliner (₹)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedMovieId == null || selectedTheatreId == null || selectedScreenId == null) {
                  return;
                }

                Navigator.of(ctx).pop();
                final pricing = {
                  'gold': double.tryParse(goldController.text) ?? 250.0,
                  'premium': double.tryParse(premController.text) ?? 350.0,
                  'recliner': double.tryParse(recController.text) ?? 450.0,
                };

                final dto = {
                  'movieId': selectedMovieId,
                  'theatreId': selectedTheatreId,
                  'screenId': selectedScreenId,
                  'showDate': dateController.text.trim(),
                  'startTime': timeController.text.trim(),
                  'format': formatController.text.trim(),
                  'language': langController.text.trim(),
                  'pricing': pricing,
                };

                final res = existing == null
                    ? await _repo.createShow(dto)
                    : await _repo.updateShow(existing.id, dto);

                if (!mounted) return;
                if (!res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.message ?? 'Show scheduling conflict or error occurred.'),
                      backgroundColor: AppColors.alertRed,
                    ),
                  );
                }
                _loadAll();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(existing == null ? 'Schedule Show' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelShow(AdminShow show) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Show Slot?', style: AppTypography.headingMedium),
        content: Text(
          'Date: ${show.showDate} at ${show.startTime} (${show.format}). If bookings already exist, the show will be safely transitioned to cancelled status.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final res = await _repo.deleteShow(show.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res.message ?? 'Show slot updated successfully.'),
                  backgroundColor: AppColors.surfaceElevated,
                ),
              );
              _loadAll();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Showtimes & Slots Scheduler', style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Link movies to theatres and screens with tiered pricing and collision protection.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddShowDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Schedule Show'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ))
          else if (_errorMessage != null)
            Center(
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.alertRed)),
              ),
            )
          else if (_shows.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No showtimes scheduled yet.', style: AppTypography.bodyMedium),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _shows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final show = _shows[index];
                final movieTitle = _movies.firstWhere((m) => m.id == show.movieId, orElse: () => AdminMovie(id: '', title: 'Movie', synopsis: '', posterUrl: '', backdropUrl: '', rating: 0, votesCount: 0, genres: [], duration: '', primaryLanguage: '', availableLanguages: [], formats: [], certificate: '', releaseDate: '', startingPrice: 0, director: '')).title;
                final theatreName = _theatres.firstWhere((t) => t.id == show.theatreId, orElse: () => AdminTheatre(id: '', name: 'Theatre', location: '')).name;
                final isCancelled = show.status == 'cancelled';

                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCancelled
                              ? AppColors.alertRed.withValues(alpha: 0.12)
                              : AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.schedule_rounded,
                          color: isCancelled ? AppColors.alertRed : AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$movieTitle • ${show.startTime}',
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isCancelled
                                        ? AppColors.alertRed.withValues(alpha: 0.15)
                                        : AppColors.liveGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    show.status.toUpperCase(),
                                    style: TextStyle(
                                      color: isCancelled ? AppColors.alertRed : AppColors.liveGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$theatreName • Date: ${show.showDate} • ${show.format} (${show.language})',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pricing: Gold ₹${show.pricing.gold.toInt()} | Prem ₹${show.pricing.premium.toInt()} | Rec ₹${show.pricing.recliner.toInt()}',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.accentGold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        onPressed: () => _showAddShowDialog(show),
                        tooltip: 'Edit Slot',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.alertRed),
                        onPressed: () => _confirmCancelShow(show),
                        tooltip: 'Cancel Show Slot',
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
