import 'movie.dart';

class ShowtimeSlot {
  final String id;
  final String time; // e.g. "10:30 AM" or "19:30"
  final MovieFormat format;
  final String language;
  final String screenName; // e.g. "Audi 2 (Laser IMAX)"
  final double basePrice;
  final bool isFillingFast;
  final bool isAlmostFull;
  final bool isSoldOut;
  final Map<String, double>? pricing;
  final int? availableSeats;
  final int? totalSeats;

  const ShowtimeSlot({
    required this.id,
    required this.time,
    required this.format,
    required this.language,
    required this.screenName,
    required this.basePrice,
    this.isFillingFast = false,
    this.isAlmostFull = false,
    this.isSoldOut = false,
    this.pricing,
    this.availableSeats,
    this.totalSeats,
  });

  factory ShowtimeSlot.fromJson(Map<String, dynamic> json) {
    final pricingRaw = json['pricing'];
    Map<String, double>? pricing;
    if (pricingRaw is Map) {
      pricing = pricingRaw.map(
        (k, v) => MapEntry(k.toString().toLowerCase(), (v as num).toDouble()),
      );
    }

    final seatAvail = json['seatAvailability'] as Map<String, dynamic>?;
    final totalSeats = (seatAvail?['totalSeats'] as num?)?.toInt() ??
        (json['totalSeats'] as num?)?.toInt();
    final availSeats = (seatAvail?['availableSeats'] as num?)?.toInt() ??
        (json['availableSeats'] as num?)?.toInt();

    final isSoldOut = json['isSoldOut'] as bool? ?? (availSeats != null && availSeats <= 0);
    final isAlmostFull = json['isAlmostFull'] as bool? ??
        (availSeats != null && totalSeats != null && totalSeats > 0 && availSeats > 0 && availSeats <= (totalSeats * 0.15));
    final isFillingFast = json['isFillingFast'] as bool? ??
        (availSeats != null && totalSeats != null && totalSeats > 0 && availSeats > 0 && availSeats <= (totalSeats * 0.40));

    final basePrice = pricing?['gold'] ?? (json['basePrice'] as num?)?.toDouble() ?? 200.0;

    return ShowtimeSlot(
      id: json['id'] as String? ?? '',
      time: json['time'] as String? ?? json['startTime'] as String? ?? '',
      format: MovieFormat.fromString(json['format'] as String? ?? '2D'),
      language: json['language'] as String? ?? 'English',
      screenName: json['screenName'] as String? ?? '',
      basePrice: basePrice,
      isFillingFast: isFillingFast,
      isAlmostFull: isAlmostFull,
      isSoldOut: isSoldOut,
      pricing: pricing,
      availableSeats: availSeats,
      totalSeats: totalSeats,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time,
    'format': format.label,
    'language': language,
    'screenName': screenName,
    'basePrice': basePrice,
    'isFillingFast': isFillingFast,
    'isAlmostFull': isAlmostFull,
    'isSoldOut': isSoldOut,
    if (pricing != null) 'pricing': pricing,
    if (availableSeats != null) 'availableSeats': availableSeats,
    if (totalSeats != null) 'totalSeats': totalSeats,
  };
}

class Theatre {
  final String id;
  final String name;
  final String location;
  final String city;
  final String address;
  final String distance;
  final List<String> amenities; // "Dolby Atmos", "Recliners", "Food Court", "Valet Parking"
  final List<ShowtimeSlot> showtimes;

  const Theatre({
    required this.id,
    required this.name,
    required this.location,
    this.city = 'Hyderabad',
    this.address = '',
    required this.distance,
    required this.amenities,
    required this.showtimes,
  });

  factory Theatre.fromJson(Map<String, dynamic> json) {
    return Theatre(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      city: json['city'] as String? ?? 'Hyderabad',
      address: json['address'] as String? ?? json['location'] as String? ?? '',
      distance: json['distance'] as String? ?? '2.5 km',
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      showtimes: (json['showtimes'] as List<dynamic>?)
              ?.map((e) => ShowtimeSlot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'location': location,
    'city': city,
    'address': address,
    'distance': distance,
    'amenities': amenities,
    'showtimes': showtimes.map((e) => e.toJson()).toList(),
  };
}
