enum ActivityCategoryType {
  bowling('Bowling'),
  cricket('Cricket & Turf'),
  goKarting('Go-Karting'),
  gaming('Gaming & Arcade'),
  escapeRooms('Escape Rooms'),
  trampoline('Trampoline & Parkour'),
  paintball('Paintball & Laser Tag'),
  adventure('Adventure & Zipline'),
  workshops('Pottery & Creative');

  final String label;
  const ActivityCategoryType(this.label);

  static ActivityCategoryType fromString(String val) {
    return ActivityCategoryType.values.firstWhere(
      (e) => e.label.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ActivityCategoryType.bowling,
    );
  }
}

class ActivityPackage {
  final String id;
  final String name; // e.g. "Standard Track", "Pro Twin-Engine", "Squad Unlimited"
  final String description;
  final double pricePerPerson;
  final String duration;
  final List<String> includedFeatures;

  const ActivityPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerPerson,
    required this.duration,
    required this.includedFeatures,
  });

  factory ActivityPackage.fromJson(Map<String, dynamic> json) {
    return ActivityPackage(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pricePerPerson: (json['pricePerPerson'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] as String? ?? '',
      includedFeatures: (json['includedFeatures'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'pricePerPerson': pricePerPerson,
    'duration': duration,
    'includedFeatures': includedFeatures,
  };
}

class ActivityAddOn {
  final String id;
  final String name;
  final String description;
  final double price;
  int quantity;

  ActivityAddOn({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.quantity = 0,
  });

  factory ActivityAddOn.fromJson(Map<String, dynamic> json) {
    return ActivityAddOn(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'quantity': quantity,
  };
}

class ActivityTimeSlot {
  final String time;
  final int availableSlots;
  final bool isFillingFast;

  const ActivityTimeSlot({
    required this.time,
    required this.availableSlots,
    this.isFillingFast = false,
  });

  factory ActivityTimeSlot.fromJson(Map<String, dynamic> json) {
    return ActivityTimeSlot(
      time: json['time'] as String? ?? '',
      availableSlots: (json['availableSlots'] as num?)?.toInt() ?? 0,
      isFillingFast: json['isFillingFast'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'availableSlots': availableSlots,
    'isFillingFast': isFillingFast,
  };
}

class PlazaActivity {
  final String id;
  final String title;
  final String venueName;
  final String location;
  final String distance;
  final ActivityCategoryType category;
  final String coverImageUrl;
  final List<String> gallery;
  final double rating;
  final int reviewCount;
  final String duration;
  final double startingPrice;
  final String liveAvailabilityLabel; // e.g. "2 lanes available at 7:30 PM"
  final String about;
  final List<String> whatIsIncluded;
  final List<String> requirements;
  final List<ActivityPackage> packages;
  final List<ActivityAddOn> addOns;
  final List<ActivityTimeSlot> availableSlots;
  final bool isTrending;
  final bool isGroupPick;
  final bool isAvailableNow;

  const PlazaActivity({
    required this.id,
    required this.title,
    required this.venueName,
    required this.location,
    required this.distance,
    required this.category,
    required this.coverImageUrl,
    required this.gallery,
    required this.rating,
    required this.reviewCount,
    required this.duration,
    required this.startingPrice,
    required this.liveAvailabilityLabel,
    required this.about,
    required this.whatIsIncluded,
    required this.requirements,
    required this.packages,
    this.addOns = const [],
    required this.availableSlots,
    this.isTrending = false,
    this.isGroupPick = false,
    this.isAvailableNow = false,
  });

  factory PlazaActivity.fromJson(Map<String, dynamic> json) {
    final pkgs = (json['packages'] as List<dynamic>?)
            ?.map((e) => ActivityPackage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    double derivedPrice = 450.0;
    if (json['startingPrice'] != null) {
      derivedPrice = (json['startingPrice'] as num).toDouble();
    } else if (pkgs.isNotEmpty) {
      derivedPrice = pkgs.map((p) => p.pricePerPerson).reduce((a, b) => a < b ? a : b);
    }

    return PlazaActivity(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      venueName: json['venueName'] as String? ?? json['location'] as String? ?? '',
      location: json['location'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      category: ActivityCategoryType.fromString(json['category'] as String? ?? 'Bowling'),
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      gallery: (json['galleryImages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (json['gallery'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      duration: json['duration'] as String? ?? '60 mins',
      startingPrice: derivedPrice,
      liveAvailabilityLabel: json['liveAvailabilityLabel'] as String? ?? 'Slots available',
      about: json['about'] as String? ?? json['description'] as String? ?? '',
      whatIsIncluded: (json['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (json['whatIsIncluded'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      requirements: (json['safetyGuidelines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (json['requirements'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      packages: pkgs,
      addOns: (json['addOns'] as List<dynamic>?)
              ?.map((e) => ActivityAddOn.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      availableSlots: (json['timeSlots'] as List<dynamic>?)
              ?.map((e) => ActivityTimeSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['availableSlots'] as List<dynamic>?)
              ?.map((e) => ActivityTimeSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isTrending: json['isTrending'] as bool? ?? false,
      isGroupPick: json['isPopular'] as bool? ?? json['isGroupPick'] as bool? ?? false,
      isAvailableNow: json['isAvailableNow'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'venueName': venueName,
    'location': location,
    'distance': distance,
    'category': category.label,
    'coverImageUrl': coverImageUrl,
    'gallery': gallery,
    'rating': rating,
    'reviewCount': reviewCount,
    'duration': duration,
    'startingPrice': startingPrice,
    'liveAvailabilityLabel': liveAvailabilityLabel,
    'about': about,
    'whatIsIncluded': whatIsIncluded,
    'requirements': requirements,
    'packages': packages.map((e) => e.toJson()).toList(),
    'addOns': addOns.map((e) => e.toJson()).toList(),
    'availableSlots': availableSlots.map((e) => e.toJson()).toList(),
    'isTrending': isTrending,
    'isGroupPick': isGroupPick,
    'isAvailableNow': isAvailableNow,
  };
}


class ActivityBooking {
  final String bookingId;
  final PlazaActivity activity;
  final DateTime date;
  final String timeSlot;
  final int numberOfPeople;
  final ActivityPackage package;
  final List<ActivityAddOn> addOns;
  final double subtotal;
  final double platformFee;
  final double taxes;
  final double discountAmount;
  final double grandTotal;
  final String paymentMethod;
  final bool isSharedGroupBooking;
  final DateTime bookedAt;

  const ActivityBooking({
    required this.bookingId,
    required this.activity,
    required this.date,
    required this.timeSlot,
    required this.numberOfPeople,
    required this.package,
    required this.addOns,
    required this.subtotal,
    required this.platformFee,
    required this.taxes,
    required this.discountAmount,
    required this.grandTotal,
    required this.paymentMethod,
    this.isSharedGroupBooking = false,
    required this.bookedAt,
  });
}
