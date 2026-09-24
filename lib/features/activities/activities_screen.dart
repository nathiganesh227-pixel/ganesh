import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/mock_data.dart';
import '../../core/data/activity_mock_data.dart';
import '../../core/models/activity.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_pill.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/plaza_image.dart';
import '../../core/widgets/section_header.dart';
import '../../core/repositories/activity_repository.dart';
import '../../core/repositories/repository_provider.dart';
import 'activity_details_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _activityRepo = widget.repository ?? RepositoryProvider.instance.activityRepo;
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    try {
      final list = await _activityRepo.getActivities();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _loadedActivities = list;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PlazaActivity> get _filteredActivities {
    return _loadedActivities.where((a) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = a.title.toLowerCase().contains(q);
        final matchesVenue = a.venueName.toLowerCase().contains(q);
        final matchesLoc = a.location.toLowerCase().contains(q);
        if (!matchesTitle && !matchesVenue && !matchesLoc) return false;
      }
      if (_selectedCategory != null && a.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final availableNow = _filteredActivities.where((a) => a.isAvailableNow).toList();
    final groupPicks = _filteredActivities.where((a) => a.isGroupPick).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
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
                            Text('Activities & Fun', style: AppTypography.headingLarge),
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
                      hintText: 'Search bowling, go-karting, turfs, gaming...',
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

                // Category Filter Pills
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 36,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: ActivityCategoryType.values.length,
                      itemBuilder: (context, index) {
                        final cat = ActivityCategoryType.values[index];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = isSelected ? null : cat;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0x3506B6D4)
                                  : AppColors.glassFillMedium,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.secondaryCyan
                                    : AppColors.glassBorderSubtle,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat.label,
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
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Empty state
                if (_filteredActivities.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No activities found matching your criteria.\nTry clearing filters.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ),
                  ),

                // Live & Available Now Section
                if (availableNow.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Live & Available Right Now',
                      subtitle: 'Instant slots • No wait times in Hyderabad',
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
                        itemCount: availableNow.length,
                        itemBuilder: (context, index) {
                          final act = availableNow[index];
                          return _buildActivityHeroCard(act);
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                ],

                // Group Activities & Squad Picks
                if (groupPicks.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Top Group & Squad Hangouts',
                      subtitle: 'Perfect for friends, colleagues & birthday groups',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final act = groupPicks[index];
                        return _buildActivityListTile(act);
                      },
                      childCount: groupPicks.length,
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

  Widget _buildActivityHeroCard(PlazaActivity act) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailsScreen(activity: act),
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
              Stack(
                children: [
                  PlazaImage(
                    imageUrl: act.coverImageUrl,
                    height: 160,
                    width: double.infinity,
                    borderRadius: 20,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GlassPill(
                      label: '${act.rating.toStringAsFixed(1)} ★',
                      textColor: AppColors.accentGold,
                      backgroundColor: const Color(0x95000000),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xCC090D16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.liveGreen, width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.liveGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            act.liveAvailabilityLabel,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
                      act.title,
                      style: AppTypography.headingSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${act.venueName} • ${act.distance}',
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
                            '₹${act.startingPrice.toInt()} onwards',
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

  Widget _buildActivityListTile(PlazaActivity act) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailsScreen(activity: act),
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
                imageUrl: act.coverImageUrl,
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
                            act.title,
                            style: AppTypography.headingSmall.copyWith(fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GlassPill(
                          label: '${act.rating.toStringAsFixed(1)} ★',
                          textColor: AppColors.accentGold,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${act.category.label} • ${act.duration}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${act.venueName} • ${act.location.split(',').first}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${act.startingPrice.toInt()} / person',
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
