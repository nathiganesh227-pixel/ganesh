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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _repo.getDashboardStats();
    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _stats = res.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res.message ?? 'Failed to load dashboard metrics.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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

    final metrics = [
      _MetricItem('Users & Members', stats.users, Icons.people_alt_rounded, AppColors.secondaryBlue, 11),
      _MetricItem('Movies & Releases', stats.movies, Icons.movie_filter_rounded, AppColors.primary, 1),
      _MetricItem('Theatres & Venues', stats.dining > 0 ? 3 : 0, Icons.theaters_rounded, AppColors.accentAmber, 2),
      _MetricItem('Dining Spots', stats.dining, Icons.restaurant_rounded, AppColors.accentGold, 5),
      _MetricItem('Events & Concerts', stats.events, Icons.celebration_rounded, AppColors.secondaryViolet, 6),
      _MetricItem('Activities & Sports', stats.activities, Icons.local_activity_rounded, AppColors.secondaryCyan, 7),
      _MetricItem('Shopping Catalog', stats.shopping, Icons.shopping_bag_rounded, AppColors.warningOrange, 8),
      _MetricItem('Hotels & Stays', stats.stays, Icons.hotel_rounded, AppColors.secondaryIndigo, 9),
      _MetricItem('Sports Arenas', stats.sports, Icons.sports_tennis_rounded, AppColors.liveGreen, 10),
      _MetricItem('Total Bookings', stats.bookings, Icons.confirmation_number_rounded, AppColors.liveGreen, null),
    ];

    return RefreshIndicator(
      onRefresh: _fetchStats,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                IconButton(
                  onPressed: _fetchStats,
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryLight),
                  tooltip: 'Refresh Metrics',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                        ? 3
                        : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: metrics.length,
                  itemBuilder: (context, index) {
                    final m = metrics[index];
                    return GestureDetector(
                      onTap: m.targetSectionIndex != null && widget.onNavigateToSection != null
                          ? () => widget.onNavigateToSection!(m.targetSectionIndex!)
                          : null,
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
                                    color: m.accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(m.icon, color: m.accentColor, size: 22),
                                ),
                                if (m.targetSectionIndex != null)
                                  const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textMuted),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${m.count}',
                                  style: AppTypography.displayMedium.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 26,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.title,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
}

class _MetricItem {
  final String title;
  final int count;
  final IconData icon;
  final Color accentColor;
  final int? targetSectionIndex;

  _MetricItem(this.title, this.count, this.icon, this.accentColor, this.targetSectionIndex);
}
