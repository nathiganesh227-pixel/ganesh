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
  List<UnifiedIncidentItem> _incidents = [];
  ReconciliationDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedType = 'ALL';
  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _types = ['ALL', 'RECOVERY', 'RECONCILIATION', 'WEBHOOK'];

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final dashFuture = _repo.getReconciliationDashboard();
    final incFuture = _repo.getUnifiedIncidents(
      type: _selectedType,
      status: _selectedStatus,
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
    );

    final results = await Future.wait([dashFuture, incFuture]);
    if (!mounted) return;

    final dashRes = results[0] as dynamic;
    final incRes = results[1] as dynamic;

    ReconciliationDashboardData? dashData;
    if (dashRes.isSuccess && dashRes.data != null) {
      dashData = dashRes.data as ReconciliationDashboardData;
    }

    List<UnifiedIncidentItem> incList = [];
    if (incRes.isSuccess && incRes.data != null) {
      incList = incRes.data as List<UnifiedIncidentItem>;
    } else {
      // Mock / fallback
      incList = [
        UnifiedIncidentItem(
          id: 'rec_sim_1',
          type: 'RECOVERY',
          title: 'Payment Recovery: UNKNOWN_PROVIDER_OUTCOME',
          description: 'Gateway request timed out during authorization capture',
          status: 'REQUIRED',
          severity: 'HIGH',
          referenceId: 'pay_sim_101',
          paymentId: 'pay_sim_101',
          bookingId: 'bk_sim_101',
          failureCategory: 'UNKNOWN_PROVIDER_OUTCOME',
          requiresManualIntervention: true,
          createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
        UnifiedIncidentItem(
          id: 'recon_sim_2',
          type: 'RECONCILIATION',
          title: 'Reconciliation: AMOUNT_MISMATCH',
          description: 'Canonical amount 1500 INR does not match observed provider amount 1200 INR',
          status: 'REQUIRED',
          severity: 'HIGH',
          referenceId: 'pay_sim_202',
          paymentId: 'pay_sim_202',
          bookingId: 'bk_sim_202',
          mismatchCategory: 'AMOUNT_MISMATCH',
          requiresManualIntervention: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
    }

    setState(() {
      _dashboardData = dashData;
      _incidents = incList;
      _isLoading = false;
      if (!incRes.isSuccess && incRes.errorMessage != null && !incRes.errorMessage!.contains('200')) {
        _errorMessage = incRes.errorMessage;
      }
    });
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RESOLVED':
      case 'PROCESSED':
        return AppColors.liveGreen;
      case 'REQUIRED':
      case 'FAILED':
        return AppColors.alertRed;
      case 'IN_PROGRESS':
      case 'PROCESSING':
        return AppColors.warningOrange;
      default:
        return AppColors.textTertiary;
    }
  }

  void _showIncidentDetails(UnifiedIncidentItem inc) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          inc.title,
                          style: AppTypography.headingMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(inc.severity).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inc.severity.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getSeverityColor(inc.severity),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusColor(inc.status).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inc.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(inc.status),
                          ),
                        ),
                      ),
                      if (inc.requiresManualIntervention)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.alertRed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'MANUAL ACTION REQUIRED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.alertRed),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),

                  // Metadata summary
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Incident ID: ${inc.id}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.accentGold)),
                          const SizedBox(height: 6),
                          if (inc.paymentId != null)
                            Text('Payment ID: ${inc.paymentId}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textSecondary)),
                          if (inc.bookingId != null)
                            Text('Booking ID: ${inc.bookingId}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          Text('Description', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(inc.description, style: AppTypography.bodySmall),
                          ),
                          const SizedBox(height: 16),
                          Text('Operational Guidelines & Safety', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Simulation Active: Real money processing = ZERO. State machine transitions are strictly enforced. Manual resolutions must follow canonical transition laws.',
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                      if (inc.status != 'RESOLVED') ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _showResolveDialog(inc);
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                          label: const Text('Resolve Incident'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.liveGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResolveDialog(UnifiedIncidentItem inc) {
    final notesController = TextEditingController();
    String selectedAction = 'MANUAL_RESOLUTION';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Resolve Incident: ${inc.id}', style: AppTypography.headingMedium),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provide an administrative resolution note. All actions are strictly validated and logged in the immutable audit registry.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedAction,
                      decoration: InputDecoration(
                        labelText: 'Resolution Action',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'MANUAL_RESOLUTION', child: Text('Standard Manual Resolution')),
                        DropdownMenuItem(value: 'VERIFIED_GATEWAY_SETTLEMENT', child: Text('Verified Gateway Settlement')),
                        DropdownMenuItem(value: 'RETRY_CONFIRMED', child: Text('Retry Succeeded & Confirmed')),
                        DropdownMenuItem(value: 'OPERATOR_DISMISSED', child: Text('Operator Dismissed')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedAction = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      style: AppTypography.bodyMedium,
                      decoration: InputDecoration(
                        labelText: 'Resolution Notes *',
                        hintText: 'e.g. Verified settlement ID with gateway operator log...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final notes = notesController.text.trim();
                    final messenger = ScaffoldMessenger.of(context);
                    if (notes.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Resolution notes are required')),
                      );
                      return;
                    }
                    Navigator.of(ctx).pop();
                    setState(() => _isLoading = true);

                    final res = await _repo.resolveUnifiedIncident(
                      inc.id,
                      action: selectedAction,
                      notes: notes,
                    );

                    if (mounted) {
                      if (res.isSuccess) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Incident resolved successfully')),
                        );
                      } else {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Resolution failed: ${res.errorMessage ?? "Unknown error"}')),
                        );
                      }
                      _loadAll();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.liveGreen),
                  child: const Text('Confirm Resolution'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassCard(
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
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTypography.headingLarge.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dash = _dashboardData;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Admin Incident Center', style: AppTypography.headingLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Unified operational console for payment recovery, reconciliation mismatches, and webhook anomalies.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _loadAll,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh Incidents',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // KPI Summary Cards
            if (dash != null)
              Row(
                children: [
                  _buildKPICard(
                    'Manual Action Needed',
                    '${dash.manualInterventionRequired}',
                    Icons.warning_rounded,
                    dash.manualInterventionRequired > 0 ? AppColors.alertRed : AppColors.liveGreen,
                  ),
                  const SizedBox(width: 12),
                  _buildKPICard(
                    'Recovery Active',
                    '${(dash.recovery['required'] ?? 0) + (dash.recovery['inProgress'] ?? 0)}',
                    Icons.healing_rounded,
                    AppColors.warningOrange,
                  ),
                  const SizedBox(width: 12),
                  _buildKPICard(
                    'Recon Discrepancies',
                    '${(dash.reconciliation['required'] ?? 0) + (dash.reconciliation['inProgress'] ?? 0)}',
                    Icons.compare_arrows_rounded,
                    AppColors.secondaryIndigo,
                  ),
                  const SizedBox(width: 12),
                  _buildKPICard(
                    'Webhook Anomalies',
                    '${(dash.webhooks['failed'] ?? 0) + (dash.webhooks['ignored'] ?? 0)}',
                    Icons.webhook_rounded,
                    AppColors.accentGold,
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Search Bar & Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _loadAll(),
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search by incident ID, payment ID, booking ID, or description...',
                      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadAll();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accentGold)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _types.map((t) {
                  final isSelected = _selectedType == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        t,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.accentGold,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: isSelected ? AppColors.accentGold : AppColors.border),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedType = t);
                          _loadAll();
                        }
                      },
                    ),
                  );
                }).toList(),
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
                  final statusColor = _getStatusColor(inc.status);

                  return InkWell(
                    onTap: () => _showIncidentDetails(inc),
                    borderRadius: BorderRadius.circular(16),
                    child: GlassCard(
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
                            child: Icon(
                              inc.type == 'RECONCILIATION'
                                  ? Icons.compare_arrows_rounded
                                  : inc.type == 'WEBHOOK'
                                      ? Icons.webhook_rounded
                                      : Icons.healing_rounded,
                              color: sevColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        inc.title,
                                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        inc.status.toUpperCase(),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  inc.description,
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'ID: ${inc.id}',
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.accentGold),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Ref: ${inc.referenceId}',
                                      style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                                    ),
                                    if (inc.requiresManualIntervention) ...[
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.alertRed.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'MANUAL ACTION',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.alertRed),
                                        ),
                                      ),
                                    ],
                                  ],
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
          ],
        ),
      ),
    );
  }
}
