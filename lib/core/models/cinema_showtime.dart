import 'movie.dart';

class ShowtimeSlot {
  final String id;
  final String time; // e.g. "10:30 AM"
  final MovieFormat format;
  final String language;
  final String screenName; // e.g. "Audi 2 (Laser IMAX)"
  final double basePrice;
  final bool isFillingFast;
  final bool isAlmostFull;
  final bool isSoldOut;

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
  });

  factory ShowtimeSlot.fromJson(Map<String, dynamic> json) {
    return ShowtimeSlot(
      id: json['id'] as String? ?? '',
      time: json['time'] as String? ?? '',
      format: MovieFormat.fromString(json['format'] as String? ?? '2D'),
      language: json['language'] as String? ?? 'English',
      screenName: json['screenName'] as String? ?? '',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      isFillingFast: json['isFillingFast'] as bool? ?? false,
      isAlmostFull: json['isAlmostFull'] as bool? ?? false,
      isSoldOut: json['isSoldOut'] as bool? ?? false,
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
  };
}

class Theatre {
  final String id;
  final String name;
  final String location;
  final String distance;
  final List<String> amenities; // "Dolby Atmos", "Recliners", "Food Court", "Valet Parking"
  final List<ShowtimeSlot> showtimes;

  const Theatre({
    required this.id,
    required this.name,
    required this.location,
    required this.distance,
    required this.amenities,
    required this.showtimes,
  });

  factory Theatre.fromJson(Map<String, dynamic> json) {
    return Theatre(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
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
    'distance': distance,
    'amenities': amenities,
    'showtimes': showtimes.map((e) => e.toJson()).toList(),
  };
}

