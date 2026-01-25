import 'dart:math';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/ai_insight.dart';

/// AI Analysis Service - Phân tích thói quen chi tiêu thông minh
/// Sử dụng rule-based analysis để đưa ra insights và lời khuyên
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

    for (final tx in recentTransactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
        categorySpending[tx.categoryId] =
            (categorySpending[tx.categoryId] ?? 0) + tx.amount;
      }
    }

    // Tạo map tên danh mục
    Map<int, String> categoryNames = {};
    for (final cat in categories) {
      if (cat.id != null) {
        categoryNames[cat.id!] = cat.name;
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

    return SpendingAnalysis(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      savingsRate: savingsRate,
      avgDailySpending: avgDailySpending,
      categorySpending: categorySpending,
      categoryNames: categoryNames,
      weeklyTrend: weeklyTrend,
      spendingChange: spendingChange,
      daysAnalyzed: days,
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

    // 6. Đưa ra mẹo tài chính
    insights.addAll(_generateFinancialTips(analysis));

    // 7. Thành tựu (nếu có)
    insights.addAll(_checkAchievements(analysis, transactions));

    // Sắp xếp theo mức độ ưu tiên
    insights.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    return insights;
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
    final nonEssentialCategories = ['Giải trí', 'Mua sắm', 'Ăn uống ngoài'];
    double nonEssentialTotal = 0;

    for (final entry in analysis.categorySpending.entries) {
      final catName = analysis.categoryNames[entry.key] ?? '';
      if (nonEssentialCategories.any(
          (name) => catName.toLowerCase().contains(name.toLowerCase()))) {
        nonEssentialTotal += entry.value;
      }
    }

    if (nonEssentialTotal > analysis.totalExpense * 0.3) {
      insights.add(AIInsight(
        title: 'Có thể cắt giảm chi tiêu không thiết yếu',
        message:
            'Các khoản chi không thiết yếu (giải trí, mua sắm) chiếm ${_formatCurrency(nonEssentialTotal)}. '
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

  /// Đưa ra mẹo tài chính
  List<AIInsight> _generateFinancialTips(SpendingAnalysis analysis) {
    List<AIInsight> insights = [];
    final random = Random();

    // Danh sách mẹo tài chính
    final tips = [
      AIInsight(
        title: 'Quy tắc 50/30/20',
        message:
            'Hãy thử phân bổ: 50% cho nhu cầu thiết yếu, 30% cho mong muốn, '
            '20% cho tiết kiệm và trả nợ.',
        type: InsightType.tip,
        priority: InsightPriority.low,
      ),
      AIInsight(
        title: 'Quỹ khẩn cấp',
        message:
            'Bạn nên có quỹ khẩn cấp bằng 3-6 tháng chi tiêu. '
            'Dựa trên chi tiêu hiện tại, bạn cần khoảng ${_formatCurrency(analysis.avgDailySpending * 30 * 3)} - ${_formatCurrency(analysis.avgDailySpending * 30 * 6)}.',
        type: InsightType.tip,
        priority: InsightPriority.low,
      ),
      AIInsight(
        title: 'Đợi 24h trước khi mua',
        message:
            'Với các khoản mua sắm lớn, hãy đợi 24 giờ trước khi quyết định. '
            'Điều này giúp tránh mua sắm theo cảm xúc.',
        type: InsightType.tip,
        priority: InsightPriority.low,
      ),
      AIInsight(
        title: 'Tự động hóa tiết kiệm',
        message:
            'Thiết lập chuyển khoản tự động vào tài khoản tiết kiệm ngay khi nhận lương. '
            '"Trả cho bản thân trước" là chìa khóa tài chính.',
        type: InsightType.tip,
        priority: InsightPriority.low,
      ),
      AIInsight(
        title: 'Theo dõi chi tiêu hàng ngày',
        message:
            'Ghi chép chi tiêu mỗi ngày giúp bạn nhận biết các khoản "rò rỉ" nhỏ '
            'nhưng tích lũy lại thành số lớn theo thời gian.',
        type: InsightType.tip,
        priority: InsightPriority.low,
      ),
    ];

    // Chọn ngẫu nhiên 1-2 mẹo
    tips.shuffle(random);
    insights.addAll(tips.take(min(2, tips.length)));

    return insights;
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

    return insights;
  }

  /// Format tiền tệ
  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)} tỷ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '${amount.toStringAsFixed(0)}đ';
  }
}
