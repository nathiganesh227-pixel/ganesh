import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminAuditLogsView extends StatefulWidget {
  final AdminRepository? repository;

  const AdminAuditLogsView({super.key, this.repository});

  @override
  State<AdminAuditLogsView> createState() => _AdminAuditLogsViewState();
}

class _AdminAuditLogsViewState extends State<AdminAuditLogsView> {
  late final AdminRepository _repo;
  List<AdminAuditLog> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _repo.getAuditLogs();
    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _logs = res.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res.message ?? 'Failed to load audit logs.';
        _isLoading = false;
      });
    }
  }

  Color _getActionColor(String action) {
    if (action.contains('CREATE')) return AppColors.liveGreen;
    if (action.contains('DELETE') || action.contains('CANCEL')) return AppColors.alertRed;
    if (action.contains('UNPUBLISH')) return AppColors.warningOrange;
    if (action.contains('PUBLISH')) return AppColors.liveGreen;
    if (action.contains('ROLE')) return AppColors.secondaryViolet;
    return AppColors.secondaryBlue;
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
                    Text('Security Audit Trail', style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Immutable chronological audit history of administrative operations.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadLogs,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryLight),
                tooltip: 'Refresh Audit Logs',
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
          else if (_logs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No audit logs recorded yet.', style: AppTypography.bodyMedium),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final log = _logs[index];
                final color = _getActionColor(log.action);
                final timeStr = '${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}';
                final dateStr = '${log.createdAt.year}-${log.createdAt.month.toString().padLeft(2, '0')}-${log.createdAt.day.toString().padLeft(2, '0')}';

                return GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              log.action,
                              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
                            ),
                          ),
                          Text(
                            '$dateStr $timeStr',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${log.resourceType}: ${log.resourceId}',
                        style: AppTypography.labelLarge.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Actor: ${log.actorEmail} (${log.actorUserId})',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      if (log.metadata != null && log.metadata!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            log.metadata.toString(),
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 10,
                              color: AppColors.textSecondary.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
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
