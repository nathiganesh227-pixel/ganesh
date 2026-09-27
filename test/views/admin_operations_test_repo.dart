import 'package:plaza/core/models/admin_models.dart';
import 'package:plaza/core/network/api_response.dart';
import 'package:plaza/core/repositories/admin_repository.dart';

class Phase21MockAdminRepository implements AdminRepository {
  @override
  Future<ApiResponse<AdminDashboardStats>> getDashboardStats() async {
    return ApiResponse.success(const AdminDashboardStats(
      users: 10,
      movies: 5,
      dining: 4,
      events: 3,
      activities: 2,
      shopping: 8,
      stays: 3,
      sports: 4,
      bookings: 20,
      platform: PlatformStats(
        grossBookingValue: 45000,
        totalBookings: 20,
        capturedPayments: 18,
        refundedPayments: 2,
        totalUsers: 10,
        totalRewardsIssued: 1500,
      ),
    ));
  }

  @override
  Future<ApiResponse<List<AdminUser>>> getUsers({int limit = 50, int offset = 0}) async {
    return ApiResponse.success([]);
  }

  @override
  Future<ApiResponse<AdminUser>> getUserById(String id) async {
    return ApiResponse.failure('Not found');
  }

  @override
  Future<ApiResponse<dynamic>> updateUserRole(String id, String role) async {
    return ApiResponse.success({'updated': true});
  }

  @override
  Future<ApiResponse<List<AdminMovie>>> getMovies({int limit = 50, int offset = 0}) async {
    return ApiResponse.success([]);
  }

  @override
  Future<ApiResponse<AdminMovie>> createMovie(Map<String, dynamic> dto) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<AdminMovie>> updateMovie(String id, Map<String, dynamic> dto) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<dynamic>> deleteMovie(String id) async {
    return ApiResponse.success({'deleted': true});
  }

  @override
  Future<ApiResponse<List<AdminTheatre>>> getTheatres({int limit = 50, int offset = 0}) async {
    return ApiResponse.success([]);
  }

  @override
  Future<ApiResponse<AdminTheatre>> createTheatre(Map<String, dynamic> dto) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<AdminTheatre>> updateTheatre(String id, Map<String, dynamic> dto) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<AdminScreen>>> getScreens({String? theatreId, int limit = 50, int offset = 0}) async {
    return ApiResponse.success([]);
  }

  @override
  Future<ApiResponse<AdminScreen>> createScreen(String theatreId, Map<String, dynamic> dto) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<AdminScreen>> updateScreen(String id, Map<String, dynamic> dto) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<AdminShow>>> getShows({String? movieId, String? theatreId, String? date, int limit = 50, int offset = 0}) async {
    return ApiResponse.success([]);
  }

  @override
  Future<ApiResponse<AdminShow>> createShow(Map<String, dynamic> dto) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<AdminShow>> updateShow(String id, Map<String, dynamic> dto) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<dynamic>> deleteShow(String id) async {
    return ApiResponse.success({'deleted': true});
  }

  @override
  Future<ApiResponse<List<AdminCatalogItem>>> getVerticalItems(String vertical, {int limit = 50, int offset = 0}) async {
    return ApiResponse.success([]);
  }

  @override
  Future<ApiResponse<AdminCatalogItem>> createVerticalItem(String vertical, Map<String, dynamic> dto) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<AdminCatalogItem>> updateVerticalItem(String vertical, String id, Map<String, dynamic> dto) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<dynamic>> deleteVerticalItem(String vertical, String id) async {
    return ApiResponse.success({'deleted': true});
  }

  @override
  Future<ApiResponse<AdminCatalogItem>> publishVerticalItem(String vertical, String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<AdminCatalogItem>> unpublishVerticalItem(String vertical, String id) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<AdminSearchResult>>> searchOperations(String query) async {
    return ApiResponse.success([
      const AdminSearchResult(
        type: 'booking',
        id: 'bk_1',
        title: 'Booking #BK-MOV-8841',
        subtitle: 'Kalki 2898 AD • Gopi Ganesh',
        status: 'confirmed',
        link: '/bookings/bk_1',
      ),
    ]);
  }

  @override
  Future<ApiResponse<List<AdminBooking>>> getBookings({
    String? vertical,
    String? status,
    String? paymentStatus,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    return ApiResponse.success([
      const AdminBooking(
        id: 'bk_1',
        userId: 'usr_1',
        type: 'movies',
        title: 'Kalki 2898 AD',
        subtitle: 'Audi 1 (IMAX)',
        date: '2026-09-26',
        location: 'PVR Inorbit Mall',
        status: 'confirmed',
        totalPrice: 700.0,
        paymentStatus: 'CAPTURED',
      ),
      const AdminBooking(
        id: 'bk_2',
        userId: 'usr_2',
        type: 'sports',
        title: 'Turf Court 1',
        subtitle: 'Box Cricket Arena',
        date: '2026-09-26',
        location: 'GamePoint Jubilee Hills',
        status: 'confirmed',
        totalPrice: 1200.0,
        paymentStatus: 'CAPTURED',
      ),
    ]);
  }

  @override
  Future<ApiResponse<AdminBookingDetail>> getBookingDetails(String id) async {
    return ApiResponse.success(const AdminBookingDetail(
      booking: AdminBooking(
        id: 'bk_1',
        userId: 'usr_1',
        type: 'movies',
        title: 'Kalki 2898 AD',
        subtitle: 'Audi 1 (IMAX)',
        date: '2026-09-26',
        location: 'PVR Inorbit Mall',
        status: 'confirmed',
        totalPrice: 700.0,
        paymentStatus: 'CAPTURED',
      ),
      customer: AdminUser(
        id: 'usr_1',
        name: 'Gopi Ganesh',
        email: 'gopi@plaza.club',
        phone: '+91 98765 43210',
        role: 'user',
      ),
      pricing: AdminPricingDetail(
        basePrice: 600,
        taxes: 100,
        totalPrice: 700,
        currency: 'INR',
      ),
      timeline: [
        {'event': 'Booking Created', 'timestamp': '2026-09-26T12:00:00Z'},
        {'event': 'Payment Captured', 'timestamp': '2026-09-26T12:00:02Z'},
      ],
    ));
  }

  @override
  Future<ApiResponse<dynamic>> refundBooking(String id, String reason) async {
    return ApiResponse.success({'refunded': true});
  }

  @override
  Future<ApiResponse<List<AdminPayment>>> getPayments({
    String? status,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    return ApiResponse.success([
      const AdminPayment(
        id: 'pay_1',
        bookingId: 'bk_1',
        userId: 'usr_1',
        amount: 700.0,
        currency: 'INR',
        provider: 'razorpay',
        providerPaymentId: 'pay_test_8841',
        status: 'captured',
      ),
    ]);
  }

  @override
  Future<ApiResponse<dynamic>> adjustUserRewards(String userId, int points, String reason) async {
    return ApiResponse.success({'adjusted': true});
  }

  @override
  Future<ApiResponse<AdminSystemHealth>> getSystemHealth() async {
    return ApiResponse.success(const AdminSystemHealth(
      status: 'HEALTHY',
      environment: 'production',
      uptimeSeconds: 86400,
      timestamp: '2026-09-26T12:00:00Z',
      apiStatus: 'UP',
      dbStatus: 'UP',
      dbLatencyMs: 2,
      paymentProvider: 'razorpay',
      paymentMode: 'TEST/SANDBOX',
      paymentWebhookConfigured: true,
      smsProvider: 'twilio',
      smsMode: 'TEST/SANDBOX',
    ));
  }

  @override
  Future<ApiResponse<List<AdminIncident>>> getIncidents({int limit = 50, int offset = 0}) async {
    return ApiResponse.success([]);
  }

  @override
  Future<ApiResponse<List<AdminNotificationItem>>> getNotifications({int limit = 50, int offset = 0}) async {
    return ApiResponse.success([]);
  }

  @override
  Future<ApiResponse<List<AdminAuditLog>>> getAuditLogs({int limit = 50, int offset = 0}) async {
    return ApiResponse.success([]);
  }
}
