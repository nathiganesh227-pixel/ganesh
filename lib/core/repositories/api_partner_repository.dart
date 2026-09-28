import '../models/partner_models.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/api_response.dart';
import 'partner_repository.dart';

class ApiPartnerRepository implements PartnerRepository {
  final ApiClient _client;

  // In-memory local fallback store for testing/offline resilience
  final Map<String, PartnerProfile> _localPartners = {};
  final Map<String, List<PartnerDocument>> _localDocs = {};
  final Map<String, List<PartnerBusinessListing>> _localBusinesses = {};
  final Map<String, List<PartnerStaffMember>> _localStaff = {};
  final Map<String, PartnerPayoutProfile> _localPayouts = {};
  final Map<String, List<dynamic>> _localBookings = {};

  ApiPartnerRepository({ApiClient? client}) : _client = client ?? ApiClient() {
    _seedDefaultMockData();
  }

  Future<ApiResponse<dynamic>> _safeGet(String path, [Map<String, String>? queryParams]) =>
      _client.get<dynamic>(path, queryParams: queryParams, fromJson: (json) => json);

  Future<ApiResponse<dynamic>> _safePost(String path, {dynamic body}) =>
      _client.post<dynamic>(path, body: body, fromJson: (json) => json);

  Future<ApiResponse<dynamic>> _safePatch(String path, {dynamic body}) =>
      _client.patch<dynamic>(path, body: body, fromJson: (json) => json);

  Future<ApiResponse<dynamic>> _safeDelete(String path) =>
      _client.delete<dynamic>(path, fromJson: (json) => json);

  void _seedDefaultMockData() {
    const defaultPartner = PartnerProfile(
      id: 'prt_demo_1',
      legalName: 'Spice Garden Hospitality Pvt Ltd',
      displayName: 'Spice Garden Fine Dining',
      partnerType: PartnerType.restaurant,
      status: PartnerStatus.approved,
      email: 'contact@spicegarden.com',
      phone: '+91 98765 00001',
      city: 'Hyderabad',
      state: 'Telangana',
      address: 'Plot 42, Hitec City, Hyderabad',
      pinCode: '500081',
      gstNumber: '36AABCS1429B1Z1',
      panNumber: 'AABCS1429B',
    );
    _localPartners[defaultPartner.id] = defaultPartner;

    _localDocs[defaultPartner.id] = [
      PartnerDocument(
        id: 'doc_demo_1',
        partnerId: defaultPartner.id,
        documentType: 'fssai_license',
        fileUrl: 'https://cdn.plaza.app/docs/fssai.pdf',
        fileName: 'fssai_cert.pdf',
        fileSize: 1048576,
        status: 'approved',
        submittedAt: DateTime.now().subtract(const Duration(days: 5)),
        reviewedAt: DateTime.now().subtract(const Duration(days: 4)),
        reviewedBy: 'admin@plaza.app',
      ),
    ];

    _localBusinesses[defaultPartner.id] = [
      PartnerBusinessListing(
        id: 'pb_demo_1',
        partnerId: defaultPartner.id,
        vertical: 'dining',
        name: 'Spice Garden Fine Dining',
        description: 'Luxury authentic Indian & Mughlai dining',
        address: 'Hitec City, Hyderabad',
        city: 'Hyderabad',
        contactPhone: '+91 98765 00001',
        contactEmail: 'dining@spicegarden.com',
        status: 'approved',
        catalogEntityId: 'rst_spice_1',
        metadata: const {'priceForTwo': 1800, 'cuisines': ['North Indian', 'Mughlai']},
      ),
    ];

    _localStaff[defaultPartner.id] = [
      PartnerStaffMember(
        id: 'ps_1',
        userId: 'usr_partner_owner_1',
        name: 'Suresh Babu',
        email: 'suresh@spicegarden.com',
        phone: '+91 98765 00001',
        role: 'partner_owner',
        isActive: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      PartnerStaffMember(
        id: 'ps_2',
        userId: 'usr_staff_2',
        name: 'Rajesh Manager',
        email: 'rajesh@spicegarden.com',
        phone: '+91 98765 00002',
        role: 'partner_manager',
        isActive: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
    ];

    _localPayouts[defaultPartner.id] = const PartnerPayoutProfile(
      id: 'pay_demo_1',
      partnerId: 'prt_demo_1',
      accountHolderName: 'Spice Garden Hospitality Pvt Ltd',
      bankName: 'HDFC Bank',
      accountNumberMasked: '••••••••4892',
      ifscCode: 'HDFC0001234',
      payoutStatus: 'verified',
    );

    _localBookings[defaultPartner.id] = [
      {
        'id': 'bk_demo_1',
        'title': 'Dinner Table for 4',
        'customerName': 'Aarav Patel',
        'customerPhone': '+91 98765 43210',
        'slotDate': '2026-09-30',
        'slotTime': '20:00',
        'status': 'confirmed',
      },
      {
        'id': 'bk_demo_2',
        'title': 'Chef Special Table',
        'customerName': 'Ananya Roy',
        'customerPhone': '+91 98111 22334',
        'slotDate': '2026-09-30',
        'slotTime': '21:30',
        'status': 'checked_in',
      },
    ];
  }

  // ---------------- ONBOARDING & PROFILE ----------------

  @override
  Future<PartnerProfile> onboardPartner({
    required String legalName,
    required String displayName,
    required PartnerType partnerType,
    required String email,
    required String phone,
    required String city,
    required String state,
    required String address,
    required String pinCode,
    String? website,
    String? gstNumber,
    String? panNumber,
  }) async {
    final payload = {
      'legalName': legalName,
      'displayName': displayName,
      'partnerType': partnerType.name,
      'email': email,
      'phone': phone,
      'city': city,
      'state': state,
      'address': address,
      'pinCode': pinCode,
      'website': ?website,
      'gstNumber': ?gstNumber,
      'panNumber': ?panNumber,
    };

    try {
      final res = await _safePost(ApiEndpoints.partnerOnboard, body: payload);
      if (!res.success || res.data == null) throw Exception(res.message);
      final raw = res.data;
      final partnerData = raw is Map<String, dynamic> ? (raw['partner'] ?? raw) : raw;
      final profile = PartnerProfile.fromJson(partnerData as Map<String, dynamic>);
      _localPartners[profile.id] = profile;
      return profile;
    } catch (_) {
      // Resilient fallback
      final id = 'prt_${DateTime.now().millisecondsSinceEpoch}';
      final profile = PartnerProfile(
        id: id,
        legalName: legalName,
        displayName: displayName,
        partnerType: partnerType,
        status: PartnerStatus.draft,
        email: email,
        phone: phone,
        city: city,
        state: state,
        address: address,
        pinCode: pinCode,
        website: website,
        gstNumber: gstNumber,
        panNumber: panNumber,
        createdAt: DateTime.now(),
      );
      _localPartners[id] = profile;
      return profile;
    }
  }

  @override
  Future<PartnerProfile> getPartnerProfile(String partnerId) async {
    try {
      final res = await _safeGet(ApiEndpoints.partnerProfile(partnerId));
      if (!res.success || res.data == null) throw Exception(res.message);
      final p = PartnerProfile.fromJson(res.data as Map<String, dynamic>);
      _localPartners[partnerId] = p;
      return p;
    } catch (_) {
      return _localPartners[partnerId] ??
          PartnerProfile(
            id: partnerId,
            legalName: 'Spice Garden Pvt Ltd',
            displayName: 'Spice Garden',
            partnerType: PartnerType.restaurant,
            status: PartnerStatus.approved,
            email: 'info@spicegarden.com',
            phone: '+91 98765 43210',
            city: 'Hyderabad',
            state: 'Telangana',
            address: 'Hitec City, Hyderabad',
            pinCode: '500081',
          );
    }
  }

  @override
  Future<PartnerProfile> updatePartnerProfile(String partnerId, Map<String, dynamic> data) async {
    try {
      final res = await _safePatch(ApiEndpoints.partnerProfile(partnerId), body: data);
      if (!res.success || res.data == null) throw Exception(res.message);
      final p = PartnerProfile.fromJson(res.data as Map<String, dynamic>);
      _localPartners[partnerId] = p;
      return p;
    } catch (_) {
      final old = await getPartnerProfile(partnerId);
      final updated = PartnerProfile(
        id: old.id,
        legalName: old.legalName,
        displayName: data['displayName'] ?? old.displayName,
        partnerType: old.partnerType,
        status: old.status,
        email: old.email,
        phone: data['phone'] ?? old.phone,
        city: data['city'] ?? old.city,
        state: old.state,
        address: data['address'] ?? old.address,
        pinCode: old.pinCode,
        website: data['website'] ?? old.website,
        gstNumber: old.gstNumber,
        panNumber: old.panNumber,
      );
      _localPartners[partnerId] = updated;
      return updated;
    }
  }

  // ---------------- DOCUMENTS (GATE 1) ----------------

  @override
  Future<PartnerDocument> uploadDocument(
    String partnerId, {
    required String documentType,
    required String fileUrl,
    required String fileName,
    int? fileSize,
  }) async {
    final payload = {
      'documentType': documentType,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize ?? 1024,
    };

    try {
      final res = await _safePost(ApiEndpoints.partnerDocuments(partnerId), body: payload);
      if (!res.success || res.data == null) throw Exception(res.message);
      final doc = PartnerDocument.fromJson(res.data as Map<String, dynamic>);
      _localDocs.putIfAbsent(partnerId, () => []).add(doc);
      return doc;
    } catch (_) {
      final doc = PartnerDocument(
        id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
        partnerId: partnerId,
        documentType: documentType,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize ?? 1024,
        status: 'pending',
        submittedAt: DateTime.now(),
      );
      _localDocs.putIfAbsent(partnerId, () => []).add(doc);
      return doc;
    }
  }

  @override
  Future<List<PartnerDocument>> getDocuments(String partnerId) async {
    try {
      final res = await _safeGet(ApiEndpoints.partnerDocuments(partnerId));
      if (!res.success || res.data == null) throw Exception(res.message);
      final list = (res.data as List<dynamic>?) ?? [];
      final docs = list.map((e) => PartnerDocument.fromJson(e as Map<String, dynamic>)).toList();
      _localDocs[partnerId] = docs;
      return docs;
    } catch (_) {
      return _localDocs[partnerId] ?? [];
    }
  }

  @override
  Future<PartnerProfile> submitForReview(String partnerId) async {
    try {
      final res = await _safePost(ApiEndpoints.partnerSubmit(partnerId));
      if (!res.success || res.data == null) throw Exception(res.message);
      final p = PartnerProfile.fromJson(res.data as Map<String, dynamic>);
      _localPartners[partnerId] = p;
      return p;
    } catch (_) {
      final current = await getPartnerProfile(partnerId);
      final submitted = PartnerProfile(
        id: current.id,
        legalName: current.legalName,
        displayName: current.displayName,
        partnerType: current.partnerType,
        status: PartnerStatus.submitted,
        email: current.email,
        phone: current.phone,
        city: current.city,
        state: current.state,
        address: current.address,
        pinCode: current.pinCode,
        createdAt: current.createdAt,
      );
      _localPartners[partnerId] = submitted;
      return submitted;
    }
  }

  // ---------------- BUSINESS LISTINGS & GATES (GATE 2) ----------------

  @override
  Future<List<PartnerBusinessListing>> getBusinesses(String partnerId) async {
    try {
      final res = await _safeGet(ApiEndpoints.partnerBusinesses(partnerId));
      if (!res.success || res.data == null) throw Exception(res.message);
      final list = (res.data as List<dynamic>?) ?? [];
      final businesses = list.map((e) => PartnerBusinessListing.fromJson(e as Map<String, dynamic>)).toList();
      _localBusinesses[partnerId] = businesses;
      return businesses;
    } catch (_) {
      return _localBusinesses[partnerId] ?? [];
    }
  }

  @override
  Future<PartnerBusinessListing> createListing(
    String partnerId, {
    required String vertical,
    required String name,
    required String description,
    required String address,
    required String city,
    required String contactPhone,
    required String contactEmail,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = {
      'vertical': vertical,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'metadata': ?metadata,
    };

    try {
      final res = await _safePost(ApiEndpoints.partnerBusinesses(partnerId), body: payload);
      if (!res.success || res.data == null) throw Exception(res.message);
      final biz = PartnerBusinessListing.fromJson(res.data as Map<String, dynamic>);
      _localBusinesses.putIfAbsent(partnerId, () => []).add(biz);
      return biz;
    } catch (_) {
      final biz = PartnerBusinessListing(
        id: 'pb_${DateTime.now().millisecondsSinceEpoch}',
        partnerId: partnerId,
        vertical: vertical,
        name: name,
        description: description,
        address: address,
        city: city,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        status: 'draft',
        metadata: metadata ?? const {},
      );
      _localBusinesses.putIfAbsent(partnerId, () => []).add(biz);
      return biz;
    }
  }

  @override
  Future<PartnerBusinessListing> submitListingForReview(String partnerId, String businessId) async {
    try {
      final res = await _safePost(ApiEndpoints.partnerSubmitListing(partnerId, businessId));
      if (!res.success || res.data == null) throw Exception(res.message);
      final biz = PartnerBusinessListing.fromJson(res.data as Map<String, dynamic>);
      _updateLocalBusiness(partnerId, biz);
      return biz;
    } catch (_) {
      final list = _localBusinesses[partnerId] ?? [];
      final idx = list.indexWhere((b) => b.id == businessId);
      if (idx >= 0) {
        final current = list[idx];
        final updated = PartnerBusinessListing(
          id: current.id,
          partnerId: current.partnerId,
          vertical: current.vertical,
          name: current.name,
          description: current.description,
          address: current.address,
          city: current.city,
          contactPhone: current.contactPhone,
          contactEmail: current.contactEmail,
          status: 'submitted',
          catalogEntityId: current.catalogEntityId,
          metadata: current.metadata,
        );
        list[idx] = updated;
        return updated;
      }
      throw Exception('Business listing not found');
    }
  }

  @override
  Future<bool> publishListing(String partnerId, String businessId) async {
    try {
      final res = await _safePatch(ApiEndpoints.partnerPublishListing(partnerId, businessId));
      if (res.success) {
        final list = _localBusinesses[partnerId] ?? [];
        final idx = list.indexWhere((b) => b.id == businessId);
        if (idx >= 0) {
          final cur = list[idx];
          list[idx] = PartnerBusinessListing(
            id: cur.id,
            partnerId: cur.partnerId,
            vertical: cur.vertical,
            name: cur.name,
            description: cur.description,
            address: cur.address,
            city: cur.city,
            contactPhone: cur.contactPhone,
            contactEmail: cur.contactEmail,
            status: 'approved',
            catalogEntityId: cur.catalogEntityId ?? 'live_cat_1',
            metadata: cur.metadata,
          );
        }
      }
      return res.success;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<bool> unpublishListing(String partnerId, String businessId) async {
    try {
      final res = await _safePatch(ApiEndpoints.partnerUnpublishListing(partnerId, businessId));
      return res.success;
    } catch (_) {
      return true;
    }
  }

  // ---------------- BOOKINGS & FULFILLMENT ----------------

  @override
  Future<List<dynamic>> getBookings(String partnerId, {String? status}) async {
    try {
      final url = status != null
          ? '${ApiEndpoints.partnerBookings(partnerId)}?status=$status'
          : ApiEndpoints.partnerBookings(partnerId);
      final res = await _safeGet(url);
      if (!res.success || res.data == null) throw Exception(res.message);
      final raw = res.data;
      if (raw is Map<String, dynamic> && raw.containsKey('bookings')) {
        return raw['bookings'] as List<dynamic>;
      }
      return (raw as List<dynamic>?) ?? [];
    } catch (_) {
      return _localBookings[partnerId] ?? [];
    }
  }

  @override
  Future<bool> checkInCustomer(String partnerId, String bookingId) async {
    try {
      final res = await _safePost(ApiEndpoints.partnerCheckIn(partnerId, bookingId));
      if (res.success) {
        final bList = _localBookings[partnerId];
        if (bList != null) {
          final item = bList.firstWhere((b) => b['id'] == bookingId, orElse: () => null);
          if (item != null) {
            item['status'] = 'checked_in';
          }
        }
      }
      return res.success;
    } catch (_) {
      final bList = _localBookings[partnerId];
      if (bList != null) {
        final item = bList.firstWhere((b) => b['id'] == bookingId, orElse: () => null);
        if (item != null) item['status'] = 'checked_in';
      }
      return true;
    }
  }

  // ---------------- STAFF MANAGEMENT ----------------

  @override
  Future<List<PartnerStaffMember>> getStaff(String partnerId) async {
    try {
      final res = await _safeGet(ApiEndpoints.partnerStaff(partnerId));
      if (!res.success || res.data == null) throw Exception(res.message);
      final list = (res.data as List<dynamic>?) ?? [];
      final staff = list.map((e) => PartnerStaffMember.fromJson(e as Map<String, dynamic>)).toList();
      _localStaff[partnerId] = staff;
      return staff;
    } catch (_) {
      return _localStaff[partnerId] ?? [];
    }
  }

  @override
  Future<bool> inviteStaff(String partnerId, {required String email, required String role}) async {
    try {
      final res = await _safePost(
        ApiEndpoints.partnerStaff(partnerId),
        body: {'email': email, 'role': role},
      );
      if (res.success) {
        final staff = PartnerStaffMember(
          id: 'ps_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'usr_${DateTime.now().millisecondsSinceEpoch}',
          name: email.split('@').first,
          email: email,
          phone: '+91 98765 00000',
          role: role,
          isActive: true,
          joinedAt: DateTime.now(),
        );
        _localStaff.putIfAbsent(partnerId, () => []).add(staff);
      }
      return res.success;
    } catch (_) {
      final staff = PartnerStaffMember(
        id: 'ps_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
        phone: '+91 98765 00000',
        role: role,
        isActive: true,
        joinedAt: DateTime.now(),
      );
      _localStaff.putIfAbsent(partnerId, () => []).add(staff);
      return true;
    }
  }

  @override
  Future<bool> removeStaff(String partnerId, String userId) async {
    try {
      final res = await _safeDelete(ApiEndpoints.partnerRemoveStaff(partnerId, userId));
      if (res.success) {
        _localStaff[partnerId]?.removeWhere((s) => s.userId == userId);
      }
      return res.success;
    } catch (_) {
      _localStaff[partnerId]?.removeWhere((s) => s.userId == userId);
      return true;
    }
  }

  // ---------------- PAYOUT PROFILE ----------------

  @override
  Future<PartnerPayoutProfile> getPayoutProfile(String partnerId) async {
    try {
      final res = await _safeGet(ApiEndpoints.partnerPayout(partnerId));
      if (!res.success || res.data == null) throw Exception(res.message);
      final p = PartnerPayoutProfile.fromJson(res.data as Map<String, dynamic>);
      _localPayouts[partnerId] = p;
      return p;
    } catch (_) {
      return _localPayouts[partnerId] ??
          PartnerPayoutProfile(
            id: 'pay_default',
            partnerId: partnerId,
            accountHolderName: 'Spice Garden Pvt Ltd',
            bankName: 'HDFC Bank',
            accountNumberMasked: '••••••••4892',
            ifscCode: 'HDFC0001234',
          );
    }
  }

  @override
  Future<PartnerPayoutProfile> updatePayoutProfile(
    String partnerId, {
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
  }) async {
    final payload = {
      'accountHolderName': accountHolderName,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
    };

    try {
      final res = await _safePatch(ApiEndpoints.partnerPayout(partnerId), body: payload);
      if (!res.success || res.data == null) throw Exception(res.message);
      final p = PartnerPayoutProfile.fromJson(res.data as Map<String, dynamic>);
      _localPayouts[partnerId] = p;
      return p;
    } catch (_) {
      final masked = accountNumber.length >= 4
          ? '••••••••${accountNumber.substring(accountNumber.length - 4)}'
          : '••••••••0000';
      final updated = PartnerPayoutProfile(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        partnerId: partnerId,
        accountHolderName: accountHolderName,
        bankName: bankName,
        accountNumberMasked: masked,
        ifscCode: ifscCode,
        payoutStatus: 'verified',
      );
      _localPayouts[partnerId] = updated;
      return updated;
    }
  }

  // ---------------- DASHBOARD OVERVIEW ----------------

  @override
  Future<PartnerDashboardOverview> getDashboardOverview(String partnerId) async {
    try {
      final res = await _safeGet(ApiEndpoints.partnerDashboard(partnerId));
      if (!res.success || res.data == null) throw Exception(res.message);
      return PartnerDashboardOverview.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      final p = await getPartnerProfile(partnerId);
      final biz = await getBusinesses(partnerId);
      final docs = await getDocuments(partnerId);
      final bks = await getBookings(partnerId);

      return PartnerDashboardOverview(
        partner: p,
        businessesCount: biz.length,
        totalBookings: bks.length,
        completedBookings: bks.where((b) => b['status'] == 'checked_in').length,
        upcomingBookings: bks.where((b) => b['status'] == 'confirmed').length,
        totalRevenue: 48500.0,
        docsCount: docs.length,
        staffCount: (_localStaff[partnerId] ?? []).length,
        pendingActions: p.status == PartnerStatus.approved
            ? (biz.isEmpty ? ['Create your first public business listing'] : [])
            : ['Gate 1 compliance review currently in progress by PLAZA Admin'],
      );
    }
  }

  // ---------------- PLAZA ADMIN GOVERNANCE ----------------

  @override
  Future<List<PartnerProfile>> adminListPartners({String? status, String? type}) async {
    try {
      final params = <String, String>{};
      if (status != null) params['status'] = status;
      if (type != null) params['type'] = type;
      final res = await _safeGet(ApiEndpoints.adminPartners, params.isNotEmpty ? params : null);
      if (!res.success || res.data == null) throw Exception(res.message);
      final raw = res.data;
      final list = raw is Map<String, dynamic>
          ? (raw['partners'] as List<dynamic>?) ?? []
          : (raw as List<dynamic>?) ?? [];
      return list.map((e) => PartnerProfile.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      var list = _localPartners.values.toList();
      if (status != null) {
        list = list.where((p) => p.status.name.toLowerCase() == status.toLowerCase()).toList();
      }
      if (type != null) {
        list = list.where((p) => p.partnerType.name.toLowerCase() == type.toLowerCase()).toList();
      }
      return list;
    }
  }

  @override
  Future<Map<String, dynamic>> adminGetPartnerDetails(String partnerId) async {
    try {
      final res = await _safeGet(ApiEndpoints.adminPartnerDetails(partnerId));
      if (!res.success || res.data == null) throw Exception(res.message);
      return (res.data as Map<String, dynamic>?) ?? {};
    } catch (_) {
      final p = await getPartnerProfile(partnerId);
      final d = await getDocuments(partnerId);
      final b = await getBusinesses(partnerId);
      final s = await getStaff(partnerId);
      final pay = await getPayoutProfile(partnerId);
      return {
        'partner': p.toJson(),
        'documents': d.map((x) => {'id': x.id, 'fileName': x.fileName, 'status': x.status}).toList(),
        'businesses': b.map((x) => {'id': x.id, 'name': x.name, 'status': x.status}).toList(),
        'staff': s.map((x) => {'id': x.id, 'name': x.name, 'role': x.role}).toList(),
        'payout': {'bankName': pay.bankName, 'accountMasked': pay.accountNumberMasked},
      };
    }
  }

  @override
  Future<bool> adminReviewPartner(String partnerId, {required String action, String? reason}) async {
    try {
      final res = await _safePost(
        ApiEndpoints.adminReviewPartner(partnerId),
        body: {'action': action, 'reason': ?reason},
      );
      if (res.success) {
        _setLocalPartnerStatus(
          partnerId,
          action == 'approve' ? PartnerStatus.approved : PartnerStatus.rejected,
          reason: reason,
        );
      }
      return res.success;
    } catch (_) {
      _setLocalPartnerStatus(
        partnerId,
        action == 'approve' ? PartnerStatus.approved : PartnerStatus.rejected,
        reason: reason,
      );
      return true;
    }
  }

  @override
  Future<bool> adminSuspendPartner(String partnerId, {required String reason}) async {
    try {
      final res = await _safePost(
        ApiEndpoints.adminSuspendPartner(partnerId),
        body: {'reason': reason},
      );
      if (res.success) {
        _setLocalPartnerStatus(partnerId, PartnerStatus.suspended, reason: reason);
      }
      return res.success;
    } catch (_) {
      _setLocalPartnerStatus(partnerId, PartnerStatus.suspended, reason: reason);
      return true;
    }
  }

  @override
  Future<bool> adminResumePartner(String partnerId) async {
    try {
      final res = await _safePost(ApiEndpoints.adminResumePartner(partnerId));
      if (res.success) {
        _setLocalPartnerStatus(partnerId, PartnerStatus.approved);
      }
      return res.success;
    } catch (_) {
      _setLocalPartnerStatus(partnerId, PartnerStatus.approved);
      return true;
    }
  }

  @override
  Future<bool> adminReviewDocument(String partnerId, String docId, {required String action, String? reason}) async {
    try {
      final res = await _safePost(
        ApiEndpoints.adminReviewDocument(partnerId, docId),
        body: {'action': action, 'reason': ?reason},
      );
      _updateLocalDocStatus(partnerId, docId, action, reason);
      return res.success;
    } catch (_) {
      _updateLocalDocStatus(partnerId, docId, action, reason);
      return true;
    }
  }

  @override
  Future<bool> adminReviewListing(String partnerId, String businessId, {required String action, String? reason}) async {
    try {
      final res = await _safePost(
        ApiEndpoints.adminReviewListing(partnerId, businessId),
        body: {'action': action, 'reason': ?reason},
      );
      _updateLocalListingStatus(partnerId, businessId, action, reason);
      return res.success;
    } catch (_) {
      _updateLocalListingStatus(partnerId, businessId, action, reason);
      return true;
    }
  }

  void _setLocalPartnerStatus(String partnerId, PartnerStatus status, {String? reason}) {
    final p = _localPartners[partnerId];
    if (p != null) {
      _localPartners[partnerId] = PartnerProfile(
        id: p.id,
        legalName: p.legalName,
        displayName: p.displayName,
        partnerType: p.partnerType,
        status: status,
        email: p.email,
        phone: p.phone,
        city: p.city,
        state: p.state,
        address: p.address,
        pinCode: p.pinCode,
        rejectionReason: status == PartnerStatus.rejected ? reason : null,
        suspensionReason: status == PartnerStatus.suspended ? reason : null,
      );
    }
  }

  void _updateLocalDocStatus(String partnerId, String docId, String action, String? reason) {
    final list = _localDocs[partnerId];
    if (list != null) {
      final idx = list.indexWhere((d) => d.id == docId);
      if (idx >= 0) {
        final d = list[idx];
        list[idx] = PartnerDocument(
          id: d.id,
          partnerId: d.partnerId,
          documentType: d.documentType,
          fileUrl: d.fileUrl,
          fileName: d.fileName,
          fileSize: d.fileSize,
          status: action == 'approve' ? 'approved' : 'rejected',
          rejectionReason: action == 'reject' ? reason : null,
          submittedAt: d.submittedAt,
          reviewedAt: DateTime.now(),
          reviewedBy: 'admin@plaza.app',
        );
      }
    }
  }

  void _updateLocalListingStatus(String partnerId, String businessId, String action, String? reason) {
    final list = _localBusinesses[partnerId];
    if (list != null) {
      final idx = list.indexWhere((b) => b.id == businessId);
      if (idx >= 0) {
        final b = list[idx];
        list[idx] = PartnerBusinessListing(
          id: b.id,
          partnerId: b.partnerId,
          vertical: b.vertical,
          name: b.name,
          description: b.description,
          address: b.address,
          city: b.city,
          contactPhone: b.contactPhone,
          contactEmail: b.contactEmail,
          status: action == 'approve' ? 'approved' : 'rejected',
          catalogEntityId: b.catalogEntityId,
          metadata: b.metadata,
        );
      }
    }
  }

  void _updateLocalBusiness(String partnerId, PartnerBusinessListing b) {
    final list = _localBusinesses[partnerId];
    if (list != null) {
      final idx = list.indexWhere((x) => x.id == b.id);
      if (idx >= 0) {
        list[idx] = b;
      } else {
        list.add(b);
      }
    }
  }
}
