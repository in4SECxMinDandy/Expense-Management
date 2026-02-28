/// Loại insight AI
enum InsightType {
  spending,      // Phân tích chi tiêu
  saving,        // Gợi ý tiết kiệm
  warning,       // Cảnh báo
  achievement,   // Thành tựu
  trend,         // Xu hướng
  tip,           // Mẹo tài chính
}

/// Mức độ ưu tiên của insight
enum InsightPriority {
  low,
  medium,
  high,
  critical,
}

/// Model cho AI Insight
class AIInsight {
  final int? id;
  final String title;
  final String message;
  final InsightType type;
  final InsightPriority priority;
  final String? actionText;
  final String? actionRoute;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final bool isRead;

  AIInsight({
    this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = InsightPriority.medium,
    this.actionText,
    this.actionRoute,
    this.metadata,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Icon cho từng loại insight
  String get icon {
    switch (type) {
      case InsightType.spending:
        return '📊';
      case InsightType.saving:
        return '💰';
      case InsightType.warning:
        return '⚠️';
      case InsightType.achievement:
        return '🏆';
      case InsightType.trend:
        return '📈';
      case InsightType.tip:
        return '💡';
    }
  }

  /// Màu cho từng mức độ ưu tiên
  String get priorityColor {
    switch (priority) {
      case InsightPriority.low:
        return '#4CAF50';
      case InsightPriority.medium:
        return '#2196F3';
      case InsightPriority.high:
        return '#FF9800';
      case InsightPriority.critical:
        return '#F44336';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.index,
      'priority': priority.index,
      'action_text': actionText,
      'action_route': actionRoute,
      'metadata': metadata?.toString(),
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  factory AIInsight.fromMap(Map<String, dynamic> map) {
    return AIInsight(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      message: (map['message'] as String?) ?? '',
      type: InsightType.values[(map['type'] as int?) ?? 0],
      priority: InsightPriority.values[(map['priority'] as int?) ?? 1],
      actionText: map['action_text'] as String?,
      actionRoute: map['action_route'] as String?,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ?? DateTime.now(),
      isRead: (map['is_read'] as int?) == 1,
    );
  }

  AIInsight copyWith({
    int? id,
    String? title,
    String? message,
    InsightType? type,
    InsightPriority? priority,
    String? actionText,
    String? actionRoute,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AIInsight(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      actionText: actionText ?? this.actionText,
      actionRoute: actionRoute ?? this.actionRoute,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Kết quả phân tích tổng hợp - Cải tiến với nhiều metrics hơn
class SpendingAnalysis {
  final double totalIncome;
  final double totalExpense;
  final double savingsRate;
  final double avgDailySpending;
  final Map<int, double> categorySpending;
  final Map<int, String> categoryNames;
  final Map<int, String> categoryIcons;
  final Map<int, int> categoryTransactionCount;
  final List<double> weeklyTrend;
  final double spendingChange; // % thay đổi so với kỳ trước
  final int daysAnalyzed;
  final double predictedMonthlyExpense; // Dự đoán chi tiêu tháng tới
  final Map<int, double> weekdaySpending; // Chi tiêu theo ngày trong tuần
  final Map<String, double> monthlyTrend; // Xu hướng 6 tháng
  final int transactionCount;

  SpendingAnalysis({
    required this.totalIncome,
    required this.totalExpense,
    required this.savingsRate,
    required this.avgDailySpending,
    required this.categorySpending,
    required this.categoryNames,
    Map<int, String>? categoryIcons,
    Map<int, int>? categoryTransactionCount,
    required this.weeklyTrend,
    required this.spendingChange,
    required this.daysAnalyzed,
    double? predictedMonthlyExpense,
    Map<int, double>? weekdaySpending,
    Map<String, double>? monthlyTrend,
    int? transactionCount,
  })  : categoryIcons = categoryIcons ?? {},
        categoryTransactionCount = categoryTransactionCount ?? {},
        predictedMonthlyExpense = predictedMonthlyExpense ?? totalExpense,
        weekdaySpending = weekdaySpending ?? {},
        monthlyTrend = monthlyTrend ?? {},
        transactionCount = transactionCount ?? 0;

  double get balance => totalIncome - totalExpense;

  /// Danh mục chi tiêu nhiều nhất
  int? get topSpendingCategoryId {
    if (categorySpending.isEmpty) return null;
    return categorySpending.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Tỷ lệ chi tiêu theo danh mục
  Map<int, double> get categoryPercentages {
    if (totalExpense == 0) return {};
    return categorySpending.map(
      (key, value) => MapEntry(key, (value / totalExpense) * 100),
    );
  }

  /// Top N danh mục chi tiêu nhiều nhất
  List<MapEntry<int, double>> getTopCategories(int n) {
    final sorted = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  /// Ngày trong tuần chi tiêu nhiều nhất
  int? get topSpendingWeekday {
    if (weekdaySpending.isEmpty) return null;
    return weekdaySpending.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
