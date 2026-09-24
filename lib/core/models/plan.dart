import 'unified_booking.dart';

enum PlanMood {
  chill(label: 'Chill', emoji: '☕', description: 'Relaxed cafe vibes & leisurely strolls'),
  foodie(label: 'Foodie', emoji: '🍜', description: 'Gourmet dining & street food crawls'),
  adventure(label: 'Adventure', emoji: '🏎️', description: 'Go-karting, bowling & thrills'),
  dateNight(label: 'Date Night', emoji: '🍷', description: 'Candlelight dinner & rooftop ambience'),
  family(label: 'Family', emoji: '👨‍👩‍👦', description: 'Kid-friendly, cinema & wholesome dining'),
  friends(label: 'Friends', emoji: '🎉', description: 'Lively pubs, sports & blockbuster movies'),
  luxury(label: 'Luxury', emoji: '✨', description: 'Five-star indulgence, spas & high-end dining'),
  explore(label: 'Explore', emoji: '🏛️', description: 'Monuments, heritage trails & local crafts');

  final String label;
  final String emoji;
  final String description;

  const PlanMood({
    required this.label,
    required this.emoji,
    required this.description,
  });
}

enum PlanTimeSlot {
  morning(label: 'Morning', timeRange: '9:00 AM - 1:00 PM'),
  afternoon(label: 'Afternoon', timeRange: '1:00 PM - 5:00 PM'),
  evening(label: 'Evening', timeRange: '5:00 PM - 9:00 PM'),
  night(label: 'Night', timeRange: '9:00 PM - 11:30 PM');

  final String label;
  final String timeRange;

  const PlanTimeSlot({
    required this.label,
    required this.timeRange,
  });
}

class PlanItem {
  final String id;
  final UnifiedBookingType vertical;
  final String title;
  final String venue;
  final String area;
  final String time;
  final String duration;
  final double costPerPerson;
  final String imageUrl;
  final String note;
  final PlanTimeSlot slot;

  const PlanItem({
    required this.id,
    required this.vertical,
    required this.title,
    required this.venue,
    required this.area,
    required this.time,
    required this.duration,
    required this.costPerPerson,
    required this.imageUrl,
    required this.note,
    required this.slot,
  });

  PlanItem copyWith({
    String? id,
    UnifiedBookingType? vertical,
    String? title,
    String? venue,
    String? area,
    String? time,
    String? duration,
    double? costPerPerson,
    String? imageUrl,
    String? note,
    PlanTimeSlot? slot,
  }) {
    return PlanItem(
      id: id ?? this.id,
      vertical: vertical ?? this.vertical,
      title: title ?? this.title,
      venue: venue ?? this.venue,
      area: area ?? this.area,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      costPerPerson: costPerPerson ?? this.costPerPerson,
      imageUrl: imageUrl ?? this.imageUrl,
      note: note ?? this.note,
      slot: slot ?? this.slot,
    );
  }
}

class PlazaPlan {
  final String id;
  final String title;
  final String subtitle;
  final PlanMood mood;
  final int peopleCount;
  final String locationArea;
  final DateTime date;
  final List<PlanItem> items;
  final bool isSaved;

  const PlazaPlan({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.mood,
    required this.peopleCount,
    required this.locationArea,
    required this.date,
    required this.items,
    this.isSaved = false,
  });

  double get totalCostPerPerson =>
      items.fold(0.0, (sum, item) => sum + item.costPerPerson);

  double get grandTotal => totalCostPerPerson * peopleCount;

  PlazaPlan copyWith({
    String? id,
    String? title,
    String? subtitle,
    PlanMood? mood,
    int? peopleCount,
    String? locationArea,
    DateTime? date,
    List<PlanItem>? items,
    bool? isSaved,
  }) {
    return PlazaPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      mood: mood ?? this.mood,
      peopleCount: peopleCount ?? this.peopleCount,
      locationArea: locationArea ?? this.locationArea,
      date: date ?? this.date,
      items: items ?? this.items,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
