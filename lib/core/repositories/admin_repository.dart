import '../network/api_response.dart';
import '../models/admin_models.dart';

abstract class AdminRepository {
  Future<ApiResponse<AdminDashboardStats>> getDashboardStats();
  
  // Users
  Future<ApiResponse<List<AdminUser>>> getUsers({int limit = 50, int offset = 0});
  Future<ApiResponse<AdminUser>> getUserById(String id);
  Future<ApiResponse<dynamic>> updateUserRole(String id, String role);

  // Movies
  Future<ApiResponse<List<AdminMovie>>> getMovies({int limit = 50, int offset = 0});
  Future<ApiResponse<AdminMovie>> createMovie(Map<String, dynamic> dto);
  Future<ApiResponse<AdminMovie>> updateMovie(String id, Map<String, dynamic> dto);
  Future<ApiResponse<dynamic>> deleteMovie(String id);

  // Theatres
  Future<ApiResponse<List<AdminTheatre>>> getTheatres({int limit = 50, int offset = 0});
  Future<ApiResponse<AdminTheatre>> createTheatre(Map<String, dynamic> dto);
  Future<ApiResponse<AdminTheatre>> updateTheatre(String id, Map<String, dynamic> dto);

  // Screens
  Future<ApiResponse<List<AdminScreen>>> getScreens({String? theatreId, int limit = 50, int offset = 0});
  Future<ApiResponse<AdminScreen>> createScreen(String theatreId, Map<String, dynamic> dto);
  Future<ApiResponse<AdminScreen>> updateScreen(String id, Map<String, dynamic> dto);

  // Shows
  Future<ApiResponse<List<AdminShow>>> getShows({String? movieId, String? theatreId, String? date, int limit = 50, int offset = 0});
  Future<ApiResponse<AdminShow>> createShow(Map<String, dynamic> dto);
  Future<ApiResponse<AdminShow>> updateShow(String id, Map<String, dynamic> dto);
  Future<ApiResponse<dynamic>> deleteShow(String id);

  // 6 Non-Movie Catalog Verticals (dining, events, activities, shopping, stays, sports)
  Future<ApiResponse<List<AdminCatalogItem>>> getVerticalItems(String vertical, {int limit = 50, int offset = 0});
  Future<ApiResponse<AdminCatalogItem>> createVerticalItem(String vertical, Map<String, dynamic> dto);
  Future<ApiResponse<AdminCatalogItem>> updateVerticalItem(String vertical, String id, Map<String, dynamic> dto);
  Future<ApiResponse<dynamic>> deleteVerticalItem(String vertical, String id);
  Future<ApiResponse<AdminCatalogItem>> publishVerticalItem(String vertical, String id);
  Future<ApiResponse<AdminCatalogItem>> unpublishVerticalItem(String vertical, String id);

  // Operations Search
  Future<ApiResponse<List<AdminSearchResult>>> searchOperations(String query);

  // Bookings Operations
  Future<ApiResponse<List<AdminBooking>>> getBookings({
    String? vertical,
    String? status,
    String? paymentStatus,
    String? search,
    int limit = 50,
    int offset = 0,
  });
  Future<ApiResponse<AdminBookingDetail>> getBookingDetails(String id);
  Future<ApiResponse<dynamic>> refundBooking(String id, String reason);

  // Payments Operations
  Future<ApiResponse<List<AdminPayment>>> getPayments({
    String? status,
    String? search,
    int limit = 50,
    int offset = 0,
  });

  // Rewards Adjustment
  Future<ApiResponse<dynamic>> adjustUserRewards(String userId, int amount, String reason);

  // System Health
  Future<ApiResponse<AdminSystemHealth>> getSystemHealth();

  // Notifications
  Future<ApiResponse<List<AdminNotificationItem>>> getNotifications({int limit = 50, int offset = 0});

  // Incidents
  Future<ApiResponse<List<AdminIncident>>> getIncidents({int limit = 50, int offset = 0});

  // Audit Logs
  Future<ApiResponse<List<AdminAuditLog>>> getAuditLogs({int limit = 50, int offset = 0});
}
