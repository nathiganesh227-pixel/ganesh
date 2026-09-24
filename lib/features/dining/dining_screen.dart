import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/mock_data.dart';
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
  CuisineType? _selectedCuisine;
  bool _filterVegOnly = false;
  bool _filterOutdoorOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _diningRepo = widget.repository ?? RepositoryProvider.instance.diningRepo;
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    try {
      final list = await _diningRepo.getRestaurants();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _loadedRestaurants = list;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Restaurant> get _filteredRestaurants {
    return _loadedRestaurants.where((r) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = r.name.toLowerCase().contains(q);
        final matchesLoc = r.location.toLowerCase().contains(q);
        final matchesCuisine = r.cuisines.any((c) => c.label.toLowerCase().contains(q));
        final matchesDish = r.popularDishes.any((d) => d.name.toLowerCase().contains(q));
        if (!matchesName && !matchesLoc && !matchesCuisine && !matchesDish) return false;
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
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final trending = _filteredRestaurants.where((r) => r.isTrending).toList();
    final fineDining = _filteredRestaurants.where((r) => r.isFineDining).toList();
    final allList = _filteredRestaurants;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient Radial Glow
          Positioned(
            top: -80,
            right: -40,
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
                            Text('Dining & Cafes', style: AppTypography.headingLarge),
                          ],
                        ),
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
                      hintText: 'Search restaurants, cuisines, dishes...',
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

                // Horizontal Filters (Cuisines + Quick Toggles)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Veg Toggle
                        _buildFilterToggle(
                          label: 'Pure Veg',
                          icon: Icons.eco_outlined,
                          isActive: _filterVegOnly,
                          onTap: () => setState(() => _filterVegOnly = !_filterVegOnly),
                        ),
                        // Outdoor Toggle
                        _buildFilterToggle(
                          label: 'Rooftop / Outdoor',
                          icon: Icons.deck_outlined,
                          isActive: _filterOutdoorOnly,
                          onTap: () => setState(() => _filterOutdoorOnly = !_filterOutdoorOnly),
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
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Empty state
                if (_filteredRestaurants.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No restaurants found matching your criteria.\nTry clearing filters.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ),
                  ),

                // Trending Section
                if (trending.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Trending Gourmet Tables',
                      subtitle: 'Top rated in Jubilee Hills & Gachibowli',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 330,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: trending.length,
                        itemBuilder: (context, index) {
                          final r = trending[index];
                          return _buildTrendingRestaurantCard(r);
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                ],

                // Fine Dining Section
                if (fineDining.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Fine Dining & Chef Experiences',
                      subtitle: 'Curated luxury tables for special evenings',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 270,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: fineDining.length,
                        itemBuilder: (context, index) {
                          final r = fineDining[index];
                          return _buildFineDiningCard(r);
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                ],

                // Near You & All Restaurants
                if (allList.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'All Restaurants Near You',
                      subtitle: '${allList.length} verified culinary destinations',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final r = allList[index];
                        return _buildRestaurantListTile(r);
                      },
                      childCount: allList.length,
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

  Widget _buildFilterToggle({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.25) : AppColors.glassFillMedium,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.glassBorderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
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

  Widget _buildTrendingRestaurantCard(Restaurant r) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsScreen(restaurant: r),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Photo with Offer Badge
              Stack(
                children: [
                  PlazaImage(
                    imageUrl: r.coverImageUrl,
                    height: 160,
                    width: double.infinity,
                    borderRadius: 20,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GlassPill(
                      label: '${r.rating.toStringAsFixed(1)} ★',
                      textColor: AppColors.accentGold,
                      backgroundColor: const Color(0x95000000),
                    ),
                  ),
                  if (r.offerBadge != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppGradients.sunsetPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r.offerBadge!,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: AppTypography.headingSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.cuisines.map((c) => c.label).join(', ')} • ₹${r.priceForTwo.toInt()} for two',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  r.location.split(',').first,
                                  style: AppTypography.bodySmall.copyWith(fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'Book Table',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w700,
                            ),
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
      ),
    );
  }

  Widget _buildFineDiningCard(Restaurant r) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsScreen(restaurant: r),
          ),
        );
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 14),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlazaImage(
                imageUrl: r.coverImageUrl,
                height: 130,
                width: double.infinity,
                borderRadius: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: AppTypography.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.tagline,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${r.priceForTwo.toInt()} for two',
                      style: AppTypography.labelSmall.copyWith(
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
  }

  Widget _buildRestaurantListTile(Restaurant r) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsScreen(restaurant: r),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PlazaImage(
                imageUrl: r.coverImageUrl,
                width: 90,
                height: 90,
                borderRadius: 16,
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
                            r.name,
                            style: AppTypography.headingSmall.copyWith(fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GlassPill(
                          label: '${r.rating.toStringAsFixed(1)} ★',
                          textColor: AppColors.accentGold,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      r.cuisines.map((c) => c.label).join(', '),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.location.split(',').first} • ${r.distance}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${r.priceForTwo.toInt()} for two',
                      style: AppTypography.labelSmall.copyWith(
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
  }
}
