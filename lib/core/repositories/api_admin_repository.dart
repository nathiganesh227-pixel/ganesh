import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/api_response.dart';
import '../models/admin_models.dart';
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
}
