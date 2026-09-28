enum PartnerType {
  restaurant,
  eventOrganizer,
  activityOperator,
  hotel,
  sportsVenue;

  static PartnerType fromString(String? val) {
    if (val == null) return PartnerType.restaurant;
    final s = val.toLowerCase().replaceAll('-', '_');
    if (s.contains('event')) return PartnerType.eventOrganizer;
    if (s.contains('activity')) return PartnerType.activityOperator;
    if (s.contains('hotel') || s.contains('stay')) return PartnerType.hotel;
    if (s.contains('sport')) return PartnerType.sportsVenue;
    return PartnerType.restaurant;
  }

  String get displayName {
    switch (this) {
      case PartnerType.restaurant:
        return 'Restaurant / Dining';
      case PartnerType.eventOrganizer:
        return 'Event Organizer';
      case PartnerType.activityOperator:
        return 'Activity Operator';
      case PartnerType.hotel:
        return 'Hotel / Stay';
      case PartnerType.sportsVenue:
        return 'Sports Venue';
    }
  }
}

enum PartnerStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  suspended,
  closed;

  static PartnerStatus fromString(String? val) {
    if (val == null) return PartnerStatus.draft;
    final s = val.toLowerCase().replaceAll('-', '_');
    if (s == 'submitted') return PartnerStatus.submitted;
    if (s == 'under_review') return PartnerStatus.underReview;
    if (s == 'approved') return PartnerStatus.approved;
    if (s == 'rejected') return PartnerStatus.rejected;
    if (s == 'suspended') return PartnerStatus.suspended;
    if (s == 'closed') return PartnerStatus.closed;
    return PartnerStatus.draft;
  }

  String get displayName {
    switch (this) {
      case PartnerStatus.draft:
        return 'Draft Profile';
      case PartnerStatus.submitted:
        return 'Under Review (Gate 1)';
      case PartnerStatus.underReview:
        return 'Under Review';
      case PartnerStatus.approved:
        return 'Verified Partner';
      case PartnerStatus.rejected:
        return 'Action Required';
      case PartnerStatus.suspended:
        return 'Suspended';
      case PartnerStatus.closed:
        return 'Closed';
    }
  }
}

class PartnerProfile {
  final String id;
  final String legalName;
  final String displayName;
  final PartnerType partnerType;
  final PartnerStatus status;
  final String email;
  final String phone;
  final String city;
  final String state;
  final String address;
  final String pinCode;
  final String? website;
  final String? gstNumber;
  final String? panNumber;
  final String? rejectionReason;
  final String? suspensionReason;
  final DateTime? createdAt;

  const PartnerProfile({
    required this.id,
    required this.legalName,
    required this.displayName,
    required this.partnerType,
    required this.status,
    required this.email,
    required this.phone,
    required this.city,
    required this.state,
    required this.address,
    required this.pinCode,
    this.website,
    this.gstNumber,
    this.panNumber,
    this.rejectionReason,
    this.suspensionReason,
    this.createdAt,
  });

  bool get isApproved => status == PartnerStatus.approved;
  bool get isSubmitted => status == PartnerStatus.submitted || status == PartnerStatus.underReview;
  bool get isRejected => status == PartnerStatus.rejected;
  bool get isSuspended => status == PartnerStatus.suspended;

  factory PartnerProfile.fromJson(Map<String, dynamic> json) {
    return PartnerProfile(
      id: json['id'] as String? ?? '',
      legalName: json['legalName'] as String? ?? 'Business Legal Name',
      displayName: json['displayName'] as String? ?? 'Display Name',
      partnerType: PartnerType.fromString(json['partnerType'] as String?),
      status: PartnerStatus.fromString(json['status'] as String?),
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? 'Hyderabad',
      state: json['state'] as String? ?? 'Telangana',
      address: json['address'] as String? ?? '',
      pinCode: json['pinCode'] as String? ?? '500081',
      website: json['website'] as String?,
      gstNumber: json['gstNumber'] as String?,
      panNumber: json['panNumber'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      suspensionReason: json['suspensionReason'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'legalName': legalName,
    'displayName': displayName,
    'partnerType': partnerType.name,
    'status': status.name,
    'email': email,
    'phone': phone,
    'city': city,
    'state': state,
    'address': address,
    'pinCode': pinCode,
    'website': website,
    'gstNumber': gstNumber,
    'panNumber': panNumber,
    'rejectionReason': rejectionReason,
    'suspensionReason': suspensionReason,
  };
}

class PartnerDocument {
  final String id;
  final String partnerId;
  final String documentType;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String status; // 'pending' | 'approved' | 'rejected' | 'expired'
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const PartnerDocument({
    required this.id,
    required this.partnerId,
    required this.documentType,
    required this.fileUrl,
    required this.fileName,
    this.fileSize = 1024,
    this.status = 'pending',
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory PartnerDocument.fromJson(Map<String, dynamic> json) {
    return PartnerDocument(
      id: json['id'] as String? ?? '',
      partnerId: json['partnerId'] as String? ?? '',
      documentType: json['documentType'] as String? ?? 'Document',
      fileUrl: json['fileUrl'] as String? ?? '',
      fileName: json['fileName'] as String? ?? 'document.pdf',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 1024,
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejectionReason'] as String?,
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt'] as String) : null,
      reviewedAt: json['reviewedAt'] != null ? DateTime.tryParse(json['reviewedAt'] as String) : null,
      reviewedBy: json['reviewedBy'] as String?,
    );
  }
}

class PartnerBusinessListing {
  final String id;
  final String partnerId;
  final String vertical;
  final String name;
  final String description;
  final String address;
  final String city;
  final String contactPhone;
  final String contactEmail;
  final String status; // 'draft' | 'submitted' | 'under_review' | 'approved' | 'rejected' | 'suspended'
  final String? catalogEntityId;
  final String? rejectionReason;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  const PartnerBusinessListing({
    required this.id,
    required this.partnerId,
    required this.vertical,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.contactPhone,
    required this.contactEmail,
    this.status = 'draft',
    this.catalogEntityId,
    this.rejectionReason,
    this.metadata = const {},
    this.createdAt,
  });

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isSubmitted => status.toLowerCase() == 'submitted';
  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isRejected => status.toLowerCase() == 'rejected';

  factory PartnerBusinessListing.fromJson(Map<String, dynamic> json) {
    return PartnerBusinessListing(
      id: json['id'] as String? ?? '',
      partnerId: json['partnerId'] as String? ?? '',
      vertical: json['vertical'] as String? ?? 'dining',
      name: json['name'] as String? ?? 'Listing Name',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? 'Hyderabad',
      contactPhone: json['contactPhone'] as String? ?? '',
      contactEmail: json['contactEmail'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      catalogEntityId: json['catalogEntityId'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

class PartnerStaffMember {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String role; // 'partner_owner' | 'partner_manager' | 'partner_staff'
  final bool isActive;
  final DateTime? joinedAt;

  const PartnerStaffMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.isActive = true,
    this.joinedAt,
  });

  bool get isOwner => role == 'partner_owner';
  bool get isManager => role == 'partner_manager';
  bool get isStaff => role == 'partner_staff';

  factory PartnerStaffMember.fromJson(Map<String, dynamic> json) {
    return PartnerStaffMember(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Staff Member',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'partner_staff',
      isActive: json['isActive'] as bool? ?? true,
      joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt'] as String) : null,
    );
  }
}

class PartnerPayoutProfile {
  final String id;
  final String partnerId;
  final String accountHolderName;
  final String bankName;
  final String accountNumberMasked;
  final String ifscCode;
  final String payoutStatus;
  final DateTime? verifiedAt;

  const PartnerPayoutProfile({
    required this.id,
    required this.partnerId,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumberMasked,
    required this.ifscCode,
    this.payoutStatus = 'pending_verification',
    this.verifiedAt,
  });

  bool get isVerified => payoutStatus.toLowerCase() == 'verified';

  factory PartnerPayoutProfile.fromJson(Map<String, dynamic> json) {
    return PartnerPayoutProfile(
      id: json['id'] as String? ?? '',
      partnerId: json['partnerId'] as String? ?? '',
      accountHolderName: json['accountHolderName'] as String? ?? '',
      bankName: json['bankName'] as String? ?? '',
      accountNumberMasked: json['accountNumberMasked'] as String? ?? '••••••••0000',
      ifscCode: json['ifscCode'] as String? ?? '',
      payoutStatus: json['payoutStatus'] as String? ?? 'pending_verification',
      verifiedAt: json['verifiedAt'] != null ? DateTime.tryParse(json['verifiedAt'] as String) : null,
    );
  }
}

class PartnerDashboardOverview {
  final PartnerProfile partner;
  final int totalBookings;
  final int upcomingBookings;
  final int completedBookings;
  final double totalRevenue;
  final int businessesCount;
  final int docsCount;
  final int staffCount;
  final List<String> pendingActions;

  const PartnerDashboardOverview({
    required this.partner,
    this.totalBookings = 0,
    this.upcomingBookings = 0,
    this.completedBookings = 0,
    this.totalRevenue = 0.0,
    this.businessesCount = 0,
    this.docsCount = 0,
    this.staffCount = 0,
    this.pendingActions = const [],
  });

  factory PartnerDashboardOverview.fromJson(Map<String, dynamic> json) {
    final pMap = json['partner'] as Map<String, dynamic>? ?? {};
    final metrics = json['metrics'] as Map<String, dynamic>? ?? {};
    final actions = (json['pendingActions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return PartnerDashboardOverview(
      partner: PartnerProfile.fromJson(pMap),
      totalBookings: (metrics['totalBookings'] as num?)?.toInt() ?? 0,
      upcomingBookings: (metrics['upcomingBookings'] as num?)?.toInt() ?? 0,
      completedBookings: (metrics['completedBookings'] as num?)?.toInt() ?? 0,
      totalRevenue: (metrics['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      businessesCount: (metrics['businessesCount'] as num?)?.toInt() ?? 0,
      docsCount: (metrics['docsCount'] as num?)?.toInt() ?? 0,
      staffCount: (metrics['staffCount'] as num?)?.toInt() ?? 0,
      pendingActions: actions,
    );
  }
}
