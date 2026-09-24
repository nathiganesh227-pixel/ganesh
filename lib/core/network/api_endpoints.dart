/// Centralized REST API endpoints
class ApiEndpoints {
  // Movies
  static const String movies = '/movies';
  static String movieDetails(String id) => '/movies/$id';
  static String movieShowtimes(String id) => '/movies/$id/showtimes';

  // Dining
  static const String dining = '/dining';
  static String restaurantDetails(String id) => '/dining/$id';
  static const String diningReservations = '/dining/reservations';

  // Events
  static const String events = '/events';
  static String eventDetails(String id) => '/events/$id';
  static const String eventBookings = '/events/bookings';

  // Activities
  static const String activities = '/activities';
  static String activityDetails(String id) => '/activities/$id';
  static const String activityBookings = '/activities/bookings';

  // Shopping
  static const String shopping = '/shopping';
  static String productDetails(String id) => '/shopping/$id';
  static const String shoppingOrders = '/shopping/orders';

  // Stays
  static const String stays = '/stays';
  static String stayDetails(String id) => '/stays/$id';
  static const String stayBookings = '/stays/bookings';

  // Sports
  static const String sports = '/sports';
  static String sportsVenueDetails(String id) => '/sports/$id';
  static const String sportsBookings = '/sports/bookings';

  // Unified Bookings
  static const String bookings = '/bookings';
  static String bookingDetails(String id) => '/bookings/$id';

  // Plans, Rewards, Notifications & Search
  static const String plans = '/plans';
  static const String rewards = '/rewards';
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String auth = '/auth';
}
