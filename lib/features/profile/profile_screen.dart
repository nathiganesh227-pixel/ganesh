import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/data/movie_mock_data.dart';
import '../../core/data/dining_mock_data.dart';
import '../../core/data/activity_mock_data.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/plaza_image.dart';
import '../../core/widgets/section_header.dart';
import '../notifications/notifications_modal.dart';
import 'rewards_screen.dart';
import '../movies/movie_details_screen.dart';
import '../dining/restaurant_details_screen.dart';
import '../activities/activity_details_screen.dart';
import '../auth/login_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openRewards(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RewardsScreen(),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    NotificationsModal.show(context);
  }

  void _showPreferencesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: AppColors.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Preferences', style: AppTypography.headingLarge),
            const SizedBox(height: 16),
            _buildPrefRow('Default Metro', 'Hyderabad (TG)'),
            _buildPrefRow('Cinema Format Preference', 'IMAX 3D Laser & Dolby Atmos'),
            _buildPrefRow('Dining Style', 'Cocktails, Rooftops & Modern Indian'),
            _buildPrefRow('Language Preference', 'Telugu, English, Hindi'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildPrefRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Text(value, style: AppTypography.labelLarge.copyWith(color: AppColors.primaryLight)),
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text('Profile & Rewards', style: AppTypography.displayMedium),
                  const SizedBox(height: 20),

                  // User Info Glass Card
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppGradients.sunsetPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'PG',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(state.userName, style: AppTypography.headingMedium),
                              const SizedBox(height: 2),
                              Text(
                                '${state.userTier} • ${state.membershipId}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.accentAmber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                state.userEmail,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quick stats / Rewards preview (Tappable to Rewards Screen)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _openRewards(context),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('PLAZA COINS', style: AppTypography.labelSmall),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.accentGold),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${state.rewardsBalance}',
                                  style: AppTypography.headingLarge.copyWith(
                                    color: AppColors.accentGold,
                                  ),
                                ),
                                Text(
                                  '₹${(state.rewardsBalance * 0.1).toInt()} redeemable',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SAVINGS', style: AppTypography.labelSmall),
                              const SizedBox(height: 4),
                              Text(
                                '₹4,820',
                                style: AppTypography.headingLarge.copyWith(
                                  color: AppColors.liveGreen,
                                ),
                              ),
                              Text('Lifetime saved', style: AppTypography.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Menu actions
                  _buildMenuTile(
                    Icons.card_giftcard_rounded,
                    'Rewards & Vouchers',
                    '${state.vouchers.where((v) => !v.isRedeemed).length} available',
                    onTap: () => _openRewards(context),
                  ),
                  _buildMenuTile(
                    Icons.notifications_none_rounded,
                    'Notifications & Alerts',
                    state.unreadNotificationsCount > 0
                        ? '${state.unreadNotificationsCount} new'
                        : '',
                    onTap: () => _openNotifications(context),
                  ),
                  _buildMenuTile(
                    Icons.tune_rounded,
                    'Personal Preferences',
                    'Hyderabad',
                    onTap: () => _showPreferencesSheet(context),
                  ),

                  const SizedBox(height: 24),

                  // Saved Experiences / Favorites Section
                  SectionHeader(
                    title: 'Saved Favorites',
                    subtitle: '${state.favoriteIds.length} experiences saved',
                  ),
                  const SizedBox(height: 12),

                  // Horizontal favorites row
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildFavoriteCard(
                          context,
                          title: 'Dune: Part Two',
                          category: 'Movie',
                          imageUrl: MovieMockData.movies.first.posterUrl,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MovieDetailsScreen(movie: MovieMockData.movies.first),
                            ),
                          ),
                        ),
                        _buildFavoriteCard(
                          context,
                          title: 'Farzi Café',
                          category: 'Dining',
                          imageUrl: DiningMockData.restaurants.first.coverImageUrl,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantDetailsScreen(restaurant: DiningMockData.restaurants.first),
                            ),
                          ),
                        ),
                        _buildFavoriteCard(
                          context,
                          title: 'Runway 9 Karting',
                          category: 'Activity',
                          imageUrl: ActivityMockData.activities.first.coverImageUrl,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityDetailsScreen(activity: ActivityMockData.activities.first),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recently Viewed Section
                  if (state.recentlyViewed.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SectionHeader(
                            title: 'Recently Viewed',
                            subtitle: '${state.recentlyViewed.length} items',
                          ),
                        ),
                        TextButton(
                          onPressed: () => state.clearRecentlyViewed(),
                          child: Text(
                            'Clear',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: state.recentlyViewed.length,
                        itemBuilder: (context, index) {
                          final item = state.recentlyViewed[index];
                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 12),
                            child: GlassCard(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 50,
                                      height: double.infinity,
                                      child: PlazaImage(imageUrl: item.imageUrl, fit: BoxFit.cover),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item.title,
                                          style: AppTypography.labelLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          item.category,
                                          style: AppTypography.bodySmall.copyWith(fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.priceInfo,
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.accentGold,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // More Settings
                  _buildMenuTile(
                    Icons.account_circle_outlined,
                    'Account & Security',
                    'Sign In / Switch',
                    onTap: () => LoginSheet.show(context),
                  ),
                  _buildMenuTile(
                    Icons.security_rounded,
                    'Security & Biometrics',
                    'Face ID Active',
                    onTap: () {},
                  ),
                  _buildMenuTile(
                    Icons.support_agent_rounded,
                    '24/7 Concierge Support',
                    'Live Chat',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connecting to PLAZA Black Concierge Support...'),
                          backgroundColor: AppColors.surfaceCard,
                        ),
                      );
                    },
                  ),
                  _buildMenuTile(
                    Icons.description_outlined,
                    'Terms & Membership Conditions',
                    '',
                    onTap: () {},
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteCard(
    BuildContext context, {
    required String title,
    required String category,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: PlazaImage(imageUrl: imageUrl, fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      category,
                      style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted),
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

  Widget _buildMenuTile(IconData icon, String title, String trailing, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryLight),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title, style: AppTypography.labelLarge),
              ),
              if (trailing.isNotEmpty) ...[
                Text(
                  trailing,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
