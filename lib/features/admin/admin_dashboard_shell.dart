import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/repositories/admin_repository.dart';
import '../navigation/plaza_navigation_shell.dart';
import 'views/admin_overview_view.dart';
import 'views/admin_movies_view.dart';
import 'views/admin_theatres_view.dart';
import 'views/admin_screens_view.dart';
import 'views/admin_shows_view.dart';
import 'views/admin_vertical_catalog_view.dart';
import 'views/admin_users_view.dart';
import 'views/admin_audit_logs_view.dart';

class AdminDashboardShell extends StatefulWidget {
  final AdminRepository? repository;
  final int initialSectionIndex;

  const AdminDashboardShell({
    super.key,
    this.repository,
    this.initialSectionIndex = 0,
  });

  @override
  State<AdminDashboardShell> createState() => _AdminDashboardShellState();
}

class _AdminDashboardShellState extends State<AdminDashboardShell> {
  late int _selectedSection;

  final List<_NavDestination> _destinations = const [
    _NavDestination('Overview', Icons.dashboard_rounded),
    _NavDestination('Movies', Icons.movie_filter_rounded),
    _NavDestination('Theatres', Icons.theaters_rounded),
    _NavDestination('Screens', Icons.tv_rounded),
    _NavDestination('Shows', Icons.schedule_rounded),
    _NavDestination('Dining', Icons.restaurant_rounded),
    _NavDestination('Events', Icons.celebration_rounded),
    _NavDestination('Activities', Icons.local_activity_rounded),
    _NavDestination('Shopping', Icons.shopping_bag_rounded),
    _NavDestination('Stays', Icons.hotel_rounded),
    _NavDestination('Sports', Icons.sports_tennis_rounded),
    _NavDestination('Users', Icons.people_alt_rounded),
    _NavDestination('Audit Logs', Icons.security_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSectionIndex;
  }

  void _handleLogout() {
    AuthService.instance.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PlazaNavigationShell()),
      (route) => false,
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedSection) {
      case 0:
        return AdminOverviewView(
          repository: widget.repository,
          onNavigateToSection: (idx) => setState(() => _selectedSection = idx),
        );
      case 1:
        return AdminMoviesView(repository: widget.repository);
      case 2:
        return AdminTheatresView(repository: widget.repository);
      case 3:
        return AdminScreensView(repository: widget.repository);
      case 4:
        return AdminShowsView(repository: widget.repository);
      case 5:
        return AdminVerticalCatalogView(
          vertical: 'dining',
          title: 'Dining & Restaurants',
          description: 'Manage royal fine dining, cuisines, menus, and publication states.',
          icon: Icons.restaurant_rounded,
          accentColor: AppColors.accentGold,
          repository: widget.repository,
        );
      case 6:
        return AdminVerticalCatalogView(
          vertical: 'events',
          title: 'Concerts & Events',
          description: 'Manage music festivals, seating tiers, artists, and live dates.',
          icon: Icons.celebration_rounded,
          accentColor: AppColors.secondaryViolet,
          repository: widget.repository,
        );
      case 7:
        return AdminVerticalCatalogView(
          vertical: 'activities',
          title: 'Adventures & Activities',
          description: 'Manage go-karting, outdoor activities, time slots, and safety guidelines.',
          icon: Icons.local_activity_rounded,
          accentColor: AppColors.secondaryCyan,
          repository: widget.repository,
        );
      case 8:
        return AdminVerticalCatalogView(
          vertical: 'shopping',
          title: 'Luxury Shopping Catalog',
          description: 'Manage luxury apparel, brands, inventory availability, and stores.',
          icon: Icons.shopping_bag_rounded,
          accentColor: AppColors.warningOrange,
          repository: widget.repository,
        );
      case 9:
        return AdminVerticalCatalogView(
          vertical: 'stays',
          title: 'Hotels & Heritage Stays',
          description: 'Manage palace hotels, suites, starting tariffs, and luxury amenities.',
          icon: Icons.hotel_rounded,
          accentColor: AppColors.secondaryIndigo,
          repository: widget.repository,
        );
      case 10:
        return AdminVerticalCatalogView(
          vertical: 'sports',
          title: 'Sports Arenas & Venues',
          description: 'Manage courts, hourly pricing, supported sports, and tournament rules.',
          icon: Icons.sports_tennis_rounded,
          accentColor: AppColors.liveGreen,
          repository: widget.repository,
        );
      case 11:
        return AdminUsersView(repository: widget.repository);
      case 12:
        return AdminAuditLogsView(repository: widget.repository);
      default:
        return AdminOverviewView(repository: widget.repository);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final currentTitle = _destinations[_selectedSection].title;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Left Sidebar
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(right: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Column(
                children: [
                  // Brand Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accentAmber],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PLAZA',
                                style: AppTypography.headingMedium.copyWith(
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'OPERATIONS CONSOLE',
                                style: TextStyle(
                                  color: AppColors.accentAmber,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.glassBorder, height: 1),

                  // Nav list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      itemCount: _destinations.length,
                      itemBuilder: (context, index) {
                        final dest = _destinations[index];
                        final isSelected = _selectedSection == index;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              dense: true,
                              leading: Icon(
                                dest.icon,
                                color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                                size: 20,
                              ),
                              title: Text(
                                dest.title,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => setState(() => _selectedSection = index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Admin Card & Logout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border(top: BorderSide(color: AppColors.glassBorder)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.shield_rounded, size: 16, color: AppColors.primaryLight),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AuthService.instance.currentUser?.name ?? 'Admin',
                                style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Role: ADMIN',
                                style: TextStyle(
                                  color: AppColors.liveGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textMuted),
                          onPressed: _handleLogout,
                          tooltip: 'Exit to PLAZA App',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  backgroundColor: AppColors.surfaceCard,
                  elevation: 0,
                  title: Text(currentTitle, style: AppTypography.headingMedium),
                  actions: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const PlazaNavigationShell()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.phone_iphone_rounded, size: 16, color: AppColors.textSecondary),
                      label: Text(
                        'View Consumer App',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                body: _buildSelectedView(),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout with Drawer
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        title: Text(currentTitle, style: AppTypography.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.textMuted),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.surfaceCard,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accentAmber],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PLAZA ADMIN', style: AppTypography.headingMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Operations Console',
                        style: TextStyle(color: AppColors.accentAmber, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final dest = _destinations[index];
                  final isSelected = _selectedSection == index;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: Icon(
                          dest.icon,
                          color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                          size: 20,
                        ),
                        title: Text(
                          dest.title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedSection = index);
                          Navigator.of(context).pop(); // Close drawer
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: AppColors.glassBorder, height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.alertRed),
              title: const Text('Exit Admin Console', style: TextStyle(color: AppColors.alertRed, fontWeight: FontWeight.w600)),
              onTap: _handleLogout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      body: _buildSelectedView(),
    );
  }
}

class _NavDestination {
  final String title;
  final IconData icon;

  const _NavDestination(this.title, this.icon);
}
