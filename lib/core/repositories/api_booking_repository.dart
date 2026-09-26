import '../models/unified_booking.dart';
import '../models/booking_quote.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/environment_config.dart';
import 'booking_repository.dart';
import 'local_booking_repository.dart';

class ApiBookingRepository implements BookingRepository {
  final ApiClient _client;
  final LocalBookingRepository _fallback;

  ApiBookingRepository({
    ApiClient? client,
    LocalBookingRepository? fallback,
  })  : _client = client ?? ApiClient(),
        _fallback = fallback ?? const LocalBookingRepository();

  @override
  Future<List<UnifiedBooking>> getBookings({String? status}) async {
    try {
      final response = await _client.get<List<UnifiedBooking>>(
        ApiEndpoints.bookings,
        queryParams: (status != null && status.isNotEmpty && status.toLowerCase() != 'all')
            ? {'status': status.toLowerCase()}
            : null,
        fromJson: (json) {
          if (json is List) {
            return json
                .map((item) =>
                    UnifiedBooking.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }

      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        throw Exception(response.message ?? 'Failed to fetch bookings from server');
      }
    } catch (_) {
      if (EnvironmentConfig.current == AppEnvironment.prod &&
          !EnvironmentConfig.useMockData) {
        rethrow;
      }
    }
    return _fallback.getBookings(status: status);
  }

  @override
  Future<UnifiedBooking?> getBookingById(String id) async {
    try {
      final response = await _client.get<UnifiedBooking?>(
        ApiEndpoints.bookingDetails(id),
        fromJson: (json) => json != null
            ? UnifiedBooking.fromJson(json as Map<String, dynamic>)
            : null,
      );

      if (response.success && response.data != null) {
        return response.data;
      }

      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        throw Exception(response.message ?? 'Failed to fetch booking #$id');
      }
    } catch (_) {
      if (EnvironmentConfig.current == AppEnvironment.prod &&
          !EnvironmentConfig.useMockData) {
        rethrow;
      }
    }
    return _fallback.getBookingById(id);
  }

  @override
  Future<bool> cancelBooking(String id) async {
    try {
      final response = await _client.delete<Map<String, dynamic>>(
        ApiEndpoints.bookingDetails(id),
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (response.success) {
        await _fallback.cancelBooking(id);
        return true;
      }

      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        throw Exception(response.message ?? 'Failed to cancel booking #$id');
      }
      return false;
    } catch (_) {
      if (EnvironmentConfig.current == AppEnvironment.prod &&
          !EnvironmentConfig.useMockData) {
        rethrow;
      }
      return false;
    }
  }

  @override
  Future<BookingQuote?> getQuote({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await _client.post<BookingQuote?>(
        ApiEndpoints.bookingQuote,
        body: {
          'type': type,
          ...payload,
        },
        fromJson: (json) => json != null
            ? BookingQuote.fromJson(json as Map<String, dynamic>)
            : null,
      );

      if (response.success && response.data != null) {
        return response.data;
      }

      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        throw Exception(response.message ?? 'Failed to obtain quote from server');
      }
    } catch (_) {
      if (EnvironmentConfig.current == AppEnvironment.prod &&
          !EnvironmentConfig.useMockData) {
        rethrow;
      }
    }
    return _fallback.getQuote(type: type, payload: payload);
  }

  @override
  Future<bool> verifyPayment({
    required String bookingId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.paymentVerify,
        body: {
          'bookingId': bookingId,
          'razorpayOrderId': orderId,
          'razorpayPaymentId': paymentId,
          'razorpaySignature': signature,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success) {
        return true;
      }

      if (EnvironmentConfig.current == AppEnvironment.prod && !EnvironmentConfig.useMockData) {
        throw Exception(response.message ?? 'Payment verification failed');
      }
      return false;
    } catch (_) {
      if (EnvironmentConfig.current == AppEnvironment.prod &&
          !EnvironmentConfig.useMockData) {
        rethrow;
      }
      return _fallback.verifyPayment(
        bookingId: bookingId,
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
    }
  }
}
