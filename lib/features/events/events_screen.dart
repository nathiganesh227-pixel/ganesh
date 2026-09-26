import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/data/event_mock_data.dart';
import '../../core/models/event.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/plaza_image.dart';
import '../../core/widgets/section_header.dart';
import '../../core/repositories/event_repository.dart';
import '../../core/repositories/repository_provider.dart';
import 'event_details_screen.dart';
import 'widgets/event_card.dart';

enum EventDateFilter {
  all('All Dates'),
  today('Today'),
  weekend('This Weekend');

  final String label;
  const EventDateFilter(this.label);
}

class EventsScreen extends StatefulWidget {
  final EventRepository? repository;
  const EventsScreen({super.key, this.repository});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final EventRepository _eventRepo;
  List<PlazaEvent> _loadedEvents = EventMockData.events;
  bool _isLoading = false;
  String? _errorMessage;

  EventCategoryType? _selectedCategory;
  EventDateFilter _selectedDateFilter = EventDateFilter.all;
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
    _eventRepo = widget.repository ?? RepositoryProvider.instance.eventRepo;
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final city = PlazaGlobalState.instance.selectedCity;
      final list = await _eventRepo.getEvents(city: city);
      if (mounted && list.isNotEmpty) {
        setState(() {
          _loadedEvents = list;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted && _loadedEvents.isEmpty) {
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
      _selectedCategory = null;
      _selectedDateFilter = EventDateFilter.all;
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
                  Text('Select Events City', style: AppTypography.headingLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Explore live concerts, comedy, and festivals near you',
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
                            _fetchEvents();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Viewing events in $city'),
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

  List<PlazaEvent> get _filteredEvents {
    final favIds = PlazaGlobalState.instance.favoriteIds;

    return _loadedEvents.where((e) {
      if (_showFavoritesOnly && !favIds.contains(e.id)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final matchesTitle = e.title.toLowerCase().contains(q);
        final matchesVenue = e.venue.toLowerCase().contains(q);
        final matchesLoc = e.location.toLowerCase().contains(q);
        final matchesTagline = e.tagline.toLowerCase().contains(q);
        final matchesCat = e.category.label.toLowerCase().contains(q);
        final matchesArtist = e.artists.any((a) => a.name.toLowerCase().contains(q));
        if (!matchesTitle && !matchesVenue && !matchesLoc && !matchesTagline && !matchesCat && !matchesArtist) {
          return false;
        }
      }
      if (_selectedCategory != null && e.category != _selectedCategory) {
        return false;
      }
      if (_selectedDateFilter == EventDateFilter.today && !e.isHappeningToday) {
        return false;
      }
      if (_selectedDateFilter == EventDateFilter.weekend && !e.isThisWeekend) {
        return false;
      }
      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != null ||
      _selectedDateFilter != EventDateFilter.all ||
      _showFavoritesOnly;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final currentCity = PlazaGlobalState.instance.selectedCity;
        final filtered = _filteredEvents;
        final trending = filtered.where((e) => e.isTrending).toList();
        final weekend = filtered.where((e) => e.isThisWeekend).toList();
        final featuredEvent = trending.isNotEmpty ? trending.first : filtered.firstOrNull;
        final isFiltering = _hasActiveFilters;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Ambient Glowing Orb
              Positioned(
                top: -100,
                left: -50,
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0x358B5CF6), // Royal violet glow
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
                                    Text('Events & Shows', style: AppTypography.headingLarge),
                                    Text(
                                      'Live concerts, comedy & festivals',
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
                          hintText: 'Search concerts, standup, festivals in $currentCity...',
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

                    // Horizontal Filters Row (Categories + Dates + Favorites)
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

                            // Date Filters
                            ...EventDateFilter.values.map((df) {
                              if (df == EventDateFilter.all) return const SizedBox.shrink();
                              final isSelected = _selectedDateFilter == df;
                              return _buildFilterToggle(
                                label: df.label,
                                icon: Icons.calendar_today_outlined,
                                isActive: isSelected,
                                activeColor: AppColors.secondaryViolet,
                                onTap: () {
                                  setState(() {
                                    _selectedDateFilter = isSelected ? EventDateFilter.all : df;
                                  });
                                },
                              );
                            }),

                            // Category Chips
                            ...EventCategoryType.values.map((c) {
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
                                        ? AppColors.secondaryViolet.withValues(alpha: 0.3)
                                        : AppColors.glassFillMedium,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: isSelected ? AppColors.secondaryViolet : AppColors.glassBorderSubtle,
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
                                '${filtered.length} ${filtered.length == 1 ? 'event' : 'events'} found',
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
                            child: CircularProgressIndicator(color: AppColors.secondaryViolet),
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
                                Text('Unable to load live events', style: AppTypography.headingMedium),
                                const SizedBox(height: 6),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _fetchEvents,
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
                                const Icon(Icons.confirmation_number_outlined, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text('No events found', style: AppTypography.headingMedium),
                                const SizedBox(height: 6),
                                Text(
                                  'Try adjusting your category or date filters',
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
                      if (!isFiltering && featuredEvent != null) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildFeaturedSpotlight(featuredEvent),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],

                      // Trending Concerts & Shows
                      if (trending.isNotEmpty && !isFiltering) ...[
                        const SliverToBoxAdapter(
                          child: SectionHeader(
                            title: 'Trending Live Experiences',
                            subtitle: 'Hottest upcoming gigs and arena tours',
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 320,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: trending.length,
                              itemBuilder: (context, index) {
                                final e = trending[index];
                                return Container(
                                  width: 270,
                                  margin: const EdgeInsets.only(right: 16),
                                  child: EventCard(
                                    event: e,
                                    variant: EventCardVariant.standard,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],

                      // This Weekend
                      if (weekend.isNotEmpty && !isFiltering) ...[
                        const SliverToBoxAdapter(
                          child: SectionHeader(
                            title: 'This Weekend in Town',
                            subtitle: 'Unmissable comedy, nightlife & experiences',
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 210,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: weekend.length,
                              itemBuilder: (context, index) {
                                final e = weekend[index];
                                return Container(
                                  width: 220,
                                  margin: const EdgeInsets.only(right: 14),
                                  child: EventCard(
                                    event: e,
                                    variant: EventCardVariant.compact,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],

                      // All Upcoming Events / Filtered List
                      SliverToBoxAdapter(
                        child: SectionHeader(
                          title: isFiltering ? 'Matching Events' : 'All Upcoming Events',
                          subtitle: '${filtered.length} verified performances in $currentCity',
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        ),
                      ),

                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final e = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              child: EventCard(
                                event: e,
                                variant: EventCardVariant.horizontal,
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
    final color = activeColor ?? AppColors.secondaryViolet;

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

  Widget _buildFeaturedSpotlight(PlazaEvent e) {
    final dateStr = DateFormat('EEE, d MMM').format(e.eventDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: e),
          ),
        );
      },
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            PlazaImage(
              imageUrl: e.bannerUrl,
              height: 220,
              width: double.infinity,
              borderRadius: 24,
            ),
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x99000000),
                    Color(0xF0070A11),
                  ],
                  stops: [0.2, 0.65, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppGradients.royalViolet,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'FEATURED SHOW',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            if (e.rating > 0)
              Positioned(
                top: 14,
                right: 14,
                child: GlassPill(
                  label: '${e.rating.toStringAsFixed(1)} ★',
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
                    e.title,
                    style: AppTypography.headingLarge.copyWith(fontSize: 20),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateStr • ${e.venue}, ${e.location.split(',').first}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.startingPrice > 0
                            ? '₹${e.startingPrice.toInt()} onwards'
                            : 'Free Entry',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.accentAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryViolet.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.secondaryViolet),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Get Tickets',
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
