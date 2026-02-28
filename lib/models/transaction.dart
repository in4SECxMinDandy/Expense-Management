/// Model giao dịch tài chính
class Transaction {
  final int? id;
  final int categoryId;
  final int? walletId;
  final double amount;
  final String date;
  final String? description;
  final String type; // 'income' or 'expense'
  final String? createdAt;
  final String? updatedAt;
  final String? notes;
  final String? receiptPath;

  Transaction({
    this.id,
    required this.categoryId,
    this.walletId,
    required this.amount,
    required this.date,
    this.description,
    required this.type,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.receiptPath,
  }) : assert(type == 'income' || type == 'expense',
            'type phải là "income" hoặc "expense"'),
       assert(amount >= 0, 'amount phải >= 0');

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'category_id': categoryId,
      'amount': amount,
      'date': date,
      'description': description,
      'type': type,
      'notes': notes,
      'receipt_path': receiptPath,
    };
    // Chỉ thêm id nếu không null (tránh lỗi khi insert)
    if (id != null) map['id'] = id;
    if (walletId != null) map['wallet_id'] = walletId;
    if (createdAt != null) map['created_at'] = createdAt;
    if (updatedAt != null) map['updated_at'] = updatedAt;
    return map;
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    // Xử lý amount an toàn - có thể là int hoặc double trong SQLite
    final rawAmount = map['amount'];
    final double amount;
    if (rawAmount is int) {
      amount = rawAmount.toDouble();
    } else if (rawAmount is double) {
      amount = rawAmount;
    } else {
      amount = double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;
    }

    return Transaction(
      id: map['id'] as int?,
      categoryId: (map['category_id'] as int?) ?? 0,
      walletId: map['wallet_id'] as int?,
      amount: amount,
      date: (map['date'] as String?) ?? DateTime.now().toIso8601String(),
      description: map['description'] as String?,
      type: (map['type'] as String?) ?? 'expense',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      notes: map['notes'] as String?,
      receiptPath: map['receipt_path'] as String?,
    );
  }

  Transaction copyWith({
    int? id,
    int? categoryId,
    int? walletId,
    double? amount,
    String? date,
    String? description,
    String? type,
    String? notes,
    String? receiptPath,
  }) {
    return Transaction(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      notes: notes ?? this.notes,
      receiptPath: receiptPath ?? this.receiptPath,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
