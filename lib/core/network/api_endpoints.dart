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

  // Admin Operations
  static const String adminHealth = '/admin/health';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static String adminUserRole(String id) => '/admin/users/$id/role';
  static const String adminMovies = '/admin/movies';
  static String adminMovieDetails(String id) => '/admin/movies/$id';
  static const String adminTheatres = '/admin/theatres';
  static String adminTheatreDetails(String id) => '/admin/theatres/$id';
  static String adminTheatreScreens(String theatreId) => '/admin/theatres/$theatreId/screens';
  static const String adminScreens = '/admin/screens';
  static String adminScreenDetails(String id) => '/admin/screens/$id';
  static const String adminShows = '/admin/shows';
  static String adminShowDetails(String id) => '/admin/shows/$id';
  static const String adminDining = '/admin/dining';
  static String adminDiningDetails(String id) => '/admin/dining/$id';
  static const String adminEvents = '/admin/events';
  static String adminEventDetails(String id) => '/admin/events/$id';
  static const String adminActivities = '/admin/activities';
  static String adminActivityDetails(String id) => '/admin/activities/$id';
  static const String adminShopping = '/admin/shopping';
  static String adminShoppingDetails(String id) => '/admin/shopping/$id';
  static const String adminStays = '/admin/stays';
  static String adminStayDetails(String id) => '/admin/stays/$id';
  static const String adminSports = '/admin/sports';
  static String adminSportsDetails(String id) => '/admin/sports/$id';
  static const String adminAuditLogs = '/admin/audit-logs';
  static String adminPublish(String vertical, String id) => '/admin/$vertical/$id/publish';
  static String adminUnpublish(String vertical, String id) => '/admin/$vertical/$id/unpublish';
}
