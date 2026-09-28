import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/integration_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminIntegrationsView extends StatefulWidget {
  final AdminRepository? repository;

  const AdminIntegrationsView({super.key, this.repository});

  @override
  State<AdminIntegrationsView> createState() => _AdminIntegrationsViewState();
}

class _AdminIntegrationsViewState extends State<AdminIntegrationsView> {
  late final AdminRepository _repo;
  bool _isLoading = true;
  String? _errorMessage;

  IntegrationHealthSummary? _health;
  List<IntegrationProviderInfo> _providers = [];
  List<IntegrationSyncRun> _syncRuns = [];
  String? _syncingProviderId;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final healthRes = await _repo.getIntegrationHealth();
      final providersRes = await _repo.getIntegrationProviders();
      final syncRunsRes = await _repo.getIntegrationSyncRuns(limit: 20);

      if (!mounted) return;

      setState(() {
        if (healthRes.isSuccess && healthRes.data != null) {
          _health = healthRes.data;
        }
        if (providersRes.isSuccess && providersRes.data != null) {
          _providers = providersRes.data!;
        }
        if (syncRunsRes.isSuccess && syncRunsRes.data != null) {
          _syncRuns = syncRunsRes.data!;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _triggerSync(String providerId) async {
    setState(() => _syncingProviderId = providerId);
    try {
      final res = await _repo.triggerIntegrationSync(providerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.isSuccess
              ? 'Synchronization triggered for $providerId'
              : (res.errorMessage ?? 'Sync failed')),
          backgroundColor: res.isSuccess ? AppColors.liveGreen : AppColors.alertRed,
        ),
      );
      await _loadData();
    } finally {
      if (mounted) setState(() => _syncingProviderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_errorMessage != null) _buildErrorBanner(),
          _buildMetricsGrid(),
          const SizedBox(height: 32),
          _buildSectionTitle('Registered Integration Providers', Icons.hub_rounded),
          const SizedBox(height: 16),
          _buildProvidersList(),
          const SizedBox(height: 32),
          _buildSectionTitle('Recent Synchronization Runs', Icons.history_rounded),
          const SizedBox(height: 16),
          _buildSyncRunsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final status = _health?.status ?? 'HEALTHY';
    final isHealthy = status == 'HEALTHY';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Integration Operations', style: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                'Real data normalization, adapter statuses, and truthful availability',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isHealthy ? AppColors.liveGreen : AppColors.warningOrange).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isHealthy ? AppColors.liveGreen : AppColors.warningOrange),
              ),
              child: Row(
                children: [
                  Icon(
                    isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
                    size: 14,
                    color: isHealthy ? AppColors.liveGreen : AppColors.warningOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: AppTypography.caption.copyWith(
                      color: isHealthy ? AppColors.liveGreen : AppColors.warningOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
              tooltip: 'Refresh Integrations',
              onPressed: _loadData,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.alertRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.alertRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.caption.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final total = _health?.totalProviders ?? _providers.length;
    final active = _health?.activeProviders ?? _providers.where((p) => p.isEnabled).length;
    final configured = _health?.configuredProviders ?? _providers.where((p) => p.isConfigured).length;
    final unconfigured = _health?.unconfiguredProviders ?? _providers.where((p) => !p.isConfigured).length;

    return Row(
      children: [
        Expanded(child: _buildMetricCard('Total Adapters', total.toString(), Icons.layers_rounded, AppColors.secondaryIndigo)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Live / Active', active.toString(), Icons.bolt_rounded, AppColors.liveGreen)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Configured', configured.toString(), Icons.settings_suggest_rounded, AppColors.accentAmber)),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard('Disabled (No Keys)', unconfigured.toString(), Icons.lock_clock_rounded, AppColors.textMuted)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.headingLarge.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: AppTypography.headingMedium.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildProvidersList() {
    if (_providers.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('No integration adapters registered', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        ),
      );
    }

    return Column(
      children: _providers.map((p) => _buildProviderCard(p)).toList(),
    );
  }

  Widget _buildProviderCard(IntegrationProviderInfo p) {
    final isSyncing = _syncingProviderId == p.providerId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (p.isEnabled ? AppColors.liveGreen : AppColors.secondaryIndigo).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                p.providerType == 'INTERNAL_PARTNER'
                    ? Icons.storefront_rounded
                    : p.providerType == 'ADMIN_CURATED'
                        ? Icons.verified_user_rounded
                        : Icons.cloud_sync_rounded,
                color: p.isEnabled ? AppColors.liveGreen : AppColors.secondaryIndigo,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.providerName,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.glassFillMedium,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.vertical.toUpperCase(),
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Configured: ${p.isConfigured ? "YES" : "NO"}',
                        style: AppTypography.caption.copyWith(
                          color: p.isConfigured ? AppColors.liveGreen : AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Enabled: ${p.isEnabled ? "YES" : "NO"}',
                        style: AppTypography.caption.copyWith(
                          color: p.isEnabled ? AppColors.liveGreen : AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      if (p.errorSummary != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.errorSummary!,
                            style: AppTypography.caption.copyWith(color: AppColors.warningOrange, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: isSyncing ? null : () => _triggerSync(p.providerId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: isSyncing
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync_rounded, size: 14),
              label: Text(isSyncing ? 'Syncing...' : 'Sync Now', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncRunsList() {
    if (_syncRuns.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text('No synchronization runs recorded yet', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _syncRuns.length,
        separatorBuilder: (_, _) => const Divider(color: AppColors.glassBorderSubtle, height: 16),
        itemBuilder: (context, idx) {
          final run = _syncRuns[idx];
          final isSuccess = run.status == 'SUCCESS';
          final isPartial = run.status == 'PARTIAL';

          return Row(
            children: [
              Icon(
                isSuccess
                    ? Icons.check_circle_rounded
                    : isPartial
                        ? Icons.info_outline_rounded
                        : Icons.error_rounded,
                color: isSuccess
                    ? AppColors.liveGreen
                    : isPartial
                        ? AppColors.warningOrange
                        : AppColors.alertRed,
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${run.provider} (${run.vertical})',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Read: ${run.recordsRead} | Created: ${run.recordsCreated} | Updated: ${run.recordsUpdated} | Failed: ${run.recordsFailed}',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                run.status,
                style: AppTypography.caption.copyWith(
                  color: isSuccess
                      ? AppColors.liveGreen
                      : isPartial
                          ? AppColors.warningOrange
                          : AppColors.alertRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
