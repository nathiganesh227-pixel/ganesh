import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/activity_mock_data.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/activity.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/plaza_image.dart';
import '../../core/widgets/section_header.dart';
import '../../core/repositories/activity_repository.dart';
import '../../core/repositories/repository_provider.dart';
import 'activity_details_screen.dart';
import 'widgets/activity_card.dart';

class ActivitiesScreen extends StatefulWidget {
  final ActivityRepository? repository;
  const ActivitiesScreen({super.key, this.repository});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final ActivityRepository _activityRepo;
  List<PlazaActivity> _loadedActivities = ActivityMockData.activities;
  ActivityCategoryType? _selectedCategory;
  String _searchQuery = '';
  Timer? _debounceTimer;
  bool _isLoading = false;
  bool _showFavoritesOnly = false;
  bool _availableNowOnly = false;
  bool _groupPicksOnly = false;

  @override
  void initState() {
    super.initState();
    _activityRepo = widget.repository ?? RepositoryProvider.instance.activityRepo;
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoading = true);
    try {
      final city = PlazaGlobalState.instance.selectedCity;
      final list = await _activityRepo.getActivities(city: city);
      if (mounted && list.isNotEmpty) {
        setState(() {
          _loadedActivities = list;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim();
        });
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
      _showFavoritesOnly = false;
      _availableNowOnly = false;
      _groupPicksOnly = false;
    });
  }

  void _openCitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        const supportedCities = [
          'Hyderabad',
          'Bengaluru',
          'Mumbai',
          'Delhi NCR',
          'Chennai',
          'Pune',
        ];

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
                      Text('Select Activities City', style: AppTypography.headingMedium),
                      const Icon(Icons.location_city_rounded, color: AppColors.primary, size: 20),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Experience centers and sports turf curated for your metro area',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 18),
                  ...supportedCities.map((city) {
                    final isSelected = PlazaGlobalState.instance.selectedCity == city;
                    return GestureDetector(
                      onTap: () {
                        PlazaGlobalState.instance.setSelectedCity(city);
                        Navigator.pop(ctx);
                        _fetchActivities();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.glassFillMedium,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.glassBorderSubtle,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 18,
                                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  city,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<PlazaActivity> _getFilteredActivities(String currentCity) {
    final favIds = PlazaGlobalState.instance.favoriteIds;

    return _loadedActivities.where((a) {
      if (_showFavoritesOnly && !favIds.contains(a.id)) {
        return false;
      }
      if (_availableNowOnly && !a.isAvailableNow) {
        return false;
      }
      if (_groupPicksOnly && !a.isGroupPick) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = a.title.toLowerCase().contains(q);
        final matchesVenue = a.venueName.toLowerCase().contains(q);
        final matchesLoc = a.location.toLowerCase().contains(q);
        final matchesAbout = a.about.toLowerCase().contains(q);
        final matchesCat = a.category.label.toLowerCase().contains(q);
        if (!matchesTitle && !matchesVenue && !matchesLoc && !matchesAbout && !matchesCat) {
          return false;
        }
      }
      if (_selectedCategory != null && a.category != _selectedCategory) {
        return false;
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
        final filtered = _getFilteredActivities(currentCity);
        final isFiltering = _searchQuery.isNotEmpty ||
            _selectedCategory != null ||
            _showFavoritesOnly ||
            _availableNowOnly ||
            _groupPicksOnly;

        final availableNow = filtered.where((a) => a.isAvailableNow).toList();
        final groupPicks = filtered.where((a) => a.isGroupPick).toList();
        final featured = _loadedActivities.where((a) => a.isTrending || a.isGroupPick).toList();
        final topHero = featured.isNotEmpty ? featured.first : (_loadedActivities.isNotEmpty ? _loadedActivities.first : null);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Ambient Cyan Glow
              Positioned(
                top: -90,
                right: -50,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0x3006B6D4), // Cyan neon glow
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
                                    Text('Activities & Fun', style: AppTypography.headingLarge),
                                    Text(
                                      'Arcades, turf, karting & experiences',
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
                          hintText: 'Search bowling, karting, turf in $currentCity...',
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Quick Filter Pills Row
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            // Favorites Toggle
                            _buildFilterToggle(
                              label: 'Favorites',
                              icon: _showFavoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              isActive: _showFavoritesOnly,
                              activeColor: AppColors.alertRed,
                              onTap: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                            ),

                            // Available Now Toggle
                            _buildFilterToggle(
                              label: 'Available Now',
                              icon: Icons.bolt_rounded,
                              isActive: _availableNowOnly,
                              activeColor: const Color(0xFF06B6D4),
                              onTap: () => setState(() => _availableNowOnly = !_availableNowOnly),
                            ),

                            // Group Picks Toggle
                            _buildFilterToggle(
                              label: 'Squad Picks',
                              icon: Icons.groups_rounded,
                              isActive: _groupPicksOnly,
                              activeColor: AppColors.secondaryViolet,
                              onTap: () => setState(() => _groupPicksOnly = !_groupPicksOnly),
                            ),

                            // Category Chips
                            ...ActivityCategoryType.values.map((c) {
                              final isSelected = _selectedCategory == c;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = isSelected ? null : c;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0x3506B6D4)
                                        : AppColors.glassFillMedium,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF06B6D4) : AppColors.glassBorderSubtle,
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
                                '${filtered.length} ${filtered.length == 1 ? 'activity' : 'activities'} found',
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
                            child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
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
                                const Icon(Icons.sports_esports_outlined, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text('No activities found', style: AppTypography.headingMedium),
                                const SizedBox(height: 6),
                                Text(
                                  'Try adjusting your search query or category filters',
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
                      // Featured Spotlight Hero
                      if (!isFiltering && topHero != null) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.whatshot_rounded, color: AppColors.accentGold, size: 16),
                                    const SizedBox(width: 6),
                                    Text('FEATURED ARENA', style: AppTypography.labelSmall.copyWith(color: AppColors.accentGold, letterSpacing: 1.0)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _buildSpotlightHeroCard(context, topHero),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],

                      // "Live & Available Right Now" Section (Preserved for existing test compatibility)
                      if (!isFiltering && availableNow.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: SectionHeader(
                            title: 'Live & Available Right Now',
                            subtitle: 'Instant slot booking with zero waiting queue',
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 285,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: availableNow.length,
                              itemBuilder: (context, index) {
                                final a = availableNow[index];
                                return Container(
                                  width: 280,
                                  margin: const EdgeInsets.only(right: 14),
                                  child: ActivityCard(
                                    activity: a,
                                    variant: ActivityCardVariant.standard,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],

                      // "Trending Squad Picks" Section
                      if (!isFiltering && groupPicks.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: SectionHeader(
                            title: 'Trending Squad Picks',
                            subtitle: 'Popular team activities and multiplayer challenges',
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 210,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: groupPicks.length,
                              itemBuilder: (context, index) {
                                final a = groupPicks[index];
                                return Container(
                                  width: 220,
                                  margin: const EdgeInsets.only(right: 14),
                                  child: ActivityCard(
                                    activity: a,
                                    variant: ActivityCardVariant.compact,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],

                      // All Activities / Search Results List
                      SliverToBoxAdapter(
                        child: SectionHeader(
                          title: isFiltering ? 'Matching Activities' : 'All Activities Near You',
                          subtitle: '${filtered.length} verified experiences in $currentCity',
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final a = filtered[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ActivityCard(
                                  activity: a,
                                  variant: ActivityCardVariant.standard,
                                ),
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.2) : AppColors.glassFillMedium,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? activeColor : AppColors.glassBorderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? activeColor : AppColors.textSecondary),
            const SizedBox(width: 5),
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

  Widget _buildSpotlightHeroCard(BuildContext context, PlazaActivity a) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailsScreen(activity: a),
          ),
        );
      },
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderColor: const Color(0x6006B6D4),
        child: Stack(
          children: [
            PlazaImage(
              imageUrl: a.coverImageUrl,
              height: 200,
              width: double.infinity,
              borderRadius: 16,
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xD0090D18),
                    Color(0xF0090D18),
                  ],
                  stops: [0.3, 0.75, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: GlassPill(
                label: 'POPULAR EXPERIENCE',
                backgroundColor: const Color(0xCC06B6D4),
                textColor: Colors.white,
              ),
            ),
            Positioned(
              bottom: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          a.title,
                          style: AppTypography.headingMedium.copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${a.venueName} • ${a.duration}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.primaryLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GlassButton(
                    text: 'Explore',
                    icon: Icons.arrow_forward_rounded,
                    variant: GlassButtonVariant.primary,
                    height: 38,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivityDetailsScreen(activity: a),
                        ),
                      );
                    },
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
