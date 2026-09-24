enum PlazaNotificationCategory {
  all,
  bookings,
  deals,
  plans,
  rewards,
  alerts;

  String get label {
    switch (this) {
      case PlazaNotificationCategory.all:
        return 'All';
      case PlazaNotificationCategory.bookings:
        return 'Bookings';
      case PlazaNotificationCategory.deals:
        return 'Deals';
      case PlazaNotificationCategory.plans:
        return 'Plans';
      case PlazaNotificationCategory.rewards:
        return 'Rewards';
      case PlazaNotificationCategory.alerts:
        return 'Alerts';
    }
  }
}

class PlazaNotification {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final PlazaNotificationCategory category;
  final bool isRead;
  final String? actionRoute;

  const PlazaNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.category,
    this.isRead = false,
    this.actionRoute,
  });

  PlazaNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? timeAgo,
    PlazaNotificationCategory? category,
    bool? isRead,
    String? actionRoute,
  }) {
    return PlazaNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }
}

class RecentlyViewedItem {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String rating;
  final String location;
  final String priceInfo;
  final DateTime viewedAt;

  const RecentlyViewedItem({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.location,
    required this.priceInfo,
    required this.viewedAt,
  });
}
