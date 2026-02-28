import 'package:flutter_test/flutter_test.dart';
import 'package:expense_manager/services/ai_analysis_service.dart';
import 'package:expense_manager/models/transaction.dart';
import 'package:expense_manager/models/category.dart';
import 'package:expense_manager/models/budget.dart';
import 'package:expense_manager/models/ai_insight.dart';

void main() {
  late AIAnalysisService service;

  setUp(() {
    service = AIAnalysisService();
  });

  group('AIAnalysisService Tests', () {
    test('analyzeSpending() returns correct totals', () {
      final transactions = [
        Transaction(
          id: 1,
          categoryId: 1,
          amount: 10000000.0,
          date: DateTime.now().toIso8601String(),
          type: 'income',
        ),
        Transaction(
          id: 2,
          categoryId: 2,
          amount: 3000000.0,
          date: DateTime.now().toIso8601String(),
          type: 'expense',
        ),
        Transaction(
          id: 3,
          categoryId: 3,
          amount: 2000000.0,
          date: DateTime.now().toIso8601String(),
          type: 'expense',
        ),
      ];

      final categories = [
        Category(id: 1, name: 'Lương', type: 'income'),
        Category(id: 2, name: 'Ăn uống', type: 'expense'),
        Category(id: 3, name: 'Di chuyển', type: 'expense'),
      ];

      final analysis = service.analyzeSpending(
        transactions: transactions,
        categories: categories,
        days: 30,
      );

      expect(analysis.totalIncome, 10000000.0);
      expect(analysis.totalExpense, 5000000.0);
      expect(analysis.balance, 5000000.0);
      expect(analysis.savingsRate, 50.0);
    });

    test('analyzeSpending() handles empty transactions', () {
      final analysis = service.analyzeSpending(
        transactions: [],
        categories: [],
        days: 30,
      );

      expect(analysis.totalIncome, 0.0);
      expect(analysis.totalExpense, 0.0);
      expect(analysis.savingsRate, 0.0);
      expect(analysis.avgDailySpending, 0.0);
    });

    test('analyzeSpending() filters by date range', () {
      final now = DateTime.now();
      final oldDate = now.subtract(const Duration(days: 60));

      final transactions = [
        Transaction(
          id: 1,
          categoryId: 1,
          amount: 5000000.0,
          date: now.toIso8601String(), // Trong khoảng
          type: 'income',
        ),
        Transaction(
          id: 2,
          categoryId: 1,
          amount: 3000000.0,
          date: oldDate.toIso8601String(), // Ngoài khoảng
          type: 'income',
        ),
      ];

      final analysis = service.analyzeSpending(
        transactions: transactions,
        categories: [],
        days: 30, // Chỉ lấy 30 ngày gần nhất
      );

      // Chỉ tính giao dịch trong 30 ngày
      expect(analysis.totalIncome, 5000000.0);
    });

    test('generateInsights() returns critical warning when over budget', () {
      final analysis = SpendingAnalysis(
        totalIncome: 5000000.0,
        totalExpense: 6000000.0, // Chi nhiều hơn thu
        savingsRate: -20.0,
        avgDailySpending: 200000.0,
        categorySpending: {},
        categoryNames: {},
        weeklyTrend: [100000, 150000, 200000, 250000],
        spendingChange: 25.0,
        daysAnalyzed: 30,
      );

      final insights = service.generateInsights(
        analysis: analysis,
        transactions: [],
        categories: [],
        budgets: [],
      );

      // Phải có ít nhất 1 insight critical
      final criticalInsights = insights.where(
        (i) => i.priority == InsightPriority.critical,
      );
      expect(criticalInsights, isNotEmpty);
    });

    test('generateInsights() returns achievement when savings rate >= 30%', () {
      final analysis = SpendingAnalysis(
        totalIncome: 10000000.0,
        totalExpense: 6000000.0,
        savingsRate: 40.0, // Tiết kiệm tốt
        avgDailySpending: 200000.0,
        categorySpending: {},
        categoryNames: {},
        weeklyTrend: [200000, 180000, 160000, 150000],
        spendingChange: -10.0,
        daysAnalyzed: 30,
      );

      final insights = service.generateInsights(
        analysis: analysis,
        transactions: [],
        categories: [],
        budgets: [],
      );

      final achievementInsights = insights.where(
        (i) => i.type == InsightType.achievement,
      );
      expect(achievementInsights, isNotEmpty);
    });

    test('generateInsights() detects over-budget categories', () {
      final budgets = [
        Budget(
          id: 1,
          categoryId: 1,
          month: '2026-02',
          limitAmount: 1000000.0,
          spentAmount: 1200000.0, // Vượt 20%
        ),
      ];

      final analysis = SpendingAnalysis(
        totalIncome: 5000000.0,
        totalExpense: 2000000.0,
        savingsRate: 60.0,
        avgDailySpending: 66666.0,
        categorySpending: {1: 1200000.0},
        categoryNames: {1: 'Ăn uống'},
        weeklyTrend: [300000, 300000, 300000, 300000],
        spendingChange: 0.0,
        daysAnalyzed: 30,
      );

      final insights = service.generateInsights(
        analysis: analysis,
        transactions: [],
        categories: [],
        budgets: budgets,
      );

      final budgetWarnings = insights.where(
        (i) => i.priority == InsightPriority.critical &&
            i.message.contains('vượt ngân sách'),
      );
      expect(budgetWarnings, isNotEmpty);
    });

    test('SpendingAnalysis.topSpendingCategoryId returns correct category', () {
      final analysis = SpendingAnalysis(
        totalIncome: 10000000.0,
        totalExpense: 5000000.0,
        savingsRate: 50.0,
        avgDailySpending: 166666.0,
        categorySpending: {
          1: 2000000.0,
          2: 1500000.0,
          3: 1000000.0,
          4: 500000.0,
        },
        categoryNames: {
          1: 'Ăn uống',
          2: 'Di chuyển',
          3: 'Mua sắm',
          4: 'Giải trí',
        },
        weeklyTrend: [],
        spendingChange: 0.0,
        daysAnalyzed: 30,
      );

      expect(analysis.topSpendingCategoryId, 1); // Ăn uống có nhiều nhất
    });

    test('SpendingAnalysis.categoryPercentages calculates correctly', () {
      final analysis = SpendingAnalysis(
        totalIncome: 10000000.0,
        totalExpense: 4000000.0,
        savingsRate: 60.0,
        avgDailySpending: 133333.0,
        categorySpending: {
          1: 2000000.0, // 50%
          2: 1000000.0, // 25%
          3: 1000000.0, // 25%
        },
        categoryNames: {1: 'A', 2: 'B', 3: 'C'},
        weeklyTrend: [],
        spendingChange: 0.0,
        daysAnalyzed: 30,
      );

      final percentages = analysis.categoryPercentages;
      expect(percentages[1], closeTo(50.0, 0.01));
      expect(percentages[2], closeTo(25.0, 0.01));
      expect(percentages[3], closeTo(25.0, 0.01));
    });
  });
}
