enum RewardCategory {
  movie,
  dining,
  stay,
  activity,
  general,
}

class RewardVoucher {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final double discountAmount;
  final double minSpend;
  final String code;
  final RewardCategory category;
  final DateTime expiryDate;
  final bool isRedeemed;

  const RewardVoucher({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.discountAmount,
    required this.minSpend,
    required this.code,
    required this.category,
    required this.expiryDate,
    this.isRedeemed = false,
  });

  RewardVoucher copyWith({
    String? id,
    String? title,
    String? description,
    int? pointsCost,
    double? discountAmount,
    double? minSpend,
    String? code,
    RewardCategory? category,
    DateTime? expiryDate,
    bool? isRedeemed,
  }) {
    return RewardVoucher(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsCost: pointsCost ?? this.pointsCost,
      discountAmount: discountAmount ?? this.discountAmount,
      minSpend: minSpend ?? this.minSpend,
      code: code ?? this.code,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      isRedeemed: isRedeemed ?? this.isRedeemed,
    );
  }
}

class RewardTransaction {
  final String id;
  final String title;
  final String description;
  final int pointsChange;
  final DateTime timestamp;
  final bool isCredit;

  const RewardTransaction({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsChange,
    required this.timestamp,
    required this.isCredit,
  });
}
