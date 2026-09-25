import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/movie_mock_data.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/movie.dart';
import '../../core/repositories/movie_repository.dart';
import '../../core/repositories/api_movie_repository.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/plaza_image.dart';
import '../../core/widgets/section_header.dart';
import 'movie_details_screen.dart';
import 'showtime_selection_screen.dart';
import 'widgets/movie_card.dart';

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
  bool _isLoading = false;
  String? _errorMessage;

  // Filters state
  String _searchQuery = '';
  String _selectedCategory = 'All'; // 'All', 'Now Showing', 'Coming Soon'
  MovieLanguage? _selectedLanguage;
  MovieFormat? _selectedFormat;
  String? _selectedGenre;
  bool _showFavoritesOnly = false;

  Timer? _debounceTimer;

  final List<String> _availableCities = [
    'Hyderabad',
    'Bengaluru',
    'Mumbai',
    'Delhi NCR',
    'Chennai',
    'Goa',
  ];

  @override
  void initState() {
    super.initState();
    _movieRepo = widget.repository ?? ApiMovieRepository();
    _fetchMovies();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final movies = await _movieRepo.getMovies();
      if (mounted && movies.isNotEmpty) {
        setState(() {
          _loadedMovies = movies;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load movies from network. Showing cached releases.';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _searchQuery = query.trim();
      });

      if (_searchQuery.isNotEmpty) {
        try {
          final results = await _movieRepo.searchMovies(_searchQuery);
          if (mounted && results.isNotEmpty) {
            setState(() {
              // Update search matches without overwriting cached list
              for (final res in results) {
                if (!_loadedMovies.any((m) => m.id == res.id)) {
                  _loadedMovies.add(res);
                }
              }
            });
          }
        } catch (_) {
          // Local filter acts as fallback
        }
      }
    });
  }

  List<Movie> get _filteredMovies {
    final favorites = PlazaGlobalState.instance.favoriteIds;

    return _loadedMovies.where((m) {
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = m.title.toLowerCase().contains(q);
        final matchesGenre = m.genres.any((g) => g.toLowerCase().contains(q));
        final matchesDirector = m.director.toLowerCase().contains(q);
        if (!matchesTitle && !matchesGenre && !matchesDirector) return false;
      }

      // Category filter
      if ((_selectedCategory == 'In Theatres' || _selectedCategory == 'Now Showing') && !m.isNowShowing) return false;
      if ((_selectedCategory == 'Upcoming' || _selectedCategory == 'Coming Soon') && !m.isComingSoon) return false;

      // Language filter
      if (_selectedLanguage != null) {
        if (!m.availableLanguages.contains(_selectedLanguage)) return false;
      }

      // Format filter
      if (_selectedFormat != null) {
        if (!m.formats.contains(_selectedFormat)) return false;
      }

      // Genre filter
      if (_selectedGenre != null) {
        if (!m.genres.contains(_selectedGenre)) return false;
      }

      // Favorites only
      if (_showFavoritesOnly && !favorites.contains(m.id)) return false;

      return true;
    }).toList();
  }

  List<String> get _allGenres {
    final set = <String>{};
    for (final m in _loadedMovies) {
      set.addAll(m.genres);
    }
    return set.toList();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedLanguage = null;
      _selectedFormat = null;
      _selectedGenre = null;
      _showFavoritesOnly = false;
    });
  }

  void _openCitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final currentCity = PlazaGlobalState.instance.selectedCity;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: const BoxDecoration(
                color: Color(0xEB090D18),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1.0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Select Movie Location', style: AppTypography.headingLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Explore showtimes and cinema halls near you',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  ..._availableCities.map(
                    (city) {
                      final isSelected = city == currentCity;
                      return ListTile(
                        title: Text(
                          city,
                          style: AppTypography.labelLarge.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                            : null,
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          PlazaGlobalState.instance.setSelectedCity(city);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Viewing movies in $city'),
                              backgroundColor: AppColors.surfaceElevated,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final currentCity = PlazaGlobalState.instance.selectedCity;
        final filtered = _filteredMovies;
        final nowShowing = filtered.where((m) => m.isNowShowing).toList();
        final comingSoon = filtered.where((m) => m.isComingSoon).toList();
        final trending = filtered.where((m) => m.isTrending).toList();
        final featuredMovie = trending.isNotEmpty
            ? trending.first
            : (nowShowing.isNotEmpty ? nowShowing.first : _loadedMovies.firstOrNull);

        final isSearching = _searchQuery.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Atmospheric Hero Ambient Glow
              Positioned(
                top: -80,
                left: -40,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.heroAmbientGlow,
                  ),
                ),
              ),

              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1100;
                    final isDesktop = constraints.maxWidth >= 1100;
                    final gridColumns = isDesktop ? 5 : (isTablet ? 3 : 2);

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Top Navigation App Bar
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

                                Row(
                                  children: [
                                    // Favorites toggle shortcut
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _showFavoritesOnly = !_showFavoritesOnly;
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _showFavoritesOnly
                                              ? AppColors.primary.withValues(alpha: 0.25)
                                              : AppColors.glassFillMedium,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: _showFavoritesOnly
                                                ? AppColors.primary
                                                : AppColors.glassBorderSubtle,
                                          ),
                                        ),
                                        child: Icon(
                                          _showFavoritesOnly
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          size: 18,
                                          color: _showFavoritesOnly
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),

                                    // City Selector Pill
                                    GestureDetector(
                                      onTap: () => _openCitySelector(context),
                                      child: GlassPill(
                                        label: currentCity,
                                        icon: Icons.location_on_rounded,
                                        iconColor: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Loading Progress Indicator
                        if (_isLoading)
                          const SliverToBoxAdapter(
                            child: LinearProgressIndicator(
                              color: AppColors.primary,
                              backgroundColor: Colors.transparent,
                              minHeight: 2,
                            ),
                          ),

                        // Error Banner if network fails
                        if (_errorMessage != null)
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0x30F59E0B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0x60F59E0B)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: AppColors.warningOrange, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTypography.bodySmall.copyWith(color: AppColors.warningOrange),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _fetchMovies,
                                    child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SliverToBoxAdapter(child: SizedBox(height: 10)),

                        // Search Bar
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GlassSearchBar(
                              hintText: 'Search movies, genres, actors...',
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 12)),

                        // Primary Category Filters (All | In Theatres | Upcoming)
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 38,
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                ...['All', 'In Theatres', 'Upcoming'].map((cat) {
                                  final isSelected = _selectedCategory == cat;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = cat;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: isSelected ? AppGradients.sunsetPrimary : null,
                                        color: isSelected ? null : AppColors.glassFillMedium,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: isSelected ? Colors.transparent : AppColors.glassBorderSubtle,
                                        ),
                                      ),
                                      child: Text(
                                        cat,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                                const VerticalDivider(color: Colors.white12, width: 16, indent: 6, endIndent: 6),

                                // Reset filters icon if active
                                if (_selectedLanguage != null || _selectedFormat != null || _selectedGenre != null || _showFavoritesOnly)
                                  GestureDetector(
                                    onTap: _resetFilters,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0x30EF4444),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: const Color(0x60EF4444)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.close_rounded, size: 14, color: AppColors.alertRed),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Reset',
                                            style: AppTypography.labelSmall.copyWith(color: AppColors.alertRed),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 8)),

                        // Sub-Filters: Languages & Formats
                        SliverToBoxAdapter(
                          child: Column(
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
                              const SizedBox(height: 6),
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
                              if (_allGenres.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                SliverFilterRow<String>(
                                  items: _allGenres,
                                  selectedItem: _selectedGenre,
                                  getItemLabel: (g) => g,
                                  onItemSelected: (g) {
                                    setState(() {
                                      _selectedGenre = _selectedGenre == g ? null : g;
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 16)),

                        // Search Results Count Header (if searching)
                        if (isSearching)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Found ${filtered.length} release${filtered.length == 1 ? '' : 's'} for "$_searchQuery"',
                                    style: AppTypography.headingSmall.copyWith(fontSize: 15),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                    child: const Text('Clear', style: TextStyle(color: AppColors.primary)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Empty State if no matches
                        if (filtered.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: const BoxDecoration(
                                        color: Color(0x15FFFFFF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.movie_filter_rounded,
                                        size: 32,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('No Movies Found', style: AppTypography.headingMedium),
                                    const SizedBox(height: 8),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'No cinema releases matched "$_searchQuery".'
                                          : 'No movies match your active filters.',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodySmall,
                                    ),
                                    const SizedBox(height: 20),
                                    GlassButton(
                                      text: 'Reset All Filters',
                                      icon: Icons.refresh_rounded,
                                      variant: GlassButtonVariant.secondary,
                                      width: 180,
                                      onPressed: _resetFilters,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Featured Hero Section (when not searching and featured exists)
                        if (!isSearching && featuredMovie != null && _selectedCategory == 'All') ...[
                          SliverToBoxAdapter(
                            child: _buildCinematicFeaturedSection(featuredMovie),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],

                        // Trending Movies (Cinematic Wide Hero Cards)
                        if (!isSearching && trending.isNotEmpty && (_selectedCategory == 'All' || _selectedCategory == 'In Theatres' || _selectedCategory == 'Now Showing')) ...[
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
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],

                        // Now Showing Section
                        if (nowShowing.isNotEmpty && (_selectedCategory == 'All' || _selectedCategory == 'In Theatres' || _selectedCategory == 'Now Showing')) ...[
                          SliverToBoxAdapter(
                            child: SectionHeader(
                              title: 'Now Showing',
                              subtitle: '${nowShowing.length} movies in $currentCity theatres',
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridColumns,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 16,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final movie = nowShowing[index];
                                  return MovieCard(movie: movie);
                                },
                                childCount: nowShowing.length,
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 28)),
                        ],

                        // Coming Soon Section
                        if (comingSoon.isNotEmpty && (_selectedCategory == 'All' || _selectedCategory == 'Upcoming' || _selectedCategory == 'Coming Soon')) ...[
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
                                  return Container(
                                    width: 165,
                                    margin: const EdgeInsets.only(right: 14),
                                    child: MovieCard(movie: movie),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],

                        // Near You / In City Section
                        if (!isSearching && nowShowing.isNotEmpty && _selectedCategory == 'All') ...[
                          SliverToBoxAdapter(
                            child: SectionHeader(
                              title: 'Near You in $currentCity',
                              subtitle: 'Top-rated multiplexes with instant ticketing',
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 290,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: nowShowing.take(4).length,
                                itemBuilder: (context, index) {
                                  final movie = nowShowing[index];
                                  return Container(
                                    width: 175,
                                    margin: const EdgeInsets.only(right: 14),
                                    child: MovieCard(movie: movie),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],

                        const SliverToBoxAdapter(child: SizedBox(height: 60)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Cinematic Featured Hero section showcasing the primary blockbuster
  Widget _buildCinematicFeaturedSection(Movie movie) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlazaImage(
              imageUrl: movie.backdropUrl,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x30000000),
                    Color(0x80070A11),
                    Color(0xF5070A11),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Specular border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.glassBorder, width: 1.2),
              ),
            ),

            // Top Badges
            Positioned(
              top: 14,
              left: 14,
              child: GlassPill(
                label: 'FEATURED PREMIERE',
                backgroundColor: AppColors.primary.withValues(alpha: 0.9),
                textColor: Colors.white,
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: GlassPill(
                label: '${movie.rating.toStringAsFixed(1)} ★',
                backgroundColor: const Color(0xA0000000),
                textColor: AppColors.accentGold,
              ),
            ),

            // Bottom Content
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    movie.title,
                    style: AppTypography.headingLarge.copyWith(fontSize: 22),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.primaryLanguage.label} • ${movie.genres.join(', ')} • ${movie.duration}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (movie.isNowShowing)
                        Expanded(
                          child: GlassButton(
                            text: 'Book Tickets',
                            icon: Icons.confirmation_number_rounded,
                            variant: GlassButtonVariant.primary,
                            height: 44,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShowtimeSelectionScreen(movie: movie),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Expanded(
                          child: GlassButton(
                            text: 'Coming Soon',
                            icon: Icons.calendar_today_rounded,
                            variant: GlassButtonVariant.secondary,
                            height: 44,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MovieDetailsScreen(movie: movie),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(width: 12),
                      GlassButton(
                        text: 'Details',
                        variant: GlassButtonVariant.secondary,
                        height: 44,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailsScreen(movie: movie),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
              if (movie.formats.isNotEmpty)
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
      height: 34,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
