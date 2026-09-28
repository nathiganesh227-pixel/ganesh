class BookingQuote {
  final String? quoteId;
  final String? expiresAt;
  final double discount;
  final int rewardsUsed;
  final int rewardsEarned;
  final String type;
  final double subtotal;
  final double convenienceFee;
  final double taxes;
  final double grandTotal;
  final String currency;
  final Map<String, dynamic> breakdown;

  const BookingQuote({
    this.quoteId,
    this.expiresAt,
    this.discount = 0.0,
    this.rewardsUsed = 0,
    this.rewardsEarned = 0,
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
      quoteId: json['quoteId'] as String?,
      expiresAt: json['expiresAt'] as String?,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      rewardsUsed: (json['rewardsUsed'] as num?)?.toInt() ?? 0,
      rewardsEarned: (json['rewardsEarned'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? 'unknown',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      convenienceFee: (json['convenienceFee'] as num?)?.toDouble() ?? (json['fees'] as num?)?.toDouble() ?? 0.0,
      taxes: (json['taxes'] as num?)?.toDouble() ?? (json['tax'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? (json['total'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      breakdown: (json['breakdown'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    if (quoteId != null) 'quoteId': quoteId,
    if (expiresAt != null) 'expiresAt': expiresAt,
    'discount': discount,
    'rewardsUsed': rewardsUsed,
    'rewardsEarned': rewardsEarned,
    'type': type,
    'subtotal': subtotal,
    'convenienceFee': convenienceFee,
    'taxes': taxes,
    'grandTotal': grandTotal,
    'currency': currency,
    'breakdown': breakdown,
  };
}
