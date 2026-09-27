import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminRewardsView extends StatefulWidget {
  final AdminRepository? repository;

  const AdminRewardsView({super.key, this.repository});

  @override
  State<AdminRewardsView> createState() => _AdminRewardsViewState();
}

class _AdminRewardsViewState extends State<AdminRewardsView> {
  late final AdminRepository _repo;
  List<AdminUser> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _repo.getUsers();
    if (!mounted) return;

    if (res.isSuccess && res.data != null) {
      setState(() {
        _users = res.data!;
        _isLoading = false;
      });
    } else {
      // Mock fallback
      setState(() {
        _users = [
          const AdminUser(
            id: 'usr_customer_1',
            email: 'customer@plaza.app',
            name: 'Jane Customer',
            role: 'user',
            rewardPoints: 500,
          ),
          const AdminUser(
            id: 'usr_customer_2',
            email: 'gopi.ganesh@plaza.club',
            name: 'Gopi Ganesh',
            role: 'user',
            rewardPoints: 2480,
          ),
        ];
        _isLoading = false;
        if (res.errorMessage != null && !res.errorMessage!.contains('200')) {
          _errorMessage = res.errorMessage;
        }
      });
    }
  }

  Future<void> _showAdjustRewardsModal(AdminUser user) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Adjust Reward Points', style: AppTypography.headingMedium),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User: ${user.name} (${user.email})\nCurrent Balance: ${user.rewardPoints} points',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  style: AppTypography.bodyMedium,
                  decoration: const InputDecoration(
                    labelText: 'Points Delta (+ to grant, - to deduct)',
                    hintText: 'e.g. 100 or -50',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  style: AppTypography.bodyMedium,
                  decoration: const InputDecoration(
                    labelText: 'Mandatory Adjustment Reason',
                    hintText: 'e.g., Goodwill gesture for screening delay',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final amt = int.tryParse(amountController.text.trim());
                        final reason = reasonController.text.trim();

                        if (amt == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid numeric points value')),
                          );
                          return;
                        }

                        if (reason.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reason is required for audit logs')),
                          );
                          return;
                        }

                        setModalState(() => isSubmitting = true);
                        final res = await _repo.adjustUserRewards(user.id, amt, reason);
                        if (!mounted) return;

                        if (res.isSuccess) {
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reward points adjusted successfully: ${amt >= 0 ? '+$amt' : '$amt'}'),
                                backgroundColor: AppColors.liveGreen,
                              ),
                            );
                          }
                          _loadUsers();
                        } else {
                          setModalState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Adjustment failed: ${res.errorMessage}'),
                                backgroundColor: AppColors.alertRed,
                              ),
                            );
                          }
                        }
                      },
                child: const Text('Apply Adjustment', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;
    final isAdmin = currentUser?.isAdmin == true;

    final filteredUsers = _users.where((u) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
    }).toList();

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
                    Text('Rewards & Loyalty Operations', style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Manage customer reward point balances with mandatory justification and audit logging.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: _loadUsers,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh Users',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Filter by user name or email...',
                hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.accentGold),
                ),
              ),
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

            // Users List
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppColors.accentGold)))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredUsers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final u = filteredUsers[index];
                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.accentGold.withValues(alpha: 0.15),
                          child: Text(
                            u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                            style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.name, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('${u.email} • ${u.role.toUpperCase()}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${u.rewardPoints} pts', style: AppTypography.headingSmall.copyWith(color: AppColors.accentGold)),
                            const SizedBox(height: 4),
                            if (isAdmin)
                              ElevatedButton.icon(
                                onPressed: () => _showAdjustRewardsModal(u),
                                icon: const Icon(Icons.tune_rounded, size: 14),
                                label: const Text('Adjust'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: AppColors.accentGold,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
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
