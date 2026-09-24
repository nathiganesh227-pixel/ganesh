import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/mock_data.dart';
import '../../core/data/movie_mock_data.dart';
import '../../core/data/dining_mock_data.dart';
import '../../core/data/event_mock_data.dart';
import '../../core/data/activity_mock_data.dart';
import '../../core/data/shopping_mock_data.dart';
import '../../core/data/stay_mock_data.dart';
import '../../core/data/sports_mock_data.dart';
import '../../core/models/category.dart';
import '../../core/models/movie.dart';
import '../../core/models/dining.dart';
import '../../core/models/event.dart';
import '../../core/models/activity.dart';
import '../../core/models/shopping.dart';
import '../../core/models/stay.dart';
import '../../core/models/sports.dart';
import '../../core/repositories/search_repository.dart';
import '../../core/repositories/repository_provider.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/plaza_image.dart';
import '../movies/movie_details_screen.dart';
import '../movies/movies_screen.dart';
import '../dining/restaurant_details_screen.dart';
import '../dining/dining_screen.dart';
import '../events/event_details_screen.dart';
import '../events/events_screen.dart';
import '../activities/activity_details_screen.dart';
import '../activities/activities_screen.dart';
import '../shopping/product_details_screen.dart';
import '../shopping/shopping_screen.dart';
import '../stays/hotel_details_screen.dart';
import '../stays/stays_screen.dart';
import '../sports/sports_venue_details_screen.dart';
import '../sports/sports_screen.dart';

class UnifiedSearchResult {
  final String title;
  final String subtitle;
  final String categoryLabel;
  final PlazaCategoryType categoryType;
  final Color categoryColor;
  final String imageUrl;
  final double rating;
  final String priceInfo;
  final VoidCallback onTap;

  const UnifiedSearchResult({
    required this.title,
    required this.subtitle,
    required this.categoryLabel,
    required this.categoryType,
    required this.categoryColor,
    required this.imageUrl,
    required this.rating,
    required this.priceInfo,
    required this.onTap,
  });
}

class ExploreScreen extends StatefulWidget {
  final SearchRepository? repository;
  const ExploreScreen({super.key, this.repository});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final SearchRepository _searchRepo;
  Timer? _debounceTimer;
  List<UnifiedSearchResult>? _apiSearchResults;
  PlazaCategoryType? _selectedCategory;
  bool _isMapView = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchRepo = widget.repository ?? RepositoryProvider.instance.searchRepo;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
    });

    _debounceTimer?.cancel();
    if (query.isEmpty) {
      setState(() {
        _apiSearchResults = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _searchRepo.search(query);
        if (mounted && _searchQuery == query) {
          final mapped = _mapApiResultsToUnified(results);
          setState(() {
            _apiSearchResults = mapped;
          });
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<UnifiedSearchResult> _mapApiResultsToUnified(SearchResults r) {
    final List<UnifiedSearchResult> list = [];
    for (final m in r.movies) {
      list.add(UnifiedSearchResult(
        title: m.title,
        subtitle: '${m.genres.take(2).join(", ")} • ${m.primaryLanguage.label}',
        categoryLabel: 'MOVIE',
        categoryType: PlazaCategoryType.movies,
        categoryColor: AppColors.accentAmber,
        imageUrl: m.posterUrl,
        rating: m.rating,
        priceInfo: 'From ₹${m.startingPrice.toInt()}',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: m))),
      ));
    }
    for (final d in r.dining) {
      list.add(UnifiedSearchResult(
        title: d.name,
        subtitle: '${d.location.split(',').first} • ${d.cuisines.map((c) => c.label).take(2).join(', ')}',
        categoryLabel: 'DINING',
        categoryType: PlazaCategoryType.dining,
        categoryColor: AppColors.primary,
        imageUrl: d.coverImageUrl,
        rating: d.rating,
        priceInfo: '₹${d.priceForTwo.toInt()} for two',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailsScreen(restaurant: d))),
      ));
    }
    for (final e in r.events) {
      list.add(UnifiedSearchResult(
        title: e.title,
        subtitle: '${e.venue} • ${e.eventDate.day}/${e.eventDate.month}',
        categoryLabel: 'EVENT',
        categoryType: PlazaCategoryType.events,
        categoryColor: AppColors.secondaryViolet,
        imageUrl: e.bannerUrl,
        rating: e.rating,
        priceInfo: 'From ₹${e.startingPrice.toInt()}',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: e))),
      ));
    }
    for (final a in r.activities) {
      list.add(UnifiedSearchResult(
        title: a.title,
        subtitle: '${a.location} • ${a.duration}',
        categoryLabel: 'ACTIVITY',
        categoryType: PlazaCategoryType.activities,
        categoryColor: AppColors.liveGreen,
        imageUrl: a.coverImageUrl,
        rating: a.rating,
        priceInfo: 'From ₹${a.startingPrice.toInt()}',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailsScreen(activity: a))),
      ));
    }
    for (final s in r.shopping) {
      list.add(UnifiedSearchResult(
        title: s.name,
        subtitle: '${s.brand} • ${s.storeName}',
        categoryLabel: 'SHOPPING',
        categoryType: PlazaCategoryType.shopping,
        categoryColor: AppColors.secondaryCyan,
        imageUrl: s.coverImageUrl,
        rating: s.rating,
        priceInfo: '₹${s.price.toInt()}',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: s))),
      ));
    }
    for (final h in r.stays) {
      list.add(UnifiedSearchResult(
        title: h.name,
        subtitle: '${h.location} • ${h.tagline}',
        categoryLabel: 'STAY',
        categoryType: PlazaCategoryType.stays,
        categoryColor: AppColors.primaryLight,
        imageUrl: h.coverImageUrl,
        rating: h.rating,
        priceInfo: '₹${h.startingPricePerNight.toInt()}/night',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HotelDetailsScreen(hotel: h))),
      ));
    }
    for (final sp in r.sports) {
      list.add(UnifiedSearchResult(
        title: sp.name,
        subtitle: '${sp.location} • ${sp.supportedSports.map((x) => x.label).take(2).join(', ')}',
        categoryLabel: 'SPORTS',
        categoryType: PlazaCategoryType.sports,
        categoryColor: AppColors.liveGreen,
        imageUrl: sp.coverImageUrl,
        rating: sp.rating,
        priceInfo: 'From ₹${sp.startingPricePerHour.toInt()}/hr',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SportsVenueDetailsScreen(venue: sp))),
      ));
    }
    return list;
  }

  List<UnifiedSearchResult> _getUnifiedSearchResults(String query) {
    if (query.trim().isEmpty) return [];
    if (_apiSearchResults != null && _apiSearchResults!.isNotEmpty) {
      return _apiSearchResults!;
    }
    final q = query.toLowerCase().trim();
    final List<UnifiedSearchResult> results = [];

    // 1. Movies
    for (final m in MovieMockData.movies) {
      if (m.title.toLowerCase().contains(q) ||
          m.genres.any((g) => g.toLowerCase().contains(q)) ||
          m.director.toLowerCase().contains(q) ||
          m.cast.any((c) => c.name.toLowerCase().contains(q))) {
        results.add(UnifiedSearchResult(
          title: m.title,
          subtitle: '${m.genres.take(2).join(", ")} • ${m.primaryLanguage.label}',
          categoryLabel: 'MOVIE',
          categoryType: PlazaCategoryType.movies,
          categoryColor: AppColors.accentAmber,
          imageUrl: m.posterUrl,
          rating: m.rating,
          priceInfo: 'From ₹${m.startingPrice.toInt()}',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: m))),
        ));
      }
    }

    // 2. Dining
    for (final r in DiningMockData.restaurants) {
      if (r.name.toLowerCase().contains(q) ||
          r.location.toLowerCase().contains(q) ||
          r.cuisines.any((c) => c.label.toLowerCase().contains(q))) {
        results.add(UnifiedSearchResult(
          title: r.name,
          subtitle: '${r.location.split(',').first} • ${r.cuisines.map((c) => c.label).take(2).join(', ')}',
          categoryLabel: 'DINING',
          categoryType: PlazaCategoryType.dining,
          categoryColor: AppColors.primary,
          imageUrl: r.coverImageUrl,
          rating: r.rating,
          priceInfo: '₹${r.priceForTwo.toInt()} for two',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailsScreen(restaurant: r))),
        ));
      }
    }

    // 3. Events
    for (final e in EventMockData.events) {
      if (e.title.toLowerCase().contains(q) ||
          e.venue.toLowerCase().contains(q) ||
          e.category.label.toLowerCase().contains(q) ||
          e.artists.any((a) => a.name.toLowerCase().contains(q))) {
        results.add(UnifiedSearchResult(
          title: e.title,
          subtitle: '${e.venue} • ${e.eventDate.day}/${e.eventDate.month}',
          categoryLabel: 'EVENT',
          categoryType: PlazaCategoryType.events,
          categoryColor: AppColors.secondaryViolet,
          imageUrl: e.bannerUrl,
          rating: e.rating,
          priceInfo: 'From ₹${e.startingPrice.toInt()}',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: e))),
        ));
      }
    }

    // 4. Activities
    for (final a in ActivityMockData.activities) {
      if (a.title.toLowerCase().contains(q) ||
          a.venueName.toLowerCase().contains(q) ||
          a.category.label.toLowerCase().contains(q)) {
        results.add(UnifiedSearchResult(
          title: a.title,
          subtitle: '${a.venueName} • ${a.duration}',
          categoryLabel: 'ACTIVITY',
          categoryType: PlazaCategoryType.activities,
          categoryColor: AppColors.secondaryCyan,
          imageUrl: a.coverImageUrl,
          rating: a.rating,
          priceInfo: '₹${a.startingPrice.toInt()} / person',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailsScreen(activity: a))),
        ));
      }
    }

    // 5. Shopping
    for (final p in ShoppingMockData.products) {
      if (p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.category.label.toLowerCase().contains(q) ||
          p.storeName.toLowerCase().contains(q)) {
        results.add(UnifiedSearchResult(
          title: p.name,
          subtitle: '${p.brand} • ${p.storeName}',
          categoryLabel: 'SHOPPING',
          categoryType: PlazaCategoryType.shopping,
          categoryColor: const Color(0xFFEC4899),
          imageUrl: p.coverImageUrl,
          rating: p.rating,
          priceInfo: '₹${p.price.toInt()}',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: p))),
        ));
      }
    }

    // 6. Stays
    for (final h in StayMockData.hotels) {
      if (h.name.toLowerCase().contains(q) ||
          h.location.toLowerCase().contains(q) ||
          h.category.label.toLowerCase().contains(q)) {
        results.add(UnifiedSearchResult(
          title: h.name,
          subtitle: '${h.location} • ${h.category.label}',
          categoryLabel: 'STAYS',
          categoryType: PlazaCategoryType.stays,
          categoryColor: AppColors.accentGold,
          imageUrl: h.coverImageUrl,
          rating: h.rating,
          priceInfo: '₹${h.startingPricePerNight.toInt()} / night',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HotelDetailsScreen(hotel: h))),
        ));
      }
    }

    // 7. Sports
    for (final v in SportsMockData.venues) {
      if (v.name.toLowerCase().contains(q) ||
          v.location.toLowerCase().contains(q) ||
          v.supportedSports.any((s) => s.label.toLowerCase().contains(q))) {
        results.add(UnifiedSearchResult(
          title: v.name,
          subtitle: '${v.location} • ${v.supportedSports.map((s) => s.label.split('&').first.trim()).join(', ')}',
          categoryLabel: 'SPORTS',
          categoryType: PlazaCategoryType.sports,
          categoryColor: AppColors.liveGreen,
          imageUrl: v.coverImageUrl,
          rating: v.rating,
          priceInfo: '₹${v.startingPricePerHour.toInt()} / hr',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SportsVenueDetailsScreen(venue: v))),
        ));
      }
    }

    if (_selectedCategory != null) {
      return results.where((r) => r.categoryType == _selectedCategory).toList();
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = _getUnifiedSearchResults(_searchQuery);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -100,
            right: -60,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header (Title + Map Toggle)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Explore Hyderabad', style: AppTypography.displayMedium.copyWith(fontSize: 22)),
                          const SizedBox(height: 2),
                          Text('7 Curated Verticals across the City', style: AppTypography.bodySmall),
                        ],
                      ),
                      // Map / List Toggle
                      GestureDetector(
                        onTap: () => setState(() => _isMapView = !_isMapView),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _isMapView
                                    ? AppColors.primary.withValues(alpha: 0.25)
                                    : AppColors.glassFillMedium,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _isMapView ? AppColors.primary : AppColors.glassBorderSubtle,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isMapView ? Icons.format_list_bulleted_rounded : Icons.map_outlined,
                                    size: 16,
                                    color: _isMapView ? Colors.white : AppColors.primaryLight,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isMapView ? 'List View' : 'Map View',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: _isMapView ? Colors.white : AppColors.textPrimary,
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
                ),

                const SizedBox(height: 10),

                // Unified Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassSearchBar(
                    hintText: 'Search AMB, Olive, Taj, iPhone, Turfs...',
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                const SizedBox(height: 12),

                // Category Filter Pills
                SizedBox(
                  height: 38,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildCategoryFilterPill(null, 'All Categories', Icons.grid_view_rounded),
                      ...MockData.categories.map(
                        (c) => _buildCategoryFilterPill(c.type, c.title, c.icon),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Content View (Map Radar vs List View / Search Results)
                Expanded(
                  child: _isMapView
                      ? _buildMapView()
                      : _searchQuery.trim().isNotEmpty
                          ? _buildSearchResultsList(searchResults)
                          : _buildListView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterPill(PlazaCategoryType? type, String label, IconData icon) {
    final isSelected = _selectedCategory == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = type),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.glassFillMedium,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.primaryLight),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsList(List<UnifiedSearchResult> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('No results for "$_searchQuery"', style: AppTypography.headingSmall),
            const SizedBox(height: 4),
            Text('Try searching for movies, restaurants, hotels, sneakers, or turfs', style: AppTypography.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: item.onTap,
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  PlazaImage(
                    imageUrl: item.imageUrl,
                    width: 76,
                    height: 76,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.categoryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.categoryLabel,
                                style: AppTypography.labelSmall.copyWith(
                                  color: item.categoryColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 12, color: AppColors.accentGold),
                                const SizedBox(width: 3),
                                Text(
                                  item.rating.toStringAsFixed(1),
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.accentGold, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: AppTypography.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.priceInfo,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.accentAmber,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hyderabad Experience Radar', style: AppTypography.headingSmall),
                GlassPill(
                  label: '35 Active Hubs',
                  icon: Icons.radar_rounded,
                  iconColor: AppColors.liveGreen,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: const Color(0xFF0F172A),
                      child: GridPaper(
                        color: const Color(0x1538BDF8),
                        divisions: 2,
                        subdivisions: 2,
                      ),
                    ),
                    _buildMapPin(0.25, 0.35, 'Jubilee Hills (Dining & Luxury)', AppColors.primary),
                    _buildMapPin(0.40, 0.20, 'Hitec City (Inorbit & IKEA)', const Color(0xFFEC4899)),
                    _buildMapPin(0.55, 0.40, 'Gachibowli (HotFut Turf & Stays)', AppColors.liveGreen),
                    _buildMapPin(0.68, 0.65, 'Falaknuma (Taj Palace)', AppColors.accentGold),
                    _buildMapPin(0.35, 0.70, 'Necklace Road (Prasads IMAX)', AppColors.accentAmber),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tap any hotspot area to view real-time available slots & passes',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPin(double topFrac, double leftFrac, String label, Color color) {
    return Positioned(
      top: 260 * topFrac,
      left: 260 * leftFrac,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Focused on $label'),
              backgroundColor: AppColors.surfaceElevated,
              duration: const Duration(milliseconds: 800),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xDD090D18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                label.split('(').first.trim(),
                style: AppTypography.labelSmall.copyWith(fontSize: 9, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Category Hub Shortcuts Grid
        if (_selectedCategory == null) ...[
          _buildVerticalHubCards(),
          const SizedBox(height: 16),
        ],

        // 1. Movies Stream
        if (_selectedCategory == null || _selectedCategory == PlazaCategoryType.movies) ...[
          _buildSectionTitle('Movies in Theatres', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MoviesScreen()));
          }),
          ...MovieMockData.movies.take(2).map((m) => _buildExploreMovieCard(m)),
          const SizedBox(height: 14),
        ],

        // 2. Dining Stream
        if (_selectedCategory == null || _selectedCategory == PlazaCategoryType.dining) ...[
          _buildSectionTitle('Restaurants & Fine Dining', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DiningScreen()));
          }),
          ...DiningMockData.restaurants.take(2).map((r) => _buildExploreDiningCard(r)),
          const SizedBox(height: 14),
        ],

        // 3. Events Stream
        if (_selectedCategory == null || _selectedCategory == PlazaCategoryType.events) ...[
          _buildSectionTitle('Live Events & Concerts', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
          }),
          ...EventMockData.events.take(2).map((e) => _buildExploreEventCard(e)),
          const SizedBox(height: 14),
        ],

        // 4. Activities Stream
        if (_selectedCategory == null || _selectedCategory == PlazaCategoryType.activities) ...[
          _buildSectionTitle('Thrills & Adventures', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivitiesScreen()));
          }),
          ...ActivityMockData.activities.take(2).map((a) => _buildExploreActivityCard(a)),
          const SizedBox(height: 14),
        ],

        // 5. Shopping Stream
        if (_selectedCategory == null || _selectedCategory == PlazaCategoryType.shopping) ...[
          _buildSectionTitle('Shopping & Boutique Flagships', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingScreen()));
          }),
          ...ShoppingMockData.products.take(2).map((p) => _buildExploreProductCard(p)),
          const SizedBox(height: 14),
        ],

        // 6. Stays Stream
        if (_selectedCategory == null || _selectedCategory == PlazaCategoryType.stays) ...[
          _buildSectionTitle('Luxury Palaces & Resorts', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StaysScreen()));
          }),
          ...StayMockData.hotels.take(2).map((h) => _buildExploreHotelCard(h)),
          const SizedBox(height: 14),
        ],

        // 7. Sports Stream
        if (_selectedCategory == null || _selectedCategory == PlazaCategoryType.sports) ...[
          _buildSectionTitle('Sports Arenas & Turfs', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SportsScreen()));
          }),
          ...SportsMockData.venues.take(2).map((v) => _buildExploreSportsCard(v)),
          const SizedBox(height: 14),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildVerticalHubCards() {
    final hubs = [
      {'title': 'Movies', 'icon': Icons.movie_filter_rounded, 'color': AppColors.accentAmber, 'screen': const MoviesScreen()},
      {'title': 'Dining', 'icon': Icons.restaurant_rounded, 'color': AppColors.primary, 'screen': const DiningScreen()},
      {'title': 'Events', 'icon': Icons.festival_rounded, 'color': AppColors.secondaryViolet, 'screen': const EventsScreen()},
      {'title': 'Activities', 'icon': Icons.sports_esports_rounded, 'color': AppColors.secondaryCyan, 'screen': const ActivitiesScreen()},
      {'title': 'Shopping', 'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFEC4899), 'screen': const ShoppingScreen()},
      {'title': 'Stays', 'icon': Icons.hotel_rounded, 'color': AppColors.accentGold, 'screen': const StaysScreen()},
      {'title': 'Sports', 'icon': Icons.sports_cricket_rounded, 'color': AppColors.liveGreen, 'screen': const SportsScreen()},
    ];

    return SizedBox(
      height: 78,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: hubs.length,
        itemBuilder: (context, index) {
          final hub = hubs[index];
          final color = hub['color'] as Color;
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => hub['screen'] as Widget));
            },
            child: Container(
              width: 104,
              margin: const EdgeInsets.only(right: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(hub['icon'] as IconData, color: color, size: 22),
                    const SizedBox(height: 6),
                    Text(
                      hub['title'] as String,
                      style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.headingSmall),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See All →',
              style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreMovieCard(Movie m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: m))),
        child: GlassCard(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PlazaImage(imageUrl: m.posterUrl, width: 60, height: 60, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title, style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${m.genres.first} • ${m.primaryLanguage.label}', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('₹${m.startingPrice.toInt()} onwards', style: AppTypography.labelSmall.copyWith(color: AppColors.accentAmber)),
                  ],
                ),
              ),
              GlassPill(label: '${m.rating.toStringAsFixed(1)} ★', textColor: AppColors.accentGold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreDiningCard(Restaurant r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailsScreen(restaurant: r))),
        child: GlassCard(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PlazaImage(imageUrl: r.coverImageUrl, width: 60, height: 60, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(r.cuisines.map((c) => c.label).take(2).join(', '), style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('₹${r.priceForTwo.toInt()} for two', style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight)),
                  ],
                ),
              ),
              GlassPill(label: '${r.rating.toStringAsFixed(1)} ★', textColor: AppColors.accentGold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreEventCard(PlazaEvent e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailsScreen(event: e))),
        child: GlassCard(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PlazaImage(imageUrl: e.bannerUrl, width: 60, height: 60, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title, style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${e.venue} • ${e.distance}', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('₹${e.startingPrice.toInt()} onwards', style: AppTypography.labelSmall.copyWith(color: AppColors.accentAmber)),
                  ],
                ),
              ),
              GlassPill(
                label: '${e.eventDate.day}/${e.eventDate.month}',
                textColor: Colors.white,
                backgroundColor: AppColors.secondaryViolet.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreActivityCard(PlazaActivity a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailsScreen(activity: a))),
        child: GlassCard(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PlazaImage(imageUrl: a.coverImageUrl, width: 60, height: 60, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title, style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${a.venueName} • ${a.duration}', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('₹${a.startingPrice.toInt()} / person', style: AppTypography.labelSmall.copyWith(color: AppColors.secondaryCyan)),
                  ],
                ),
              ),
              GlassPill(label: '${a.rating.toStringAsFixed(1)} ★', textColor: AppColors.accentGold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreProductCard(Product p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: p))),
        child: GlassCard(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PlazaImage(imageUrl: p.coverImageUrl, width: 60, height: 60, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${p.brand} • ${p.storeName}', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('₹${p.price.toInt()}', style: AppTypography.labelSmall.copyWith(color: AppColors.accentAmber)),
                  ],
                ),
              ),
              GlassPill(label: '${p.rating.toStringAsFixed(1)} ★', textColor: AppColors.accentGold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreHotelCard(Hotel h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HotelDetailsScreen(hotel: h))),
        child: GlassCard(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PlazaImage(imageUrl: h.coverImageUrl, width: 60, height: 60, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name, style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('${h.location} • ${h.category.label}', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('₹${h.startingPricePerNight.toInt()} / night', style: AppTypography.labelSmall.copyWith(color: AppColors.accentGold)),
                  ],
                ),
              ),
              GlassPill(label: '${h.rating.toStringAsFixed(1)} ★', textColor: AppColors.accentGold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreSportsCard(SportsVenue v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SportsVenueDetailsScreen(venue: v))),
        child: GlassCard(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PlazaImage(imageUrl: v.coverImageUrl, width: 60, height: 60, borderRadius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.name, style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      v.supportedSports.map((s) => s.label.split('&').first.trim()).join(' • '),
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('₹${v.startingPricePerHour.toInt()} / hr', style: AppTypography.labelSmall.copyWith(color: AppColors.liveGreen)),
                  ],
                ),
              ),
              GlassPill(label: '${v.rating.toStringAsFixed(1)} ★', textColor: AppColors.accentGold),
            ],
          ),
        ),
      ),
    );
  }
}
