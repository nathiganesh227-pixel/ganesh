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
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
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
