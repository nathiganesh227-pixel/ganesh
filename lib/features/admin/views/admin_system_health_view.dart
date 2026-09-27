import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminSystemHealthView extends StatefulWidget {
  final AdminRepository? repository;

  const AdminSystemHealthView({super.key, this.repository});

  @override
  State<AdminSystemHealthView> createState() => _AdminSystemHealthViewState();
}

class _AdminSystemHealthViewState extends State<AdminSystemHealthView> {
  late final AdminRepository _repo;
  AdminSystemHealth _health = const AdminSystemHealth();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadHealth();
  }

  Future<void> _loadHealth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _repo.getSystemHealth();
    if (!mounted) return;

    if (res.isSuccess && res.data != null) {
      setState(() {
        _health = res.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _health = const AdminSystemHealth();
        _isLoading = false;
        if (res.errorMessage != null && !res.errorMessage!.contains('200')) {
          _errorMessage = res.errorMessage;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHealthy = _health.status.toUpperCase() == 'HEALTHY';
    final isLivePayment = _health.paymentMode.toUpperCase() == 'LIVE';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
          : SingleChildScrollView(
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
                    Text('System Health & Infrastructure', style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Live telemetry for backend API, PostgreSQL database, and active gateway environments.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: _loadHealth,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh Health Telemetry',
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
                    Expanded(
                      child: Text(_errorMessage!, style: AppTypography.caption.copyWith(color: AppColors.alertRed)),
                    ),
                  ],
                ),
              ),

            // Overall Status Banner
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: (isHealthy ? AppColors.liveGreen : AppColors.alertRed).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
                      color: isHealthy ? AppColors.liveGreen : AppColors.alertRed,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHealthy ? 'All Systems Operational' : 'Degraded System Performance',
                          style: AppTypography.headingMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Environment: ${_health.environment.toUpperCase()} • System Uptime: ${_formatUptime(_health.uptimeSeconds)}',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isHealthy ? AppColors.liveGreen : AppColors.alertRed).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _health.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isHealthy ? AppColors.liveGreen : AppColors.alertRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Telemetry Grid
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // 1. API Service
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.dns_rounded, color: AppColors.accentGold, size: 28),
                          _buildStatusPill(_health.apiStatus),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NestJS REST API', style: AppTypography.headingSmall),
                          const SizedBox(height: 4),
                          Text(
                            'Port 3000 • Production Cluster',
                            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Database Service
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.storage_rounded, color: AppColors.secondaryCyan, size: 28),
                          _buildStatusPill(_health.dbStatus),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PostgreSQL Database', style: AppTypography.headingSmall),
                          const SizedBox(height: 4),
                          Text(
                            'Latency: ${_health.dbLatencyMs} ms • 17 Entities Connected',
                            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Payment Gateway Mode
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded, color: AppColors.warningOrange, size: 28),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isLivePayment ? AppColors.liveGreen : AppColors.warningOrange).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _health.paymentMode,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isLivePayment ? AppColors.liveGreen : AppColors.warningOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_health.paymentProvider.toUpperCase()} Adapter', style: AppTypography.headingSmall),
                          const SizedBox(height: 4),
                          Text(
                            _health.paymentWebhookConfigured
                                ? 'HMAC-SHA256 Webhook Active'
                                : 'Webhook Verification Standby',
                            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final isUp = status.toUpperCase() == 'UP';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isUp ? AppColors.liveGreen : AppColors.alertRed).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isUp ? AppColors.liveGreen : AppColors.alertRed,
        ),
      ),
    );
  }

  String _formatUptime(int seconds) {
    if (seconds <= 0) return '0s';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    if (mins > 0) return '${mins}m ${secs}s';
    return '${secs}s';
  }
}
