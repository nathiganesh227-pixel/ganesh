enum SeatTier {
  vip('VIP Recliner', 450.0),
  premium('Premium', 295.0),
  executive('Executive', 175.0);

  final String label;
  final double defaultPrice;
  const SeatTier(this.label, this.defaultPrice);
}

enum SeatStatus {
  available,
  selected,
  occupied,
}

class CinemaSeat {
  final String id; // e.g. "A_5"
  final String rowLabel; // "A", "B", etc.
  final int seatNumber; // 1, 2, 3...
  final SeatTier tier;
  final double price;
  SeatStatus status;

  CinemaSeat({
    required this.id,
    required this.rowLabel,
    required this.seatNumber,
    required this.tier,
    required this.price,
    this.status = SeatStatus.available,
  });

  String get displayName => '$rowLabel$seatNumber';

  CinemaSeat copyWith({
    SeatStatus? status,
  }) {
    return CinemaSeat(
      id: id,
      rowLabel: rowLabel,
      seatNumber: seatNumber,
      tier: tier,
      price: price,
      status: status ?? this.status,
    );
  }
}
