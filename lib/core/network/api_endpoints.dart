/// Centralized REST API endpoints
class ApiEndpoints {
  // Movies
  static const String movies = '/movies';
  static String movieDetails(String id) => '/movies/$id';
  static String movieShowtimes(String id) => '/movies/$id/showtimes';
  static String movieShows(String id) => '/movies/$id/shows';

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

  // Unified Bookings & Payments
  static const String bookings = '/bookings';
  static String bookingDetails(String id) => '/bookings/$id';
  static const String bookingQuote = '/bookings/quote';
  static const String paymentOrders = '/payments/orders';
  static const String paymentVerify = '/payments/verify';
  static const String paymentFailed = '/payments/failed';

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

  // Operations Console
  static const String adminSystemHealth = '/admin/system-health';
  static const String adminSearch = '/admin/search';
  static const String adminBookings = '/admin/bookings';
  static String adminBookingDetails(String id) => '/admin/bookings/$id';
  static String adminRefundBooking(String id) => '/admin/bookings/$id/refund';
  static const String adminPayments = '/admin/payments';
  static String adminAdjustRewards(String id) => '/admin/users/$id/rewards';
  static const String adminNotifications = '/admin/notifications';
  static const String adminIncidents = '/admin/incidents';
  static String adminIncidentDetails(String id) => '/admin/incidents/$id';
  static String adminResolveIncident(String id) => '/admin/incidents/$id/resolve';
  static const String adminReconciliationDashboard = '/admin/payments/reconciliation/dashboard';
  static const String adminReconciliationRecords = '/admin/payments/reconciliation';
  static const String adminReconciliationSummary = '/admin/payments/reconciliation/summary';
  static String adminReconciliationDetails(String id) => '/admin/payments/reconciliation/$id';
  static String adminTriggerPaymentReconcile(String paymentId) => '/admin/payments/reconciliation/$paymentId/reconcile';
  static const String adminTriggerBatchReconcile = '/admin/payments/reconciliation/batch';
  static String adminResolveReconciliation(String id) => '/admin/payments/reconciliation/$id/resolve';

  // Phase 22 — Partner Portal Endpoints
  static const String partnerOnboard = '/partners/onboard';
  static String partnerProfile(String id) => '/partners/$id/profile';
  static String partnerDocuments(String id) => '/partners/$id/documents';
  static String partnerSubmit(String id) => '/partners/$id/submit';
  static String partnerBusinesses(String id) => '/partners/$id/businesses';
  static String partnerSubmitListing(String id, String bId) => '/partners/$id/businesses/$bId/submit';
  static String partnerPublishListing(String id, String bId) => '/partners/$id/businesses/$bId/publish';
  static String partnerUnpublishListing(String id, String bId) => '/partners/$id/businesses/$bId/unpublish';
  static String partnerBookings(String id) => '/partners/$id/bookings';
  static String partnerCheckIn(String id, String bId) => '/partners/$id/bookings/$bId/checkin';
  static String partnerStaff(String id) => '/partners/$id/staff';
  static String partnerInviteStaff(String id) => '/partners/$id/staff/invite';
  static String partnerRemoveStaff(String id, String uId) => '/partners/$id/staff/$uId';
  static String partnerPayout(String id) => '/partners/$id/payout';
  static String partnerDashboard(String id) => '/partners/$id/dashboard';

  // Phase 22 — Admin Partner Review Endpoints
  static const String adminPartners = '/admin/partners';
  static String adminPartnerDetails(String id) => '/admin/partners/$id';
  static String adminReviewPartner(String id) => '/admin/partners/$id/review';
  static String adminSuspendPartner(String id) => '/admin/partners/$id/suspend';
  static String adminResumePartner(String id) => '/admin/partners/$id/resume';
  static String adminReviewDocument(String id, String docId) => '/admin/partners/$id/documents/$docId/review';
  static String adminReviewListing(String id, String bId) => '/admin/partners/$id/businesses/$bId/review';

  // Phase 23 — Real Data & Availability Integration Layer
  static const String adminIntegrationProviders = '/admin/integrations/providers';
  static const String adminIntegrationHealth = '/admin/integrations/health';
  static const String adminIntegrationSyncRuns = '/admin/integrations/sync-runs';
  static const String adminIntegrationMappings = '/admin/integrations/mappings';
  static String adminIntegrationSync(String providerId) => '/admin/integrations/$providerId/sync';
  static String partnerUpdateAvailability(String id, String bId) => '/partners/$id/businesses/$bId/availability';
}
