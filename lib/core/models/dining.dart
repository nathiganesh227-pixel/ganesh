enum CuisineType {
  telugu('Telugu & Andhra'),
  northIndian('North Indian'),
  southIndian('South Indian'),
  chinese('Asian & Chinese'),
  italian('Italian & Continental'),
  japanese('Japanese & Sushi'),
  cafe('Café & Bakery'),
  desserts('Desserts & Gelato'),
  mughlai('Biryani & Mughlai');

  final String label;
  const CuisineType(this.label);

  static CuisineType fromString(String val) {
    return CuisineType.values.firstWhere(
      (e) => e.label.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => CuisineType.northIndian,
    );
  }
}

enum SeatingPreference {
  indoor('Indoor AC'),
  outdoor('Outdoor / Rooftop'),
  window('Window View'),
  private('Private Dining');

  final String label;
  const SeatingPreference(this.label);

  static SeatingPreference fromString(String val) {
    return SeatingPreference.values.firstWhere(
      (e) => e.label.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => SeatingPreference.indoor,
    );
  }
}

class DishItem {
  final String name;
  final String description;
  final double price;
  final bool isVeg;
  final bool isChefSpecial;
  final String imageUrl;

  const DishItem({
    required this.name,
    required this.description,
    required this.price,
    this.isVeg = false,
    this.isChefSpecial = false,
    required this.imageUrl,
  });

  factory DishItem.fromJson(Map<String, dynamic> json) {
    return DishItem(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isVeg: json['isVeg'] as bool? ?? false,
      isChefSpecial: json['isChefSpecial'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
    'isVeg': isVeg,
    'isChefSpecial': isChefSpecial,
    'imageUrl': imageUrl,
  };
}

class DiningReview {
  final String userName;
  final double rating;
  final String comment;
  final String date;

  const DiningReview({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory DiningReview.fromJson(Map<String, dynamic> json) {
    return DiningReview(
      userName: json['userName'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'rating': rating,
    'comment': comment,
    'date': date,
  };
}

enum SlotAvailabilityStatus {
  available,
  fillingFast,
  fewTablesLeft,
  soldOut;

  static SlotAvailabilityStatus fromString(String val) {
    return SlotAvailabilityStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => SlotAvailabilityStatus.available,
    );
  }
}

class DiningTimeSlot {
  final String time; // e.g. "07:30 PM"
  final SlotAvailabilityStatus status;
  final int tablesLeft;

  const DiningTimeSlot({
    required this.time,
    required this.status,
    required this.tablesLeft,
  });

  factory DiningTimeSlot.fromJson(Map<String, dynamic> json) {
    return DiningTimeSlot(
      time: json['time'] as String? ?? '',
      status: SlotAvailabilityStatus.fromString(json['status'] as String? ?? 'available'),
      tablesLeft: (json['tablesLeft'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'status': status.name,
    'tablesLeft': tablesLeft,
  };
}

class Restaurant {
  final String id;
  final String name;
  final String tagline;
  final String about;
  final String coverImageUrl;
  final List<String> galleryImages;
  final double rating;
  final int reviewCount;
  final List<CuisineType> cuisines;
  final double priceForTwo;
  final String location;
  final String distance;
  final String openingHours;
  final bool isPureVeg;
  final bool hasOutdoor;
  final bool isOpenNow;
  final String? offerBadge;
  final List<String> amenities;
  final List<DishItem> popularDishes;
  final List<DiningReview> reviews;
  final List<DiningTimeSlot> availableSlots;
  final bool isTrending;
  final bool isFineDining;

  const Restaurant({
    required this.id,
    required this.name,
    required this.tagline,
    required this.about,
    required this.coverImageUrl,
    required this.galleryImages,
    required this.rating,
    required this.reviewCount,
    required this.cuisines,
    required this.priceForTwo,
    required this.location,
    required this.distance,
    required this.openingHours,
    this.isPureVeg = false,
    this.hasOutdoor = false,
    this.isOpenNow = true,
    this.offerBadge,
    required this.amenities,
    required this.popularDishes,
    required this.reviews,
    required this.availableSlots,
    this.isTrending = false,
    this.isFineDining = false,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      about: json['about'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      galleryImages: (json['galleryImages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      cuisines: (json['cuisines'] as List<dynamic>?)
              ?.map((e) => CuisineType.fromString(e.toString()))
              .toList() ??
          [],
      priceForTwo: (json['priceForTwo'] as num?)?.toDouble() ?? 0.0,
      location: json['location'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      openingHours: json['openingHours'] as String? ?? '',
      isPureVeg: json['isPureVeg'] as bool? ?? false,
      hasOutdoor: json['hasOutdoor'] as bool? ?? false,
      isOpenNow: json['isOpenNow'] as bool? ?? true,
      offerBadge: json['offerBadge'] as String?,
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      popularDishes: (json['popularDishes'] as List<dynamic>?)
              ?.map((e) => DishItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => DiningReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      availableSlots: (json['availableSlots'] as List<dynamic>?)
              ?.map((e) => DiningTimeSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isTrending: json['isTrending'] as bool? ?? false,
      isFineDining: json['isFineDining'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tagline': tagline,
    'about': about,
    'coverImageUrl': coverImageUrl,
    'galleryImages': galleryImages,
    'rating': rating,
    'reviewCount': reviewCount,
    'cuisines': cuisines.map((e) => e.label).toList(),
    'priceForTwo': priceForTwo,
    'location': location,
    'distance': distance,
    'openingHours': openingHours,
    'isPureVeg': isPureVeg,
    'hasOutdoor': hasOutdoor,
    'isOpenNow': isOpenNow,
    'offerBadge': offerBadge,
    'amenities': amenities,
    'popularDishes': popularDishes.map((e) => e.toJson()).toList(),
    'reviews': reviews.map((e) => e.toJson()).toList(),
    'availableSlots': availableSlots.map((e) => e.toJson()).toList(),
    'isTrending': isTrending,
    'isFineDining': isFineDining,
  };
}

class DiningReservation {
  final String reservationId;
  final Restaurant restaurant;
  final DateTime date;
  final String timeSlot;
  final int partySize;
  final SeatingPreference seatingPreference;
  final String? specialRequest;
  final String guestName;
  final String guestPhone;
  final DateTime createdAt;

  const DiningReservation({
    required this.reservationId,
    required this.restaurant,
    required this.date,
    required this.timeSlot,
    required this.partySize,
    required this.seatingPreference,
    this.specialRequest,
    required this.guestName,
    required this.guestPhone,
    required this.createdAt,
  });
}

