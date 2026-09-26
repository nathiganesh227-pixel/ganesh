import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/data/sports_mock_data.dart';
import '../../core/models/sports.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/glass_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/repositories/sports_repository.dart';
import '../../core/repositories/repository_provider.dart';
import 'widgets/sports_venue_card.dart';

class SportsScreen extends StatefulWidget {
  final SportsRepository? repository;
  const SportsScreen({super.key, this.repository});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  late final SportsRepository _sportsRepo;
  List<SportsVenue> _loadedVenues = SportsMockData.venues;
  SportType? _selectedSport;
  String _searchQuery = '';
  bool _favoritesOnly = false;
  bool _availableTodayOnly = false;

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
    _sportsRepo = widget.repository ?? RepositoryProvider.instance.sportsRepo;
    _searchController.addListener(_onSearchChanged);
    _fetchVenues();
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

  Future<void> _fetchVenues() async {
    try {
      final city = PlazaGlobalState.instance.selectedCity;
      final list = await _sportsRepo.getVenues(
        city: city,
        sport: _selectedSport?.label,
        q: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (mounted && list.isNotEmpty) {
        setState(() {
          _loadedVenues = list;
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
      _selectedSport = null;
      _favoritesOnly = false;
      _availableTodayOnly = false;
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
                      Text('Select Sports City', style: AppTypography.headingLarge),
                      const Icon(Icons.sports_cricket_rounded, color: AppColors.liveGreen, size: 22),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Book FIFA turfs, badminton arenas, and cricket nets near you',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  ..._supportedCities.map(
                    (city) {
                      final isSelected = city.toLowerCase() == currentCity.toLowerCase();
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          tileColor: isSelected ? AppColors.glassFillMedium : Colors.transparent,
                          leading: Icon(
                            Icons.location_on_rounded,
                            color: isSelected ? AppColors.liveGreen : AppColors.textMuted,
                            size: 20,
                          ),
                          title: Text(
                            city,
                            style: AppTypography.labelLarge.copyWith(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.liveGreen, size: 20)
                              : null,
                          onTap: () {
                            PlazaGlobalState.instance.setSelectedCity(city);
                            Navigator.pop(ctx);
                            _fetchVenues();
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

  List<SportsVenue> get _filteredVenues {
    final favIds = PlazaGlobalState.instance.favoriteIds;
    return _loadedVenues.where((v) {
      if (_selectedSport != null && !v.supportedSports.contains(_selectedSport)) {
        return false;
      }
      if (_favoritesOnly && !favIds.contains(v.id)) {
        return false;
      }
      if (_availableTodayOnly && !v.isLiveNow) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final matchesName = v.name.toLowerCase().contains(_searchQuery);
        final matchesLocation = v.location.toLowerCase().contains(_searchQuery);
        final matchesAddress = v.address.toLowerCase().contains(_searchQuery);
        final matchesSports = v.supportedSports.any((s) => s.label.toLowerCase().contains(_searchQuery));
        final matchesDesc = v.description.toLowerCase().contains(_searchQuery);
        return matchesName || matchesLocation || matchesAddress || matchesSports || matchesDesc;
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
        final liveVenues = _loadedVenues.where((v) => v.isLiveNow).toList();
        final venues = _filteredVenues;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Background Atmospheric Ambient Glow
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
                        AppColors.liveGreen.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: RefreshIndicator(
                  color: AppColors.liveGreen,
                  backgroundColor: AppColors.surfaceElevated,
                  onRefresh: _fetchVenues,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      // Header Row
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
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _openCitySelector(context),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on_rounded, size: 13, color: AppColors.liveGreen),
                                            const SizedBox(width: 3),
                                            Text(
                                              currentCity.toUpperCase(),
                                              style: AppTypography.labelSmall.copyWith(
                                                letterSpacing: 1.2,
                                                color: AppColors.liveGreen,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.liveGreen),
                                          ],
                                        ),
                                      ),
                                      Text('Sports & Turfs', style: AppTypography.headingMedium),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.liveGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.liveGreen.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppColors.liveGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${liveVenues.length} Turfs Live',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.liveGreen,
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

                      // Search Bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: GlassSearchBar(
                            controller: _searchController,
                            hintText: 'Search turfs, football pitches, cricket nets...',
                          ),
                        ),
                      ),

                      // Quick Filter Chips (All, Favorites, Available Today, Sport types)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 48,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            children: [
                              // All Sports chip
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedSport = null;
                                    _favoritesOnly = false;
                                    _availableTodayOnly = false;
                                  }),
                                  child: GlassPill(
                                    label: 'All Sports',
                                    backgroundColor: (_selectedSport == null && !_favoritesOnly && !_availableTodayOnly)
                                        ? AppColors.primary.withValues(alpha: 0.25)
                                        : AppColors.glassFillMedium,
                                    borderColor: (_selectedSport == null && !_favoritesOnly && !_availableTodayOnly)
                                        ? AppColors.primary
                                        : AppColors.glassBorderSubtle,
                                    textColor: (_selectedSport == null && !_favoritesOnly && !_availableTodayOnly)
                                        ? AppColors.primaryLight
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),

                              // Favorites chip
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _favoritesOnly = !_favoritesOnly;
                                  }),
                                  child: GlassPill(
                                    label: 'Favorites ❤️',
                                    backgroundColor: _favoritesOnly
                                        ? AppColors.alertRed.withValues(alpha: 0.25)
                                        : AppColors.glassFillMedium,
                                    borderColor: _favoritesOnly
                                        ? AppColors.alertRed
                                        : AppColors.glassBorderSubtle,
                                    textColor: _favoritesOnly
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),

                              // Available Right Now chip
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _availableTodayOnly = !_availableTodayOnly;
                                  }),
                                  child: GlassPill(
                                    label: 'Available Right Now ⚡',
                                    backgroundColor: _availableTodayOnly
                                        ? AppColors.liveGreen.withValues(alpha: 0.25)
                                        : AppColors.glassFillMedium,
                                    borderColor: _availableTodayOnly
                                        ? AppColors.liveGreen
                                        : AppColors.glassBorderSubtle,
                                    textColor: _availableTodayOnly
                                        ? AppColors.liveGreen
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),

                              // Sport categories
                              ...SportType.values.map((sport) {
                                final isSelected = _selectedSport == sport;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedSport = isSelected ? null : sport;
                                    }),
                                    child: GlassPill(
                                      label: '${sport.emoji} ${sport.label}',
                                      backgroundColor: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.25)
                                          : AppColors.glassFillMedium,
                                      borderColor: isSelected
                                          ? AppColors.primary
                                          : AppColors.glassBorderSubtle,
                                      textColor: isSelected
                                          ? AppColors.primaryLight
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                      // Live & Trending Turfs Horizontal Carousel
                      if (_searchQuery.isEmpty && _selectedSport == null && !_favoritesOnly && liveVenues.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: SectionHeader(
                              title: 'Live & Trending Arenas 🔥',
                              actionText: '${liveVenues.length} Open',
                              onActionTap: () {},
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 230,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: liveVenues.length,
                              itemBuilder: (context, index) {
                                return SportsVenueCard(
                                  venue: liveVenues[index],
                                  variant: SportsVenueCardVariant.horizontal,
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      // Section Header for All Curated Venues
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: SectionHeader(
                            title: 'All Curated Venues in $currentCity',
                            actionText: '${venues.length} Venues',
                            onActionTap: () {},
                          ),
                        ),
                      ),

                      // Venues List or Empty State
                      if (venues.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                            child: GlassCard(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sports_soccer_rounded, size: 54, color: AppColors.textMuted),
                                  const SizedBox(height: 14),
                                  Text(
                                    _favoritesOnly
                                        ? 'No Favorite Venues Saved'
                                        : 'No Sports Venues Found',
                                    style: AppTypography.headingSmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _favoritesOnly
                                        ? 'Tap the heart icon on any sports arena or turf to save it to your favorites.'
                                        : 'Try adjusting your search query, city, or sports filter.',
                                    style: AppTypography.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  GlassButton(
                                    text: 'Reset Filters',
                                    variant: GlassButtonVariant.secondary,
                                    onPressed: _resetFilters,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: SportsVenueCard(
                                    venue: venues[index],
                                    variant: SportsVenueCardVariant.standard,
                                  ),
                                );
                              },
                              childCount: venues.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
