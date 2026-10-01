import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/api_response.dart';
import '../models/admin_models.dart';
import '../models/integration_models.dart';
import 'admin_repository.dart';

class ApiAdminRepository implements AdminRepository {
  final ApiClient _client;

  ApiAdminRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<ApiResponse<AdminDashboardStats>> getDashboardStats() {
    return _client.get<AdminDashboardStats>(
      ApiEndpoints.adminDashboard,
      fromJson: (json) => AdminDashboardStats.fromJson(json as Map<String, dynamic>),
    );
  }

  // ---------------- USERS ----------------
  @override
  Future<ApiResponse<List<AdminUser>>> getUsers({int limit = 50, int offset = 0}) {
    return _client.get<List<AdminUser>>(
      ApiEndpoints.adminUsers,
      queryParams: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => AdminUser.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<AdminUser>> getUserById(String id) {
    return _client.get<AdminUser>(
      '${ApiEndpoints.adminUsers}/$id',
      fromJson: (json) => AdminUser.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<dynamic>> updateUserRole(String id, String role) {
    return _client.patch<dynamic>(
      ApiEndpoints.adminUserRole(id),
      body: {'role': role},
      fromJson: (json) => json,
    );
  }

  // ---------------- MOVIES ----------------
  @override
  Future<ApiResponse<List<AdminMovie>>> getMovies({int limit = 50, int offset = 0}) {
    return _client.get<List<AdminMovie>>(
      ApiEndpoints.adminMovies,
      queryParams: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => AdminMovie.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<AdminMovie>> createMovie(Map<String, dynamic> dto) {
    return _client.post<AdminMovie>(
      ApiEndpoints.adminMovies,
      body: dto,
      fromJson: (json) => AdminMovie.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<AdminMovie>> updateMovie(String id, Map<String, dynamic> dto) {
    return _client.patch<AdminMovie>(
      ApiEndpoints.adminMovieDetails(id),
      body: dto,
      fromJson: (json) => AdminMovie.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<dynamic>> deleteMovie(String id) {
    return _client.delete<dynamic>(
      ApiEndpoints.adminMovieDetails(id),
      fromJson: (json) => json,
    );
  }

  // ---------------- THEATRES ----------------
  @override
  Future<ApiResponse<List<AdminTheatre>>> getTheatres({int limit = 50, int offset = 0}) {
    return _client.get<List<AdminTheatre>>(
      ApiEndpoints.adminTheatres,
      queryParams: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => AdminTheatre.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<AdminTheatre>> createTheatre(Map<String, dynamic> dto) {
    return _client.post<AdminTheatre>(
      ApiEndpoints.adminTheatres,
      body: dto,
      fromJson: (json) => AdminTheatre.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<AdminTheatre>> updateTheatre(String id, Map<String, dynamic> dto) {
    return _client.patch<AdminTheatre>(
      ApiEndpoints.adminTheatreDetails(id),
      body: dto,
      fromJson: (json) => AdminTheatre.fromJson(json as Map<String, dynamic>),
    );
  }

  // ---------------- SCREENS ----------------
  @override
  Future<ApiResponse<List<AdminScreen>>> getScreens({String? theatreId, int limit = 50, int offset = 0}) {
    final query = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (theatreId != null && theatreId.isNotEmpty) {
      query['theatreId'] = theatreId;
    }
    return _client.get<List<AdminScreen>>(
      ApiEndpoints.adminScreens,
      queryParams: query,
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => AdminScreen.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<AdminScreen>> createScreen(String theatreId, Map<String, dynamic> dto) {
    return _client.post<AdminScreen>(
      ApiEndpoints.adminTheatreScreens(theatreId),
      body: dto,
      fromJson: (json) => AdminScreen.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<AdminScreen>> updateScreen(String id, Map<String, dynamic> dto) {
    return _client.patch<AdminScreen>(
      ApiEndpoints.adminScreenDetails(id),
      body: dto,
      fromJson: (json) => AdminScreen.fromJson(json as Map<String, dynamic>),
    );
  }

  // ---------------- SHOWS ----------------
  @override
  Future<ApiResponse<List<AdminShow>>> getShows({
    String? movieId,
    String? theatreId,
    String? date,
    int limit = 50,
    int offset = 0,
  }) {
    final query = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (movieId != null && movieId.isNotEmpty) query['movieId'] = movieId;
    if (theatreId != null && theatreId.isNotEmpty) query['theatreId'] = theatreId;
    if (date != null && date.isNotEmpty) query['date'] = date;

    return _client.get<List<AdminShow>>(
      ApiEndpoints.adminShows,
      queryParams: query,
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => AdminShow.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<AdminShow>> createShow(Map<String, dynamic> dto) {
    return _client.post<AdminShow>(
      ApiEndpoints.adminShows,
      body: dto,
      fromJson: (json) => AdminShow.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<AdminShow>> updateShow(String id, Map<String, dynamic> dto) {
    return _client.patch<AdminShow>(
      ApiEndpoints.adminShowDetails(id),
      body: dto,
      fromJson: (json) => AdminShow.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<dynamic>> deleteShow(String id) {
    return _client.delete<dynamic>(
      ApiEndpoints.adminShowDetails(id),
      fromJson: (json) => json,
    );
  }

  // ---------------- 6 NON-MOVIE CATALOG VERTICALS ----------------
  @override
  Future<ApiResponse<List<AdminCatalogItem>>> getVerticalItems(String vertical, {int limit = 50, int offset = 0}) {
    return _client.get<List<AdminCatalogItem>>(
      '/admin/$vertical',
      queryParams: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => AdminCatalogItem.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<AdminCatalogItem>> createVerticalItem(String vertical, Map<String, dynamic> dto) {
    return _client.post<AdminCatalogItem>(
      '/admin/$vertical',
      body: dto,
      fromJson: (json) => AdminCatalogItem.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<AdminCatalogItem>> updateVerticalItem(String vertical, String id, Map<String, dynamic> dto) {
    return _client.patch<AdminCatalogItem>(
      '/admin/$vertical/$id',
      body: dto,
      fromJson: (json) => AdminCatalogItem.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<dynamic>> deleteVerticalItem(String vertical, String id) {
    return _client.delete<dynamic>(
      '/admin/$vertical/$id',
      fromJson: (json) => json,
    );
  }

  @override
  Future<ApiResponse<AdminCatalogItem>> publishVerticalItem(String vertical, String id) {
    return _client.patch<AdminCatalogItem>(
      ApiEndpoints.adminPublish(vertical, id),
      fromJson: (json) => AdminCatalogItem.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<AdminCatalogItem>> unpublishVerticalItem(String vertical, String id) {
    return _client.patch<AdminCatalogItem>(
      ApiEndpoints.adminUnpublish(vertical, id),
      fromJson: (json) => AdminCatalogItem.fromJson(json as Map<String, dynamic>),
    );
  }

  // ---------------- AUDIT LOGS ----------------
  @override
  Future<ApiResponse<List<AdminAuditLog>>> getAuditLogs({int limit = 50, int offset = 0}) {
    return _client.get<List<AdminAuditLog>>(
      ApiEndpoints.adminAuditLogs,
      queryParams: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => AdminAuditLog.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  // ---------------- OPERATIONS SEARCH ----------------
  @override
  Future<ApiResponse<List<AdminSearchResult>>> searchOperations(String query) {
    return _client.get<List<AdminSearchResult>>(
      ApiEndpoints.adminSearch,
      queryParams: {'q': query},
      fromJson: (json) {
        if (json is Map<String, dynamic> && json['results'] is List) {
          return (json['results'] as List)
              .map((e) => AdminSearchResult.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  // ---------------- BOOKINGS OPERATIONS ----------------
  @override
  Future<ApiResponse<List<AdminBooking>>> getBookings({
    String? vertical,
    String? status,
    String? paymentStatus,
    String? search,
    int limit = 50,
    int offset = 0,
  }) {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (vertical != null && vertical.isNotEmpty && vertical != 'all') {
      params['vertical'] = vertical;
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      params['status'] = status;
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty && paymentStatus != 'all') {
      params['paymentStatus'] = paymentStatus;
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    return _client.get<List<AdminBooking>>(
      ApiEndpoints.adminBookings,
      queryParams: params,
      fromJson: (json) {
        if (json is Map<String, dynamic> && json['bookings'] is List) {
          return (json['bookings'] as List)
              .map((e) => AdminBooking.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (json is List) {
          return json.map((e) => AdminBooking.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<AdminBookingDetail>> getBookingDetails(String id) {
    return _client.get<AdminBookingDetail>(
      ApiEndpoints.adminBookingDetails(id),
      fromJson: (json) => AdminBookingDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<dynamic>> refundBooking(String id, String reason) {
    return _client.post<dynamic>(
      ApiEndpoints.adminRefundBooking(id),
      body: {'reason': reason},
      fromJson: (json) => json,
    );
  }

  // ---------------- PAYMENTS OPERATIONS ----------------
  @override
  Future<ApiResponse<List<AdminPayment>>> getPayments({
    String? status,
    String? search,
    int limit = 50,
    int offset = 0,
  }) {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null && status.isNotEmpty && status != 'all') {
      params['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    return _client.get<List<AdminPayment>>(
      ApiEndpoints.adminPayments,
      queryParams: params,
      fromJson: (json) {
        if (json is Map<String, dynamic> && json['payments'] is List) {
          return (json['payments'] as List)
              .map((e) => AdminPayment.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (json is List) {
          return json.map((e) => AdminPayment.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  // ---------------- REWARDS ADJUSTMENT ----------------
  @override
  Future<ApiResponse<dynamic>> adjustUserRewards(String userId, int amount, String reason) {
    return _client.post<dynamic>(
      ApiEndpoints.adminAdjustRewards(userId),
      body: {'amount': amount, 'reason': reason},
      fromJson: (json) => json,
    );
  }

  // ---------------- SYSTEM HEALTH ----------------
  @override
  Future<ApiResponse<AdminSystemHealth>> getSystemHealth() {
    return _client.get<AdminSystemHealth>(
      ApiEndpoints.adminSystemHealth,
      fromJson: (json) => AdminSystemHealth.fromJson(json as Map<String, dynamic>),
    );
  }

  // ---------------- NOTIFICATIONS ----------------
  @override
  Future<ApiResponse<List<AdminNotificationItem>>> getNotifications({int limit = 50, int offset = 0}) {
    return _client.get<List<AdminNotificationItem>>(
      ApiEndpoints.adminNotifications,
      queryParams: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (json) {
        if (json is Map<String, dynamic> && json['notifications'] is List) {
          return (json['notifications'] as List)
              .map((e) => AdminNotificationItem.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (json is List) {
          return json.map((e) => AdminNotificationItem.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  // ---------------- INCIDENTS ----------------
  @override
  Future<ApiResponse<List<AdminIncident>>> getIncidents({int limit = 50, int offset = 0}) {
    return _client.get<List<AdminIncident>>(
      ApiEndpoints.adminIncidents,
      queryParams: {'limit': limit.toString(), 'offset': offset.toString()},
      fromJson: (json) {
        if (json is Map<String, dynamic> && json['incidents'] is List) {
          return (json['incidents'] as List)
              .map((e) => AdminIncident.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (json is List) {
          return json.map((e) => AdminIncident.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  // ---------------- PHASE 23 INTEGRATIONS ----------------
  @override
  Future<ApiResponse<List<IntegrationProviderInfo>>> getIntegrationProviders() {
    return _client.get<List<IntegrationProviderInfo>>(
      ApiEndpoints.adminIntegrationProviders,
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => IntegrationProviderInfo.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<IntegrationHealthSummary>> getIntegrationHealth() {
    return _client.get<IntegrationHealthSummary>(
      ApiEndpoints.adminIntegrationHealth,
      fromJson: (json) => IntegrationHealthSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<List<IntegrationSyncRun>>> getIntegrationSyncRuns({String? provider, int limit = 20, int offset = 0}) {
    final params = {'limit': limit.toString(), 'offset': offset.toString()};
    if (provider != null) params['provider'] = provider;

    return _client.get<List<IntegrationSyncRun>>(
      ApiEndpoints.adminIntegrationSyncRuns,
      queryParams: params,
      fromJson: (json) {
        if (json is Map<String, dynamic> && json['items'] is List) {
          return (json['items'] as List)
              .map((e) => IntegrationSyncRun.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (json is List) {
          return json.map((e) => IntegrationSyncRun.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<dynamic>> triggerIntegrationSync(String providerId, {String? vertical}) {
    return _client.post<dynamic>(
      ApiEndpoints.adminIntegrationSync(providerId),
      body: vertical != null ? {'vertical': vertical} : {},
      fromJson: (json) => json,
    );
  }

  // ---------------- PHASE 25.7 RECONCILIATION & INCIDENT CENTER ----------------
  @override
  Future<ApiResponse<ReconciliationDashboardData>> getReconciliationDashboard() {
    return _client.get<ReconciliationDashboardData>(
      ApiEndpoints.adminReconciliationDashboard,
      fromJson: (json) => ReconciliationDashboardData.fromJson(json as Map<String, dynamic>),
    );
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
  }) {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null) params['status'] = status;
    if (mismatchCategory != null) params['mismatchCategory'] = mismatchCategory;
    if (paymentId != null) params['paymentId'] = paymentId;
    if (bookingId != null) params['bookingId'] = bookingId;
    if (requiresManualIntervention != null) params['requiresManualIntervention'] = requiresManualIntervention.toString();

    return _client.get<List<ReconciliationRecordItem>>(
      ApiEndpoints.adminReconciliationRecords,
      queryParams: params,
      fromJson: (json) {
        if (json is Map<String, dynamic> && json['items'] is List) {
          return (json['items'] as List)
              .map((e) => ReconciliationRecordItem.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (json is List) {
          return json.map((e) => ReconciliationRecordItem.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<ReconciliationDetailData>> getReconciliationDetails(String id) {
    return _client.get<ReconciliationDetailData>(
      ApiEndpoints.adminReconciliationDetails(id),
      fromJson: (json) => ReconciliationDetailData.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<ReconciliationRecordItem>> triggerReconcile(String paymentId, {bool? force, String? notes}) {
    final body = <String, dynamic>{};
    if (force != null) body['force'] = force;
    if (notes != null) body['notes'] = notes;

    return _client.post<ReconciliationRecordItem>(
      ApiEndpoints.adminTriggerPaymentReconcile(paymentId),
      body: body,
      fromJson: (json) => ReconciliationRecordItem.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<dynamic>> triggerBatchReconcile({int limit = 20}) {
    return _client.post<dynamic>(
      '${ApiEndpoints.adminTriggerBatchReconcile}?limit=$limit',
      fromJson: (json) => json,
    );
  }

  @override
  Future<ApiResponse<ReconciliationRecordItem>> resolveReconciliation(
    String id, {
    String? action,
    String? notes,
    String? targetPaymentStatus,
    String? targetBookingStatus,
  }) {
    final body = <String, dynamic>{};
    if (action != null) body['action'] = action;
    if (notes != null) body['notes'] = notes;
    if (targetPaymentStatus != null) body['targetPaymentStatus'] = targetPaymentStatus;
    if (targetBookingStatus != null) body['targetBookingStatus'] = targetBookingStatus;

    return _client.post<ReconciliationRecordItem>(
      ApiEndpoints.adminResolveReconciliation(id),
      body: body,
      fromJson: (json) => ReconciliationRecordItem.fromJson(json as Map<String, dynamic>),
    );
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
  }) {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;
    if (severity != null) params['severity'] = severity;
    if (requiresManualIntervention != null) params['requiresManualIntervention'] = requiresManualIntervention.toString();
    if (search != null) params['search'] = search;

    return _client.get<List<UnifiedIncidentItem>>(
      ApiEndpoints.adminIncidents,
      queryParams: params,
      fromJson: (json) {
        if (json is Map<String, dynamic> && json['incidents'] is List) {
          return (json['incidents'] as List)
              .map((e) => UnifiedIncidentItem.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (json is List) {
          return json.map((e) => UnifiedIncidentItem.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUnifiedIncidentDetails(String id) {
    return _client.get<Map<String, dynamic>>(
      ApiEndpoints.adminIncidentDetails(id),
      fromJson: (json) => json is Map<String, dynamic> ? json : {},
    );
  }

  @override
  Future<ApiResponse<dynamic>> resolveUnifiedIncident(
    String id, {
    String? action,
    String? notes,
    bool? force,
    String? targetPaymentStatus,
    String? targetBookingStatus,
  }) {
    final body = <String, dynamic>{};
    if (action != null) body['action'] = action;
    if (notes != null) body['notes'] = notes;
    if (force != null) body['force'] = force;
    if (targetPaymentStatus != null) body['targetPaymentStatus'] = targetPaymentStatus;
    if (targetBookingStatus != null) body['targetBookingStatus'] = targetBookingStatus;

    return _client.post<dynamic>(
      ApiEndpoints.adminResolveIncident(id),
      body: body,
      fromJson: (json) => json,
    );
  }
}
