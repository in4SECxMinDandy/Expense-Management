class Budget {
  final int? id;
  final int? categoryId; // Null means overall budget
  final String month; // e.g., '2026-01'
  final double limitAmount;
  final double spentAmount;

  Budget({
    this.id,
    this.categoryId,
    required this.month,
    required this.limitAmount,
    this.spentAmount = 0.0,
  });

  Budget copyWith({
    int? id,
    int? categoryId,
    String? month,
    double? limitAmount,
    double? spentAmount,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'month': month,
      'limit_amount': limitAmount,
      'spent_amount': spentAmount,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      categoryId: map['category_id'],
      month: map['month'],
      limitAmount: map['limit_amount'],
      spentAmount: map['spent_amount'] ?? 0.0,
    );
  }
}
