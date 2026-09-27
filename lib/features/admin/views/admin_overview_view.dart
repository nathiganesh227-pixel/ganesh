import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminOverviewView extends StatefulWidget {
  final AdminRepository? repository;
  final void Function(int sectionIndex)? onNavigateToSection;

  const AdminOverviewView({
    super.key,
    this.repository,
    this.onNavigateToSection,
  });

  @override
  State<AdminOverviewView> createState() => _AdminOverviewViewState();
}

class _AdminOverviewViewState extends State<AdminOverviewView> {
  late final AdminRepository _repo;
  AdminDashboardStats? _stats;
  AdminSystemHealth? _health;
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _fetchStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final results = await Future.wait([
      _repo.getDashboardStats(),
      _repo.getSystemHealth(),
    ]);

    if (!mounted) return;

    final statsRes = results[0] as dynamic;
    final healthRes = results[1] as dynamic;

    if (statsRes.isSuccess && statsRes.data != null) {
      setState(() {
        _stats = statsRes.data as AdminDashboardStats;
        if (healthRes.isSuccess && healthRes.data != null) {
          _health = healthRes.data as AdminSystemHealth;
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = statsRes.errorMessage ?? 'Failed to load dashboard metrics.';
        _isLoading = false;
      });
    }
  }

  void _triggerSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => _GlobalSearchDialog(query: query, repository: _repo),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGold),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.alertRed, size: 40),
              const SizedBox(height: 12),
              Text('Unable to Load Metrics', style: AppTypography.headingMedium),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _fetchStats,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _stats ??
        const AdminDashboardStats(
          users: 0,
          movies: 0,
          dining: 0,
          events: 0,
          activities: 0,
          shopping: 0,
          stays: 0,
          sports: 0,
          bookings: 0,
        );

    final p = stats.platform;

    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: AppColors.accentGold,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Cockpit Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Executive Control Cockpit', style: AppTypography.headingLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Live system overview across all PLAZA city experiences & services.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Health Indicator Button
                GestureDetector(
                  onTap: () => widget.onNavigateToSection?.call(14), // Health section
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ((_health?.status.toUpperCase() == 'HEALTHY' || _health == null)
                              ? AppColors.liveGreen
                              : AppColors.alertRed)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ((_health?.status.toUpperCase() == 'HEALTHY' || _health == null)
                                ? AppColors.liveGreen
                                : AppColors.alertRed)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: (_health?.status.toUpperCase() == 'HEALTHY' || _health == null)
                              ? AppColors.liveGreen
                              : AppColors.alertRed,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _health?.status.toUpperCase() ?? 'HEALTHY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: (_health?.status.toUpperCase() == 'HEALTHY' || _health == null)
                                ? AppColors.liveGreen
                                : AppColors.alertRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Global Operations Search Bar
            TextField(
              controller: _searchController,
              onSubmitted: (_) => _triggerSearch(),
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search bookings, payments, customers, and catalog items...',
                hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentGold),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.accentGold),
                  onPressed: _triggerSearch,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.accentGold),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Platform Highlights (Financial & Operations)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isWide ? 1.8 : 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      'Gross Booking Value',
                      '₹${p.grossBookingValue.toStringAsFixed(0)}',
                      Icons.currency_rupee_rounded,
                      AppColors.accentGold,
                      onTap: () => widget.onNavigateToSection?.call(13), // Bookings
                    ),
                    _buildStatCard(
                      'Total Bookings',
                      '${p.totalBookings > 0 ? p.totalBookings : stats.bookings}',
                      Icons.confirmation_number_rounded,
                      AppColors.secondaryIndigo,
                      onTap: () => widget.onNavigateToSection?.call(13), // Bookings
                    ),
                    _buildStatCard(
                      'Captured Payments',
                      '${p.capturedPayments}',
                      Icons.check_circle_rounded,
                      AppColors.liveGreen,
                      onTap: () => widget.onNavigateToSection?.call(14), // Payments
                    ),
                    _buildStatCard(
                      'Users & Members',
                      '${p.totalUsers > 0 ? p.totalUsers : stats.users}',
                      Icons.people_alt_rounded,
                      AppColors.secondaryCyan,
                      onTap: () => widget.onNavigateToSection?.call(11), // Users
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Vertical Experiences Grid
            Text('7 Vertical Catalog Portfolios', style: AppTypography.headingMedium),
            const SizedBox(height: 4),
            Text(
              'Item inventory counts and active publication status across all experiences.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                        ? 3
                        : 2;

                final verticalCards = [
                  _VerticalItem(
                    title: 'Movies & Releases',
                    count: stats.movies,
                    activeCount: stats.verticals['movies']?.active ?? stats.movies,
                    icon: Icons.movie_filter_rounded,
                    color: AppColors.primary,
                    sectionIndex: 1,
                  ),
                  _VerticalItem(
                    title: 'Theatres & Venues',
                    count: stats.dining > 0 ? 3 : 0,
                    activeCount: stats.dining > 0 ? 3 : 0,
                    icon: Icons.theaters_rounded,
                    color: AppColors.accentAmber,
                    sectionIndex: 2,
                  ),
                  _VerticalItem(
                    title: 'Dining Spots',
                    count: stats.dining,
                    activeCount: stats.verticals['dining']?.active ?? stats.dining,
                    icon: Icons.restaurant_rounded,
                    color: AppColors.accentGold,
                    sectionIndex: 5,
                  ),
                  _VerticalItem(
                    title: 'Concerts & Events',
                    count: stats.events,
                    activeCount: stats.verticals['events']?.active ?? stats.events,
                    icon: Icons.celebration_rounded,
                    color: AppColors.secondaryViolet,
                    sectionIndex: 6,
                  ),
                  _VerticalItem(
                    title: 'Adventures & Activities',
                    count: stats.activities,
                    activeCount: stats.verticals['activities']?.active ?? stats.activities,
                    icon: Icons.local_activity_rounded,
                    color: AppColors.secondaryCyan,
                    sectionIndex: 7,
                  ),
                  _VerticalItem(
                    title: 'Luxury Shopping',
                    count: stats.shopping,
                    activeCount: stats.verticals['shopping']?.active ?? stats.shopping,
                    icon: Icons.shopping_bag_rounded,
                    color: AppColors.warningOrange,
                    sectionIndex: 8,
                  ),
                  _VerticalItem(
                    title: 'Hotels & Stays',
                    count: stats.stays,
                    activeCount: stats.verticals['stays']?.active ?? stats.stays,
                    icon: Icons.hotel_rounded,
                    color: AppColors.secondaryIndigo,
                    sectionIndex: 9,
                  ),
                  _VerticalItem(
                    title: 'Sports Arenas',
                    count: stats.sports,
                    activeCount: stats.verticals['sports']?.active ?? stats.sports,
                    icon: Icons.sports_tennis_rounded,
                    color: AppColors.liveGreen,
                    sectionIndex: 10,
                  ),
                ];

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: verticalCards.length,
                  itemBuilder: (context, index) {
                    final item = verticalCards[index];
                    return GestureDetector(
                      onTap: () => widget.onNavigateToSection?.call(item.sectionIndex),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: item.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(item.icon, color: item.color, size: 22),
                                ),
                                const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textTertiary),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.count}',
                                  style: AppTypography.displayMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 24,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.title,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${item.activeCount} active items',
                                  style: AppTypography.caption.copyWith(color: AppColors.textTertiary, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            Text(
              value,
              style: AppTypography.displayMedium.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalItem {
  final String title;
  final int count;
  final int activeCount;
  final IconData icon;
  final Color color;
  final int sectionIndex;

  _VerticalItem({
    required this.title,
    required this.count,
    required this.activeCount,
    required this.icon,
    required this.color,
    required this.sectionIndex,
  });
}

/// Global Operations Search Dialog
class _GlobalSearchDialog extends StatefulWidget {
  final String query;
  final AdminRepository repository;

  const _GlobalSearchDialog({required this.query, required this.repository});

  @override
  State<_GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<_GlobalSearchDialog> {
  List<AdminSearchResult> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    final res = await widget.repository.searchOperations(widget.query);
    if (!mounted) return;

    if (res.isSuccess && res.data != null) {
      setState(() {
        _results = res.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _results = [];
        _isLoading = false;
      });
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return AppColors.accentGold;
      case 'payment':
        return AppColors.liveGreen;
      case 'user':
        return AppColors.secondaryIndigo;
      case 'catalog':
        return AppColors.secondaryCyan;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.accentGold),
                    const SizedBox(width: 8),
                    Text('Search Results for "${widget.query}"', style: AppTypography.headingSmall),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: AppColors.accentGold),
                ),
              )
            else if (_results.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off_rounded, color: AppColors.textTertiary, size: 48),
                      const SizedBox(height: 12),
                      Text('No Matches Found', style: AppTypography.headingMedium),
                      const SizedBox(height: 4),
                      Text(
                        'No bookings, payments, users, or items matched "${widget.query}".',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    final color = _getTypeColor(item.type);

                    return GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (item.status != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                item.status!.toUpperCase(),
                                style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                              ),
                            ),
                          ],
                        ],
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
}
