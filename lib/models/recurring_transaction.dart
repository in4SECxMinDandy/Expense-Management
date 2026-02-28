/// Chu kỳ lặp lại của giao dịch định kỳ
enum RepeatInterval { daily, weekly, monthly, yearly }

/// Extension để lấy tên tiếng Việt
extension RepeatIntervalExtension on RepeatInterval {
  String get displayName {
    switch (this) {
      case RepeatInterval.daily:
        return 'Hàng ngày';
      case RepeatInterval.weekly:
        return 'Hàng tuần';
      case RepeatInterval.monthly:
        return 'Hàng tháng';
      case RepeatInterval.yearly:
        return 'Hàng năm';
    }
  }

  /// Tính ngày chạy tiếp theo từ ngày hiện tại
  DateTime nextDate(DateTime from) {
    switch (this) {
      case RepeatInterval.daily:
        return from.add(const Duration(days: 1));
      case RepeatInterval.weekly:
        return from.add(const Duration(days: 7));
      case RepeatInterval.monthly:
        // Xử lý tháng cuối năm và ngày cuối tháng
        final nextMonth = from.month == 12 ? 1 : from.month + 1;
        final nextYear = from.month == 12 ? from.year + 1 : from.year;
        final daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        final day = from.day > daysInNextMonth ? daysInNextMonth : from.day;
        return DateTime(nextYear, nextMonth, day, from.hour, from.minute);
      case RepeatInterval.yearly:
        return DateTime(
          from.year + 1,
          from.month,
          from.day,
          from.hour,
          from.minute,
        );
    }
  }
}

/// Model giao dịch định kỳ
class RecurringTransaction {
  final int? id;
  final double amount;
  final int categoryId;
  final String description;
  final String type; // 'income' or 'expense'
  final RepeatInterval interval;
  final DateTime nextRunDate;
  final bool isActive;
  final DateTime? lastRunDate;
  final bool notificationEnabled;

  RecurringTransaction({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.type,
    required this.interval,
    required this.nextRunDate,
    this.isActive = true,
    this.lastRunDate,
    this.notificationEnabled = true,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'amount': amount,
      'category_id': categoryId,
      'description': description,
      'type': type,
      'repeat_interval': interval.name,
      'next_run_date': nextRunDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'notification_enabled': notificationEnabled ? 1 : 0,
    };
    if (id != null) map['id'] = id;
    if (lastRunDate != null) map['last_run_date'] = lastRunDate!.toIso8601String();
    return map;
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    // Parse interval an toàn
    RepeatInterval interval;
    try {
      interval = RepeatInterval.values.byName(
        (map['repeat_interval'] as String?) ?? 'monthly',
      );
    } catch (_) {
      interval = RepeatInterval.monthly;
    }

    // Parse nextRunDate an toàn
    DateTime nextRunDate;
    try {
      nextRunDate = DateTime.parse(
        (map['next_run_date'] as String?) ?? DateTime.now().toIso8601String(),
      );
    } catch (_) {
      nextRunDate = DateTime.now();
    }

    // Parse lastRunDate an toàn
    DateTime? lastRunDate;
    if (map['last_run_date'] != null) {
      try {
        lastRunDate = DateTime.parse(map['last_run_date'] as String);
      } catch (_) {}
    }

    return RecurringTransaction(
      id: map['id'] as int?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: (map['category_id'] as int?) ?? 0,
      description: (map['description'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'expense',
      interval: interval,
      nextRunDate: nextRunDate,
      isActive: (map['is_active'] as int?) == 1,
      lastRunDate: lastRunDate,
      notificationEnabled: (map['notification_enabled'] as int?) != 0,
    );
  }

  RecurringTransaction copyWith({
    int? id,
    double? amount,
    int? categoryId,
    String? description,
    String? type,
    RepeatInterval? interval,
    DateTime? nextRunDate,
    bool? isActive,
    DateTime? lastRunDate,
    bool? notificationEnabled,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      type: type ?? this.type,
      interval: interval ?? this.interval,
      nextRunDate: nextRunDate ?? this.nextRunDate,
      isActive: isActive ?? this.isActive,
      lastRunDate: lastRunDate ?? this.lastRunDate,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }

  /// Kiểm tra xem giao dịch có đến hạn không
  bool get isDue => isActive && nextRunDate.isBefore(DateTime.now());

  /// Số ngày còn lại đến lần chạy tiếp theo
  int get daysUntilNextRun {
    final now = DateTime.now();
    return nextRunDate.difference(now).inDays;
  }

  @override
  String toString() {
    return 'RecurringTransaction(id: $id, description: $description, interval: ${interval.name})';
  }
}
