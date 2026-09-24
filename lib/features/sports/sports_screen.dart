import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/sports_mock_data.dart';
import '../../core/models/sports.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/plaza_image.dart';
import '../../core/widgets/section_header.dart';
import '../../core/repositories/sports_repository.dart';
import '../../core/repositories/repository_provider.dart';
import 'sports_venue_details_screen.dart';

class SportsScreen extends StatefulWidget {
  final SportsRepository? repository;
  const SportsScreen({super.key, this.repository});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final SportsRepository _sportsRepo;
  List<SportsVenue> _loadedVenues = SportsMockData.venues;
  SportType? _selectedSport;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _sportsRepo = widget.repository ?? RepositoryProvider.instance.sportsRepo;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _fetchVenues();
  }

  Future<void> _fetchVenues() async {
    try {
      final list = await _sportsRepo.getVenues();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _loadedVenues = list;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SportsVenue> get _filteredVenues {
    return _loadedVenues.where((v) {
      if (_selectedSport != null && !v.supportedSports.contains(_selectedSport)) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final matchesName = v.name.toLowerCase().contains(_searchQuery);
        final matchesLocation = v.location.toLowerCase().contains(_searchQuery);
        final matchesSports = v.supportedSports.any((s) => s.label.toLowerCase().contains(_searchQuery));
        return matchesName || matchesLocation || matchesSports;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final liveVenues = _loadedVenues.where((v) => v.isLiveNow).toList();

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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
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
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 13, color: AppColors.primary),
                                    const SizedBox(width: 3),
                                    Text('HYDERABAD TURFS', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2)),
                                  ],
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
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: AppColors.liveGreen, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text('Live Slots', style: AppTypography.labelSmall.copyWith(color: AppColors.liveGreen)),
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
                      hintText: 'Search box cricket, badminton, turfs...',
                      controller: _searchController,
                      onFilterTap: () {},
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Sports Horizontal Category Filter
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 38,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: SportType.values.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isAllSelected = _selectedSport == null;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSport = null),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isAllSelected ? AppColors.liveGreen : AppColors.glassFillMedium,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isAllSelected ? AppColors.liveGreen : AppColors.glassBorderSubtle,
                                ),
                              ),
                              child: Text(
                                'All Sports',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isAllSelected ? Colors.black : AppColors.textSecondary,
                                  fontWeight: isAllSelected ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }

                        final sport = SportType.values[index - 1];
                        final isSelected = _selectedSport == sport;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSport = isSelected ? null : sport),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.liveGreen : AppColors.glassFillMedium,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected ? AppColors.liveGreen : AppColors.glassBorderSubtle,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(sport.emoji, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 6),
                                Text(
                                  sport.label.split('&').first.trim(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected ? Colors.black : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 22)),

                if (_searchQuery.isEmpty && _selectedSport == null) ...[
                  // Available Now Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        title: 'Available Right Now ⚡',
                        actionText: 'View All',
                        onActionTap: () {},
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 265,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: liveVenues.length,
                        itemBuilder: (context, index) => _buildLiveVenueCard(liveVenues[index]),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // All Sports Venues Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        title: 'All Turfs & Arenas',
                        actionText: '${_filteredVenues.length} arenas',
                        onActionTap: () {},
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],

                // Venues List
                if (_filteredVenues.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No sports arenas found matching your search.'),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildVenueListTile(_filteredVenues[index]),
                      childCount: _filteredVenues.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveVenueCard(SportsVenue v) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SportsVenueDetailsScreen(venue: v)),
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
              Stack(
                children: [
                  PlazaImage(
                    imageUrl: v.coverImageUrl,
                    height: 150,
                    width: double.infinity,
                    borderRadius: 20,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GlassPill(
                      label: '${v.rating.toStringAsFixed(1)} ★',
                      textColor: AppColors.accentGold,
                      backgroundColor: const Color(0x95000000),
                    ),
                  ),
                  if (v.badge != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xCC090D16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.liveGreen, width: 1.0),
                        ),
                        child: Text(
                          v.badge!,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      style: AppTypography.headingSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${v.location} • ${v.distance}',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '₹${v.startingPricePerHour.toInt()} / hr',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.accentAmber,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'Book Slot',
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

  Widget _buildVenueListTile(SportsVenue v) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SportsVenueDetailsScreen(venue: v)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PlazaImage(
                imageUrl: v.coverImageUrl,
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
                            v.name,
                            style: AppTypography.headingSmall.copyWith(fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GlassPill(
                          label: '${v.rating.toStringAsFixed(1)} ★',
                          textColor: AppColors.accentGold,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      v.supportedSports.map((s) => s.label.split('&').first.trim()).join(' • '),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${v.location} • ${v.distance}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${v.startingPricePerHour.toInt()} / hour onwards',
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
