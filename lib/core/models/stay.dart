enum StayCategoryType {
  luxury('Luxury Palaces & 5★', '👑'),
  resorts('Resorts & Spas', '🌴'),
  boutique('Boutique & Heritage', '🏛️'),
  business('Business & Tech Stays', '💼'),
  weekendGetaways('Weekend Getaways', '🚗'),
  villas('Private Villas & Pools', '🏡');

  final String label;
  final String emoji;
  const StayCategoryType(this.label, this.emoji);

  static StayCategoryType fromString(String val) {
    return StayCategoryType.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == val.toLowerCase() ||
          e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => StayCategoryType.luxury,
    );
  }
}

enum HotelAmenity {
  infinityPool('Infinity Pool', '🏊‍♂️'),
  freeWifi('Ultra-fast Wi-Fi', '📶'),
  spaWellness('Luxury Spa & Ayurvedic Wellness', '💆‍♀️'),
  fineDining('Fine Dining & Rooftop Bar', '🍽️'),
  valetParking('Complimentary Valet Parking', '🚗'),
  gymFitness('24/7 Fitness Center', '💪'),
  butlerService('Royal Butler Service', '🛎️'),
  airportShuttle('Airport Chauffeur Transfer', '✈️'),
  breakfastIncluded('Gourmet Buffet Breakfast', '☕');

  final String label;
  final String icon;
  const HotelAmenity(this.label, this.icon);

  static HotelAmenity fromString(String val) {
    return HotelAmenity.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == val.toLowerCase() ||
          e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => HotelAmenity.freeWifi,
    );
  }
}

class RoomType {
  final String id;
  final String name; // e.g. "Royal Heritage Suite", "Palace Deluxe Room"
  final String description;
  final String imageUrl;
  final double pricePerNight;
  final double? originalPricePerNight;
  final int maxGuests;
  final String bedType;
  final String roomSize;
  final List<String> highlights;
  final bool isAvailable;

  const RoomType({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.pricePerNight,
    this.originalPricePerNight,
    required this.maxGuests,
    required this.bedType,
    required this.roomSize,
    required this.highlights,
    this.isAvailable = true,
  });

  factory RoomType.fromJson(Map<String, dynamic> json) {
    return RoomType(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0.0,
      originalPricePerNight: (json['originalPricePerNight'] as num?)?.toDouble(),
      maxGuests: (json['maxGuests'] as num?)?.toInt() ?? 2,
      bedType: json['bedType'] as String? ?? '',
      roomSize: json['roomSize'] as String? ?? '',
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'pricePerNight': pricePerNight,
    'originalPricePerNight': originalPricePerNight,
    'maxGuests': maxGuests,
    'bedType': bedType,
    'roomSize': roomSize,
    'highlights': highlights,
    'isAvailable': isAvailable,
  };
}

class HotelAddOn {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool isPerNight;

  const HotelAddOn({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.isPerNight = false,
  });

  factory HotelAddOn.fromJson(Map<String, dynamic> json) {
    return HotelAddOn(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isPerNight: json['isPerNight'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'isPerNight': isPerNight,
  };
}

class Hotel {
  final String id;
  final String name;
  final String tagline;
  final StayCategoryType category;
  final String location;
  final String address;
  final String distance;
  final double rating;
  final int reviewCount;
  final double startingPricePerNight;
  final String coverImageUrl;
  final List<String> galleryImages;
  final String description;
  final List<HotelAmenity> amenities;
  final List<RoomType> roomTypes;
  final String checkInTime;
  final String checkOutTime;
  final bool isFeatured;
  final String? dealBadge;

  const Hotel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.category,
    required this.location,
    required this.address,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.startingPricePerNight,
    required this.coverImageUrl,
    required this.galleryImages,
    required this.description,
    required this.amenities,
    required this.roomTypes,
    this.checkInTime = '02:00 PM',
    this.checkOutTime = '12:00 PM',
    this.isFeatured = false,
    this.dealBadge,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      category: StayCategoryType.fromString(json['category'] as String? ?? ''),
      location: json['location'] as String? ?? '',
      address: json['address'] as String? ?? json['location'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      startingPricePerNight:
          (json['startingPricePerNight'] as num?)?.toDouble() ?? 0.0,
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      galleryImages: (json['galleryImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: json['description'] as String? ?? '',
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => HotelAmenity.fromString(e.toString()))
              .toList() ??
          [],
      roomTypes: (json['rooms'] as List<dynamic>?)
              ?.map((e) => RoomType.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['roomTypes'] as List<dynamic>?)
              ?.map((e) => RoomType.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      checkInTime: json['checkInTime'] as String? ?? '02:00 PM',
      checkOutTime: json['checkOutTime'] as String? ?? '12:00 PM',
      isFeatured: json['isFeatured'] as bool? ?? false,
      dealBadge: json['dealBadge'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tagline': tagline,
    'category': category.name,
    'location': location,
    'address': address,
    'distance': distance,
    'rating': rating,
    'reviewCount': reviewCount,
    'startingPricePerNight': startingPricePerNight,
    'coverImageUrl': coverImageUrl,
    'galleryImages': galleryImages,
    'description': description,
    'amenities': amenities.map((a) => a.name).toList(),
    'roomTypes': roomTypes.map((r) => r.toJson()).toList(),
    'checkInTime': checkInTime,
    'checkOutTime': checkOutTime,
    'isFeatured': isFeatured,
    'dealBadge': dealBadge,
  };
}

class HotelBooking {
  final String bookingId;
  final Hotel hotel;
  final RoomType roomType;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int nights;
  final int guestsCount;
  final int roomsCount;
  final List<HotelAddOn> selectedAddOns;
  final double roomTotal;
  final double addOnsTotal;
  final double taxesAndFees;
  final double grandTotal;
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final String specialRequests;
  final String qrCodeData;
  final String paymentMethod;
  final DateTime bookingTime;

  const HotelBooking({
    required this.bookingId,
    required this.hotel,
    required this.roomType,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.guestsCount,
    required this.roomsCount,
    required this.selectedAddOns,
    required this.roomTotal,
    required this.addOnsTotal,
    required this.taxesAndFees,
    required this.grandTotal,
    required this.guestName,
    required this.guestEmail,
    required this.guestPhone,
    required this.specialRequests,
    required this.qrCodeData,
    required this.paymentMethod,
    required this.bookingTime,
  });

  factory HotelBooking.fromJson(Map<String, dynamic> json) {
    return HotelBooking(
      bookingId: json['bookingId'] as String? ?? json['id'] as String? ?? '',
      hotel: Hotel.fromJson(json['hotel'] as Map<String, dynamic>),
      roomType: RoomType.fromJson(json['roomType'] as Map<String, dynamic>),
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      nights: (json['nights'] as num?)?.toInt() ?? 1,
      guestsCount: (json['guestsCount'] as num?)?.toInt() ?? 1,
      roomsCount: (json['roomsCount'] as num?)?.toInt() ?? 1,
      selectedAddOns: (json['selectedAddOns'] as List<dynamic>?)
              ?.map((e) => HotelAddOn.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      roomTotal: (json['roomTotal'] as num?)?.toDouble() ?? 0.0,
      addOnsTotal: (json['addOnsTotal'] as num?)?.toDouble() ?? 0.0,
      taxesAndFees: (json['taxesAndFees'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ??
          (json['totalPrice'] as num?)?.toDouble() ??
          0.0,
      guestName: json['guestName'] as String? ?? '',
      guestEmail: json['guestEmail'] as String? ?? '',
      guestPhone: json['guestPhone'] as String? ?? '',
      specialRequests: json['specialRequests'] as String? ?? '',
      qrCodeData: json['qrCodeData'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? 'Apple Pay',
      bookingTime: json['bookingTime'] != null
          ? DateTime.tryParse(json['bookingTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'bookingId': bookingId,
    'hotel': hotel.toJson(),
    'roomType': roomType.toJson(),
    'checkInDate': checkInDate.toIso8601String(),
    'checkOutDate': checkOutDate.toIso8601String(),
    'nights': nights,
    'guestsCount': guestsCount,
    'roomsCount': roomsCount,
    'selectedAddOns': selectedAddOns.map((a) => a.toJson()).toList(),
    'roomTotal': roomTotal,
    'addOnsTotal': addOnsTotal,
    'taxesAndFees': taxesAndFees,
    'grandTotal': grandTotal,
    'guestName': guestName,
    'guestEmail': guestEmail,
    'guestPhone': guestPhone,
    'specialRequests': specialRequests,
    'qrCodeData': qrCodeData,
    'paymentMethod': paymentMethod,
    'bookingTime': bookingTime.toIso8601String(),
  };
}
