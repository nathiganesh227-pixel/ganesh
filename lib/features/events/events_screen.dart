import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/mock_data.dart';
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
  EventCategoryType? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _eventRepo = widget.repository ?? RepositoryProvider.instance.eventRepo;
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final list = await _eventRepo.getEvents();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _loadedEvents = list;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PlazaEvent> get _filteredEvents {
    return _loadedEvents.where((e) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = e.title.toLowerCase().contains(q);
        final matchesVenue = e.venue.toLowerCase().contains(q);
        final matchesArtist = e.artists.any((a) => a.name.toLowerCase().contains(q));
        if (!matchesTitle && !matchesVenue && !matchesArtist) return false;
      }
      if (_selectedCategory != null && e.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final trending = _filteredEvents.where((e) => e.isTrending).toList();
    final today = _filteredEvents.where((e) => e.isHappeningToday).toList();
    final weekend = _filteredEvents.where((e) => e.isThisWeekend).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x358B5CF6), // Royal violet ambient
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
                            Text('Events & Shows', style: AppTypography.headingLarge),
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
                      hintText: 'Search concerts, standup, festivals...',
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
                      itemCount: EventCategoryType.values.length,
                      itemBuilder: (context, index) {
                        final cat = EventCategoryType.values[index];
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
                                  ? const Color(0x358B5CF6)
                                  : AppColors.glassFillMedium,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.secondaryViolet
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

                // Empty State
                if (_filteredEvents.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No events found matching your search.\nTry clearing filters.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                    ),
                  ),

                // Trending Events (Hero Cards)
                if (trending.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Trending Live Experiences',
                      subtitle: 'Most anticipated concerts & comedy shows',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 360,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: trending.length,
                        itemBuilder: (context, index) {
                          final event = trending[index];
                          return _buildTrendingEventCard(event);
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                ],

                // Happening Today
                if (today.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Happening Today',
                      subtitle: 'Tonight in Hyderabad',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 250,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: today.length,
                        itemBuilder: (context, index) {
                          final event = today[index];
                          return _buildCompactEventCard(event);
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                ],

                // This Weekend
                if (weekend.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'This Weekend in Town',
                      subtitle: 'Top picks for Saturday & Sunday',
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final event = weekend[index];
                        return _buildEventListTile(event);
                      },
                      childCount: weekend.length,
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

  Widget _buildTrendingEventCard(PlazaEvent event) {
    final dateStr = DateFormat('EEE, d MMM').format(event.eventDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Container(
        width: 290,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x70000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PlazaImage(imageUrl: event.posterUrl, fit: BoxFit.cover),
              Container(
                decoration: const BoxDecoration(
                  gradient: AppGradients.cardImageOverlay,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.glassBorder, width: 1.2),
                ),
              ),

              // Date Tag
              Positioned(
                top: 14,
                left: 14,
                child: GlassPill(
                  label: dateStr,
                  icon: Icons.calendar_today_rounded,
                  backgroundColor: const Color(0x95070A11),
                  textColor: AppColors.primaryLight,
                ),
              ),

              // Category Pill
              Positioned(
                top: 14,
                right: 14,
                child: GlassPill(
                  label: event.category.label.split('&').first.trim(),
                  backgroundColor: AppColors.secondaryViolet.withValues(alpha: 0.8),
                  textColor: Colors.white,
                ),
              ),

              // Bottom Glass Info Panel
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x55090D18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.glassBorderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.title,
                            style: AppTypography.headingSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${event.venue} • ${event.distance}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '₹${event.startingPrice.toInt()} onwards',
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  gradient: AppGradients.royalViolet,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Get Tickets',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildCompactEventCard(PlazaEvent event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlazaImage(
                imageUrl: event.posterUrl,
                height: 120,
                width: double.infinity,
                borderRadius: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppTypography.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.time,
                      style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.primaryLight),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${event.startingPrice.toInt()} onwards',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.accentAmber, fontWeight: FontWeight.w700),
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

  Widget _buildEventListTile(PlazaEvent event) {
    final dateStr = DateFormat('EEE, d MMM').format(event.eventDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
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
                imageUrl: event.posterUrl,
                width: 85,
                height: 95,
                borderRadius: 16,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppTypography.headingSmall.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateStr • ${event.time}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.venue,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${event.startingPrice.toInt()} onwards',
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
