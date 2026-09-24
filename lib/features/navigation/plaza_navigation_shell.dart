import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../bookings/bookings_screen.dart';
import '../plans/plans_screen.dart';
import '../profile/profile_screen.dart';

class PlazaNavigationShell extends StatefulWidget {
  const PlazaNavigationShell({super.key});

  @override
  State<PlazaNavigationShell> createState() => _PlazaNavigationShellState();
}

class _PlazaNavigationShellState extends State<PlazaNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onCategorySelect: (catType) {
              // Could switch or trigger filter
            },
            onBuildMyDayTap: () {
              setState(() => _currentIndex = 3); // Switch to Plans tab
            },
          ),
          const ExploreScreen(),
          const BookingsScreen(),
          const PlansScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildFloatingGlassDock(),
    );
  }

  Widget _buildFloatingGlassDock() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xB8090D18), // Deep frosted glass
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x70000000),
                  blurRadius: 32,
                  offset: Offset(0, 10),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.explore_rounded, Icons.explore_outlined, 'Home'),
                _buildNavItem(1, Icons.map_rounded, Icons.map_outlined, 'Explore'),
                _buildNavItem(2, Icons.confirmation_number_rounded, Icons.confirmation_number_outlined, 'Bookings'),
                _buildNavItem(3, Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'Plans'),
                _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0x35FF5E36),
                    Color(0x18FF8B3D),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0x50FF5E36),
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x30FF5E36),
                    blurRadius: 14,
                    offset: Offset(0, 0),
                  ),
                ],
              )
            : const BoxDecoration(
                color: Colors.transparent,
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
