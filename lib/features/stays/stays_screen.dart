import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/stay_mock_data.dart';
import '../../core/models/stay.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/plaza_image.dart';
import '../../core/widgets/section_header.dart';
import '../../core/repositories/stay_repository.dart';
import '../../core/repositories/repository_provider.dart';
import 'hotel_details_screen.dart';

class StaysScreen extends StatefulWidget {
  final StayRepository? repository;
  const StaysScreen({super.key, this.repository});

  @override
  State<StaysScreen> createState() => _StaysScreenState();
}

class _StaysScreenState extends State<StaysScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final StayRepository _stayRepo;
  List<Hotel> _loadedHotels = StayMockData.hotels;
  StayCategoryType? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _stayRepo = widget.repository ?? RepositoryProvider.instance.stayRepo;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _fetchHotels();
  }

  Future<void> _fetchHotels() async {
    try {
      final list = await _stayRepo.getHotels();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _loadedHotels = list;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Hotel> get _filteredHotels {
    return _loadedHotels.where((h) {
      if (_selectedCategory != null && h.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final matchesName = h.name.toLowerCase().contains(_searchQuery);
        final matchesLocation = h.location.toLowerCase().contains(_searchQuery);
        final matchesCategory = h.category.label.toLowerCase().contains(_searchQuery);
        return matchesName || matchesLocation || matchesCategory;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final featuredHotels = _loadedHotels.where((h) => h.isFeatured).toList();

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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 13, color: AppColors.primary),
                                    const SizedBox(width: 3),
                                    Text('HYDERABAD & RESORTS', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2)),
                                  ],
                                ),
                                Text('Stays & Luxury Escapes', style: AppTypography.headingMedium),
                              ],
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
                      onFilterTap: () {},
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Stay Categories Filter
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 38,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: StayCategoryType.values.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final isAllSelected = _selectedCategory == null;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = null),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isAllSelected ? AppColors.accentGold : AppColors.glassFillMedium,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isAllSelected ? AppColors.accentGold : AppColors.glassBorderSubtle,
                                ),
                              ),
                              child: Text(
                                'All Stays',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isAllSelected ? Colors.black : AppColors.textSecondary,
                                  fontWeight: isAllSelected ? FontWeight.w800 : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }

                        final cat = StayCategoryType.values[index - 1];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = isSelected ? null : cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.accentGold : AppColors.glassFillMedium,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected ? AppColors.accentGold : AppColors.glassBorderSubtle,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(cat.emoji, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 6),
                                Text(
                                  cat.label.split('&').first.trim(),
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

                if (_searchQuery.isEmpty && _selectedCategory == null) ...[
                  // Featured Palaces & Luxury Escapes
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        title: 'Signature Palaces & 5★ Stays 👑',
                        actionText: 'Explore All',
                        onActionTap: () {},
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 270,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: featuredHotels.length,
                        itemBuilder: (context, index) => _buildFeaturedHotelCard(featuredHotels[index]),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // All Stays Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        title: 'Curated Hotels & Resorts',
                        actionText: '${_filteredHotels.length} stays',
                        onActionTap: () {},
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],

                // Stays List
                if (_filteredHotels.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('No hotels found matching your destination search.'),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildHotelListTile(_filteredHotels[index]),
                      childCount: _filteredHotels.length,
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

  Widget _buildFeaturedHotelCard(Hotel h) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HotelDetailsScreen(hotel: h)),
        );
      },
      child: Container(
        width: 290,
        margin: const EdgeInsets.only(right: 16),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  PlazaImage(
                    imageUrl: h.coverImageUrl,
                    height: 155,
                    width: double.infinity,
                    borderRadius: 20,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GlassPill(
                      label: '${h.rating.toStringAsFixed(2)} ★',
                      textColor: AppColors.accentGold,
                      backgroundColor: const Color(0x95000000),
                    ),
                  ),
                  if (h.dealBadge != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xD0000000),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          h.dealBadge!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.accentGold,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
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
                      h.name,
                      style: AppTypography.headingSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${h.location} • ${h.distance}',
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
                            '₹${h.startingPricePerNight.toInt()} / night',
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
                            'View Rooms',
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

  Widget _buildHotelListTile(Hotel h) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HotelDetailsScreen(hotel: h)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PlazaImage(
                imageUrl: h.coverImageUrl,
                width: 96,
                height: 96,
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
                            h.name,
                            style: AppTypography.headingSmall.copyWith(fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GlassPill(
                          label: '${h.rating.toStringAsFixed(1)} ★',
                          textColor: AppColors.accentGold,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      h.category.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${h.location} • ${h.distance}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${h.startingPricePerNight.toInt()} / night onwards',
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
