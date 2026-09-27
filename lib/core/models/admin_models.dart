/// Platform-wide operations metrics
class PlatformStats {
  final int totalUsers;
  final int adminUsers;
  final int operatorUsers;
  final int totalBookings;
  final int upcomingBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int failedBookings;
  final int totalPayments;
  final int capturedPayments;
  final int failedPayments;
  final int refundedPayments;
  final double grossBookingValue;
  final double totalRefundAmount;
  final int totalRewardsIssued;

  const PlatformStats({
    this.totalUsers = 0,
    this.adminUsers = 0,
    this.operatorUsers = 0,
    this.totalBookings = 0,
    this.upcomingBookings = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.failedBookings = 0,
    this.totalPayments = 0,
    this.capturedPayments = 0,
    this.failedPayments = 0,
    this.refundedPayments = 0,
    this.grossBookingValue = 0,
    this.totalRefundAmount = 0,
    this.totalRewardsIssued = 0,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    return PlatformStats(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      adminUsers: (json['adminUsers'] as num?)?.toInt() ?? 0,
      operatorUsers: (json['operatorUsers'] as num?)?.toInt() ?? 0,
      totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
      upcomingBookings: (json['upcomingBookings'] as num?)?.toInt() ?? 0,
      completedBookings: (json['completedBookings'] as num?)?.toInt() ?? 0,
      cancelledBookings: (json['cancelledBookings'] as num?)?.toInt() ?? 0,
      failedBookings: (json['failedBookings'] as num?)?.toInt() ?? 0,
      totalPayments: (json['totalPayments'] as num?)?.toInt() ?? 0,
      capturedPayments: (json['capturedPayments'] as num?)?.toInt() ?? 0,
      failedPayments: (json['failedPayments'] as num?)?.toInt() ?? 0,
      refundedPayments: (json['refundedPayments'] as num?)?.toInt() ?? 0,
      grossBookingValue: (json['grossBookingValue'] as num?)?.toDouble() ?? 0,
      totalRefundAmount: (json['totalRefundAmount'] as num?)?.toDouble() ?? 0,
      totalRewardsIssued: (json['totalRewardsIssued'] as num?)?.toInt() ?? 0,
    );
  }
}

class VerticalMetric {
  final int total;
  final int active;

  const VerticalMetric({this.total = 0, this.active = 0});

  factory VerticalMetric.fromJson(Map<String, dynamic> json) {
    return VerticalMetric(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Data models for the PLAZA Admin Management System
class AdminDashboardStats {
  final int users;
  final int movies;
  final int dining;
  final int events;
  final int activities;
  final int shopping;
  final int stays;
  final int sports;
  final int bookings;
  final PlatformStats platform;
  final Map<String, VerticalMetric> verticals;

  const AdminDashboardStats({
    required this.users,
    required this.movies,
    required this.dining,
    required this.events,
    required this.activities,
    required this.shopping,
    required this.stays,
    required this.sports,
    required this.bookings,
    this.platform = const PlatformStats(),
    this.verticals = const {},
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final platformJson = json['platform'] as Map<String, dynamic>?;
    final verticalsJson = json['verticals'] as Map<String, dynamic>?;

    final verts = <String, VerticalMetric>{};
    if (verticalsJson != null) {
      verticalsJson.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          verts[k] = VerticalMetric.fromJson(v);
        }
      });
    }

    return AdminDashboardStats(
      users: (json['users'] as num?)?.toInt() ?? 0,
      movies: (json['movies'] as num?)?.toInt() ?? 0,
      dining: (json['dining'] as num?)?.toInt() ?? 0,
      events: (json['events'] as num?)?.toInt() ?? 0,
      activities: (json['activities'] as num?)?.toInt() ?? 0,
      shopping: (json['shopping'] as num?)?.toInt() ?? 0,
      stays: (json['stays'] as num?)?.toInt() ?? 0,
      sports: (json['sports'] as num?)?.toInt() ?? 0,
      bookings: (json['bookings'] as num?)?.toInt() ?? 0,
      platform: platformJson != null ? PlatformStats.fromJson(platformJson) : const PlatformStats(),
      verticals: verts,
    );
  }
}

class AdminUser {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? city;
  final String role;
  final int rewardPoints;
  final DateTime? createdAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.city,
    required this.role,
    this.rewardPoints = 0,
    this.createdAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      role: json['role'] as String? ?? 'user',
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

class AdminAuditLog {
  final String id;
  final String actorUserId;
  final String actorEmail;
  final String action;
  final String resourceType;
  final String resourceId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const AdminAuditLog({
    required this.id,
    required this.actorUserId,
    required this.actorEmail,
    required this.action,
    required this.resourceType,
    required this.resourceId,
    this.metadata,
    required this.createdAt,
  });

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    return AdminAuditLog(
      id: json['id'] as String? ?? '',
      actorUserId: json['actorUserId'] as String? ?? 'unknown',
      actorEmail: json['actorEmail'] as String? ?? 'system',
      action: json['action'] as String? ?? '',
      resourceType: json['resourceType'] as String? ?? '',
      resourceId: json['resourceId'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AdminMovie {
  final String id;
  final String title;
  final String? tagline;
  final String synopsis;
  final String posterUrl;
  final String backdropUrl;
  final double rating;
  final int votesCount;
  final List<String> genres;
  final String duration;
  final String primaryLanguage;
  final List<String> availableLanguages;
  final List<String> formats;
  final String certificate;
  final String releaseDate;
  final double startingPrice;
  final String director;
  final String? trailerYoutubeId;
  final bool isNowShowing;
  final bool isTrending;
  final bool isComingSoon;

  const AdminMovie({
    required this.id,
    required this.title,
    this.tagline,
    required this.synopsis,
    required this.posterUrl,
    required this.backdropUrl,
    required this.rating,
    required this.votesCount,
    required this.genres,
    required this.duration,
    required this.primaryLanguage,
    required this.availableLanguages,
    required this.formats,
    required this.certificate,
    required this.releaseDate,
    required this.startingPrice,
    required this.director,
    this.trailerYoutubeId,
    this.isNowShowing = true,
    this.isTrending = false,
    this.isComingSoon = false,
  });

  factory AdminMovie.fromJson(Map<String, dynamic> json) {
    return AdminMovie(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      tagline: json['tagline'] as String?,
      synopsis: json['synopsis'] as String? ?? '',
      posterUrl: json['posterUrl'] as String? ?? '',
      backdropUrl: json['backdropUrl'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      votesCount: (json['votesCount'] as num?)?.toInt() ?? 0,
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      duration: json['duration'] as String? ?? '2h',
      primaryLanguage: json['primaryLanguage'] as String? ?? 'Telugu',
      availableLanguages: (json['availableLanguages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      formats: (json['formats'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      certificate: json['certificate'] as String? ?? 'UA',
      releaseDate: json['releaseDate'] as String? ?? '',
      startingPrice: (json['startingPrice'] as num?)?.toDouble() ?? 0.0,
      director: json['director'] as String? ?? '',
      trailerYoutubeId: json['trailerYoutubeId'] as String?,
      isNowShowing: json['isNowShowing'] as bool? ?? true,
      isTrending: json['isTrending'] as bool? ?? false,
      isComingSoon: json['isComingSoon'] as bool? ?? false,
    );
  }
}

class AdminTheatre {
  final String id;
  final String name;
  final String location;
  final String city;
  final String? address;
  final String? distance;
  final List<String> amenities;
  final bool isActive;

  const AdminTheatre({
    required this.id,
    required this.name,
    required this.location,
    this.city = 'Hyderabad',
    this.address,
    this.distance,
    this.amenities = const [],
    this.isActive = true,
  });

  factory AdminTheatre.fromJson(Map<String, dynamic> json) {
    return AdminTheatre(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      city: json['city'] as String? ?? 'Hyderabad',
      address: json['address'] as String?,
      distance: json['distance'] as String?,
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class AdminScreen {
  final String id;
  final String theatreId;
  final String name;
  final String screenType;
  final int capacity;
  final bool isActive;

  const AdminScreen({
    required this.id,
    required this.theatreId,
    required this.name,
    this.screenType = 'standard',
    required this.capacity,
    this.isActive = true,
  });

  factory AdminScreen.fromJson(Map<String, dynamic> json) {
    return AdminScreen(
      id: json['id'] as String? ?? '',
      theatreId: json['theatreId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      screenType: json['screenType'] as String? ?? 'standard',
      capacity: (json['capacity'] as num?)?.toInt() ?? 100,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class AdminShowPricing {
  final double gold;
  final double premium;
  final double recliner;

  const AdminShowPricing({
    required this.gold,
    required this.premium,
    required this.recliner,
  });

  factory AdminShowPricing.fromJson(Map<String, dynamic> json) {
    return AdminShowPricing(
      gold: (json['gold'] as num?)?.toDouble() ?? 250.0,
      premium: (json['premium'] as num?)?.toDouble() ?? 350.0,
      recliner: (json['recliner'] as num?)?.toDouble() ?? 450.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'gold': gold,
    'premium': premium,
    'recliner': recliner,
  };
}

class AdminShow {
  final String id;
  final String movieId;
  final String theatreId;
  final String screenId;
  final String showDate;
  final String startTime;
  final String format;
  final String language;
  final AdminShowPricing pricing;
  final String status;

  const AdminShow({
    required this.id,
    required this.movieId,
    required this.theatreId,
    required this.screenId,
    required this.showDate,
    required this.startTime,
    this.format = '2D',
    this.language = 'Telugu',
    required this.pricing,
    this.status = 'active',
  });

  factory AdminShow.fromJson(Map<String, dynamic> json) {
    return AdminShow(
      id: json['id'] as String? ?? '',
      movieId: json['movieId'] as String? ?? '',
      theatreId: json['theatreId'] as String? ?? '',
      screenId: json['screenId'] as String? ?? '',
      showDate: json['showDate'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      format: json['format'] as String? ?? '2D',
      language: json['language'] as String? ?? 'Telugu',
      pricing: json['pricing'] is Map<String, dynamic>
          ? AdminShowPricing.fromJson(json['pricing'] as Map<String, dynamic>)
          : const AdminShowPricing(gold: 250, premium: 350, recliner: 450),
      status: json['status'] as String? ?? 'active',
    );
  }
}

/// Unified Catalog Item representation for the 6 non-movie verticals
class AdminCatalogItem {
  final String id;
  final String nameOrTitle;
  final String? tagline;
  final String? category;
  final String? location;
  final double? price;
  final double rating;
  final bool isPublished;
  final String? imageUrl;
  final Map<String, dynamic> raw;

  const AdminCatalogItem({
    required this.id,
    required this.nameOrTitle,
    this.tagline,
    this.category,
    this.location,
    this.price,
    this.rating = 4.5,
    this.isPublished = true,
    this.imageUrl,
    this.raw = const {},
  });

  factory AdminCatalogItem.fromJson(Map<String, dynamic> json) {
    final title = json['name'] as String? ?? json['title'] as String? ?? 'Untitled';
    final tag = json['tagline'] as String? ?? json['brand'] as String?;
    final cat = json['category'] as String?;
    final loc = json['location'] as String? ?? json['storeLocation'] as String? ?? json['venue'] as String?;
    final img = json['coverImageUrl'] as String? ?? json['posterUrl'] as String?;
    final prc = (json['price'] as num?)?.toDouble() ??
        (json['priceForTwo'] as num?)?.toDouble() ??
        (json['startingPricePerNight'] as num?)?.toDouble() ??
        (json['startingPricePerHour'] as num?)?.toDouble();

    return AdminCatalogItem(
      id: json['id'] as String? ?? '',
      nameOrTitle: title,
      tagline: tag,
      category: cat,
      location: loc,
      price: prc,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      isPublished: json['isPublished'] as bool? ?? true,
      imageUrl: img,
      raw: json,
    );
  }
}

/// Global Operations Search Result Item
class AdminSearchResult {
  final String type;
  final String id;
  final String title;
  final String subtitle;
  final String? status;
  final String? vertical;
  final String link;
  final Map<String, dynamic>? metadata;

  const AdminSearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    this.status,
    this.vertical,
    required this.link,
    this.metadata,
  });

  factory AdminSearchResult.fromJson(Map<String, dynamic> json) {
    return AdminSearchResult(
      type: json['type'] as String? ?? 'unknown',
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      status: json['status'] as String?,
      vertical: json['vertical'] as String?,
      link: json['link'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Admin Customer Booking Model
class AdminBooking {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String date;
  final String? time;
  final String location;
  final String status;
  final double totalPrice;
  final String paymentStatus;
  final String? paymentMethod;
  final double refundAmount;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  const AdminBooking({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.date,
    this.time,
    required this.location,
    required this.status,
    required this.totalPrice,
    this.paymentStatus = 'UNPAID',
    this.paymentMethod,
    this.refundAmount = 0,
    this.createdAt,
    this.metadata,
  });

  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get canRefund =>
      !isCancelled &&
      (paymentStatus.toUpperCase() == 'CAPTURED' || paymentStatus.toUpperCase() == 'AUTHORIZED');

  factory AdminBooking.fromJson(Map<String, dynamic> json) {
    return AdminBooking(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? 'movie',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      date: json['date'] as String? ?? '',
      time: json['time'] as String?,
      location: json['location'] as String? ?? '',
      status: json['status'] as String? ?? 'upcoming',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      paymentStatus: json['paymentStatus'] as String? ?? 'UNPAID',
      paymentMethod: json['paymentMethod'] as String?,
      refundAmount: (json['refundAmount'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

class AdminPricingDetail {
  final double basePrice;
  final double taxes;
  final double convenienceFee;
  final double discount;
  final double totalPrice;
  final String currency;

  const AdminPricingDetail({
    this.basePrice = 0,
    this.taxes = 0,
    this.convenienceFee = 0,
    this.discount = 0,
    this.totalPrice = 0,
    this.currency = 'INR',
  });

  factory AdminPricingDetail.fromJson(Map<String, dynamic> json) {
    return AdminPricingDetail(
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? 0,
      convenienceFee: (json['convenienceFee'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
    );
  }
}

class AdminBookingDetail {
  final AdminBooking booking;
  final AdminUser customer;
  final AdminPricingDetail pricing;
  final AdminPayment? payment;
  final List<Map<String, dynamic>> timeline;
  final List<AdminAuditLog> auditLogs;

  const AdminBookingDetail({
    required this.booking,
    required this.customer,
    required this.pricing,
    this.payment,
    this.timeline = const [],
    this.auditLogs = const [],
  });

  factory AdminBookingDetail.fromJson(Map<String, dynamic> json) {
    final b = AdminBooking.fromJson(json['booking'] as Map<String, dynamic>? ?? {});
    final c = AdminUser.fromJson(json['customer'] as Map<String, dynamic>? ?? {});
    final prc = AdminPricingDetail.fromJson(json['pricing'] as Map<String, dynamic>? ?? {});
    final pay = json['payment'] != null
        ? AdminPayment.fromJson(json['payment'] as Map<String, dynamic>)
        : null;

    final tl = (json['timeline'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];

    final logs = (json['auditLogs'] as List<dynamic>?)
            ?.map((e) => AdminAuditLog.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return AdminBookingDetail(
      booking: b,
      customer: c,
      pricing: prc,
      payment: pay,
      timeline: tl,
      auditLogs: logs,
    );
  }
}

/// Admin Payment Model
class AdminPayment {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String currency;
  final String provider;
  final String? providerOrderId;
  final String? providerPaymentId;
  final String status;
  final String? paymentMethod;
  final String? failureReason;
  final double refundAmount;
  final String? refundId;
  final DateTime? createdAt;

  const AdminPayment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    this.currency = 'INR',
    this.provider = 'razorpay',
    this.providerOrderId,
    this.providerPaymentId,
    required this.status,
    this.paymentMethod,
    this.failureReason,
    this.refundAmount = 0,
    this.refundId,
    this.createdAt,
  });

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    return AdminPayment(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      provider: json['provider'] as String? ?? 'razorpay',
      providerOrderId: json['providerOrderId'] as String?,
      providerPaymentId: json['providerPaymentId'] as String?,
      status: json['status'] as String? ?? 'CREATED',
      paymentMethod: json['paymentMethod'] as String?,
      failureReason: json['failureReason'] as String?,
      refundAmount: (json['refundAmount'] as num?)?.toDouble() ?? 0,
      refundId: json['refundId'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

/// Admin System Health Model
class AdminSystemHealth {
  final String status;
  final String timestamp;
  final int uptimeSeconds;
  final String environment;
  final String apiStatus;
  final String dbStatus;
  final int dbLatencyMs;
  final String paymentProvider;
  final String paymentMode;
  final bool paymentWebhookConfigured;
  final String smsProvider;
  final String smsMode;

  const AdminSystemHealth({
    this.status = 'HEALTHY',
    this.timestamp = '',
    this.uptimeSeconds = 0,
    this.environment = 'production',
    this.apiStatus = 'UP',
    this.dbStatus = 'UP',
    this.dbLatencyMs = 2,
    this.paymentProvider = 'razorpay',
    this.paymentMode = 'TEST/SANDBOX',
    this.paymentWebhookConfigured = true,
    this.smsProvider = 'twilio',
    this.smsMode = 'TEST/SANDBOX',
  });

  factory AdminSystemHealth.fromJson(Map<String, dynamic> json) {
    final services = json['services'] as Map<String, dynamic>? ?? {};
    final api = services['api'] as Map<String, dynamic>? ?? {};
    final db = services['database'] as Map<String, dynamic>? ?? {};
    final payments = services['payments'] as Map<String, dynamic>? ?? {};
    final notifs = services['notifications'] as Map<String, dynamic>? ?? {};

    return AdminSystemHealth(
      status: json['status'] as String? ?? 'HEALTHY',
      timestamp: json['timestamp'] as String? ?? '',
      uptimeSeconds: (json['uptimeSeconds'] as num?)?.toInt() ?? 0,
      environment: json['environment'] as String? ?? 'production',
      apiStatus: api['status'] as String? ?? 'UP',
      dbStatus: db['status'] as String? ?? 'UP',
      dbLatencyMs: (db['latencyMs'] as num?)?.toInt() ?? 0,
      paymentProvider: payments['provider'] as String? ?? 'razorpay',
      paymentMode: payments['mode'] as String? ?? 'TEST/SANDBOX',
      paymentWebhookConfigured: payments['webhookConfigured'] as bool? ?? false,
      smsProvider: notifs['smsProvider'] as String? ?? 'twilio',
      smsMode: notifs['mode'] as String? ?? 'TEST/SANDBOX',
    );
  }
}

/// Operational Incident Model
class AdminIncident {
  final String id;
  final String correlationId;
  final String severity;
  final String source;
  final String title;
  final String message;
  final String resourceType;
  final String resourceId;
  final String? bookingId;
  final DateTime? timestamp;

  const AdminIncident({
    required this.id,
    required this.correlationId,
    required this.severity,
    required this.source,
    required this.title,
    required this.message,
    required this.resourceType,
    required this.resourceId,
    this.bookingId,
    this.timestamp,
  });

  factory AdminIncident.fromJson(Map<String, dynamic> json) {
    return AdminIncident(
      id: json['id'] as String? ?? '',
      correlationId: json['correlationId'] as String? ?? '',
      severity: json['severity'] as String? ?? 'MEDIUM',
      source: json['source'] as String? ?? 'SYSTEM',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      resourceType: json['resourceType'] as String? ?? '',
      resourceId: json['resourceId'] as String? ?? '',
      bookingId: json['bookingId'] as String?,
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'] as String) : null,
    );
  }
}

/// Admin Notification Delivery Log Model
class AdminNotificationItem {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String timeAgo;
  final bool isRead;
  final String? actionRoute;
  final DateTime? createdAt;

  const AdminNotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.timeAgo = '',
    this.isRead = false,
    this.actionRoute,
    this.createdAt,
  });

  factory AdminNotificationItem.fromJson(Map<String, dynamic> json) {
    return AdminNotificationItem(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      timeAgo: json['timeAgo'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      actionRoute: json['actionRoute'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}
