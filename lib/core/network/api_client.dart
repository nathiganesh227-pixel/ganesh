import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_response.dart';
import 'environment_config.dart';

/// Resilient HTTP client for PLAZA REST API
class ApiClient {
  final http.Client _client;
  String? _authToken;
  static String? _globalAuthToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Set token on this specific ApiClient instance and synchronize globally
  void setAuthToken(String? token) {
    _authToken = token;
    _globalAuthToken = token;
  }

  /// Global auth token setter for application-wide synchronization
  static void setGlobalAuthToken(String? token) {
    _globalAuthToken = token;
  }

  /// Current active token (instance token takes precedence over global token)
  String? get authToken => _authToken ?? _globalAuthToken;

  Map<String, String> _buildHeaders([Map<String, String>? customHeaders]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  String _extractErrorMessage(http.Response response) {
    try {
      if (response.body.isNotEmpty) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          final msg = decoded['message'];
          if (msg is String && msg.isNotEmpty) {
            return 'HTTP ${response.statusCode}: $msg';
          } else if (msg is List && msg.isNotEmpty) {
            return 'HTTP ${response.statusCode}: ${msg.join(", ")}';
          }
        }
      }
    } catch (_) {}
    return 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? "Error"}';
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final uri = Uri.parse('${EnvironmentConfig.baseUrl}$path').replace(
        queryParameters: queryParams,
      );

      final response = await _client
          .get(uri, headers: _buildHeaders(headers))
          .timeout(EnvironmentConfig.receiveTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body);
        if (body is Map<String, dynamic> && body.containsKey('data')) {
          return ApiResponse.success(
            fromJson(body['data']),
            message: body['message'] as String?,
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success(
          fromJson(body),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.failure(
          _extractErrorMessage(response),
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.failure('Network unavailable or server unreachable');
    } on TimeoutException {
      return ApiResponse.failure('Request timeout');
    } on http.ClientException catch (e) {
      return ApiResponse.failure('Client error: ${e.message}');
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final uri = Uri.parse('${EnvironmentConfig.baseUrl}$path');

      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(EnvironmentConfig.receiveTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resBody = json.decode(response.body);
        if (resBody is Map<String, dynamic> && resBody.containsKey('data')) {
          return ApiResponse.success(
            fromJson(resBody['data']),
            message: resBody['message'] as String?,
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success(
          fromJson(resBody),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.failure(
          _extractErrorMessage(response),
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.failure('Network unavailable or server unreachable');
    } on TimeoutException {
      return ApiResponse.failure('Request timeout');
    } on http.ClientException catch (e) {
      return ApiResponse.failure('Client error: ${e.message}');
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final uri = Uri.parse('${EnvironmentConfig.baseUrl}$path');

      final response = await _client
          .delete(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(EnvironmentConfig.receiveTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resBody = json.decode(response.body);
        if (resBody is Map<String, dynamic> && resBody.containsKey('data')) {
          return ApiResponse.success(
            fromJson(resBody['data']),
            message: resBody['message'] as String?,
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success(
          fromJson(resBody),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.failure(
          _extractErrorMessage(response),
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.failure('Network unavailable or server unreachable');
    } on TimeoutException {
      return ApiResponse.failure('Request timeout');
    } on http.ClientException catch (e) {
      return ApiResponse.failure('Client error: ${e.message}');
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final uri = Uri.parse('${EnvironmentConfig.baseUrl}$path');

      final response = await _client
          .patch(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(EnvironmentConfig.receiveTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resBody = json.decode(response.body);
        if (resBody is Map<String, dynamic> && resBody.containsKey('data')) {
          return ApiResponse.success(
            fromJson(resBody['data']),
            message: resBody['message'] as String?,
            statusCode: response.statusCode,
          );
        }
        return ApiResponse.success(
          fromJson(resBody),
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse.failure(
          _extractErrorMessage(response),
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.failure('Network unavailable or server unreachable');
    } on TimeoutException {
      return ApiResponse.failure('Request timeout');
    } on http.ClientException catch (e) {
      return ApiResponse.failure('Client error: ${e.message}');
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e');
    }
  }
}
