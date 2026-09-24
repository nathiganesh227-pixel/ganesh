enum SportType {
  boxCricket('Box Cricket', '🏏'),
  football('Football & Futsal', '⚽'),
  badminton('Badminton Courts', '🏸'),
  tennis('Lawn Tennis', '🎾'),
  basketball('Basketball 3x3 / Full', '🏀'),
  swimming('Heated Lap Pool', '🏊‍♂️'),
  pickleball('Pickleball & Padel', '🏓'),
  turf('Multi-Sport FIFA Turf', '🌱');

  final String label;
  final String emoji;
  const SportType(this.label, this.emoji);

  static SportType fromString(String val) {
    return SportType.values.firstWhere(
      (e) => e.label.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => SportType.boxCricket,
    );
  }
}

enum SlotStatus {
  available,
  fillingFast,
  fewSlotsLeft,
  soldOut;

  static SlotStatus fromString(String val) {
    return SlotStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => SlotStatus.available,
    );
  }
}

class SportsSlot {
  final String id;
  final String time; // e.g. "06:00 PM"
  final String duration; // e.g. "60 min"
  final double price;
  final SlotStatus status;
  final String courtName; // e.g. "Court A (Floodlit Turf)"

  const SportsSlot({
    required this.id,
    required this.time,
    this.duration = '60 min',
    required this.price,
    this.status = SlotStatus.available,
    required this.courtName,
  });

  bool get isBookable => status != SlotStatus.soldOut;

  factory SportsSlot.fromJson(Map<String, dynamic> json) {
    return SportsSlot(
      id: json['id'] as String? ?? '',
      time: json['time'] as String? ?? '',
      duration: json['duration'] as String? ?? '60 min',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: SlotStatus.fromString(json['status'] as String? ?? 'available'),
      courtName: json['courtName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time,
    'duration': duration,
    'price': price,
    'status': status.name,
    'courtName': courtName,
  };
}

class SportsAddOn {
  final String id;
  final String name;
  final double price;
  final String description;

  const SportsAddOn({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
  });

  factory SportsAddOn.fromJson(Map<String, dynamic> json) {
    return SportsAddOn(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'description': description,
  };
}

class SportsVenue {
  final String id;
  final String name;
  final List<SportType> supportedSports;
  final String location;
  final String address;
  final String distance;
  final double rating;
  final int reviewCount;
  final double startingPricePerHour;
  final String coverImageUrl;
  final List<String> galleryImages;
  final String description;
  final List<String> facilities;
  final List<String> rules;
  final List<SportsSlot> availableSlots;
  final List<SportsAddOn> equipmentAddOns;
  final bool isLiveNow;
  final String? badge;

  const SportsVenue({
    required this.id,
    required this.name,
    required this.supportedSports,
    required this.location,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.startingPricePerHour,
    required this.coverImageUrl,
    required this.galleryImages,
    required this.description,
    required this.facilities,
    required this.rules,
    required this.availableSlots,
    required this.equipmentAddOns,
    this.isLiveNow = false,
    this.badge,
  });

  factory SportsVenue.fromJson(Map<String, dynamic> json) {
    return SportsVenue(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      supportedSports: (json['supportedSports'] as List<dynamic>?)
              ?.map((e) => SportType.fromString(e.toString()))
              .toList() ??
          [],
      location: json['location'] as String? ?? '',
      address: json['address'] as String? ?? json['location'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      startingPricePerHour: (json['startingPricePerHour'] as num?)?.toDouble() ?? 0.0,
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      galleryImages: (json['galleryImages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      description: json['description'] as String? ?? json['rules'] as String? ?? '',
      facilities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          (json['facilities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      rules: json['rules'] is List
          ? (json['rules'] as List<dynamic>).map((e) => e.toString()).toList()
          : [json['rules'] as String? ?? 'Follow venue rules'],
      availableSlots: (json['slots'] as List<dynamic>?)
              ?.map((e) => SportsSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['availableSlots'] as List<dynamic>?)
              ?.map((e) => SportsSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      equipmentAddOns: (json['addOns'] as List<dynamic>?)
              ?.map((e) => SportsAddOn.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['equipmentAddOns'] as List<dynamic>?)
              ?.map((e) => SportsAddOn.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isLiveNow: json['isLiveNow'] as bool? ?? true,
      badge: json['badge'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'supportedSports': supportedSports.map((e) => e.label).toList(),
    'location': location,
    'address': address,
    'distance': distance,
    'rating': rating,
    'reviewCount': reviewCount,
    'startingPricePerHour': startingPricePerHour,
    'coverImageUrl': coverImageUrl,
    'galleryImages': galleryImages,
    'description': description,
    'facilities': facilities,
    'rules': rules,
    'availableSlots': availableSlots.map((e) => e.toJson()).toList(),
    'equipmentAddOns': equipmentAddOns.map((e) => e.toJson()).toList(),
    'isLiveNow': isLiveNow,
    'badge': badge,
  };
}


class SportsBooking {
  final String bookingId;
  final SportsVenue venue;
  final SportType sport;
  final DateTime date;
  final SportsSlot slot;
  final int durationMinutes;
  final int playersCount;
  final List<SportsAddOn> addOns;
  final bool isSquadBooking;
  final String squadName;
  final double courtPrice;
  final double addOnsTotal;
  final double convenienceFee;
  final double grandTotal;
  final double perPersonCost;
  final String bookerName;
  final String bookerPhone;
  final String qrCodeData;
  final String paymentMethod;
  final DateTime bookingTime;

  const SportsBooking({
    required this.bookingId,
    required this.venue,
    required this.sport,
    required this.date,
    required this.slot,
    required this.durationMinutes,
    required this.playersCount,
    required this.addOns,
    this.isSquadBooking = false,
    this.squadName = '',
    required this.courtPrice,
    required this.addOnsTotal,
    required this.convenienceFee,
    required this.grandTotal,
    required this.perPersonCost,
    required this.bookerName,
    required this.bookerPhone,
    required this.qrCodeData,
    required this.paymentMethod,
    required this.bookingTime,
  });
}
