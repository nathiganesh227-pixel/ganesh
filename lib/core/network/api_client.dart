import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_response.dart';
import 'environment_config.dart';

/// Resilient HTTP client for PLAZA REST API
class ApiClient {
  final http.Client _client;
  String? _authToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParams,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final uri = Uri.parse('${EnvironmentConfig.baseUrl}$path').replace(
        queryParameters: queryParams,
      );

      final response = await _client
          .get(uri, headers: _buildHeaders())
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
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.failure('Network unavailable or server unreachable');
    } on http.ClientException catch (e) {
      return ApiResponse.failure('Client error: ${e.message}');
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final uri = Uri.parse('${EnvironmentConfig.baseUrl}$path');

      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(),
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
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.failure('Network unavailable or server unreachable');
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final uri = Uri.parse('${EnvironmentConfig.baseUrl}$path');

      final response = await _client
          .delete(
            uri,
            headers: _buildHeaders(),
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
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.failure('Network unavailable or server unreachable');
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic>? body,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final uri = Uri.parse('${EnvironmentConfig.baseUrl}$path');

      final response = await _client
          .patch(
            uri,
            headers: _buildHeaders(),
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
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.failure('Network unavailable or server unreachable');
    } catch (e) {
      return ApiResponse.failure('Unexpected error: $e');
    }
  }
}

