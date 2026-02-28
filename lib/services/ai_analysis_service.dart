import 'dart:math';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/ai_insight.dart';

/// AI Analysis Service - Phân tích thói quen chi tiêu thông minh
/// Sử dụng rule-based analysis để đưa ra insights và lời khuyên
/// Cải tiến: Phân tích sâu hơn, dự đoán xu hướng, phát hiện pattern
class AIAnalysisService {
  // Singleton pattern
  static final AIAnalysisService _instance = AIAnalysisService._internal();
  factory AIAnalysisService() => _instance;
  AIAnalysisService._internal();

  /// Phân tích toàn bộ dữ liệu chi tiêu
  SpendingAnalysis analyzeSpending({
    required List<Transaction> transactions,
    required List<Category> categories,
    int days = 30,
  }) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    // Lọc giao dịch trong khoảng thời gian
    final recentTransactions = transactions.where((t) {
      final txDate = DateTime.tryParse(t.date);
      return txDate != null && txDate.isAfter(startDate);
    }).toList();

    // Tính tổng thu/chi
    double totalIncome = 0;
    double totalExpense = 0;
    Map<int, double> categorySpending = {};
    Map<int, int> categoryTransactionCount = {};

    for (final tx in recentTransactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        categorySpending[tx.categoryId] =
            (categorySpending[tx.categoryId] ?? 0) + tx.amount;
        categoryTransactionCount[tx.categoryId] =
            (categoryTransactionCount[tx.categoryId] ?? 0) + 1;
      }
    }

    // Tạo map tên danh mục
    Map<int, String> categoryNames = {};
    Map<int, String> categoryIcons = {};
    for (final cat in categories) {
      if (cat.id != null) {
        categoryNames[cat.id!] = cat.name;
        categoryIcons[cat.id!] = cat.icon ?? '📦';
      }
    }

    // Tính xu hướng theo tuần (4 tuần gần nhất)
    List<double> weeklyTrend = _calculateWeeklyTrend(recentTransactions, 4);

    // Tính % thay đổi chi tiêu so với kỳ trước
    double spendingChange = _calculateSpendingChange(transactions, days);

    // Tỷ lệ tiết kiệm
    double savingsRate = totalIncome > 0
        ? ((totalIncome - totalExpense) / totalIncome) * 100
        : 0;

    // Chi tiêu trung bình mỗi ngày
    double avgDailySpending = days > 0 ? totalExpense / days : 0;

    // Dự đoán chi tiêu tháng tới (linear regression đơn giản)
    double predictedMonthlyExpense = _predictNextMonthExpense(
      transactions: transactions,
      currentMonthExpense: totalExpense,
      days: days,
    );

    // Phân tích chi tiêu theo ngày trong tuần
    Map<int, double> weekdaySpending = _analyzeWeekdaySpending(recentTransactions);

    // Phân tích chi tiêu theo giờ (nếu có timestamp)
    Map<String, double> monthlyTrend = _calculateMonthlyTrend(transactions, 6);

    return SpendingAnalysis(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      savingsRate: savingsRate,
      avgDailySpending: avgDailySpending,
      categorySpending: categorySpending,
      categoryNames: categoryNames,
      categoryIcons: categoryIcons,
      categoryTransactionCount: categoryTransactionCount,
      weeklyTrend: weeklyTrend,
      spendingChange: spendingChange,
      daysAnalyzed: days,
      predictedMonthlyExpense: predictedMonthlyExpense,
      weekdaySpending: weekdaySpending,
      monthlyTrend: monthlyTrend,
      transactionCount: recentTransactions.length,
    );
  }

  /// Tạo insights từ phân tích
  List<AIInsight> generateInsights({
    required SpendingAnalysis analysis,
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<Budget> budgets,
  }) {
    List<AIInsight> insights = [];

    // 1. Phân tích tỷ lệ tiết kiệm
    insights.addAll(_analyzeSavingsRate(analysis));

    // 2. Phân tích xu hướng chi tiêu
    insights.addAll(_analyzeSpendingTrend(analysis));

    // 3. Phát hiện chi tiêu bất thường
    insights.addAll(_detectAnomalies(transactions, analysis));

    // 4. Phân tích theo danh mục
    insights.addAll(_analyzeCategorySpending(analysis, categories));

    // 5. Kiểm tra ngân sách
    insights.addAll(_analyzeBudgetCompliance(budgets, analysis));

    // 6. Phân tích pattern chi tiêu theo ngày
    insights.addAll(_analyzeSpendingPattern(analysis));

    // 7. Dự đoán chi tiêu
    insights.addAll(_generatePredictions(analysis));

    // 8. Đưa ra mẹo tài chính (deterministic dựa trên dữ liệu)
    insights.addAll(_generateFinancialTips(analysis));

    // 9. Thành tựu (nếu có)
    insights.addAll(_checkAchievements(analysis, transactions));

    // Sắp xếp theo mức độ ưu tiên (critical > high > medium > low)
    insights.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    // Giới hạn số lượng insights để không quá nhiều
    return insights.take(15).toList();
  }

  /// Tính xu hướng chi tiêu theo tuần
  List<double> _calculateWeeklyTrend(List<Transaction> transactions, int weeks) {
    List<double> trend = List.filled(weeks, 0);
    final now = DateTime.now();

    for (int i = 0; i < weeks; i++) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7));
      final weekEnd = now.subtract(Duration(days: i * 7));

      double weekTotal = 0;
      for (final tx in transactions) {
        if (tx.type == 'expense') {
          final txDate = DateTime.tryParse(tx.date);
          if (txDate != null &&
              txDate.isAfter(weekStart) &&
              txDate.isBefore(weekEnd)) {
            weekTotal += tx.amount;
          }
        }
      }
      trend[weeks - 1 - i] = weekTotal;
    }

    return trend;
  }

  /// Tính xu hướng chi tiêu theo tháng (6 tháng gần nhất)
  Map<String, double> _calculateMonthlyTrend(
      List<Transaction> transactions, int months) {
    final Map<String, double> trend = {};
    final now = DateTime.now();

    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';
      double total = 0;

      for (final tx in transactions) {
        if (tx.type == 'expense') {
          final txDate = DateTime.tryParse(tx.date);
          if (txDate != null &&
              txDate.year == month.year &&
              txDate.month == month.month) {
            total += tx.amount;
          }
        }
      }
      trend[monthKey] = total;
    }

    return trend;
  }

  /// Phân tích chi tiêu theo ngày trong tuần
  Map<int, double> _analyzeWeekdaySpending(List<Transaction> transactions) {
    final Map<int, double> weekdaySpending = {};
    for (int i = 1; i <= 7; i++) {
      weekdaySpending[i] = 0;
    }

    for (final tx in transactions) {
      if (tx.type == 'expense') {
        final txDate = DateTime.tryParse(tx.date);
        if (txDate != null) {
          weekdaySpending[txDate.weekday] =
              (weekdaySpending[txDate.weekday] ?? 0) + tx.amount;
        }
      }
    }

    return weekdaySpending;
  }

  /// Tính % thay đổi chi tiêu so với kỳ trước
  double _calculateSpendingChange(List<Transaction> transactions, int days) {
    final now = DateTime.now();
    final currentStart = now.subtract(Duration(days: days));
    final previousStart = now.subtract(Duration(days: days * 2));

    double currentPeriod = 0;
    double previousPeriod = 0;

    for (final tx in transactions) {
      if (tx.type == 'expense') {
        final txDate = DateTime.tryParse(tx.date);
        if (txDate != null) {
          if (txDate.isAfter(currentStart)) {
            currentPeriod += tx.amount;
          } else if (txDate.isAfter(previousStart) &&
              txDate.isBefore(currentStart)) {
            previousPeriod += tx.amount;
          }
        }
      }
    }

    if (previousPeriod == 0) return 0;
    return ((currentPeriod - previousPeriod) / previousPeriod) * 100;
  }

  /// Dự đoán chi tiêu tháng tới dựa trên xu hướng
  double _predictNextMonthExpense({
    required List<Transaction> transactions,
    required double currentMonthExpense,
    required int days,
  }) {
    // Lấy chi tiêu 3 tháng gần nhất
    final now = DateTime.now();
    List<double> monthlyExpenses = [];

    for (int i = 1; i <= 3; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      double total = 0;
      for (final tx in transactions) {
        if (tx.type == 'expense') {
          final txDate = DateTime.tryParse(tx.date);
          if (txDate != null &&
              txDate.year == month.year &&
              txDate.month == month.month) {
            total += tx.amount;
          }
        }
      }
      monthlyExpenses.add(total);
    }

    if (monthlyExpenses.isEmpty) return currentMonthExpense;

    // Tính trung bình có trọng số (tháng gần nhất có trọng số cao hơn)
    double weightedSum = 0;
    double totalWeight = 0;
    for (int i = 0; i < monthlyExpenses.length; i++) {
      final weight = (monthlyExpenses.length - i).toDouble();
      weightedSum += monthlyExpenses[i] * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : currentMonthExpense;
  }

  /// Phân tích tỷ lệ tiết kiệm
  List<AIInsight> _analyzeSavingsRate(SpendingAnalysis analysis) {
    List<AIInsight> insights = [];

    if (analysis.totalIncome == 0) return insights;

    if (analysis.savingsRate >= 30) {
      insights.add(AIInsight(
        title: 'Tuyệt vời! Tỷ lệ tiết kiệm cao',
        message:
            'Bạn đang tiết kiệm ${analysis.savingsRate.toStringAsFixed(1)}% thu nhập. '
            'Đây là một thói quen tài chính rất tốt! Hãy duy trì nhé.',
        type: InsightType.achievement,
        priority: InsightPriority.low,
      ));
    } else if (analysis.savingsRate >= 20) {
      insights.add(AIInsight(
        title: 'Tỷ lệ tiết kiệm ổn định',
        message:
            'Bạn tiết kiệm được ${analysis.savingsRate.toStringAsFixed(1)}% thu nhập. '
            'Cố gắng nâng lên 30% để đạt mục tiêu tài chính nhanh hơn.',
        type: InsightType.saving,
        priority: InsightPriority.low,
      ));
    } else if (analysis.savingsRate >= 10) {
      insights.add(AIInsight(
        title: 'Cần tăng tỷ lệ tiết kiệm',
        message:
            'Tỷ lệ tiết kiệm hiện tại ${analysis.savingsRate.toStringAsFixed(1)}% khá thấp. '
            'Hãy cắt giảm các khoản chi không cần thiết để đạt tối thiểu 20%.',
        type: InsightType.warning,
        priority: InsightPriority.medium,
      ));
    } else if (analysis.savingsRate >= 0) {
      insights.add(AIInsight(
        title: 'Cảnh báo: Tiết kiệm quá ít',
        message:
            'Bạn chỉ tiết kiệm ${analysis.savingsRate.toStringAsFixed(1)}% thu nhập. '
            'Điều này có thể gây khó khăn khi có tình huống khẩn cấp. '
            'Hãy xem lại các khoản chi tiêu ngay.',
        type: InsightType.warning,
        priority: InsightPriority.high,
        actionText: 'Xem chi tiêu',
        actionRoute: '/transactions',
      ));
    } else {
      insights.add(AIInsight(
        title: '⚠️ Chi tiêu vượt thu nhập!',
        message:
            'Bạn đang chi nhiều hơn kiếm được. '
            'Tổng chi: ${_formatCurrency(analysis.totalExpense)}, '
            'Tổng thu: ${_formatCurrency(analysis.totalIncome)}. '
            'Cần điều chỉnh ngay để tránh nợ nần.',
        type: InsightType.warning,
        priority: InsightPriority.critical,
        actionText: 'Đặt ngân sách',
        actionRoute: '/budgets',
      ));
    }

    return insights;
  }

  /// Phân tích xu hướng chi tiêu
  List<AIInsight> _analyzeSpendingTrend(SpendingAnalysis analysis) {
    List<AIInsight> insights = [];

    if (analysis.weeklyTrend.length < 2) return insights;

    // Tính xu hướng
    final recent = analysis.weeklyTrend.last;
    final previous = analysis.weeklyTrend[analysis.weeklyTrend.length - 2];

    if (previous == 0) return insights;

    final changePercent = ((recent - previous) / previous) * 100;

    if (changePercent > 30) {
      insights.add(AIInsight(
        title: 'Chi tiêu tăng đột biến',
        message:
            'Chi tiêu tuần này tăng ${changePercent.toStringAsFixed(0)}% so với tuần trước. '
            'Hãy kiểm tra xem có khoản nào đặc biệt không.',
        type: InsightType.warning,
        priority: InsightPriority.high,
      ));
    } else if (changePercent > 15) {
      insights.add(AIInsight(
        title: 'Chi tiêu có xu hướng tăng',
        message:
            'Chi tiêu tuần này tăng ${changePercent.toStringAsFixed(0)}%. '
            'Theo dõi để đảm bảo không vượt ngân sách.',
        type: InsightType.trend,
        priority: InsightPriority.medium,
      ));
    } else if (changePercent < -20) {
      insights.add(AIInsight(
        title: 'Giảm chi tiêu thành công!',
        message:
            'Bạn đã giảm ${(-changePercent).toStringAsFixed(0)}% chi tiêu so với tuần trước. '
            'Tiếp tục duy trì thói quen tốt này!',
        type: InsightType.achievement,
        priority: InsightPriority.low,
      ));
    }

    // Phân tích xu hướng dài hạn
    if (analysis.spendingChange > 20) {
      insights.add(AIInsight(
        title: 'Xu hướng chi tiêu tăng trong tháng',
        message:
            'Chi tiêu tháng này cao hơn ${analysis.spendingChange.toStringAsFixed(0)}% '
            'so với tháng trước. Hãy cân nhắc điều chỉnh.',
        type: InsightType.trend,
        priority: InsightPriority.medium,
      ));
    } else if (analysis.spendingChange < -15) {
      insights.add(AIInsight(
        title: 'Chi tiêu giảm so với tháng trước',
        message:
            'Chi tiêu tháng này thấp hơn ${(-analysis.spendingChange).toStringAsFixed(0)}% '
            'so với tháng trước. Bạn đang kiểm soát tốt!',
        type: InsightType.achievement,
        priority: InsightPriority.low,
      ));
    }

    return insights;
  }

  /// Phát hiện chi tiêu bất thường
  List<AIInsight> _detectAnomalies(
      List<Transaction> transactions, SpendingAnalysis analysis) {
    List<AIInsight> insights = [];

    if (transactions.isEmpty || analysis.avgDailySpending == 0) return insights;

    // Tìm giao dịch lớn bất thường (> 3x trung bình ngày)
    final threshold = analysis.avgDailySpending * 3;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    List<Transaction> unusualTransactions = [];
    for (final tx in transactions) {
      if (tx.type == 'expense' && tx.amount > threshold) {
        final txDate = DateTime.tryParse(tx.date);
        if (txDate != null && txDate.isAfter(weekAgo)) {
          unusualTransactions.add(tx);
        }
      }
    }

    if (unusualTransactions.isNotEmpty) {
      final total =
          unusualTransactions.fold<double>(0, (sum, tx) => sum + tx.amount);
      insights.add(AIInsight(
        title: 'Phát hiện ${unusualTransactions.length} giao dịch lớn',
        message:
            'Trong tuần qua có ${unusualTransactions.length} giao dịch vượt mức bình thường, '
            'tổng ${_formatCurrency(total)}. Đây có thể là các khoản chi đặc biệt.',
        type: InsightType.warning,
        priority: InsightPriority.medium,
        metadata: {
          'transactions': unusualTransactions.map((t) => t.id).toList(),
        },
      ));
    }

    return insights;
  }

  /// Phân tích chi tiêu theo danh mục
  List<AIInsight> _analyzeCategorySpending(
      SpendingAnalysis analysis, List<Category> categories) {
    List<AIInsight> insights = [];

    if (analysis.categorySpending.isEmpty) return insights;

    // Tìm danh mục chi tiêu nhiều nhất
    final topCatId = analysis.topSpendingCategoryId;
    if (topCatId != null) {
      final catName = analysis.categoryNames[topCatId] ?? 'Không xác định';
      final amount = analysis.categorySpending[topCatId] ?? 0;
      final percent = analysis.categoryPercentages[topCatId] ?? 0;

      if (percent > 50) {
        insights.add(AIInsight(
          title: 'Chi tiêu tập trung vào "$catName"',
          message:
              'Danh mục "$catName" chiếm ${percent.toStringAsFixed(0)}% tổng chi tiêu '
              '(${_formatCurrency(amount)}). Hãy cân nhắc phân bổ lại ngân sách.',
          type: InsightType.spending,
          priority: InsightPriority.medium,
        ));
      } else if (percent > 30) {
        insights.add(AIInsight(
          title: 'Danh mục chi tiêu hàng đầu',
          message:
              '"$catName" là danh mục bạn chi nhiều nhất với ${_formatCurrency(amount)} '
              '(${percent.toStringAsFixed(0)}% tổng chi tiêu).',
          type: InsightType.spending,
          priority: InsightPriority.low,
        ));
      }
    }

    // Phân tích danh mục có thể cắt giảm
    final nonEssentialKeywords = ['giải trí', 'mua sắm', 'ăn uống ngoài', 'cafe', 'quà tặng'];
    double nonEssentialTotal = 0;

    for (final entry in analysis.categorySpending.entries) {
      final catName = (analysis.categoryNames[entry.key] ?? '').toLowerCase();
      if (nonEssentialKeywords.any((keyword) => catName.contains(keyword))) {
        nonEssentialTotal += entry.value;
      }
    }

    if (nonEssentialTotal > analysis.totalExpense * 0.3) {
      insights.add(AIInsight(
        title: 'Có thể cắt giảm chi tiêu không thiết yếu',
        message:
            'Các khoản chi không thiết yếu chiếm ${_formatCurrency(nonEssentialTotal)}. '
            'Cắt giảm 20% có thể tiết kiệm thêm ${_formatCurrency(nonEssentialTotal * 0.2)} mỗi tháng.',
        type: InsightType.tip,
        priority: InsightPriority.medium,
      ));
    }

    return insights;
  }

  /// Kiểm tra tuân thủ ngân sách
  List<AIInsight> _analyzeBudgetCompliance(
      List<Budget> budgets, SpendingAnalysis analysis) {
    List<AIInsight> insights = [];

    int overBudgetCount = 0;
    int nearLimitCount = 0;

    for (final budget in budgets) {
      if (budget.limitAmount > 0) {
        final percent = (budget.spentAmount / budget.limitAmount) * 100;

        if (percent >= 100) {
          overBudgetCount++;
        } else if (percent >= 80) {
          nearLimitCount++;
        }
      }
    }

    if (overBudgetCount > 0) {
      insights.add(AIInsight(
        title: 'Vượt ngân sách $overBudgetCount danh mục!',
        message:
            'Bạn đã vượt ngân sách ở $overBudgetCount danh mục trong tháng này. '
            'Hãy điều chỉnh chi tiêu hoặc xem lại mức ngân sách.',
        type: InsightType.warning,
        priority: InsightPriority.critical,
        actionText: 'Xem ngân sách',
        actionRoute: '/budgets',
      ));
    }

    if (nearLimitCount > 0) {
      insights.add(AIInsight(
        title: 'Sắp đạt giới hạn ngân sách',
        message:
            '$nearLimitCount danh mục đã sử dụng hơn 80% ngân sách. '
            'Hãy cân nhắc kỹ trước khi chi tiêu thêm.',
        type: InsightType.warning,
        priority: InsightPriority.high,
      ));
    }

    if (overBudgetCount == 0 && budgets.isNotEmpty) {
      insights.add(AIInsight(
        title: 'Tuân thủ ngân sách tốt!',
        message:
            'Bạn đang kiểm soát chi tiêu tốt trong phạm vi ngân sách đã đặt. '
            'Tiếp tục duy trì nhé!',
        type: InsightType.achievement,
        priority: InsightPriority.low,
      ));
    }

    return insights;
  }

  /// Phân tích pattern chi tiêu theo ngày trong tuần
  List<AIInsight> _analyzeSpendingPattern(SpendingAnalysis analysis) {
    List<AIInsight> insights = [];

    if (analysis.weekdaySpending.isEmpty) return insights;

    // Tìm ngày chi tiêu nhiều nhất
    int? maxDay;
    double maxAmount = 0;
    for (final entry in analysis.weekdaySpending.entries) {
      if (entry.value > maxAmount) {
        maxAmount = entry.value;
        maxDay = entry.key;
      }
    }

    if (maxDay != null && maxAmount > 0) {
      final weekdayNames = ['', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
      final dayName = weekdayNames[maxDay];

      // Tính tổng chi tiêu để so sánh
      final totalWeekdaySpending = analysis.weekdaySpending.values
          .fold(0.0, (sum, v) => sum + v);

      if (totalWeekdaySpending > 0) {
        final percent = (maxAmount / totalWeekdaySpending) * 100;
        if (percent > 25) {
          insights.add(AIInsight(
            title: 'Chi tiêu nhiều nhất vào $dayName',
            message:
                'Bạn thường chi tiêu nhiều nhất vào $dayName '
                '(${percent.toStringAsFixed(0)}% tổng chi tiêu tuần). '
                'Hãy lên kế hoạch trước cho ngày này.',
            type: InsightType.trend,
            priority: InsightPriority.low,
          ));
        }
      }
    }

    return insights;
  }

  /// Tạo dự đoán chi tiêu
  List<AIInsight> _generatePredictions(SpendingAnalysis analysis) {
    List<AIInsight> insights = [];

    if (analysis.predictedMonthlyExpense <= 0) return insights;

    final predicted = analysis.predictedMonthlyExpense;
    final current = analysis.totalExpense;

    if (predicted > current * 1.1) {
      insights.add(AIInsight(
        title: 'Dự báo chi tiêu tháng tới tăng',
        message:
            'Dựa trên xu hướng hiện tại, chi tiêu tháng tới có thể đạt '
            '${_formatCurrency(predicted)} (tăng ${((predicted - current) / current * 100).toStringAsFixed(0)}%). '
            'Hãy chuẩn bị ngân sách phù hợp.',
        type: InsightType.trend,
        priority: InsightPriority.medium,
      ));
    } else if (predicted < current * 0.9) {
      insights.add(AIInsight(
        title: 'Dự báo chi tiêu tháng tới giảm',
        message:
            'Xu hướng cho thấy chi tiêu tháng tới có thể giảm xuống '
            '${_formatCurrency(predicted)}. Đây là tín hiệu tích cực!',
        type: InsightType.trend,
        priority: InsightPriority.low,
      ));
    }

    return insights;
  }

  /// Đưa ra mẹo tài chính (deterministic dựa trên dữ liệu thực tế)
  List<AIInsight> _generateFinancialTips(SpendingAnalysis analysis) {
    List<AIInsight> insights = [];

    // Chọn mẹo dựa trên tình trạng tài chính thực tế
    if (analysis.savingsRate < 20 && analysis.totalIncome > 0) {
      insights.add(AIInsight(
        title: 'Quy tắc 50/30/20',
        message:
            'Hãy thử phân bổ: 50% cho nhu cầu thiết yếu, 30% cho mong muốn, '
            '20% cho tiết kiệm và trả nợ. '
            'Hiện tại bạn đang tiết kiệm ${analysis.savingsRate.toStringAsFixed(0)}%.',
        type: InsightType.tip,
        priority: InsightPriority.low,
      ));
    }

    if (analysis.avgDailySpending > 0) {
      final emergencyFundMin = analysis.avgDailySpending * 30 * 3;
      final emergencyFundMax = analysis.avgDailySpending * 30 * 6;
      insights.add(AIInsight(
        title: 'Quỹ khẩn cấp',
        message:
            'Bạn nên có quỹ khẩn cấp bằng 3-6 tháng chi tiêu. '
            'Dựa trên chi tiêu hiện tại, bạn cần khoảng '
            '${_formatCurrency(emergencyFundMin)} - ${_formatCurrency(emergencyFundMax)}.',
        type: InsightType.tip,
        priority: InsightPriority.low,
      ));
    }

    // Mẹo về chi tiêu cuối tuần nếu có pattern
    if (analysis.weekdaySpending.isNotEmpty) {
      final weekendSpending = (analysis.weekdaySpending[6] ?? 0) +
          (analysis.weekdaySpending[7] ?? 0);
      final weekdaySpending = analysis.weekdaySpending.entries
          .where((e) => e.key >= 1 && e.key <= 5)
          .fold(0.0, (sum, e) => sum + e.value);

      if (weekdaySpending > 0 && weekendSpending > weekdaySpending * 0.5) {
        insights.add(AIInsight(
          title: 'Chi tiêu cuối tuần cao',
          message:
              'Chi tiêu cuối tuần của bạn khá cao. '
              'Hãy lên kế hoạch hoạt động cuối tuần tiết kiệm hơn.',
          type: InsightType.tip,
          priority: InsightPriority.low,
        ));
      }
    }

    return insights.take(2).toList();
  }

  /// Kiểm tra thành tựu
  List<AIInsight> _checkAchievements(
      SpendingAnalysis analysis, List<Transaction> transactions) {
    List<AIInsight> insights = [];

    // Streak ghi chép liên tục
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final hasTransaction = transactions.any((t) => t.date.startsWith(dateStr));
      if (hasTransaction) {
        streak++;
      } else {
        break;
      }
    }

    if (streak >= 7) {
      insights.add(AIInsight(
        title: '🔥 Streak $streak ngày!',
        message:
            'Bạn đã ghi chép chi tiêu liên tục $streak ngày. '
            'Thói quen tuyệt vời! Tiếp tục duy trì nhé.',
        type: InsightType.achievement,
        priority: InsightPriority.low,
      ));
    }

    // Thành tựu tiết kiệm
    if (analysis.savingsRate >= 50) {
      insights.add(AIInsight(
        title: '🏆 Siêu tiết kiệm!',
        message:
            'Wow! Bạn tiết kiệm được hơn 50% thu nhập. '
            'Đây là thành tích đáng ngưỡng mộ!',
        type: InsightType.achievement,
        priority: InsightPriority.low,
      ));
    }

    // Thành tựu số lượng giao dịch
    if (analysis.transactionCount >= 50) {
      insights.add(AIInsight(
        title: '📊 Theo dõi tích cực!',
        message:
            'Bạn đã ghi chép ${analysis.transactionCount} giao dịch trong kỳ này. '
            'Việc theo dõi chi tiết giúp bạn kiểm soát tài chính tốt hơn.',
        type: InsightType.achievement,
        priority: InsightPriority.low,
      ));
    }

    return insights;
  }

  /// Format tiền tệ
  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} tỷ đ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} tr đ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k đ';
    }
    return '${amount.toStringAsFixed(0)} đ';
  }
}
