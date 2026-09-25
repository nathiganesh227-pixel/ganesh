import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/data/dining_mock_data.dart';
import '../../core/models/dining.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/plaza_image.dart';
import '../../core/widgets/section_header.dart';
import '../../core/repositories/dining_repository.dart';
import '../../core/repositories/repository_provider.dart';
import 'restaurant_details_screen.dart';
import 'widgets/restaurant_card.dart';

class DiningScreen extends StatefulWidget {
  final DiningRepository? repository;
  const DiningScreen({super.key, this.repository});

  @override
  State<DiningScreen> createState() => _DiningScreenState();
}

class _DiningScreenState extends State<DiningScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final DiningRepository _diningRepo;
  List<Restaurant> _loadedRestaurants = DiningMockData.restaurants;
  bool _isLoading = false;
  String? _errorMessage;

  CuisineType? _selectedCuisine;
  bool _filterVegOnly = false;
  bool _filterOutdoorOnly = false;
  bool _filterFineDiningOnly = false;
  bool _showFavoritesOnly = false;
  String _searchQuery = '';

  static const List<String> _availableCities = [
    'Hyderabad',
    'Bengaluru',
    'Mumbai',
    'Delhi NCR',
    'Chennai',
    'Pune',
  ];

  @override
  void initState() {
    super.initState();
    _diningRepo = widget.repository ?? RepositoryProvider.instance.diningRepo;
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    try {
      final city = PlazaGlobalState.instance.selectedCity;
      final list = await _diningRepo.getRestaurants(city: city);
      if (mounted && list.isNotEmpty) {
        setState(() {
          _loadedRestaurants = list;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted && _loadedRestaurants.isEmpty) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCuisine = null;
      _filterVegOnly = false;
      _filterOutdoorOnly = false;
      _filterFineDiningOnly = false;
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
                  Text('Select Dining City', style: AppTypography.headingLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Explore top restaurants, cafes, and rooftop dining',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  ..._availableCities.map(
                    (city) {
                      final isSelected = city == currentCity;
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
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
                            _fetchRestaurants();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Exploring dining in $city'),
                                backgroundColor: AppColors.surfaceElevated,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
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

  List<Restaurant> get _filteredRestaurants {
    final favIds = PlazaGlobalState.instance.favoriteIds;

    return _loadedRestaurants.where((r) {
      if (_showFavoritesOnly && !favIds.contains(r.id)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchesName = r.name.toLowerCase().contains(q);
        final matchesLoc = r.location.toLowerCase().contains(q);
        final matchesTagline = r.tagline.toLowerCase().contains(q);
        final matchesAbout = r.about.toLowerCase().contains(q);
        final matchesCuisine = r.cuisines.any((c) => c.label.toLowerCase().contains(q));
        final matchesDish = r.popularDishes.any((d) =>
            d.name.toLowerCase().contains(q) || d.description.toLowerCase().contains(q));
        if (!matchesName && !matchesLoc && !matchesTagline && !matchesAbout && !matchesCuisine && !matchesDish) {
          return false;
        }
      }
      if (_selectedCuisine != null && !r.cuisines.contains(_selectedCuisine)) {
        return false;
      }
      if (_filterVegOnly && !r.isPureVeg) {
        return false;
      }
      if (_filterOutdoorOnly && !r.hasOutdoor) {
        return false;
      }
      if (_filterFineDiningOnly && !r.isFineDining) {
        return false;
      }
      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCuisine != null ||
      _filterVegOnly ||
      _filterOutdoorOnly ||
      _filterFineDiningOnly ||
      _showFavoritesOnly;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final currentCity = PlazaGlobalState.instance.selectedCity;
        final filtered = _filteredRestaurants;
        final trending = filtered.where((r) => r.isTrending).toList();
        final fineDining = filtered.where((r) => r.isFineDining).toList();
        final isFiltering = _hasActiveFilters;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Ambient Radial Glow
              Positioned(
                top: -80,
                right: -40,
                child: Container(
                  width: 340,
                  height: 340,
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
                    // Top App Bar
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Dining & Cafes', style: AppTypography.headingLarge),
                                    Text(
                                      'Reserve gourmet tables & cafes',
                                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
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
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 10)),

                    // Search Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GlassSearchBar(
                          hintText: 'Search restaurants, dishes, cuisines in $currentCity...',
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Horizontal Filters (Cuisines + Quick Toggles)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 38,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // Favorites Toggle
                            _buildFilterToggle(
                              label: 'Favorites',
                              icon: _showFavoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              isActive: _showFavoritesOnly,
                              activeColor: AppColors.alertRed,
                              onTap: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                            ),
                            // Pure Veg Toggle
                            _buildFilterToggle(
                              label: 'Pure Veg',
                              icon: Icons.eco_outlined,
                              isActive: _filterVegOnly,
                              activeColor: AppColors.liveGreen,
                              onTap: () => setState(() => _filterVegOnly = !_filterVegOnly),
                            ),
                            // Outdoor Toggle
                            _buildFilterToggle(
                              label: 'Rooftop / Outdoor',
                              icon: Icons.deck_outlined,
                              isActive: _filterOutdoorOnly,
                              onTap: () => setState(() => _filterOutdoorOnly = !_filterOutdoorOnly),
                            ),
                            // Fine Dining Toggle
                            _buildFilterToggle(
                              label: 'Fine Dining',
                              icon: Icons.wine_bar_rounded,
                              isActive: _filterFineDiningOnly,
                              onTap: () => setState(() => _filterFineDiningOnly = !_filterFineDiningOnly),
                            ),
                            // Cuisine Pills
                            ...CuisineType.values.map((c) {
                              final isSelected = _selectedCuisine == c;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCuisine = isSelected ? null : c;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                                      c.label,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isSelected ? Colors.white : AppColors.textSecondary,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    // Active Filter Reset Bar
                    if (isFiltering)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filtered.length} ${filtered.length == 1 ? 'place' : 'places'} found',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight),
                              ),
                              GestureDetector(
                                onTap: _clearFilters,
                                child: Text(
                                  'Clear all filters',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.accentGold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    // Loading State
                    if (_isLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        ),
                      )
                    // Error State
                    else if (_errorMessage != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text('Unable to load dining venues', style: AppTypography.headingMedium),
                                const SizedBox(height: 6),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _fetchRestaurants,
                                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryLight),
                                  label: Text(
                                    'Try Again',
                                    style: AppTypography.labelLarge.copyWith(color: AppColors.primaryLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    // Empty Results State
                    else if (filtered.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text('No restaurants match your search', style: AppTypography.headingMedium),
                                const SizedBox(height: 6),
                                Text(
                                  'Try adjusting your cuisine or dietary filters',
                                  style: AppTypography.bodySmall,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.glassFillMedium,
                                    foregroundColor: AppColors.textPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: AppColors.glassBorderSubtle),
                                    ),
                                  ),
                                  onPressed: _clearFilters,
                                  child: const Text('Reset All Filters'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else ...[
                      // Featured Spotlight Hero Card (when not searching)
                      if (!isFiltering && trending.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildSpotlightCard(trending.first),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],

                      // Trending Gourmet Tables Section
                      if (trending.isNotEmpty && !isFiltering) ...[
                        SliverToBoxAdapter(
                          child: SectionHeader(
                            title: 'Trending Gourmet Tables',
                            subtitle: 'Top rated in $currentCity',
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 295,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: trending.length,
                              itemBuilder: (context, index) {
                                final r = trending[index];
                                return Container(
                                  width: 280,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: RestaurantCard(
                                    restaurant: r,
                                    variant: RestaurantCardVariant.standard,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],

                      // Fine Dining & Chef Experiences Section
                      if (fineDining.isNotEmpty && !isFiltering) ...[
                        SliverToBoxAdapter(
                          child: SectionHeader(
                            title: 'Fine Dining & Chef Experiences',
                            subtitle: 'Curated luxury tables for special evenings',
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 180,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: fineDining.length,
                              itemBuilder: (context, index) {
                                final r = fineDining[index];
                                return Container(
                                  width: 220,
                                  margin: const EdgeInsets.only(right: 14),
                                  child: RestaurantCard(
                                    restaurant: r,
                                    variant: RestaurantCardVariant.compact,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],

                      // All Restaurants Near You / Filtered List
                      SliverToBoxAdapter(
                        child: SectionHeader(
                          title: isFiltering ? 'Matching Restaurants' : 'All Restaurants Near You',
                          subtitle: '${filtered.length} verified culinary destinations',
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        ),
                      ),

                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final r = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              child: RestaurantCard(
                                restaurant: r,
                                variant: RestaurantCardVariant.horizontal,
                              ),
                            );
                          },
                          childCount: filtered.length,
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
      },
    );
  }

  Widget _buildFilterToggle({
    required String label,
    required IconData icon,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = activeColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.25) : AppColors.glassFillMedium,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? color : AppColors.glassBorderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotlightCard(Restaurant r) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsScreen(restaurant: r),
          ),
        );
      },
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            PlazaImage(
              imageUrl: r.coverImageUrl,
              height: 210,
              width: double.infinity,
              borderRadius: 24,
            ),
            Container(
              height: 210,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x99000000),
                    Color(0xE6070A11),
                  ],
                  stops: [0.3, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppGradients.sunsetPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CHEF’S SPOTLIGHT',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: GlassPill(
                label: '${r.rating.toStringAsFixed(1)} ★',
                textColor: AppColors.accentGold,
                backgroundColor: const Color(0xB3000000),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: AppTypography.headingLarge.copyWith(fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${r.tagline} • ${r.location.split(',').first}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryLight,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${r.priceForTwo.toInt()} for two',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.accentAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryLight),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Explore Menu & Tables',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                          ],
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
    );
  }
}
