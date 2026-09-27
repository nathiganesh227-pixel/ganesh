import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminNotificationsView extends StatefulWidget {
  final AdminRepository? repository;

  const AdminNotificationsView({super.key, this.repository});

  @override
  State<AdminNotificationsView> createState() => _AdminNotificationsViewState();
}

class _AdminNotificationsViewState extends State<AdminNotificationsView> {
  late final AdminRepository _repo;
  List<AdminNotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _repo.getNotifications();
    if (!mounted) return;

    if (res.isSuccess && res.data != null) {
      setState(() {
        _notifications = res.data!;
        _isLoading = false;
      });
    } else {
      // Mock fallback
      setState(() {
        _notifications = [
          AdminNotificationItem(
            id: 'notif_1',
            userId: 'usr_customer_1',
            title: 'Booking Confirmed: Pushpa 2',
            message: 'Your booking at AMB Cinemas is confirmed. Show QR pass at entrance.',
            type: 'booking',
            timeAgo: '15m ago',
            createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
          AdminNotificationItem(
            id: 'notif_2',
            userId: 'usr_customer_2',
            title: 'VIP Pass Active: Sunburn Arena',
            message: 'Your entry pass for Sunburn Arena Hyderabad is ready.',
            type: 'event',
            timeAgo: '1h ago',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ];
        _isLoading = false;
        if (res.errorMessage != null && !res.errorMessage!.contains('200')) {
          _errorMessage = res.errorMessage;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notification Delivery Logs', style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Customer delivery feed across SMS and in-app channels.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: _loadNotifications,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh Notifications',
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.alertRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.alertRed, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: AppTypography.caption.copyWith(color: AppColors.alertRed))),
                  ],
                ),
              ),

            // Notifications List
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppColors.accentGold)))
            else if (_notifications.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: AppColors.textTertiary, size: 48),
                      const SizedBox(height: 12),
                      Text('No Notifications Logged', style: AppTypography.headingMedium),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryIndigo.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: AppColors.secondaryIndigo, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(notif.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                  Text(notif.timeAgo, style: AppTypography.caption.copyWith(color: AppColors.textTertiary)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(notif.message, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text('Recipient: ${notif.userId}', style: AppTypography.caption.copyWith(color: AppColors.accentGold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
