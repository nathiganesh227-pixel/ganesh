import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminIncidentsView extends StatefulWidget {
  final AdminRepository? repository;

  const AdminIncidentsView({super.key, this.repository});

  @override
  State<AdminIncidentsView> createState() => _AdminIncidentsViewState();
}

class _AdminIncidentsViewState extends State<AdminIncidentsView> {
  late final AdminRepository _repo;
  List<AdminIncident> _incidents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _repo.getIncidents();
    if (!mounted) return;

    if (res.isSuccess && res.data != null) {
      setState(() {
        _incidents = res.data!;
        _isLoading = false;
      });
    } else {
      // Mock fallback
      setState(() {
        _incidents = [
          AdminIncident(
            id: 'inc_pay_mock_1',
            correlationId: 'order_rzp_mock_fail',
            severity: 'HIGH',
            source: 'PAYMENT_GATEWAY',
            title: 'Payment Gateway Authorization Decline',
            message: 'Customer issuing bank rejected transaction: insufficient funds.',
            resourceType: 'Payment',
            resourceId: 'pay_fail_202',
            bookingId: 'bk_fail_303',
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
          ),
        ];
        _isLoading = false;
        if (res.errorMessage != null && !res.errorMessage!.contains('200')) {
          _errorMessage = res.errorMessage;
        }
      });
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return AppColors.alertRed;
      case 'MEDIUM':
        return AppColors.warningOrange;
      default:
        return AppColors.secondaryIndigo;
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
                    Text('Incidents & Operational Errors', style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Live failure tracker with correlation IDs across payment gateways and booking engines.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: _loadIncidents,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh Incidents',
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

            // Incidents List
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppColors.accentGold)))
            else if (_incidents.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: AppColors.liveGreen, size: 48),
                      const SizedBox(height: 12),
                      Text('No Active Incidents', style: AppTypography.headingMedium),
                      const SizedBox(height: 4),
                      Text(
                        'All platform services are processing transactions smoothly without errors.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _incidents.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final inc = _incidents[index];
                  final sevColor = _getSeverityColor(inc.severity);

                  return GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: sevColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.warning_amber_rounded, color: sevColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(inc.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: sevColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      inc.severity.toUpperCase(),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sevColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(inc.message, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Correlation ID: ${inc.correlationId}',
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.accentGold),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Source: ${inc.source}',
                                    style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                                  ),
                                ],
                              ),
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
