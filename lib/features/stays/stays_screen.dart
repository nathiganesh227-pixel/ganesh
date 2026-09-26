import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/data/stay_mock_data.dart';
import '../../core/models/stay.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/section_header.dart';
import '../../core/repositories/stay_repository.dart';
import '../../core/repositories/repository_provider.dart';
import 'widgets/stay_card.dart';

class StaysScreen extends StatefulWidget {
  final StayRepository? repository;
  const StaysScreen({super.key, this.repository});

  @override
  State<StaysScreen> createState() => _StaysScreenState();
}

class _StaysScreenState extends State<StaysScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  late final StayRepository _stayRepo;
  List<Hotel> _loadedHotels = StayMockData.hotels;
  StayCategoryType? _selectedCategory;
  String _searchQuery = '';
  bool _favoritesOnly = false;
  bool _trendingOnly = false;

  final List<String> _supportedCities = [
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
    _stayRepo = widget.repository ?? RepositoryProvider.instance.stayRepo;
    _searchController.addListener(_onSearchChanged);
    _fetchHotels();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  Future<void> _fetchHotels() async {
    try {
      final city = PlazaGlobalState.instance.selectedCity;
      final list = await _stayRepo.getHotels(city: city);
      if (mounted && list.isNotEmpty) {
        setState(() {
          _loadedHotels = list;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
      _favoritesOnly = false;
      _trendingOnly = false;
    });
  }

  void _openCitySelector(BuildContext context) {
    final currentCity = PlazaGlobalState.instance.selectedCity;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: const BoxDecoration(
                color: Color(0xF0090D18),
                border: Border(
                  top: BorderSide(color: AppColors.glassBorder, width: 1.5),
                ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Select Stays City', style: AppTypography.headingLarge),
                      const Icon(Icons.location_city_rounded, color: AppColors.accentGold, size: 20),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Browse 5★ luxury palaces, boutique retreats, and private villas',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  ..._supportedCities.map(
                    (city) {
                      final isSelected = city.toLowerCase() == currentCity.toLowerCase();
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          title: Text(
                            city,
                            style: AppTypography.labelLarge.copyWith(
                              color: isSelected ? AppColors.accentGold : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.accentGold, size: 20)
                              : null,
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            PlazaGlobalState.instance.setSelectedCity(city);
                            Navigator.pop(ctx);
                            _fetchHotels();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Viewing luxury stays in $city'),
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

  List<Hotel> _getFilteredHotels(String currentCity) {
    final favIds = PlazaGlobalState.instance.favoriteIds;

    return _loadedHotels.where((h) {
      if (_favoritesOnly && !favIds.contains(h.id)) {
        return false;
      }
      if (_trendingOnly && !h.isFeatured) {
        return false;
      }
      if (_selectedCategory != null && h.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final matchesName = h.name.toLowerCase().contains(_searchQuery);
        final matchesLocation = h.location.toLowerCase().contains(_searchQuery);
        final matchesCategory = h.category.label.toLowerCase().contains(_searchQuery);
        final matchesTagline = h.tagline.toLowerCase().contains(_searchQuery);
        if (!matchesName && !matchesLocation && !matchesCategory && !matchesTagline) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final currentCity = PlazaGlobalState.instance.selectedCity;
        final filtered = _getFilteredHotels(currentCity);
        final featuredHotels = _loadedHotels.where((h) => h.isFeatured).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Atmospheric Glow
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentGold.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Top Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.glassFillMedium,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.glassBorderSubtle),
                                    ),
                                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => _openCitySelector(context),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_rounded, size: 13, color: AppColors.accentGold),
                                          const SizedBox(width: 3),
                                          Text(
                                            currentCity.toUpperCase(),
                                            style: AppTypography.labelSmall.copyWith(
                                              letterSpacing: 1.2,
                                              color: AppColors.accentGold,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.accentGold),
                                        ],
                                      ),
                                      Text('Stays & Luxury Escapes', style: AppTypography.headingMedium),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.hotel_rounded, size: 14, color: AppColors.accentGold),
                                  const SizedBox(width: 4),
                                  Text('5★ & Heritage', style: AppTypography.labelSmall.copyWith(color: AppColors.accentGold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    // Search Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GlassSearchBar(
                          hintText: 'Search Taj Falaknuma, ITC Kohenur, villas...',
                          controller: _searchController,
                          onFilterTap: () => _openCitySelector(context),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    // Category & Quick Filter Chips
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 38,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            // All Stays chip
                            _buildQuickChip(
                              label: 'All Stays',
                              isSelected: _selectedCategory == null && !_favoritesOnly && !_trendingOnly,
                              onTap: _resetFilters,
                            ),
                            // Favorites chip
                            _buildQuickChip(
                              label: 'Favorites ❤️',
                              isSelected: _favoritesOnly,
                              onTap: () => setState(() => _favoritesOnly = !_favoritesOnly),
                            ),
                            // Featured / Signature chip
                            _buildQuickChip(
                              label: 'Featured 👑',
                              isSelected: _trendingOnly,
                              onTap: () => setState(() => _trendingOnly = !_trendingOnly),
                            ),
                            // Categories
                            ...StayCategoryType.values.map(
                              (cat) => _buildQuickChip(
                                label: '${cat.emoji} ${cat.label.split('&').first.trim()}',
                                isSelected: _selectedCategory == cat,
                                onTap: () => setState(() {
                                  _selectedCategory = _selectedCategory == cat ? null : cat;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // Featured Escapes Carousel (only when not searching / filtering by text)
                    if (_searchQuery.isEmpty && !_favoritesOnly && _selectedCategory == null && featuredHotels.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SectionHeader(
                            title: 'Signature Palaces & 5★ Stays 👑',
                            actionText: 'View All',
                            onActionTap: () {},
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 240,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: featuredHotels.length,
                            itemBuilder: (context, index) {
                              return StayCard(
                                hotel: featuredHotels[index],
                                variant: StayCardVariant.compact,
                              );
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],

                    // Section Title: Available Stays
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _favoritesOnly
                                  ? 'Favorite Stays (${filtered.length})'
                                  : _selectedCategory != null
                                      ? '${_selectedCategory!.label} (${filtered.length})'
                                      : 'All Curated Stays in $currentCity (${filtered.length})',
                              style: AppTypography.headingSmall,
                            ),
                            if (_searchQuery.isNotEmpty || _favoritesOnly || _selectedCategory != null)
                              GestureDetector(
                                onTap: _resetFilters,
                                child: Text(
                                  'Clear',
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Empty State or Stays List
                    if (filtered.isEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.glassFillMedium,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.glassBorderSubtle),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.hotel_outlined, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 16),
                              Text('No Stays Found', style: AppTypography.headingSmall),
                              const SizedBox(height: 6),
                              Text(
                                _favoritesOnly
                                    ? 'You have not favorited any luxury stays yet.'
                                    : 'No stays match your search or filter in $currentCity.',
                                style: AppTypography.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: _resetFilters,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentGold,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Reset All Filters',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: StayCard(
                                  hotel: filtered[index],
                                  variant: StayCardVariant.standard,
                                ),
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGold : AppColors.glassFillMedium,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.accentGold : AppColors.glassBorderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
