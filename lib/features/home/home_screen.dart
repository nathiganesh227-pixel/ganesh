import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/mock_data.dart';
import '../../core/data/movie_mock_data.dart';
import '../../core/data/dining_mock_data.dart';
import '../../core/data/event_mock_data.dart';
import '../../core/data/activity_mock_data.dart';
import '../../core/models/category.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/deal_card.dart';
import '../../core/widgets/experience_card.dart';
import '../../core/widgets/glass_search_bar.dart';
import '../../core/widgets/live_availability_card.dart';
import '../../core/widgets/section_header.dart';
import '../movies/movies_screen.dart';
import '../movies/movie_details_screen.dart';
import '../dining/dining_screen.dart';
import '../dining/restaurant_details_screen.dart';
import '../events/events_screen.dart';
import '../events/event_details_screen.dart';
import '../activities/activities_screen.dart';
import '../activities/activity_details_screen.dart';
import '../shopping/shopping_screen.dart';
import '../stays/stays_screen.dart';
import '../sports/sports_screen.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/widgets/glass_card.dart';
import '../notifications/notifications_modal.dart';
import '../bookings/widgets/universal_pass_modal.dart';
import 'widgets/build_my_day_card.dart';
import 'widgets/home_header.dart';

class HomeScreen extends StatefulWidget {
  final Function(PlazaCategoryType)? onCategorySelect;
  final VoidCallback? onBuildMyDayTap;

  const HomeScreen({
    super.key,
    this.onCategorySelect,
    this.onBuildMyDayTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PlazaCategoryType? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showNotificationSheet() {
    NotificationsModal.show(context);
  }
  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1.0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Your City', style: AppTypography.headingLarge),
            const SizedBox(height: 8),
            Text('Discover premier experiences in your area', style: AppTypography.bodySmall),
            const SizedBox(height: 20),
            ...['Hyderabad', 'Bengaluru', 'Mumbai', 'Delhi NCR', 'Chennai', 'Goa'].map(
              (city) => ListTile(
                title: Text(
                  city,
                  style: AppTypography.labelLarge.copyWith(
                    color: city == MockData.currentCity ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                trailing: city == MockData.currentCity
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                    : null,
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched to $city'),
                      backgroundColor: AppColors.surfaceElevated,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final state = PlazaGlobalState.instance;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
          // Background Atmospheric Ambient Glow
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.heroAmbientGlow,
              ),
            ),
          ),

          // Main Scrollable Home Canvas
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Header (City + PLAZA brand + Notifications)
                SliverToBoxAdapter(
                  child: HomeHeader(
                    onLocationTap: _showCityPicker,
                    onNotificationTap: _showNotificationSheet,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 14)),

                // Hero Headline: "What are you up to?"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What are you\nup to today?',
                          style: AppTypography.displayLarge,
                        ),
                        const SizedBox(height: 16),

                        // Liquid Glass Search Bar
                        GlassSearchBar(
                          controller: _searchController,
                          onFilterTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Search filters opened'),
                                backgroundColor: AppColors.surfaceElevated,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 22)),

                // Category Shortcut Pills (Movies, Dining, Events, Activities, Shopping, Stays, Sports)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 46,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: MockData.categories.length,
                      itemBuilder: (context, index) {
                        final cat = MockData.categories[index];
                        final isSelected = _selectedCategory == cat.type;
                        return CategoryChip(
                          category: cat,
                          isSelected: isSelected,
                          onTap: () {
                            if (cat.type == PlazaCategoryType.movies) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const MoviesScreen()));
                              return;
                            } else if (cat.type == PlazaCategoryType.dining) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const DiningScreen()));
                              return;
                            } else if (cat.type == PlazaCategoryType.events) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsScreen()));
                              return;
                            } else if (cat.type == PlazaCategoryType.activities) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivitiesScreen()));
                              return;
                            } else if (cat.type == PlazaCategoryType.shopping) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ShoppingScreen()));
                              return;
                            } else if (cat.type == PlazaCategoryType.stays) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const StaysScreen()));
                              return;
                            } else if (cat.type == PlazaCategoryType.sports) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const SportsScreen()));
                              return;
                            }
                            setState(() {
                              _selectedCategory = isSelected ? null : cat.type;
                            });
                            widget.onCategorySelect?.call(cat.type);
                          },
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Upcoming Booking Quick Access Banner
                if (state.upcomingBookings.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          UniversalPassModal.show(context, state.upcomingBookings.first);
                        },
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          borderColor: AppColors.primary.withValues(alpha: 0.5),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.sunsetPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'UPCOMING PASS',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.accentGold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '• ${state.upcomingBookings.first.time}',
                                          style: AppTypography.labelSmall.copyWith(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      state.upcomingBookings.first.title,
                                      style: AppTypography.headingSmall.copyWith(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      state.upcomingBookings.first.subtitle,
                                      style: AppTypography.bodySmall.copyWith(fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.primaryLight, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // "Build My Day" Interactive Glass Card
                SliverToBoxAdapter(
                  child: BuildMyDayCard(
                    plan: MockData.sampleDayPlan,
                    onCustomizeTap: widget.onBuildMyDayTap,
                    onBookPlanTap: () {
                      final plan = state.savedPlans.first;
                      final planId = PlazaGlobalState.instance.bookEntirePlan(plan);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Plan "${plan.title}" booked! (ID $planId). Check Bookings Wallet.'),
                          backgroundColor: AppColors.surfaceCard,
                        ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // "Trending near you" Section
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Trending near you',
                    subtitle: 'Top rated in Hyderabad this week',
                    onActionTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MoviesScreen(),
                        ),
                      );
                    },
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 360,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: MockData.trendingExperiences.length,
                      itemBuilder: (context, index) {
                        final exp = MockData.trendingExperiences[index];
                        return ExperienceCard(
                          experience: exp,
                          onTap: () {
                            if (exp.category == PlazaCategoryType.movies) {
                              final movie = MovieMockData.movies.firstWhere(
                                (m) => exp.title.contains(m.title) || m.title.contains(exp.title.split('(').first.trim()),
                                orElse: () => MovieMockData.movies.first,
                              );
                              Navigator.push(context, MaterialPageRoute(builder: (context) => MovieDetailsScreen(movie: movie)));
                              return;
                            } else if (exp.category == PlazaCategoryType.dining) {
                              final restaurant = DiningMockData.restaurants.firstWhere(
                                (r) => exp.title.contains(r.name) || r.name.contains(exp.title.split('&').first.trim()),
                                orElse: () => DiningMockData.restaurants.first,
                              );
                              Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailsScreen(restaurant: restaurant)));
                              return;
                            } else if (exp.category == PlazaCategoryType.events) {
                              final event = EventMockData.events.firstWhere(
                                (e) => exp.title.contains(e.title) || e.title.contains(exp.title.split('ft.').first.trim()),
                                orElse: () => EventMockData.events.first,
                              );
                              Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailsScreen(event: event)));
                              return;
                            } else if (exp.category == PlazaCategoryType.activities) {
                              final activity = ActivityMockData.activities.firstWhere(
                                (a) => exp.title.contains(a.title) || a.title.contains(exp.title.split('&').first.trim()),
                                orElse: () => ActivityMockData.activities.first,
                              );
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityDetailsScreen(activity: activity)));
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Selected ${exp.title}'),
                                backgroundColor: AppColors.surfaceElevated,
                                duration: const Duration(milliseconds: 800),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // "Live & Available Now" Section
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Live & Available Now',
                    subtitle: 'Instant slots • No wait times',
                    onActionTap: () {},
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 235,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: MockData.liveSlots.length,
                      itemBuilder: (context, index) {
                        final slot = MockData.liveSlots[index];
                        return LiveAvailabilityCard(
                          slot: slot,
                          onTap: () {
                            if (slot.category == PlazaCategoryType.movies) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const MoviesScreen()));
                              return;
                            } else if (slot.category == PlazaCategoryType.dining) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const DiningScreen()));
                              return;
                            } else if (slot.category == PlazaCategoryType.activities || slot.category == PlazaCategoryType.sports) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivitiesScreen()));
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reserving slot at ${slot.venue}'),
                                backgroundColor: AppColors.surfaceElevated,
                                duration: const Duration(milliseconds: 800),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // "Today's Deals" Section
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: "Today's Deals",
                    subtitle: 'Exclusive discounts on movies, dining & fun',
                    onActionTap: () {},
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: MockData.todaysDeals.length,
                      itemBuilder: (context, index) {
                        final deal = MockData.todaysDeals[index];
                        return DealCard(
                          deal: deal,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Applied coupon: ${deal.code} (${deal.discount})'),
                                backgroundColor: AppColors.primary,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                // Generous bottom padding for comfortable scrolling above the floating dock
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  },
);
  }
}
