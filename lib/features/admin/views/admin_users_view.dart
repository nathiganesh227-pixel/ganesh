import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminUsersView extends StatefulWidget {
  final AdminRepository? repository;

  const AdminUsersView({super.key, this.repository});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  late final AdminRepository _repo;
  List<AdminUser> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _repo.getUsers();
    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _users = res.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res.message ?? 'Failed to load user list.';
        _isLoading = false;
      });
    }
  }

  void _showChangeRoleDialog(AdminUser user) {
    String selectedRole = user.role.toLowerCase();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Change User Role: ${user.name}', style: AppTypography.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign operational access level for ${user.email}.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setDlgState(() => selectedRole = 'user'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedRole == 'user' ? AppColors.surfaceElevated : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedRole == 'user' ? AppColors.primary : AppColors.glassBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedRole == 'user' ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selectedRole == 'user' ? AppColors.primary : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customer (USER)', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('Standard consumer app access only', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => setDlgState(() => selectedRole = 'admin'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedRole == 'admin' ? AppColors.surfaceElevated : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedRole == 'admin' ? AppColors.primary : AppColors.glassBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedRole == 'admin' ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: selectedRole == 'admin' ? AppColors.primary : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Administrator (ADMIN)', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('Full console & catalog management rights', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
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
              onPressed: () async {
                Navigator.of(ctx).pop();
                final res = await _repo.updateUserRole(user.id, selectedRole);
                if (!mounted) return;

                if (res.success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated ${user.name} role to ${selectedRole.toUpperCase()}'),
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                  );
                  _loadUsers();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res.message ?? 'Failed to update role.'),
                      backgroundColor: AppColors.alertRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Save Role'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
                    Text('User Directory & Roles', style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Safe projections of registered members, reward points, and administrator roles.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryLight),
                tooltip: 'Refresh Users',
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ))
          else if (_errorMessage != null)
            Center(
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.alertRed)),
              ),
            )
          else if (_users.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No users found.', style: AppTypography.bodyMedium),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _users.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final u = _users[index];
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: u.isAdmin
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.secondaryBlue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: u.isAdmin ? AppColors.primaryLight : AppColors.secondaryBlue,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    u.name,
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: u.isAdmin
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : AppColors.secondaryBlue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: u.isAdmin
                                          ? AppColors.primary.withValues(alpha: 0.3)
                                          : AppColors.secondaryBlue.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    u.role.toUpperCase(),
                                    style: TextStyle(
                                      color: u.isAdmin ? AppColors.primaryLight : AppColors.secondaryBlue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              u.email,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${u.phone ?? "No phone"} • ${u.city ?? "Hyderabad"} • ${u.rewardPoints} pts',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.manage_accounts_outlined, size: 20, color: AppColors.textSecondary),
                        onPressed: () => _showChangeRoleDialog(u),
                        tooltip: 'Manage Role',
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
