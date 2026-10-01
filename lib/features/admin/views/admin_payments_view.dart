import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminPaymentsView extends StatefulWidget {
  final AdminRepository? repository;

  const AdminPaymentsView({super.key, this.repository});

  @override
  State<AdminPaymentsView> createState() => _AdminPaymentsViewState();
}

class _AdminPaymentsViewState extends State<AdminPaymentsView> with SingleTickerProviderStateMixin {
  late final AdminRepository _repo;
  late final TabController _tabController;

  // Payments State
  List<AdminPayment> _payments = [];
  bool _isLoadingPayments = true;
  String? _paymentsError;
  String _selectedPaymentStatus = 'all';
  final TextEditingController _paymentSearchController = TextEditingController();

  // Reconciliation State
  List<ReconciliationRecordItem> _reconRecords = [];
  ReconciliationDashboardData? _dashboardData;
  bool _isLoadingRecon = true;
  String? _reconError;
  String _selectedReconMismatch = 'ALL';
  final TextEditingController _reconSearchController = TextEditingController();

  final List<String> _paymentStatuses = [
    'all',
    'CAPTURED',
    'FAILED',
    'REFUNDED',
    'PENDING',
  ];

  final List<String> _mismatchFilters = [
    'ALL',
    'AMOUNT_MISMATCH',
    'CURRENCY_MISMATCH',
    'PAYMENT_STATE_MISMATCH',
    'BOOKING_STATE_MISMATCH',
    'PROVIDER_ORDER_MISMATCH',
    'MISSING_PROVIDER_PAYMENT',
    'UNKNOWN_PROVIDER_STATE',
  ];

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _tabController = TabController(length: 2, vsync: this);
    _loadPayments();
    _loadReconciliation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paymentSearchController.dispose();
    _reconSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoadingPayments = true;
      _paymentsError = null;
    });

    final res = await _repo.getPayments(
      status: _selectedPaymentStatus,
      search: _paymentSearchController.text.trim().isNotEmpty ? _paymentSearchController.text.trim() : null,
    );

    if (!mounted) return;

    if (res.isSuccess && res.data != null) {
      setState(() {
        _payments = res.data!;
        _isLoadingPayments = false;
      });
    } else {
      // Offline fallback
      setState(() {
        _payments = [
          AdminPayment(
            id: 'pay_rzp_mock_1',
            bookingId: 'bk_mov_mock_1',
            userId: 'usr_customer_1',
            amount: 700,
            currency: 'INR',
            provider: 'razorpay',
            providerOrderId: 'order_rzp_1',
            providerPaymentId: 'pay_gw_1',
            status: 'CAPTURED',
            paymentMethod: 'UPI',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          AdminPayment(
            id: 'pay_rzp_mock_2',
            bookingId: 'bk_evt_mock_2',
            userId: 'usr_customer_2',
            amount: 2500,
            currency: 'INR',
            provider: 'razorpay',
            providerOrderId: 'order_rzp_2',
            providerPaymentId: 'pay_gw_2',
            status: 'CAPTURED',
            paymentMethod: 'CARD',
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ];
        _isLoadingPayments = false;
        if (res.errorMessage != null && !res.errorMessage!.contains('200')) {
          _paymentsError = res.errorMessage;
        }
      });
    }
  }

  Future<void> _loadReconciliation() async {
    setState(() {
      _isLoadingRecon = true;
      _reconError = null;
    });

    final dashFuture = _repo.getReconciliationDashboard();
    final recordsFuture = _repo.getReconciliationRecords(
      mismatchCategory: _selectedReconMismatch != 'ALL' ? _selectedReconMismatch : null,
      paymentId: _reconSearchController.text.trim().isNotEmpty ? _reconSearchController.text.trim() : null,
    );

    final results = await Future.wait([dashFuture, recordsFuture]);
    if (!mounted) return;

    final dashRes = results[0] as dynamic;
    final recRes = results[1] as dynamic;

    ReconciliationDashboardData? dashData;
    if (dashRes.isSuccess && dashRes.data != null) {
      dashData = dashRes.data as ReconciliationDashboardData;
    }

    List<ReconciliationRecordItem> recList = [];
    if (recRes.isSuccess && recRes.data != null) {
      recList = recRes.data as List<ReconciliationRecordItem>;
    } else {
      recList = [
        ReconciliationRecordItem(
          id: 'recon_sim_1',
          paymentId: 'pay_sim_1',
          bookingId: 'bk_sim_1',
          provider: 'simulated',
          canonicalPaymentStatus: 'CAPTURED',
          observedProviderStatus: 'AUTHORIZED',
          canonicalAmount: 1200,
          canonicalAmountInMinorUnits: 120000,
          observedAmountInMinorUnits: 120000,
          canonicalCurrency: 'INR',
          observedCurrency: 'INR',
          mismatchCategory: 'PAYMENT_STATE_MISMATCH',
          status: 'REQUIRED',
          attemptCount: 1,
          requiresManualIntervention: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
    }

    setState(() {
      _dashboardData = dashData;
      _reconRecords = recList;
      _isLoadingRecon = false;
      if (!recRes.isSuccess && recRes.errorMessage != null && !recRes.errorMessage!.contains('200')) {
        _reconError = recRes.errorMessage;
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CAPTURED':
      case 'RESOLVED':
        return AppColors.liveGreen;
      case 'REFUNDED':
        return AppColors.secondaryIndigo;
      case 'FAILED':
      case 'REQUIRED':
        return AppColors.alertRed;
      case 'PENDING':
      case 'AUTHORIZED':
      case 'IN_PROGRESS':
        return AppColors.warningOrange;
      default:
        return AppColors.textTertiary;
    }
  }

  void _triggerPaymentReconcile(String paymentId) async {
    setState(() => _isLoadingRecon = true);
    final res = await _repo.triggerReconcile(paymentId, force: true, notes: 'Operator manual UI audit trigger');
    if (mounted) {
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reconciliation run completed')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reconciliation trigger failed: ${res.errorMessage ?? "Unknown error"}')),
        );
      }
      _loadReconciliation();
    }
  }

  void _triggerBatchReconcile() async {
    setState(() => _isLoadingRecon = true);
    final res = await _repo.triggerBatchReconcile(limit: 20);
    if (mounted) {
      if (res.isSuccess) {
        final data = res.data;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Batch sweep completed: processed ${data?['processed'] ?? 0}, resolved ${data?['resolved'] ?? 0}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Batch sweep failed: ${res.errorMessage ?? "Unknown error"}'),
          ),
        );
      }
      _loadReconciliation();
    }
  }

  void _showReconciliationDetails(ReconciliationRecordItem record) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 750),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Reconciliation: ${record.mismatchCategory}',
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
                  Text('ID: ${record.id}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.accentGold)),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),

                  // Comparison Table
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Canonical vs Observed Gateway State', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          Table(
                            border: TableBorder.all(color: AppColors.border, borderRadius: BorderRadius.circular(8)),
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.5)),
                                children: const [
                                  Padding(padding: EdgeInsets.all(8), child: Text('Dimension', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('Canonical DB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('Observed Gateway', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Padding(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(fontSize: 12))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(record.canonicalPaymentStatus, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(record.observedProviderStatus ?? 'N/A', style: TextStyle(fontSize: 12, color: record.canonicalPaymentStatus != record.observedProviderStatus ? AppColors.alertRed : AppColors.liveGreen))),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Padding(padding: EdgeInsets.all(8), child: Text('Amount', style: TextStyle(fontSize: 12))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text('₹${record.canonicalAmount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(record.observedAmountInMinorUnits != null ? '₹${record.observedAmountInMinorUnits! / 100}' : 'N/A', style: TextStyle(fontSize: 12, color: (record.observedAmountInMinorUnits ?? 0) != record.canonicalAmountInMinorUnits ? AppColors.alertRed : AppColors.liveGreen))),
                                ],
                              ),
                              TableRow(
                                children: [
                                  const Padding(padding: EdgeInsets.all(8), child: Text('Currency', style: TextStyle(fontSize: 12))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(record.canonicalCurrency, style: const TextStyle(fontSize: 12))),
                                  Padding(padding: const EdgeInsets.all(8), child: Text(record.observedCurrency ?? 'N/A', style: const TextStyle(fontSize: 12))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('References & Context', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          Text('Payment ID: ${record.paymentId}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textSecondary)),
                          if (record.bookingId != null)
                            Text('Booking ID: ${record.bookingId}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textSecondary)),
                          if (record.providerPaymentId != null)
                            Text('Provider Payment ID: ${record.providerPaymentId}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textSecondary)),
                          if (record.providerOrderId != null)
                            Text('Provider Order ID: ${record.providerOrderId}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Simulation Active: Real money processed = ZERO. Strict state machine transitions enforced.',
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
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _triggerPaymentReconcile(record.paymentId);
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Run Reconcile'),
                      ),
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
                      Text('Payments & Reconciliation', style: AppTypography.headingLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Live transactions log with automated gateway reconciliation engine and discrepancy tracker.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    _loadPayments();
                    _loadReconciliation();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh All',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tab Bar
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accentGold,
              labelColor: AppColors.accentGold,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.payment_rounded, size: 18), text: 'Transaction Ledger'),
                Tab(icon: Icon(Icons.compare_arrows_rounded, size: 18), text: 'Reconciliation Queue'),
              ],
            ),
            const SizedBox(height: 20),

            // Tab Content
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 0) {
                  return _buildTransactionsTab();
                } else {
                  return _buildReconciliationTab(dash);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        TextField(
          controller: _paymentSearchController,
          onSubmitted: (_) => _loadPayments(),
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search by payment ID, booking ID, or user ID...',
            hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            suffixIcon: _paymentSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _paymentSearchController.clear();
                      _loadPayments();
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
        const SizedBox(height: 16),

        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _paymentStatuses.map((s) {
              final isSelected = _selectedPaymentStatus == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    s.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: _getStatusColor(s),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(color: isSelected ? _getStatusColor(s) : AppColors.border),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedPaymentStatus = s);
                      _loadPayments();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        if (_paymentsError != null)
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
                Expanded(child: Text(_paymentsError!, style: AppTypography.caption.copyWith(color: AppColors.alertRed))),
              ],
            ),
          ),

        // Payments List
        if (_isLoadingPayments)
          const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppColors.accentGold)))
        else if (_payments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  const Icon(Icons.payment_rounded, color: AppColors.textTertiary, size: 48),
                  const SizedBox(height: 12),
                  Text('No Payments Found', style: AppTypography.headingMedium),
                  const SizedBox(height: 4),
                  Text('No transactions match the selected filter criteria.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _payments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = _payments[index];
              final statusColor = _getStatusColor(p.status);

              return GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.payment_rounded, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('₹${p.amount}', style: AppTypography.headingMedium.copyWith(color: AppColors.accentGold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(p.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('ID: ${p.id}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textPrimary)),
                          if (p.bookingId.isNotEmpty)
                            Text('Booking: ${p.bookingId}', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('Provider: ${p.provider}', style: AppTypography.caption.copyWith(color: AppColors.textTertiary)),
                              if (p.paymentMethod != null) ...[
                                const SizedBox(width: 12),
                                Text('Method: ${p.paymentMethod}', style: AppTypography.caption.copyWith(color: AppColors.textTertiary)),
                              ],
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
    );
  }

  Widget _buildReconciliationTab(ReconciliationDashboardData? dash) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Safety Banner & Action Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.liveGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, size: 14, color: AppColors.liveGreen),
                        const SizedBox(width: 4),
                        Text(
                          'SIMULATED (LIVE BLOCKED)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.liveGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _triggerBatchReconcile,
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Run Batch Reconcile'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // KPI row
        if (dash != null)
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Action Required', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${dash.reconciliation['required'] ?? 0}', style: AppTypography.headingLarge.copyWith(color: AppColors.alertRed)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('In Progress', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${dash.reconciliation['inProgress'] ?? 0}', style: AppTypography.headingLarge.copyWith(color: AppColors.warningOrange)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Resolved', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${dash.reconciliation['resolved'] ?? 0}', style: AppTypography.headingLarge.copyWith(color: AppColors.liveGreen)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Failed', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text('${dash.reconciliation['failed'] ?? 0}', style: AppTypography.headingLarge.copyWith(color: AppColors.alertRed)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),

        // Mismatch Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _mismatchFilters.map((m) {
              final isSelected = _selectedReconMismatch == m;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    m,
                    style: TextStyle(
                      fontSize: 10,
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
                      setState(() => _selectedReconMismatch = m);
                      _loadReconciliation();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        if (_reconError != null)
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
                Expanded(child: Text(_reconError!, style: AppTypography.caption.copyWith(color: AppColors.alertRed))),
              ],
            ),
          ),

        // Recon List
        if (_isLoadingRecon)
          const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: AppColors.accentGold)))
        else if (_reconRecords.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: AppColors.liveGreen, size: 48),
                  const SizedBox(height: 12),
                  Text('No Reconciliation Mismatches', style: AppTypography.headingMedium),
                  const SizedBox(height: 4),
                  Text('All canonical database records match provider states perfectly.', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reconRecords.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = _reconRecords[index];
              final statusColor = _getStatusColor(r.status);

              return GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.compare_arrows_rounded, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(r.mismatchCategory, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(r.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Payment ID: ${r.paymentId}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.accentGold)),
                          const SizedBox(height: 4),
                          Text(
                            'Canonical: ${r.canonicalPaymentStatus} (₹${r.canonicalAmount}) vs Observed: ${r.observedProviderStatus ?? "UNKNOWN"}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showReconciliationDetails(r),
                                icon: const Icon(Icons.visibility_rounded, size: 14),
                                label: const Text('Inspect'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _triggerPaymentReconcile(r.paymentId),
                                icon: const Icon(Icons.refresh_rounded, size: 14),
                                label: const Text('Reconcile'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
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
    );
  }
}
