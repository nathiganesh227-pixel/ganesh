/// Standard API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode ?? 200,
    );
  }

  factory ApiResponse.failure(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      data: null,
      message: message,
      statusCode: statusCode ?? 500,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
      statusCode: json['statusCode'] as int?,
    );
  }
}
