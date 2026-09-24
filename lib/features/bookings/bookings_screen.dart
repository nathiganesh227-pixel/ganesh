import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/unified_booking.dart';
import '../../core/widgets/glass_card.dart';
import 'widgets/booking_card.dart';
import 'widgets/experience_timeline_view.dart';
import 'widgets/universal_pass_modal.dart';
import '../../core/repositories/booking_repository.dart';
import '../../core/repositories/repository_provider.dart';
import '../movies/booking_confirmation_screen.dart';
import '../dining/dining_confirmation_screen.dart';
import '../events/event_confirmation_screen.dart';
import '../activities/activity_confirmation_screen.dart';
import '../shopping/shopping_confirmation_screen.dart';
import '../stays/hotel_confirmation_screen.dart';
import '../sports/sports_confirmation_screen.dart';

class BookingsScreen extends StatefulWidget {
  final BookingRepository? repository;
  const BookingsScreen({super.key, this.repository});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final BookingRepository _bookingRepo;
  bool _isTimelineView = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<BookingStatus> _tabs = [
    BookingStatus.upcoming,
    BookingStatus.active,
    BookingStatus.completed,
    BookingStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _bookingRepo = widget.repository ?? RepositoryProvider.instance.bookingRepo;
    _syncBookings();
  }

  Future<void> _syncBookings() async {
    try {
      final remote = await _bookingRepo.getBookings();
      if (remote.isNotEmpty && mounted) {
        for (final b in remote) {
          if (!PlazaGlobalState.instance.bookings.any((item) => item.id == b.id)) {
            PlazaGlobalState.instance.addBooking(b);
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openBookingPass(BuildContext context, UnifiedBooking booking) {
    if (booking.movieBooking != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(booking: booking.movieBooking!),
        ),
      );
    } else if (booking.diningReservation != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiningConfirmationScreen(reservation: booking.diningReservation!),
        ),
      );
    } else if (booking.eventBooking != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventConfirmationScreen(booking: booking.eventBooking!),
        ),
      );
    } else if (booking.activityBooking != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityConfirmationScreen(booking: booking.activityBooking!),
        ),
      );
    } else if (booking.shoppingOrder != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShoppingConfirmationScreen(order: booking.shoppingOrder!),
        ),
      );
    } else if (booking.hotelBooking != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HotelConfirmationScreen(booking: booking.hotelBooking!),
        ),
      );
    } else if (booking.sportsBooking != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SportsConfirmationScreen(booking: booking.sportsBooking!),
        ),
      );
    } else {
      UniversalPassModal.show(
        context,
        booking,
        onCancel: () => _confirmCancel(context, booking),
      );
    }
  }

  void _confirmCancel(BuildContext context, UnifiedBooking booking) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: Text('Cancel Booking?', style: AppTypography.headingMedium),
        content: Text(
          'Are you sure you want to cancel "${booking.title}"? Your refund will be credited to your original payment method in 2 hours.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Keep Booking', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _bookingRepo.cancelBooking(booking.id);
              PlazaGlobalState.instance.cancelBooking(booking.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${booking.title} has been cancelled.'),
                  backgroundColor: AppColors.surfaceElevated,
                ),
              );
            },
            child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
          body: SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.accentGold,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'CENTRAL WALLET',
                                        style: AppTypography.labelSmall.copyWith(
                                          letterSpacing: 1.2,
                                          color: AppColors.accentGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('My Bookings', style: AppTypography.displayMedium),
                                ],
                              ),
                              // View mode switcher (List vs Timeline)
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.view_agenda_rounded,
                                        size: 18,
                                        color: !_isTimelineView ? AppColors.primary : AppColors.textMuted,
                                      ),
                                      onPressed: () => setState(() => _isTimelineView = false),
                                      tooltip: 'Card View',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.timeline_rounded,
                                        size: 18,
                                        color: _isTimelineView ? AppColors.primary : AppColors.textMuted,
                                      ),
                                      onPressed: () => setState(() => _isTimelineView = true),
                                      tooltip: 'Timeline View',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Search Filter bar
                          GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                                    style: AppTypography.bodySmall.copyWith(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Search passes by title or ID...',
                                      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    child: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Status Category Tabs
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            indicatorColor: AppColors.primary,
                            indicatorSize: TabBarIndicatorSize.label,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: AppColors.textMuted,
                            labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                            unselectedLabelStyle: AppTypography.labelLarge,
                            tabs: [
                              Tab(text: 'Upcoming (${state.upcomingBookings.length})'),
                              Tab(text: 'Active Now (${state.activeBookings.length})'),
                              Tab(text: 'Completed (${state.completedBookings.length})'),
                              Tab(text: 'Cancelled (${state.cancelledBookings.length})'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: _tabs.map((status) {
                  List<UnifiedBooking> list;
                  switch (status) {
                    case BookingStatus.upcoming:
                      list = state.upcomingBookings;
                      break;
                    case BookingStatus.active:
                      list = state.activeBookings;
                      break;
                    case BookingStatus.completed:
                      list = state.completedBookings;
                      break;
                    case BookingStatus.cancelled:
                      list = state.cancelledBookings;
                      break;
                  }

                  if (_searchQuery.isNotEmpty) {
                    list = list
                        .where((b) =>
                            b.title.toLowerCase().contains(_searchQuery) ||
                            b.id.toLowerCase().contains(_searchQuery) ||
                            b.location.toLowerCase().contains(_searchQuery))
                        .toList();
                  }

                  if (_isTimelineView && status == BookingStatus.upcoming) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          ExperienceTimelineView(
                            bookings: list,
                            onBookingTap: (b) => _openBookingPass(context, b),
                          ),
                          const SizedBox(height: 120),
                        ],
                      ),
                    );
                  }

                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: GlassCard(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                status == BookingStatus.cancelled
                                    ? Icons.cancel_presentation_rounded
                                    : Icons.confirmation_number_outlined,
                                size: 48,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No ${status.label} Bookings',
                                style: AppTypography.headingMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                status == BookingStatus.upcoming
                                    ? 'Book movies, dining, sports, or experiences to see your live passes here.'
                                    : 'All your past ${status.label.toLowerCase()} passes will be catalogued here.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: list.length + 1,
                    itemBuilder: (context, index) {
                      if (index == list.length) {
                        return const SizedBox(height: 120);
                      }
                      final booking = list[index];
                      return BookingCard(
                        booking: booking,
                        onTap: () => _openBookingPass(context, booking),
                        onCancel: status == BookingStatus.upcoming
                            ? () => _confirmCancel(context, booking)
                            : null,
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
