import '../../core/models/movie_booking.dart';
import '../../core/models/dining.dart';
import '../../core/models/event.dart';
import '../../core/models/activity.dart';
import '../../core/models/shopping.dart';
import '../../core/models/stay.dart';
import '../../core/models/sports.dart';

enum UnifiedBookingType {
  movie,
  dining,
  event,
  activity,
  shopping,
  stay,
  sports;

  String get displayName {
    switch (this) {
      case UnifiedBookingType.movie:
        return 'Movie';
      case UnifiedBookingType.dining:
        return 'Dining';
      case UnifiedBookingType.event:
        return 'Event';
      case UnifiedBookingType.activity:
        return 'Activity';
      case UnifiedBookingType.shopping:
        return 'Shopping';
      case UnifiedBookingType.stay:
        return 'Hotel Stay';
      case UnifiedBookingType.sports:
        return 'Sports';
    }
  }

  String get iconAsset {
    switch (this) {
      case UnifiedBookingType.movie:
        return 'movie';
      case UnifiedBookingType.dining:
        return 'dining';
      case UnifiedBookingType.event:
        return 'event';
      case UnifiedBookingType.activity:
        return 'activity';
      case UnifiedBookingType.shopping:
        return 'shopping';
      case UnifiedBookingType.stay:
        return 'stay';
      case UnifiedBookingType.sports:
        return 'sports';
    }
  }

  static UnifiedBookingType fromString(String val) {
    return UnifiedBookingType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => UnifiedBookingType.movie,
    );
  }
}

enum BookingStatus {
  upcoming,
  active,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.active:
        return 'Active Now';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  static BookingStatus fromString(String val) {
    return BookingStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => BookingStatus.upcoming,
    );
  }
}

class UnifiedBooking {
  final String id;
  final UnifiedBookingType type;
  final String title;
  final String subtitle;
  final String location;
  final DateTime date;
  final String time;
  final String imageUrl;
  final BookingStatus status;
  final double totalAmount;
  final String? confirmationCode;
  final String? seatOrSlotInfo;

  // Raw underlying booking instances for pass reconstruction
  final MovieBooking? movieBooking;
  final DiningReservation? diningReservation;
  final EventBooking? eventBooking;
  final ActivityBooking? activityBooking;
  final ShoppingOrder? shoppingOrder;
  final HotelBooking? hotelBooking;
  final SportsBooking? sportsBooking;

  const UnifiedBooking({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.date,
    required this.time,
    required this.imageUrl,
    required this.status,
    required this.totalAmount,
    this.confirmationCode,
    this.seatOrSlotInfo,
    this.movieBooking,
    this.diningReservation,
    this.eventBooking,
    this.activityBooking,
    this.shoppingOrder,
    this.hotelBooking,
    this.sportsBooking,
  });

  factory UnifiedBooking.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final dateVal = json['date'];
    if (dateVal is String) {
      parsedDate = DateTime.tryParse(dateVal) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return UnifiedBooking(
      id: json['id'] as String? ?? '',
      type: UnifiedBookingType.fromString(json['type'] as String? ?? 'movie'),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      location: json['location'] as String? ?? '',
      date: parsedDate,
      time: json['time'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      status: BookingStatus.fromString(json['status'] as String? ?? 'upcoming'),
      totalAmount: (json['totalPrice'] as num?)?.toDouble() ??
          (json['totalAmount'] as num?)?.toDouble() ??
          0.0,
      confirmationCode:
          json['qrCodeData'] as String? ?? json['confirmationCode'] as String?,
      seatOrSlotInfo: json['subtitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'subtitle': subtitle,
    'location': location,
    'date': date.toIso8601String(),
    'time': time,
    'imageUrl': imageUrl,
    'status': status.name,
    'totalPrice': totalAmount,
    'qrCodeData': confirmationCode,
  };

  UnifiedBooking copyWith({
    String? id,
    UnifiedBookingType? type,
    String? title,
    String? subtitle,
    String? location,
    DateTime? date,
    String? time,
    String? imageUrl,
    BookingStatus? status,
    double? totalAmount,
    String? confirmationCode,
    String? seatOrSlotInfo,
  }) {
    return UnifiedBooking(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      location: location ?? this.location,
      date: date ?? this.date,
      time: time ?? this.time,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      seatOrSlotInfo: seatOrSlotInfo ?? this.seatOrSlotInfo,
      movieBooking: movieBooking,
      diningReservation: diningReservation,
      eventBooking: eventBooking,
      activityBooking: activityBooking,
      shoppingOrder: shoppingOrder,
      hotelBooking: hotelBooking,
      sportsBooking: sportsBooking,
    );
  }
}
