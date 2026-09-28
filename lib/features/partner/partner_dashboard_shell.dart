import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/partner_models.dart';
import '../../core/repositories/partner_repository.dart';
import '../../core/repositories/api_partner_repository.dart';

class PartnerDashboardShell extends StatefulWidget {
  final String partnerId;
  final PartnerRepository? repository;

  const PartnerDashboardShell({
    super.key,
    required this.partnerId,
    this.repository,
  });

  @override
  State<PartnerDashboardShell> createState() => _PartnerDashboardShellState();
}

class _PartnerDashboardShellState extends State<PartnerDashboardShell> {
  late final PartnerRepository _repository;
  int _selectedTab = 0; // 0: Overview, 1: Listings, 2: Bookings, 3: Docs, 4: Staff, 5: Payout
  bool _isLoading = true;

  PartnerDashboardOverview? _overview;
  List<PartnerBusinessListing> _listings = [];
  List<dynamic> _bookings = [];
  List<PartnerDocument> _documents = [];
  List<PartnerStaffMember> _staff = [];
  PartnerPayoutProfile? _payout;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiPartnerRepository();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final overview = await _repository.getDashboardOverview(widget.partnerId);
      final listings = await _repository.getBusinesses(widget.partnerId);
      final bookings = await _repository.getBookings(widget.partnerId);
      final docs = await _repository.getDocuments(widget.partnerId);
      final staff = await _repository.getStaff(widget.partnerId);
      final payout = await _repository.getPayoutProfile(widget.partnerId);

      if (mounted) {
        setState(() {
          _overview = overview;
          _listings = listings;
          _bookings = bookings;
          _documents = docs;
          _staff = staff;
          _payout = payout;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
      );
    }

    final partner = _overview?.partner;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  partner?.displayName ?? 'Partner Portal',
                  style: AppTypography.headingSmall.copyWith(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(width: 8),
                _buildStatusPill(partner?.status ?? PartnerStatus.draft),
              ],
            ),
            Text(
              partner?.partnerType.displayName ?? 'Partner Organization',
              style: AppTypography.bodySmall.copyWith(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _buildSelectedTabContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.accentGold,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Listings'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_rounded), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_shared_rounded), label: 'KYC Docs'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Staff'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_rounded), label: 'Payout'),
        ],
      ),
    );
  }

  Widget _buildStatusPill(PartnerStatus status) {
    Color bg = Colors.white12;
    Color fg = Colors.white70;

    switch (status) {
      case PartnerStatus.approved:
        bg = Colors.greenAccent.withValues(alpha: 0.15);
        fg = Colors.greenAccent;
        break;
      case PartnerStatus.submitted:
      case PartnerStatus.underReview:
        bg = AppColors.accentGold.withValues(alpha: 0.15);
        fg = AppColors.accentGold;
        break;
      case PartnerStatus.rejected:
      case PartnerStatus.suspended:
        bg = Colors.redAccent.withValues(alpha: 0.15);
        fg = Colors.redAccent;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildListingsTab();
      case 2:
        return _buildBookingsTab();
      case 3:
        return _buildDocumentsTab();
      case 4:
        return _buildStaffTab();
      case 5:
        return _buildPayoutTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------- TAB 0: OVERVIEW ----------------
  Widget _buildOverviewTab() {
    final partner = _overview?.partner;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.accentGold,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gate 1 Status Banner
          if (partner?.status != PartnerStatus.approved) _buildGate1Banner(partner),

          // KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Upcoming Bookings',
                  '${_overview?.upcomingBookings ?? 0}',
                  Icons.calendar_today_rounded,
                  AppColors.accentGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Gross Revenue',
                  '₹${(_overview?.totalRevenue ?? 0).toStringAsFixed(0)}',
                  Icons.currency_rupee_rounded,
                  Colors.greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Active Listings',
                  '${_overview?.businessesCount ?? 0}',
                  Icons.storefront_rounded,
                  Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Staff Team',
                  '${_overview?.staffCount ?? 0}',
                  Icons.people_outline_rounded,
                  Colors.purpleAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text('Pending Operational Actions', style: AppTypography.headingSmall.copyWith(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 10),
          if (_overview?.pendingActions.isEmpty ?? true)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent),
                  SizedBox(width: 12),
                  Text('All verification gates and listings are in sync.', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          else
            ...(_overview?.pendingActions ?? []).map(
              (act) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.accentGold, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(act, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGate1Banner(PartnerProfile? partner) {
    Color bg = AppColors.accentGold.withValues(alpha: 0.12);
    Color border = AppColors.accentGold.withValues(alpha: 0.4);
    IconData icon = Icons.hourglass_top_rounded;
    String title = 'Gate 1 Verification in Progress';
    String desc = 'PLAZA Admin is reviewing your submitted KYC documents.';

    if (partner?.status == PartnerStatus.draft) {
      icon = Icons.edit_document;
      title = 'Gate 1 Incomplete: Draft Application';
      desc = 'Please upload your required verification documents to submit for approval.';
    } else if (partner?.status == PartnerStatus.rejected) {
      bg = Colors.redAccent.withValues(alpha: 0.12);
      border = Colors.redAccent.withValues(alpha: 0.4);
      icon = Icons.warning_amber_rounded;
      title = 'Gate 1 Action Required: Submission Rejected';
      desc = partner?.rejectionReason ?? 'Please review rejection feedback and resubmit.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: border, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTypography.headingSmall.copyWith(color: Colors.white, fontSize: 20)),
        ],
      ),
    );
  }

  // ---------------- TAB 1: LISTINGS (GATE 2) ----------------
  Widget _buildListingsTab() {
    final isGate1Approved = _overview?.partner.isApproved ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Business Listings', style: AppTypography.headingSmall.copyWith(color: Colors.white, fontSize: 16)),
            ElevatedButton.icon(
              onPressed: isGate1Approved ? _showCreateListingDialog : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Listing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ),
        if (!isGate1Approved)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'Gate 1 Notice: Partner organization must be approved by PLAZA Admin before creating new public listings.',
              style: TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        if (_listings.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('No business listings created yet.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          ..._listings.map((b) => _buildListingCard(b)),
      ],
    );
  }

  Widget _buildListingCard(PartnerBusinessListing b) {
    final isApproved = b.isApproved;
    final isSubmitted = b.isSubmitted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(b.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              _buildListingStatusBadge(b.status),
            ],
          ),
          const SizedBox(height: 4),
          Text('${b.vertical.toUpperCase()} • ${b.city}', style: const TextStyle(color: AppColors.accentGold, fontSize: 12)),
          const SizedBox(height: 8),
          Text(b.description, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2),
          const SizedBox(height: 14),
          Row(
            children: [
              if (b.isDraft)
                ElevatedButton(
                  onPressed: () => _submitListingForReview(b.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold.withValues(alpha: 0.2),
                    foregroundColor: AppColors.accentGold,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Submit for Review (Gate 2)'),
                ),
              if (isApproved)
                ElevatedButton.icon(
                  onPressed: () => _publishListing(b.id),
                  icon: const Icon(Icons.public, size: 16),
                  label: const Text('Publish Live'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.withValues(alpha: 0.2),
                    foregroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              if (isSubmitted)
                const Text('Under PLAZA Review...', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListingStatusBadge(String status) {
    Color color = Colors.white54;
    if (status == 'approved') color = Colors.greenAccent;
    if (status == 'submitted') color = AppColors.accentGold;
    if (status == 'rejected') color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showCreateListingDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('New Business Listing', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Listing Title *', labelStyle: TextStyle(color: Colors.white54)),
              ),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description *', labelStyle: TextStyle(color: Colors.white54)),
              ),
              TextField(
                controller: addrCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Venue Address *', labelStyle: TextStyle(color: Colors.white54)),
              ),
              TextField(
                controller: phoneCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Contact Phone *', labelStyle: TextStyle(color: Colors.white54)),
              ),
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Contact Email *', labelStyle: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: Colors.black),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && addrCtrl.text.isNotEmpty) {
                Navigator.of(ctx).pop();
                await _repository.createListing(
                  widget.partnerId,
                  vertical: _overview?.partner.partnerType.name ?? 'dining',
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  city: _overview?.partner.city ?? 'Hyderabad',
                  contactPhone: phoneCtrl.text.trim(),
                  contactEmail: emailCtrl.text.trim(),
                );
                _loadDashboardData();
              }
            },
            child: const Text('Create Listing'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitListingForReview(String bId) async {
    await _repository.submitListingForReview(widget.partnerId, bId);
    _loadDashboardData();
  }

  Future<void> _publishListing(String bId) async {
    final ok = await _repository.publishListing(widget.partnerId, bId);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing published live to customers!')),
      );
    }
    _loadDashboardData();
  }

  // ---------------- TAB 2: BOOKINGS ----------------
  Widget _buildBookingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Customer Bookings', style: AppTypography.headingSmall.copyWith(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 12),
        if (_bookings.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('No bookings received yet.', style: TextStyle(color: Colors.white54)),
            ),
          )
        else
          ..._bookings.map((b) => _buildBookingCard(b)),
      ],
    );
  }

  Widget _buildBookingCard(dynamic b) {
    final id = b['id'] as String? ?? '';
    final title = b['title'] as String? ?? 'Booking';
    final customer = b['customerName'] as String? ?? 'Customer';
    final phone = b['customerPhone'] as String? ?? '';
    final date = b['date'] as String? ?? '';
    final time = b['time'] as String? ?? '';
    final status = b['status'] as String? ?? 'confirmed';
    final isCompleted = status.toLowerCase() == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              _buildListingStatusBadge(status),
            ],
          ),
          const SizedBox(height: 6),
          Text('Customer: $customer ($phone)', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text('Slot: $date at $time', style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isCompleted ? null : () => _checkInBooking(id),
              icon: Icon(isCompleted ? Icons.check : Icons.qr_code_scanner, size: 16),
              label: Text(isCompleted ? 'Checked In' : 'Check In Customer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted ? Colors.white10 : AppColors.accentGold,
                foregroundColor: isCompleted ? Colors.white38 : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkInBooking(String id) async {
    final ok = await _repository.checkInCustomer(widget.partnerId, id);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer checked in successfully!')),
      );
    }
    _loadDashboardData();
  }

  // ---------------- TAB 3: DOCUMENTS ----------------
  Widget _buildDocumentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('KYC Verification Documents', style: AppTypography.headingSmall.copyWith(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Gate 1 Verification documents submitted to PLAZA Admin.', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 16),
        ..._documents.map(
          (d) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  d.isApproved ? Icons.verified_user_rounded : (d.isRejected ? Icons.error_outline : Icons.description_outlined),
                  color: d.isApproved ? Colors.greenAccent : (d.isRejected ? Colors.redAccent : AppColors.accentGold),
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('${d.documentType.toUpperCase()} • ${d.status.toUpperCase()}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      if (d.rejectionReason != null)
                        Text('Reason: ${d.rejectionReason}', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- TAB 4: STAFF ----------------
  Widget _buildStaffTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Authorized Staff', style: AppTypography.headingSmall.copyWith(color: Colors.white, fontSize: 16)),
            ElevatedButton.icon(
              onPressed: _showInviteStaffDialog,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Invite Staff'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._staff.map(
          (s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: s.isOwner ? AppColors.accentGold : Colors.white12,
                  child: Icon(s.isOwner ? Icons.star : Icons.person, color: s.isOwner ? Colors.black : Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('${s.role.replaceAll('_', ' ').toUpperCase()} • ${s.email}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showInviteStaffDialog() {
    final emailCtrl = TextEditingController();
    String selectedRole = 'partner_staff';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Invite Staff Member', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Staff Email *', labelStyle: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Assigned Role', labelStyle: TextStyle(color: Colors.white54)),
                items: const [
                  DropdownMenuItem(value: 'partner_manager', child: Text('Partner Manager')),
                  DropdownMenuItem(value: 'partner_staff', child: Text('Partner Staff / Operations')),
                ],
                onChanged: (val) => setDlgState(() => selectedRole = val ?? 'partner_staff'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold, foregroundColor: Colors.black),
              onPressed: () async {
                if (emailCtrl.text.isNotEmpty) {
                  Navigator.of(ctx).pop();
                  await _repository.inviteStaff(widget.partnerId, email: emailCtrl.text.trim(), role: selectedRole);
                  _loadDashboardData();
                }
              },
              child: const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TAB 5: PAYOUT PROFILE ----------------
  Widget _buildPayoutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Bank & Payout Profile', style: AppTypography.headingSmall.copyWith(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('Settlement bank account details (Protected & Masked).', style: TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              _buildPayoutRow('Account Holder', _payout?.accountHolderName ?? 'Spice Garden Pvt Ltd'),
              const Divider(color: Colors.white12, height: 24),
              _buildPayoutRow('Bank Name', _payout?.bankName ?? 'HDFC Bank'),
              const Divider(color: Colors.white12, height: 24),
              _buildPayoutRow('Account Number', _payout?.accountNumberMasked ?? '••••••••4892'),
              const Divider(color: Colors.white12, height: 24),
              _buildPayoutRow('IFSC Code', _payout?.ifscCode ?? 'HDFC0001234'),
              const Divider(color: Colors.white12, height: 24),
              _buildPayoutRow(
                'Verification Status',
                (_payout?.payoutStatus ?? 'verified').toUpperCase(),
                valueColor: Colors.greenAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutRow(String label, String value, {Color valueColor = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
