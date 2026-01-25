class Transaction {
  final int? id;
  final int categoryId;
  final double amount;
  final String date;
  final String? description;
  final String type; // 'income' or 'expense'
  final String? createdAt;
  final String? notes;
  final String? receiptPath;

  Transaction({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.description,
    required this.type,
    this.createdAt,
    this.notes,
    this.receiptPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'date': date,
      'description': description,
      'type': type,
      'created_at': createdAt,
      'notes': notes,
      'receipt_path': receiptPath,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      categoryId: map['category_id'],
      amount: map['amount'],
      date: map['date'],
      description: map['description'],
      type: map['type'],
      createdAt: map['created_at'],
      notes: map['notes'],
      receiptPath: map['receipt_path'],
    );
  }

  Transaction copyWith({
    int? id,
    int? categoryId,
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
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt,
      notes: notes ?? this.notes,
      receiptPath: receiptPath ?? this.receiptPath,
    );
  }
}
