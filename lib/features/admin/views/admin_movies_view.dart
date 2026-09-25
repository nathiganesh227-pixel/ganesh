import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminMoviesView extends StatefulWidget {
  final AdminRepository? repository;

  const AdminMoviesView({super.key, this.repository});

  @override
  State<AdminMoviesView> createState() => _AdminMoviesViewState();
}

class _AdminMoviesViewState extends State<AdminMoviesView> {
  late final AdminRepository _repo;
  List<AdminMovie> _movies = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _repo.getMovies();
    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _movies = res.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res.message ?? 'Failed to load movie catalog.';
        _isLoading = false;
      });
    }
  }

  void _showAddMovieDialog([AdminMovie? existing]) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final directorController = TextEditingController(text: existing?.director ?? '');
    final synopsisController = TextEditingController(text: existing?.synopsis ?? '');
    final posterController = TextEditingController(text: existing?.posterUrl ?? '');
    final priceController = TextEditingController(text: existing?.startingPrice.toString() ?? '250');
    final langController = TextEditingController(text: existing?.primaryLanguage ?? 'Telugu');
    bool isNowShowing = existing?.isNowShowing ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(existing == null ? 'New Movie Release' : 'Edit Movie', style: AppTypography.headingMedium),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(labelText: 'Movie Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: directorController,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(labelText: 'Director'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: synopsisController,
                    maxLines: 3,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(labelText: 'Synopsis'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: posterController,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(labelText: 'Poster Image URL'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: langController,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'Primary Language'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'Starting Price (₹)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: Text('Now Showing in Theatres', style: AppTypography.bodySmall),
                    value: isNowShowing,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDlgState(() => isNowShowing = val),
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
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                Navigator.of(ctx).pop();
                final dto = {
                  'title': title,
                  'director': directorController.text.trim().isEmpty ? 'Director' : directorController.text.trim(),
                  'synopsis': synopsisController.text.trim().isEmpty ? 'Synopsis' : synopsisController.text.trim(),
                  'posterUrl': posterController.text.trim().isEmpty ? 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba' : posterController.text.trim(),
                  'backdropUrl': 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba',
                  'primaryLanguage': langController.text.trim().isEmpty ? 'Telugu' : langController.text.trim(),
                  'startingPrice': double.tryParse(priceController.text) ?? 250.0,
                  'isNowShowing': isNowShowing,
                  'rating': 9.0,
                  'votesCount': 1000,
                  'genres': ['Action', 'Drama'],
                  'duration': '2h 45min',
                  'certificate': 'UA',
                  'releaseDate': '2026-09-25',
                };

                if (existing == null) {
                  await _repo.createMovie(dto);
                } else {
                  await _repo.updateMovie(existing.id, dto);
                }
                _loadMovies();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(existing == null ? 'Create Release' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMovie(AdminMovie movie) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Archive / Delete "${movie.title}"?', style: AppTypography.headingMedium),
        content: Text(
          'If active showtimes or bookings exist, this movie will be safely archived (marked not showing). Otherwise it will be removed permanently.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final res = await _repo.deleteMovie(movie.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res.message ?? 'Movie archived/deleted successfully.'),
                  backgroundColor: AppColors.surfaceElevated,
                ),
              );
              _loadMovies();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _movies.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return m.title.toLowerCase().contains(q) ||
          m.primaryLanguage.toLowerCase().contains(q) ||
          m.director.toLowerCase().contains(q);
    }).toList();

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
                    Text('Movie Catalog & Releases', style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Manage cinematic releases, formats, pricing, and show statuses.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddMovieDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Release'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Search bar
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search releases by title, director, or language...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
          const SizedBox(height: 18),

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
          else if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No movies found matching criteria.', style: AppTypography.bodyMedium),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final movie = filtered[index];
                return GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 50,
                          height: 70,
                          color: AppColors.surfaceElevated,
                          child: movie.posterUrl.isNotEmpty
                              ? Image.network(
                                  movie.posterUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(Icons.movie_creation_outlined, color: AppColors.textMuted),
                                )
                              : const Icon(Icons.movie_creation_outlined, color: AppColors.textMuted),
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
                                    movie.title,
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: movie.isNowShowing
                                        ? AppColors.liveGreen.withValues(alpha: 0.15)
                                        : AppColors.warningOrange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    movie.isNowShowing ? 'Now Showing' : 'Archived',
                                    style: TextStyle(
                                      color: movie.isNowShowing ? AppColors.liveGreen : AppColors.warningOrange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${movie.primaryLanguage} • Dir. ${movie.director} • ₹${movie.startingPrice.toInt()}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 14),
                                const SizedBox(width: 4),
                                Text('${movie.rating} ★', style: AppTypography.labelSmall),
                                const SizedBox(width: 12),
                                Text(movie.duration, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        onPressed: () => _showAddMovieDialog(movie),
                        tooltip: 'Edit Movie',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.alertRed),
                        onPressed: () => _confirmDeleteMovie(movie),
                        tooltip: 'Archive or Delete',
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
