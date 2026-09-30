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
  final int? _explicitAmountInMinorUnits;
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
    int? amountInMinorUnits,
    this.currency = 'INR',
    this.breakdown = const {},
  }) : _explicitAmountInMinorUnits = amountInMinorUnits;

  int get amountInMinorUnits =>
      _explicitAmountInMinorUnits ?? (grandTotal * 100).round();

  factory BookingQuote.fromJson(Map<String, dynamic> json) {
    final grandTotal = (json['grandTotal'] as num?)?.toDouble() ??
        (json['total'] as num?)?.toDouble() ??
        0.0;
    return BookingQuote(
      quoteId: json['quoteId'] as String?,
      expiresAt: json['expiresAt'] as String?,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      rewardsUsed: (json['rewardsUsed'] as num?)?.toInt() ?? 0,
      rewardsEarned: (json['rewardsEarned'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? 'unknown',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      convenienceFee: (json['convenienceFee'] as num?)?.toDouble() ??
          (json['fees'] as num?)?.toDouble() ??
          0.0,
      taxes: (json['taxes'] as num?)?.toDouble() ??
          (json['tax'] as num?)?.toDouble() ??
          0.0,
      grandTotal: grandTotal,
      amountInMinorUnits: (json['amountInMinorUnits'] as num?)?.toInt() ??
          (grandTotal * 100).round(),
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
    'amountInMinorUnits': amountInMinorUnits,
    'currency': currency,
    'breakdown': breakdown,
  };
}

/// Safe server-issued payment order session returned by POST /api/v1/payments/orders.
/// Contains only public checkout parameters and never includes server-side gateway secrets.
class PaymentOrderSession {
  final String paymentId;
  final String bookingId;
  final String quoteId;
  final String providerOrderId;
  final double amount;
  final int amountInMinorUnits;
  final String currency;
  final String paymentMode;
  final String status;
  final String? keyId;
  final String merchantName;
  final String description;
  final String expiresAt;
  final bool idempotentReplay;

  const PaymentOrderSession({
    required this.paymentId,
    required this.bookingId,
    required this.quoteId,
    required this.providerOrderId,
    required this.amount,
    required this.amountInMinorUnits,
    this.currency = 'INR',
    this.paymentMode = 'SIMULATED',
    this.status = 'PENDING',
    this.keyId,
    this.merchantName = 'PLAZA',
    this.description = 'PLAZA Booking',
    required this.expiresAt,
    this.idempotentReplay = false,
  });

  factory PaymentOrderSession.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    return PaymentOrderSession(
      paymentId: json['paymentId'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      quoteId: json['quoteId'] as String? ?? '',
      providerOrderId: json['providerOrderId'] as String? ??
          json['orderId'] as String? ??
          '',
      amount: amount,
      amountInMinorUnits: (json['amountInMinorUnits'] as num?)?.toInt() ??
          (amount * 100).round(),
      currency: json['currency'] as String? ?? 'INR',
      paymentMode: json['paymentMode'] as String? ?? 'SIMULATED',
      status: json['status'] as String? ?? 'PENDING',
      keyId: json['keyId'] as String?,
      merchantName: json['merchantName'] as String? ?? 'PLAZA',
      description: json['description'] as String? ?? 'PLAZA Booking',
      expiresAt: json['expiresAt'] as String? ?? '',
      idempotentReplay: json['idempotentReplay'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'paymentId': paymentId,
    'bookingId': bookingId,
    'quoteId': quoteId,
    'providerOrderId': providerOrderId,
    'amount': amount,
    'amountInMinorUnits': amountInMinorUnits,
    'currency': currency,
    'paymentMode': paymentMode,
    'status': status,
    if (keyId != null) 'keyId': keyId,
    'merchantName': merchantName,
    'description': description,
    'expiresAt': expiresAt,
    'idempotentReplay': idempotentReplay,
  };
}

