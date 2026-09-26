import '../data/plaza_global_state.dart';
import '../models/unified_booking.dart';
import '../models/booking_quote.dart';
import 'booking_repository.dart';

class LocalBookingRepository implements BookingRepository {
  const LocalBookingRepository();

  @override
  Future<List<UnifiedBooking>> getBookings({String? status}) async {
    final list = PlazaGlobalState.instance.bookings;
    if (status == null || status.isEmpty || status.toLowerCase() == 'all') {
      return list;
    }
    return list.where((b) => b.status.name.toLowerCase() == status.toLowerCase() || b.status.label.toLowerCase() == status.toLowerCase()).toList();
  }

  @override
  Future<UnifiedBooking?> getBookingById(String id) async {
    try {
      return PlazaGlobalState.instance.bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> cancelBooking(String id) async {
    PlazaGlobalState.instance.cancelBooking(id);
    return true;
  }

  @override
  Future<BookingQuote?> getQuote({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final t = type.toLowerCase();
    switch (t) {
      case 'movie':
        final seatCount = (payload['seatIds'] as List?)?.length ?? payload['seatCount'] ?? 2;
        const seatPrice = 450.0;
        final subtotal = seatPrice * seatCount;
        const convenienceFee = 70.0;
        final taxes = (subtotal * 0.05).roundToDouble();
        return BookingQuote(
          type: 'movie',
          subtotal: subtotal,
          convenienceFee: convenienceFee,
          taxes: taxes,
          grandTotal: subtotal + convenienceFee + taxes,
          currency: 'INR',
          breakdown: {'seatPrice': seatPrice, 'seatCount': seatCount},
        );
      case 'dining':
        return const BookingQuote(
          type: 'dining',
          subtotal: 0.0,
          convenienceFee: 0.0,
          taxes: 0.0,
          grandTotal: 0.0,
          currency: 'INR',
          breakdown: {'pricingModel': 'COMPLIMENTARY'},
        );
      case 'event':
        final ticketCount = (payload['ticketCount'] as num?)?.toInt() ?? 1;
        const ticketPrice = 999.0;
        final subtotal = ticketPrice * ticketCount;
        final convenienceFee = (subtotal * 0.05).roundToDouble();
        return BookingQuote(
          type: 'event',
          subtotal: subtotal,
          convenienceFee: convenienceFee,
          taxes: 0.0,
          grandTotal: subtotal + convenienceFee,
          currency: 'INR',
          breakdown: {'ticketPrice': ticketPrice, 'ticketCount': ticketCount},
        );
      case 'activity':
        final people = (payload['numberOfPeople'] as num?)?.toInt() ?? 1;
        const pricePerPerson = 1200.0;
        final subtotal = pricePerPerson * people;
        final taxes = (subtotal * 0.18).roundToDouble();
        return BookingQuote(
          type: 'activity',
          subtotal: subtotal,
          convenienceFee: 0.0,
          taxes: taxes,
          grandTotal: subtotal + taxes,
          currency: 'INR',
          breakdown: {'pricePerPerson': pricePerPerson, 'people': people},
        );
      case 'shopping':
        final items = (payload['items'] as List?) ?? [];
        final subtotal = items.length * 1200.0;
        const platformFee = 29.0;
        final gst = (subtotal * 0.05).roundToDouble();
        return BookingQuote(
          type: 'shopping',
          subtotal: subtotal,
          convenienceFee: platformFee,
          taxes: gst,
          grandTotal: subtotal + platformFee + gst,
          currency: 'INR',
        );
      case 'stay':
        final nights = (payload['nights'] as num?)?.toInt() ?? 1;
        final rooms = (payload['roomsCount'] as num?)?.toInt() ?? 1;
        const pricePerNight = 3500.0;
        final subtotal = pricePerNight * nights * rooms;
        final taxes = (subtotal * 0.12).roundToDouble();
        return BookingQuote(
          type: 'stay',
          subtotal: subtotal,
          convenienceFee: 0.0,
          taxes: taxes,
          grandTotal: subtotal + taxes,
          currency: 'INR',
        );
      case 'sports':
        const courtPrice = 1200.0;
        const convenienceFee = 50.0;
        return const BookingQuote(
          type: 'sports',
          subtotal: courtPrice,
          convenienceFee: convenienceFee,
          taxes: 0.0,
          grandTotal: courtPrice + convenienceFee,
          currency: 'INR',
        );
      default:
        return null;
    }
  }

  @override
  Future<bool> verifyPayment({
    required String bookingId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    return true;
  }
}
