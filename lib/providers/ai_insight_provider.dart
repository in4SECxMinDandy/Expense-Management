import 'package:flutter/foundation.dart' hide Category;
import '../models/ai_insight.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../services/ai_analysis_service.dart';
import '../database_helper.dart';

/// Provider quản lý AI Insights
class AIInsightProvider extends ChangeNotifier {
  final AIAnalysisService _aiService = AIAnalysisService();

  List<AIInsight> _insights = [];
  SpendingAnalysis? _analysis;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastAnalyzed;

  // Getters
  List<AIInsight> get insights => _insights;
  List<AIInsight> get unreadInsights => _insights.where((i) => !i.isRead).toList();
  List<AIInsight> get highPriorityInsights =>
      _insights.where((i) => i.priority.index >= InsightPriority.high.index).toList();
  SpendingAnalysis? get analysis => _analysis;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastAnalyzed => _lastAnalyzed;
  int get unreadCount => unreadInsights.length;

  /// Chạy phân tích AI
  Future<void> runAnalysis({
    List<Transaction>? transactions,
    List<Category>? categories,
    List<Budget>? budgets,
    int days = 30,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Lấy dữ liệu từ database nếu không được cung cấp
      final db = await DatabaseHelper.instance.database;

      // Lấy transactions
      List<Transaction> txList = transactions ?? [];
      if (txList.isEmpty) {
        final txMaps = await db.query('transactions', orderBy: 'date DESC');
        txList = txMaps.map((m) => Transaction.fromMap(m)).toList();
      }

      // Lấy categories
      List<Category> catList = categories ?? [];
      if (catList.isEmpty) {
        final catMaps = await db.query('categories');
        catList = catMaps.map((m) => Category.fromMap(m)).toList();
      }

      // Lấy budgets
      List<Budget> budgetList = budgets ?? [];
      if (budgetList.isEmpty) {
        final now = DateTime.now();
        final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final budgetMaps = await db.query(
          'budgets',
          where: 'month = ?',
          whereArgs: [currentMonth],
        );
        budgetList = budgetMaps.map((m) => Budget.fromMap(m)).toList();
      }

      // Chạy phân tích
      _analysis = _aiService.analyzeSpending(
        transactions: txList,
        categories: catList,
        days: days,
      );

      // Tạo insights
      _insights = _aiService.generateInsights(
        analysis: _analysis!,
        transactions: txList,
        categories: catList,
        budgets: budgetList,
      );

      _lastAnalyzed = DateTime.now();

      // Lưu insights vào database (optional)
      await _saveInsightsToDb();

    } catch (e) {
      _error = 'Lỗi phân tích: $e';
      debugPrint('AI Analysis error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Đánh dấu insight đã đọc
  void markAsRead(int index) {
    if (index >= 0 && index < _insights.length) {
      _insights[index] = _insights[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Đánh dấu tất cả đã đọc
  void markAllAsRead() {
    _insights = _insights.map((i) => i.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  /// Xóa một insight
  void dismissInsight(int index) {
    if (index >= 0 && index < _insights.length) {
      _insights.removeAt(index);
      notifyListeners();
    }
  }

  /// Làm mới phân tích
  Future<void> refresh() async {
    await runAnalysis();
  }

  /// Lưu insights vào database
  Future<void> _saveInsightsToDb() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      final period = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Xóa insights cũ của tháng này
      await db.delete(
        'ai_insights',
        where: 'period = ?',
        whereArgs: [period],
      );

      // Lưu insights mới (chỉ lưu tóm tắt)
      if (_insights.isNotEmpty) {
        final summary = _insights.take(5).map((i) => i.title).join('; ');
        await db.insert('ai_insights', {
          'period': period,
          'insight': summary,
          'prediction': _analysis?.savingsRate ?? 0,
          'created_at': now.toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error saving insights: $e');
    }
  }

  /// Lấy insights từ database (lịch sử)
  Future<List<Map<String, dynamic>>> getInsightHistory() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.query(
        'ai_insights',
        orderBy: 'created_at DESC',
        limit: 12,
      );
    } catch (e) {
      debugPrint('Error loading insight history: $e');
      return [];
    }
  }

  /// Lấy tóm tắt nhanh (cho dashboard)
  String getQuickSummary() {
    if (_analysis == null) return 'Chưa có phân tích';

    final a = _analysis!;
    if (a.savingsRate < 0) {
      return 'Chi tiêu vượt thu nhập ${(-a.savingsRate).toStringAsFixed(0)}%';
    } else if (a.savingsRate < 10) {
      return 'Tiết kiệm thấp: ${a.savingsRate.toStringAsFixed(0)}%';
    } else if (a.savingsRate >= 30) {
      return 'Tiết kiệm tốt: ${a.savingsRate.toStringAsFixed(0)}%';
    } else {
      return 'Tiết kiệm: ${a.savingsRate.toStringAsFixed(0)}%';
    }
  }

  /// Lấy màu trạng thái (cho dashboard)
  String getStatusColor() {
    if (_analysis == null) return '#9E9E9E';

    final rate = _analysis!.savingsRate;
    if (rate < 0) return '#F44336';
    if (rate < 10) return '#FF9800';
    if (rate >= 30) return '#4CAF50';
    return '#2196F3';
  }
}
