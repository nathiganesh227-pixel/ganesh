import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/mock_data.dart';
import '../../core/data/movie_mock_data.dart';
import '../../core/models/movie.dart';
import '../../core/repositories/movie_repository.dart';
import '../../core/repositories/api_movie_repository.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/plaza_image.dart';
import '../../core/widgets/section_header.dart';
import 'movie_details_screen.dart';

class MoviesScreen extends StatefulWidget {
  final MovieRepository? repository;
  const MoviesScreen({super.key, this.repository});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final MovieRepository _movieRepo;
  List<Movie> _loadedMovies = MovieMockData.movies;
  MovieLanguage? _selectedLanguage;
  MovieFormat? _selectedFormat;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _movieRepo = widget.repository ?? ApiMovieRepository();
    _fetchMovies();
  }

  Future<void> _fetchMovies() async {
    try {
      final movies = await _movieRepo.getMovies();
      if (mounted && movies.isNotEmpty) {
        setState(() {
          _loadedMovies = movies;
        });
      }
    } catch (_) {
      // Keep loaded mock fallback
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Movie> get _filteredMovies {
    return _loadedMovies.where((m) {

      if (_searchQuery.isNotEmpty) {
        final matchesTitle = m.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesGenre = m.genres.any((g) => g.toLowerCase().contains(_searchQuery.toLowerCase()));
        if (!matchesTitle && !matchesGenre) return false;
      }
      if (_selectedLanguage != null) {
        if (!m.availableLanguages.contains(_selectedLanguage)) return false;
      }
      if (_selectedFormat != null) {
        if (!m.formats.contains(_selectedFormat)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final nowShowing = _filteredMovies.where((m) => m.isNowShowing).toList();
    final comingSoon = _filteredMovies.where((m) => m.isComingSoon).toList();
    final trending = _filteredMovies.where((m) => m.isTrending).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient Radial Glow
          Positioned(
            top: -80,
            left: -40,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.heroAmbientGlow,
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top App Bar with back button & Hyderabad city pill
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.glassFillMedium,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.glassBorderSubtle,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 18,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('Movies', style: AppTypography.headingLarge),
                          ],
                        ),

                        // City Pill
                        GlassPill(
                          label: MockData.currentCity,
                          icon: Icons.location_on_rounded,
                          iconColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GlassSearchBar(
                      hintText: 'Search movies, genres, actors...',
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Horizontal Filters (Languages & Formats)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Language Filter Row
                      SliverFilterRow<MovieLanguage>(
                        items: MovieLanguage.values,
                        selectedItem: _selectedLanguage,
                        getItemLabel: (l) => l.label,
                        onItemSelected: (l) {
                          setState(() {
                            _selectedLanguage = _selectedLanguage == l ? null : l;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      // Format Filter Row
                      SliverFilterRow<MovieFormat>(
                        items: MovieFormat.values,
                        selectedItem: _selectedFormat,
                        getItemLabel: (f) => f.label,
                        onItemSelected: (f) {
                          setState(() {
                            _selectedFormat = _selectedFormat == f ? null : f;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // If filter resulted in empty list
                if (_filteredMovies.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No movies found matching your filters.\nTry resetting filters.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ),
                  ),

                // Trending Movies (Cinematic Wide Hero Cards)
                if (trending.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Trending in IMAX & 3D',
                      subtitle: 'Most anticipated blockbuster screenings',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 380,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: trending.length,
                        itemBuilder: (context, index) {
                          final movie = trending[index];
                          return _buildTrendingHeroCard(movie);
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],

                // Now Showing Section
                if (nowShowing.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Now Showing',
                      subtitle: '${nowShowing.length} movies in Hyderabad theatres',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.56,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final movie = nowShowing[index];
                          return _buildMovieGridCard(movie);
                        },
                        childCount: nowShowing.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],

                // Coming Soon Section
                if (comingSoon.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Coming Soon',
                      subtitle: 'Advance bookings opening shortly',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 280,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: comingSoon.length,
                        itemBuilder: (context, index) {
                          final movie = comingSoon[index];
                          return _buildComingSoonCard(movie);
                        },
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingHeroCard(Movie movie) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(movie: movie),
          ),
        );
      },
      child: Container(
        width: 290,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x70000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PlazaImage(
                imageUrl: movie.posterUrl,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.cardImageOverlay,
                ),
              ),
              // Specular border
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.glassBorder, width: 1.2),
                ),
              ),

              // Rating pill
              Positioned(
                top: 14,
                right: 14,
                child: GlassPill(
                  label: '${movie.rating.toStringAsFixed(1)} ★',
                  backgroundColor: const Color(0x95070A11),
                  textColor: AppColors.accentGold,
                ),
              ),

              // Formats badges
              Positioned(
                top: 14,
                left: 14,
                child: GlassPill(
                  label: movie.formats.first.label,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.85),
                  textColor: Colors.white,
                ),
              ),

              // Bottom Info Panel
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x55090D18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.glassBorderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            movie.title,
                            style: AppTypography.headingSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${movie.primaryLanguage.label} • ${movie.genres.take(2).join(', ')} • ${movie.duration}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${movie.startingPrice.toInt()} onwards',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.accentAmber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.sunsetPrimary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Book',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildMovieGridCard(Movie movie) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(movie: movie),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlazaImage(
                    imageUrl: movie.posterUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.glassBorderSubtle),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x80070A11),
                        ],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GlassPill(
                      label: '${movie.rating.toStringAsFixed(1)} ★',
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      backgroundColor: const Color(0x90000000),
                      textColor: AppColors.accentGold,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: GlassPill(
                      label: movie.certificate,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      backgroundColor: const Color(0x60000000),
                      textColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            style: AppTypography.headingSmall.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${movie.primaryLanguage.label} • ${movie.genres.first}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '₹${movie.startingPrice.toInt()} onwards',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.accentAmber,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonCard(Movie movie) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(movie: movie),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlazaImage(
                      imageUrl: movie.posterUrl,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.glassBorderSubtle),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: GlassPill(
                        label: 'Releases Dec 6',
                        backgroundColor: const Color(0x95070A11),
                        textColor: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              style: AppTypography.labelMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              movie.primaryLanguage.label,
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class SliverFilterRow<T> extends StatelessWidget {
  final List<T> items;
  final T? selectedItem;
  final String Function(T) getItemLabel;
  final ValueChanged<T> onItemSelected;

  const SliverFilterRow({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.getItemLabel,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedItem == item;
          return GestureDetector(
            onTap: () => onItemSelected(item),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : AppColors.glassFillMedium,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  getItemLabel(item),
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
