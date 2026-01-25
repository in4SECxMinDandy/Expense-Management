enum RepeatInterval { daily, weekly, monthly, yearly }

class RecurringTransaction {
  final int? id;
  final double amount;
  final int categoryId;
  final String description;
  final String type; // 'income' or 'expense'
  final RepeatInterval interval;
  final DateTime nextRunDate;
  final bool isActive;

  RecurringTransaction({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.type,
    required this.interval,
    required this.nextRunDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId,
      'description': description,
      'type': type,
      'repeat_interval': interval.name,
      'next_run_date': nextRunDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'],
      amount: map['amount'],
      categoryId: map['category_id'],
      description: map['description'],
      type: map['type'],
      interval: RepeatInterval.values.byName(map['repeat_interval']),
      nextRunDate: DateTime.parse(map['next_run_date']),
      isActive: map['is_active'] == 1,
    );
  }
}
