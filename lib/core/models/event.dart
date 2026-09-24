enum EventCategoryType {
  concerts('Concerts & Live Music'),
  comedy('Stand-up Comedy'),
  theatre('Theatre & Plays'),
  festivals('Festivals & Food'),
  workshops('Workshops & Art'),
  nightlife('Nightlife & DJ'),
  exhibitions('Exhibitions & Expos'),
  sports('Sports Events');

  final String label;
  const EventCategoryType(this.label);

  static EventCategoryType fromString(String val) {
    return EventCategoryType.values.firstWhere(
      (e) => e.label.toLowerCase() == val.toLowerCase() || e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => EventCategoryType.concerts,
    );
  }
}

class EventTicketTier {
  final String id;
  final String name; // e.g. "General Entry", "VIP Pass", "Fan Pit"
  final String description;
  final double price;
  final int remainingCount;
  final List<String> perks;

  const EventTicketTier({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.remainingCount,
    this.perks = const [],
  });

  factory EventTicketTier.fromJson(Map<String, dynamic> json) {
    return EventTicketTier(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      remainingCount: (json['remainingCount'] as num?)?.toInt() ?? 0,
      perks: (json['perks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'remainingCount': remainingCount,
    'perks': perks,
  };
}

class Performer {
  final String name;
  final String role;
  final String imageUrl;

  const Performer({
    required this.name,
    required this.role,
    required this.imageUrl,
  });

  factory Performer.fromJson(Map<String, dynamic> json) {
    return Performer(
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    'imageUrl': imageUrl,
  };
}

class PlazaEvent {
  final String id;
  final String title;
  final String tagline;
  final String description;
  final EventCategoryType category;
  final String posterUrl;
  final String bannerUrl;
  final DateTime eventDate;
  final String time;
  final String venue;
  final String location;
  final String distance;
  final double rating;
  final int interestedCount;
  final String ageRestriction;
  final String language;
  final String duration;
  final List<Performer> artists;
  final List<EventTicketTier> ticketTiers;
  final List<String> highlights;
  final List<String> gallery;
  final bool isHappeningToday;
  final bool isThisWeekend;
  final bool isTrending;

  const PlazaEvent({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.category,
    required this.posterUrl,
    required this.bannerUrl,
    required this.eventDate,
    required this.time,
    required this.venue,
    required this.location,
    required this.distance,
    required this.rating,
    required this.interestedCount,
    required this.ageRestriction,
    required this.language,
    required this.duration,
    required this.artists,
    required this.ticketTiers,
    required this.highlights,
    required this.gallery,
    this.isHappeningToday = false,
    this.isThisWeekend = false,
    this.isTrending = false,
  });

  double get startingPrice {
    if (ticketTiers.isEmpty) return 0;
    return ticketTiers.map((t) => t.price).reduce((a, b) => a < b ? a : b);
  }

  factory PlazaEvent.fromJson(Map<String, dynamic> json) {
    return PlazaEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      tagline: json['tagline'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: EventCategoryType.fromString(json['category'] as String? ?? 'Concerts'),
      posterUrl: json['posterUrl'] as String? ?? '',
      bannerUrl: json['bannerUrl'] as String? ?? '',
      eventDate: json['eventDate'] != null
          ? DateTime.tryParse(json['eventDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      time: json['time'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      location: json['location'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      interestedCount: (json['interestedCount'] as num?)?.toInt() ?? 0,
      ageRestriction: json['ageRestriction'] as String? ?? 'All Ages',
      language: json['languages'] as String? ?? json['language'] as String? ?? 'English',
      duration: json['duration'] as String? ?? '3 Hours',
      artists: (json['performers'] as List<dynamic>?)
              ?.map((e) => Performer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['artists'] as List<dynamic>?)
              ?.map((e) => Performer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ticketTiers: (json['ticketTiers'] as List<dynamic>?)
              ?.map((e) => EventTicketTier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      highlights: (json['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      gallery: (json['gallery'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isHappeningToday: json['isHappeningToday'] as bool? ?? false,
      isThisWeekend: json['isThisWeekend'] as bool? ?? false,
      isTrending: json['isTrending'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'tagline': tagline,
    'description': description,
    'category': category.label,
    'posterUrl': posterUrl,
    'bannerUrl': bannerUrl,
    'eventDate': eventDate.toIso8601String(),
    'time': time,
    'venue': venue,
    'location': location,
    'distance': distance,
    'rating': rating,
    'interestedCount': interestedCount,
    'ageRestriction': ageRestriction,
    'language': language,
    'duration': duration,
    'artists': artists.map((e) => e.toJson()).toList(),
    'ticketTiers': ticketTiers.map((e) => e.toJson()).toList(),
    'highlights': highlights,
    'gallery': gallery,
    'isHappeningToday': isHappeningToday,
    'isThisWeekend': isThisWeekend,
    'isTrending': isTrending,
  };
}


class EventBooking {
  final String bookingId;
  final PlazaEvent event;
  final DateTime date;
  final EventTicketTier ticketTier;
  final int quantity;
  final double subtotal;
  final double platformFee;
  final double taxes;
  final double discountAmount;
  final double grandTotal;
  final String paymentMethod;
  final DateTime bookedAt;

  const EventBooking({
    required this.bookingId,
    required this.event,
    required this.date,
    required this.ticketTier,
    required this.quantity,
    required this.subtotal,
    required this.platformFee,
    required this.taxes,
    required this.discountAmount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.bookedAt,
  });
}
