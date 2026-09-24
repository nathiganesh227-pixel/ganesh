import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/data/plaza_global_state.dart';
import '../../core/models/notification.dart';
import '../../core/widgets/glass_card.dart';

class NotificationsModal extends StatefulWidget {
  const NotificationsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsModal(),
    );
  }

  @override
  State<NotificationsModal> createState() => _NotificationsModalState();
}

class _NotificationsModalState extends State<NotificationsModal> {
  PlazaNotificationCategory _selectedCategory = PlazaNotificationCategory.all;

  Color _getCategoryColor(PlazaNotificationCategory cat) {
    switch (cat) {
      case PlazaNotificationCategory.all:
        return AppColors.textPrimary;
      case PlazaNotificationCategory.bookings:
        return AppColors.primary;
      case PlazaNotificationCategory.deals:
        return AppColors.accentAmber;
      case PlazaNotificationCategory.plans:
        return const Color(0xFF8B5CF6);
      case PlazaNotificationCategory.rewards:
        return AppColors.accentGold;
      case PlazaNotificationCategory.alerts:
        return AppColors.liveGreen;
    }
  }

  IconData _getCategoryIcon(PlazaNotificationCategory cat) {
    switch (cat) {
      case PlazaNotificationCategory.all:
        return Icons.notifications_rounded;
      case PlazaNotificationCategory.bookings:
        return Icons.confirmation_number_rounded;
      case PlazaNotificationCategory.deals:
        return Icons.local_offer_rounded;
      case PlazaNotificationCategory.plans:
        return Icons.auto_awesome_rounded;
      case PlazaNotificationCategory.rewards:
        return Icons.stars_rounded;
      case PlazaNotificationCategory.alerts:
        return Icons.bolt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlazaGlobalState.instance,
      builder: (context, _) {
        final state = PlazaGlobalState.instance;

        var list = state.notifications;
        if (_selectedCategory != PlazaNotificationCategory.all) {
          list = list.where((n) => n.category == _selectedCategory).toList();
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: AppColors.glassBorder, width: 1.2)),
          ),
          child: Column(
            children: [
              // Top drag bar
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NOTIFICATIONS', style: AppTypography.labelSmall.copyWith(letterSpacing: 1.2)),
                          Text('Inbox & Alerts', style: AppTypography.headingLarge),
                        ],
                      ),
                    ),
                    if (state.unreadNotificationsCount > 0)
                      TextButton(
                        onPressed: () => state.markAllNotificationsAsRead(),
                        child: Text(
                          'Mark all read',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),

              // Filter Pills Bar
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: PlazaNotificationCategory.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = PlazaNotificationCategory.values[index];
                    final isSelected = _selectedCategory == cat;
                    final color = _getCategoryColor(cat);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.2)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : AppColors.glassBorder,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(cat),
                              size: 14,
                              color: isSelected ? color : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.label,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Notifications List
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_off_outlined,
                              size: 44,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No notifications in this category',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final notif = list[index];
                          final icon = _getCategoryIcon(notif.category);
                          final color = _getCategoryColor(notif.category);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                state.markNotificationAsRead(notif.id);
                              },
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                borderColor: notif.isRead
                                    ? AppColors.glassBorderSubtle
                                    : color.withValues(alpha: 0.4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(icon, color: color, size: 20),
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
                                                  notif.title,
                                                  style: AppTypography.headingSmall.copyWith(
                                                    fontSize: 14,
                                                    fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                notif.timeAgo,
                                                style: AppTypography.bodySmall.copyWith(
                                                  fontSize: 10,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif.message,
                                            style: AppTypography.bodySmall.copyWith(
                                              color: notif.isRead ? AppColors.textMuted : AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!notif.isRead) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 6),
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
