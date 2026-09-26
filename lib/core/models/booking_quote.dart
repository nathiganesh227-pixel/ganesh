class BookingQuote {
  final String type;
  final double subtotal;
  final double convenienceFee;
  final double taxes;
  final double grandTotal;
  final String currency;
  final Map<String, dynamic> breakdown;

  const BookingQuote({
    required this.type,
    required this.subtotal,
    required this.convenienceFee,
    required this.taxes,
    required this.grandTotal,
    this.currency = 'INR',
    this.breakdown = const {},
  });

  factory BookingQuote.fromJson(Map<String, dynamic> json) {
    return BookingQuote(
      type: json['type'] as String? ?? 'unknown',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      convenienceFee: (json['convenienceFee'] as num?)?.toDouble() ?? 0.0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      breakdown: (json['breakdown'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'subtotal': subtotal,
    'convenienceFee': convenienceFee,
    'taxes': taxes,
    'grandTotal': grandTotal,
    'currency': currency,
    'breakdown': breakdown,
  };
}
