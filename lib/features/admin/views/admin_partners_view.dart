import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/partner_models.dart';
import '../../../core/repositories/partner_repository.dart';
import '../../../core/repositories/api_partner_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminPartnersView extends StatefulWidget {
  final PartnerRepository? partnerRepository;

  const AdminPartnersView({super.key, this.partnerRepository});

  @override
  State<AdminPartnersView> createState() => _AdminPartnersViewState();
}

class _AdminPartnersViewState extends State<AdminPartnersView> {
  late final PartnerRepository _repo;
  List<PartnerProfile> _partners = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatusFilter = 'ALL';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repo = widget.partnerRepository ?? ApiPartnerRepository();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final statusParam = _selectedStatusFilter == 'ALL' ? null : _selectedStatusFilter.toLowerCase();
      final list = await _repo.adminListPartners(status: statusParam);
      if (!mounted) return;
      setState(() {
        _partners = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load partners: $e';
        _isLoading = false;
      });
    }
  }

  List<PartnerProfile> get _filteredPartners {
    if (_searchQuery.trim().isEmpty) return _partners;
    final q = _searchQuery.toLowerCase();
    return _partners.where((p) {
      return p.displayName.toLowerCase().contains(q) ||
          p.legalName.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q) ||
          p.city.toLowerCase().contains(q);
    }).toList();
  }

  Color _getStatusColor(PartnerStatus status) {
    switch (status) {
      case PartnerStatus.approved:
        return AppColors.liveGreen;
      case PartnerStatus.submitted:
      case PartnerStatus.underReview:
        return AppColors.accentGold;
      case PartnerStatus.suspended:
        return AppColors.warningOrange;
      case PartnerStatus.rejected:
      case PartnerStatus.closed:
        return AppColors.alertRed;
      case PartnerStatus.draft:
        return Colors.white54;
    }
  }

  Color _getTypeColor(PartnerType type) {
    switch (type) {
      case PartnerType.restaurant:
        return AppColors.accentGold;
      case PartnerType.eventOrganizer:
        return AppColors.secondaryViolet;
      case PartnerType.activityOperator:
        return AppColors.secondaryCyan;
      case PartnerType.hotel:
        return AppColors.secondaryIndigo;
      case PartnerType.sportsVenue:
        return AppColors.liveGreen;
    }
  }

  IconData _getTypeIcon(PartnerType type) {
    switch (type) {
      case PartnerType.restaurant:
        return Icons.restaurant_rounded;
      case PartnerType.eventOrganizer:
        return Icons.celebration_rounded;
      case PartnerType.activityOperator:
        return Icons.local_activity_rounded;
      case PartnerType.hotel:
        return Icons.hotel_rounded;
      case PartnerType.sportsVenue:
        return Icons.sports_tennis_rounded;
    }
  }

  void _showInspectPartnerSheet(PartnerProfile partner) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PartnerInspectionSheet(
        partner: partner,
        repository: _repo,
        onActionCompleted: () {
          _loadPartners();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadPartners,
        color: AppColors.accentGold,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Partner & Vendor Governance', style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Gate 1 legitimacy validation and Gate 2 listing publication review.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  onPressed: _loadPartners,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar & Filters
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search partners by name, legal entity, city...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accentGold),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final status in ['ALL', 'SUBMITTED', 'APPROVED', 'SUSPENDED', 'REJECTED', 'DRAFT'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(status),
                        selected: _selectedStatusFilter == status,
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedStatusFilter = status);
                            _loadPartners();
                          }
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.3),
                        checkmarkColor: AppColors.accentGold,
                        backgroundColor: AppColors.surfaceElevated,
                        labelStyle: TextStyle(
                          color: _selectedStatusFilter == status ? AppColors.accentGold : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: _selectedStatusFilter == status ? AppColors.accentGold : AppColors.glassBorder,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.accentGold),
                ),
              )
            else if (_errorMessage != null)
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.alertRed, size: 36),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: AppTypography.bodyMedium),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPartners,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_filteredPartners.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.store_mall_directory_outlined, color: Colors.white38, size: 48),
                      const SizedBox(height: 16),
                      Text('No Partners Found', style: AppTypography.headingMedium),
                      const SizedBox(height: 8),
                      Text(
                        _selectedStatusFilter == 'ALL'
                            ? 'No partner registrations match the search filter.'
                            : 'No partners with status "$_selectedStatusFilter".',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final partner in _filteredPartners)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vertical Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getTypeColor(partner.partnerType).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getTypeColor(partner.partnerType).withValues(alpha: 0.3)),
                          ),
                          child: Icon(
                            _getTypeIcon(partner.partnerType),
                            color: _getTypeColor(partner.partnerType),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Partner Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      partner.displayName,
                                      style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(partner.status).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _getStatusColor(partner.status)),
                                    ),
                                    child: Text(
                                      partner.status.name.toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(partner.status),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${partner.legalName} • ${partner.partnerType.displayName}',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 13, color: Colors.white38),
                                      const SizedBox(width: 4),
                                      Text(
                                        partner.city,
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.email_outlined, size: 13, color: Colors.white38),
                                      const SizedBox(width: 4),
                                      Text(
                                        partner.email,
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  if (partner.gstNumber != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.receipt_long_outlined, size: 13, color: Colors.white38),
                                        const SizedBox(width: 4),
                                        Text(
                                          'GST: ${partner.gstNumber}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Actions
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showInspectPartnerSheet(partner),
                          icon: const Icon(Icons.verified_user_outlined, size: 16),
                          label: const Text('Inspect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _PartnerInspectionSheet extends StatefulWidget {
  final PartnerProfile partner;
  final PartnerRepository repository;
  final VoidCallback onActionCompleted;

  const _PartnerInspectionSheet({
    required this.partner,
    required this.repository,
    required this.onActionCompleted,
  });

  @override
  State<_PartnerInspectionSheet> createState() => _PartnerInspectionSheetState();
}

class _PartnerInspectionSheetState extends State<_PartnerInspectionSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<PartnerDocument> _documents = [];
  List<PartnerBusinessListing> _businesses = [];
  PartnerPayoutProfile? _payout;
  late PartnerProfile _currentPartner;

  @override
  void initState() {
    super.initState();
    _currentPartner = widget.partner;
    _tabController = TabController(length: 3, vsync: this);
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final docs = await widget.repository.getDocuments(_currentPartner.id);
      final bizs = await widget.repository.getBusinesses(_currentPartner.id);
      final payout = await widget.repository.getPayoutProfile(_currentPartner.id);
      final profile = await widget.repository.getPartnerProfile(_currentPartner.id);

      if (mounted) {
        setState(() {
          _documents = docs;
          _businesses = bizs;
          _payout = payout;
          _currentPartner = profile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePartnerReview(String action) async {
    String? reason;
    if (action == 'reject' || action == 'suspend') {
      reason = await _promptReasonDialog(
        title: action == 'reject' ? 'Reject Partner Application' : 'Suspend Partner Access',
        actionLabel: action == 'reject' ? 'Confirm Rejection' : 'Confirm Suspension',
      );
      if (reason == null || reason.trim().isEmpty) return;
    }

    setState(() => _isLoading = true);
    try {
      if (action == 'suspend') {
        await widget.repository.adminSuspendPartner(_currentPartner.id, reason: reason!);
      } else if (action == 'resume') {
        await widget.repository.adminResumePartner(_currentPartner.id);
      } else {
        await widget.repository.adminReviewPartner(_currentPartner.id, action: action, reason: reason);
      }

      widget.onActionCompleted();
      await _loadDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Partner status updated to $action successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.alertRed),
        );
      }
    }
  }

  Future<void> _handleDocumentReview(PartnerDocument doc, String action) async {
    String? reason;
    if (action == 'reject') {
      reason = await _promptReasonDialog(
        title: 'Reject Document: ${doc.documentType}',
        actionLabel: 'Reject Document',
      );
      if (reason == null || reason.trim().isEmpty) return;
    }

    try {
      await widget.repository.adminReviewDocument(
        _currentPartner.id,
        doc.id,
        action: action,
        reason: reason,
      );
      widget.onActionCompleted();
      await _loadDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document ${doc.documentType} $action status saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.alertRed),
        );
      }
    }
  }

  Future<void> _handleListingReview(PartnerBusinessListing biz, String action) async {
    String? reason;
    if (action == 'reject') {
      reason = await _promptReasonDialog(
        title: 'Reject Listing: ${biz.name}',
        actionLabel: 'Reject Listing',
      );
      if (reason == null || reason.trim().isEmpty) return;
    }

    try {
      await widget.repository.adminReviewListing(
        _currentPartner.id,
        biz.id,
        action: action,
        reason: reason,
      );
      widget.onActionCompleted();
      await _loadDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Listing ${biz.name} $action status saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.alertRed),
        );
      }
    }
  }

  Future<String?> _promptReasonDialog({required String title, required String actionLabel}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: AppTypography.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please specify a formal justification recorded in the governance audit log:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Expired FSSAI certificate or missing venue license...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentPartner.displayName, style: AppTypography.headingMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${_currentPartner.legalName} • ${_currentPartner.partnerType.displayName}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Governance Status Banner & Quick Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AppColors.surfaceElevated,
            child: Row(
              children: [
                Text(
                  'GATE 1 STATUS: ${_currentPartner.status.name.toUpperCase()}',
                  style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Spacer(),
                if (_currentPartner.status == PartnerStatus.submitted || _currentPartner.status == PartnerStatus.draft) ...[
                  OutlinedButton(
                    onPressed: () => _handlePartnerReview('reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.alertRed,
                      side: const BorderSide(color: AppColors.alertRed),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handlePartnerReview('approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.liveGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Approve Gate 1', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ] else if (_currentPartner.status == PartnerStatus.approved) ...[
                  ElevatedButton.icon(
                    onPressed: () => _handlePartnerReview('suspend'),
                    icon: const Icon(Icons.pause_circle_outline, size: 16),
                    label: const Text('Suspend Partner', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warningOrange,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ] else if (_currentPartner.status == PartnerStatus.suspended) ...[
                  ElevatedButton.icon(
                    onPressed: () => _handlePartnerReview('resume'),
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: const Text('Resume Partner', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.liveGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accentGold,
            labelColor: AppColors.accentGold,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'Overview & Payout'),
              Tab(text: 'Gate 1: Documents'),
              Tab(text: 'Gate 2: Listings'),
            ],
          ),

          // Tab View Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accentGold))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Overview & Payout
                      _buildOverviewTab(),

                      // Tab 2: Documents (Gate 1)
                      _buildDocumentsTab(),

                      // Tab 3: Listings (Gate 2)
                      _buildListingsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard('Business Credentials', [
          _infoRow('Legal Name', _currentPartner.legalName),
          _infoRow('Display Name', _currentPartner.displayName),
          _infoRow('GST Number', _currentPartner.gstNumber ?? 'Not provided'),
          _infoRow('PAN Number', _currentPartner.panNumber ?? 'Not provided'),
          _infoRow('Official Email', _currentPartner.email),
          _infoRow('Phone', _currentPartner.phone),
          _infoRow('Address', '${_currentPartner.address}, ${_currentPartner.city}, ${_currentPartner.state} - ${_currentPartner.pinCode}'),
          if (_currentPartner.website != null) _infoRow('Website', _currentPartner.website!),
          if (_currentPartner.rejectionReason != null)
            _infoRow('Rejection Reason', _currentPartner.rejectionReason!, isAlert: true),
          if (_currentPartner.suspensionReason != null)
            _infoRow('Suspension Reason', _currentPartner.suspensionReason!, isAlert: true),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Settlement & Payout Profile', [
          if (_payout != null) ...[
            _infoRow('Account Holder', _payout!.accountHolderName),
            _infoRow('Bank Name', _payout!.bankName),
            _infoRow('Masked Account', _payout!.accountNumberMasked),
            _infoRow('IFSC Code', _payout!.ifscCode),
            _infoRow('Verification Status', _payout!.isVerified ? 'VERIFIED' : 'PENDING'),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No payout profile configured yet.', style: TextStyle(color: Colors.white54)),
            ),
        ]),
      ],
    );
  }

  Widget _buildDocumentsTab() {
    if (_documents.isEmpty) {
      return const Center(
        child: Text('No KYC / compliance documents uploaded yet.', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _documents.length,
      itemBuilder: (ctx, idx) {
        final doc = _documents[idx];
        final isApproved = doc.status.toLowerCase() == 'approved';
        final isRejected = doc.status.toLowerCase() == 'rejected';

        return Card(
          color: AppColors.surfaceElevated,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      doc.documentType.toUpperCase(),
                      style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isApproved
                                ? AppColors.liveGreen
                                : isRejected
                                    ? AppColors.alertRed
                                    : AppColors.accentGold)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doc.status.toUpperCase(),
                        style: TextStyle(
                          color: isApproved
                              ? AppColors.liveGreen
                              : isRejected
                                  ? AppColors.alertRed
                                  : AppColors.accentGold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('File: ${doc.fileName}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('URL: ${doc.fileUrl}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                if (doc.rejectionReason != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Rejection Reason: ${doc.rejectionReason}',
                    style: const TextStyle(color: AppColors.alertRed, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isRejected)
                      OutlinedButton(
                        onPressed: () => _handleDocumentReview(doc, 'reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.alertRed,
                          side: const BorderSide(color: AppColors.alertRed),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text('Reject Doc', style: TextStyle(fontSize: 11)),
                      ),
                    const SizedBox(width: 8),
                    if (!isApproved)
                      ElevatedButton(
                        onPressed: () => _handleDocumentReview(doc, 'approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.liveGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        ),
                        child: const Text('Approve Doc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListingsTab() {
    if (_businesses.isEmpty) {
      return const Center(
        child: Text('No business listings created yet.', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _businesses.length,
      itemBuilder: (ctx, idx) {
        final biz = _businesses[idx];
        final isApproved = biz.status.toLowerCase() == 'approved';
        final isPending = biz.status.toLowerCase() == 'pending_review';

        return Card(
          color: AppColors.surfaceElevated,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      biz.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isApproved
                                ? AppColors.liveGreen
                                : isPending
                                    ? AppColors.accentGold
                                    : AppColors.alertRed)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        biz.status.toUpperCase(),
                        style: TextStyle(
                          color: isApproved
                              ? AppColors.liveGreen
                              : isPending
                                  ? AppColors.accentGold
                                  : AppColors.alertRed,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Vertical: ${biz.vertical.toUpperCase()} • City: ${biz.city}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 6),
                Text(biz.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _handleListingReview(biz, 'reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.alertRed,
                        side: const BorderSide(color: AppColors.alertRed),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text('Reject Listing', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleListingReview(biz, 'approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.liveGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                      child: const Text('Approve Gate 2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      color: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(color: Colors.white12, height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isAlert ? AppColors.alertRed : Colors.white,
                fontWeight: isAlert ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
