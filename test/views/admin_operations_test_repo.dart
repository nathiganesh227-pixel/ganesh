import 'package:plaza/core/models/admin_models.dart';
import 'package:plaza/core/models/integration_models.dart';
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

  @override
  Future<ApiResponse<List<IntegrationProviderInfo>>> getIntegrationProviders() async {
    return ApiResponse.success([]);
  }

  @override
  Future<ApiResponse<IntegrationHealthSummary>> getIntegrationHealth() async {
    return ApiResponse.success(const IntegrationHealthSummary(
      status: 'HEALTHY',
      totalProviders: 9,
      activeProviders: 2,
      configuredProviders: 2,
      unconfiguredProviders: 7,
      recentSyncRuns: [],
    ));
  }

  @override
  Future<ApiResponse<List<IntegrationSyncRun>>> getIntegrationSyncRuns({String? provider, int limit = 20, int offset = 0}) async {
    return ApiResponse.success([]);
  }

  @override
  Future<ApiResponse<dynamic>> triggerIntegrationSync(String providerId, {String? vertical}) async {
    return ApiResponse.success({'triggered': true, 'providerId': providerId});
  }

  // Phase 25.7 Stubs
  @override
  Future<ApiResponse<ReconciliationDashboardData>> getReconciliationDashboard() async {
    return ApiResponse.success(const ReconciliationDashboardData(
      reconciliation: {'total': 12, 'required': 3, 'inProgress': 1, 'resolved': 8, 'failed': 0, 'notRequired': 0},
      recovery: {'total': 5, 'required': 2, 'inProgress': 1, 'resolved': 2, 'failed': 0},
      webhooks: {'total': 18, 'received': 2, 'processing': 0, 'processed': 15, 'failed': 1, 'ignored': 0},
      mismatches: {'AMOUNT_MISMATCH': 2, 'NO_MISMATCH': 10},
      manualInterventionRequired: 5,
      paymentConfig: {'paymentMode': 'SIMULATED', 'razorpayLiveEnabled': false, 'livePaymentBlocked': true, 'status': 'SIMULATED_SAFE'},
    ));
  }

  @override
  Future<ApiResponse<List<ReconciliationRecordItem>>> getReconciliationRecords({
    String? status,
    String? mismatchCategory,
    String? paymentId,
    String? bookingId,
    bool? requiresManualIntervention,
    int limit = 50,
    int offset = 0,
  }) async {
    return ApiResponse.success([
      ReconciliationRecordItem(
        id: 'recon_101',
        paymentId: 'pay_recon_101',
        bookingId: 'bk_mov_101',
        provider: 'simulated',
        canonicalPaymentStatus: 'CAPTURED',
        observedProviderStatus: 'PENDING',
        canonicalAmount: 543,
        canonicalAmountInMinorUnits: 54300,
        observedAmountInMinorUnits: 54300,
        canonicalCurrency: 'INR',
        mismatchCategory: 'AMOUNT_MISMATCH',
        status: 'REQUIRED',
        attemptCount: 1,
        requiresManualIntervention: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<ApiResponse<ReconciliationDetailData>> getReconciliationDetails(String id) async {
    return ApiResponse.success(ReconciliationDetailData(
      record: ReconciliationRecordItem(
        id: id,
        paymentId: 'pay_recon_101',
        provider: 'simulated',
        canonicalPaymentStatus: 'CAPTURED',
        canonicalAmount: 543,
        canonicalAmountInMinorUnits: 54300,
        canonicalCurrency: 'INR',
        mismatchCategory: 'AMOUNT_MISMATCH',
        status: 'REQUIRED',
        attemptCount: 1,
        requiresManualIntervention: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      canonicalVsObserved: {
        'status': {'canonical': 'CAPTURED', 'observed': 'PENDING', 'matches': false},
        'amount': {'canonical': 543, 'canonicalMinor': 54300, 'observedMinor': 54300, 'matches': true},
        'currency': {'canonical': 'INR', 'observed': 'INR', 'matches': true},
      },
      timeline: [
        AdminTimelineEvent(
          timestamp: DateTime.now(),
          event: 'PAYMENT_CREATED',
          actor: 'system',
          status: 'PENDING',
          description: 'Payment intent created',
        ),
      ],
      auditLogs: [],
    ));
  }

  @override
  Future<ApiResponse<ReconciliationRecordItem>> triggerReconcile(String paymentId, {bool? force, String? notes}) async {
    return ApiResponse.success(ReconciliationRecordItem(
      id: 'recon_triggered',
      paymentId: paymentId,
      provider: 'simulated',
      canonicalPaymentStatus: 'CAPTURED',
      canonicalAmount: 543,
      canonicalAmountInMinorUnits: 54300,
      canonicalCurrency: 'INR',
      mismatchCategory: 'NO_MISMATCH',
      status: 'RESOLVED',
      attemptCount: 2,
      requiresManualIntervention: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<ApiResponse<dynamic>> triggerBatchReconcile({int limit = 20}) async {
    return ApiResponse.success({'processed': 5, 'resolved': 3, 'failed': 0});
  }

  @override
  Future<ApiResponse<ReconciliationRecordItem>> resolveReconciliation(
    String id, {
    String? action,
    String? notes,
    String? targetPaymentStatus,
    String? targetBookingStatus,
  }) async {
    return ApiResponse.success(ReconciliationRecordItem(
      id: id,
      paymentId: 'pay_recon_101',
      provider: 'simulated',
      canonicalPaymentStatus: targetPaymentStatus ?? 'CAPTURED',
      canonicalAmount: 543,
      canonicalAmountInMinorUnits: 54300,
      canonicalCurrency: 'INR',
      mismatchCategory: 'AMOUNT_MISMATCH',
      status: 'RESOLVED',
      attemptCount: 1,
      requiresManualIntervention: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<ApiResponse<List<UnifiedIncidentItem>>> getUnifiedIncidents({
    String? type,
    String? status,
    String? severity,
    bool? requiresManualIntervention,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    return ApiResponse.success([
      UnifiedIncidentItem(
        id: 'inc_rec_001',
        type: 'RECOVERY',
        title: 'Payment Recovery: UNKNOWN_PROVIDER_OUTCOME',
        description: 'Gateway timeout during capture',
        status: 'REQUIRED',
        severity: 'HIGH',
        referenceId: 'pay_sim_123',
        paymentId: 'pay_sim_123',
        bookingId: 'bk_001',
        failureCategory: 'UNKNOWN_PROVIDER_OUTCOME',
        requiresManualIntervention: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UnifiedIncidentItem(
        id: 'inc_recon_002',
        type: 'RECONCILIATION',
        title: 'Reconciliation: AMOUNT_MISMATCH',
        description: 'Discrepancy category AMOUNT_MISMATCH',
        status: 'REQUIRED',
        severity: 'HIGH',
        referenceId: 'pay_recon_101',
        paymentId: 'pay_recon_101',
        bookingId: 'bk_mov_101',
        mismatchCategory: 'AMOUNT_MISMATCH',
        requiresManualIntervention: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      UnifiedIncidentItem(
        id: 'evt_wh_003',
        type: 'WEBHOOK',
        title: 'Webhook: payment.failed',
        description: 'Signature verification error',
        status: 'FAILED',
        severity: 'HIGH',
        referenceId: 'pay_wh_003',
        failureCategory: 'WEBHOOK_FAILURE',
        requiresManualIntervention: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUnifiedIncidentDetails(String id) async {
    return ApiResponse.success({});
  }

  @override
  Future<ApiResponse<dynamic>> resolveUnifiedIncident(
    String id, {
    String? action,
    String? notes,
    bool? force,
    String? targetPaymentStatus,
    String? targetBookingStatus,
  }) async {
    return ApiResponse.success({'resolved': true});
  }
}
