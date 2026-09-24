import 'movie.dart';
import 'cinema_showtime.dart';
import 'cinema_seat.dart';

class FandBItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  int quantity;

  FandBItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.quantity = 0,
  });

  FandBItem copyWith({int? quantity}) {
    return FandBItem(
      id: id,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }
}

class MovieBooking {
  final String bookingId;
  final Movie movie;
  final Theatre theatre;
  final ShowtimeSlot showtime;
  final DateTime date;
  final List<CinemaSeat> seats;
  final List<FandBItem> snacks;
  final double ticketTotal;
  final double convenienceFee;
  final double taxes;
  final double discountAmount;
  final double grandTotal;
  final String paymentMethod;
  final DateTime bookedAt;

  const MovieBooking({
    required this.bookingId,
    required this.movie,
    required this.theatre,
    required this.showtime,
    required this.date,
    required this.seats,
    required this.snacks,
    required this.ticketTotal,
    required this.convenienceFee,
    required this.taxes,
    required this.discountAmount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.bookedAt,
  });

  String get seatsFormatted => seats.map((s) => s.displayName).join(', ');
}
