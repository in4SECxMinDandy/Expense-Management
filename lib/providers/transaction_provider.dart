import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/transaction.dart';
import '../services/notification_service.dart';

/// TransactionProvider - Quản lý state giao dịch tài chính
/// Xử lý CRUD và đồng bộ ngân sách tự động
class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // === COMPUTED PROPERTIES ===

  double get totalIncome {
    return _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  /// Lấy giao dịch theo tháng
  List<Transaction> getTransactionsByMonth(int year, int month) {
    return _transactions.where((t) {
      try {
        final date = DateTime.parse(t.date);
        return date.year == year && date.month == month;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  /// Lấy giao dịch theo khoảng ngày
  List<Transaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) {
      try {
        final date = DateTime.parse(t.date);
        return !date.isBefore(start) && !date.isAfter(end);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  /// Tổng chi tiêu theo danh mục trong tháng
  Map<int, double> getExpenseByCategory(int year, int month) {
    final monthTransactions = getTransactionsByMonth(year, month);
    final Map<int, double> result = {};
    for (final t in monthTransactions.where((t) => t.type == 'expense')) {
      result[t.categoryId] = (result[t.categoryId] ?? 0) + t.amount;
    }
    return result;
  }

  // === CRUD OPERATIONS ===

  /// Tải tất cả giao dịch từ database
  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        orderBy: 'date DESC, created_at DESC',
      );
      _transactions = maps.map((map) => Transaction.fromMap(map)).toList();
    } catch (e) {
      _error = 'Lỗi tải giao dịch: $e';
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm giao dịch mới
  Future<bool> addTransaction(Transaction transaction) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Insert transaction
      final id = await db.insert('transactions', transaction.toMap());

      // Cập nhật ngân sách nếu là chi tiêu
      if (transaction.type == 'expense') {
        await _updateBudgetSpent(
          db: db,
          categoryId: transaction.categoryId,
          month: _extractMonth(transaction.date),
          delta: transaction.amount,
        );
      }

      await loadTransactions();
      return true;
    } catch (e) {
      _error = 'Lỗi thêm giao dịch: $e';
      debugPrint('Error adding transaction: $e');
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật giao dịch
  Future<bool> updateTransaction(Transaction transaction) async {
    if (transaction.id == null) return false;

    try {
      final db = await DatabaseHelper.instance.database;

      // Lấy giao dịch cũ để hoàn tác ngân sách
      final oldList = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      if (oldList.isNotEmpty) {
        final oldTx = Transaction.fromMap(oldList.first);

        // Hoàn tác ngân sách cũ
        if (oldTx.type == 'expense') {
          await _updateBudgetSpent(
            db: db,
            categoryId: oldTx.categoryId,
            month: _extractMonth(oldTx.date),
            delta: -oldTx.amount, // Trừ đi số tiền cũ
          );
        }

        // Áp dụng ngân sách mới
        if (transaction.type == 'expense') {
          await _updateBudgetSpent(
            db: db,
            categoryId: transaction.categoryId,
            month: _extractMonth(transaction.date),
            delta: transaction.amount,
          );
        }
      }

      // Cập nhật giao dịch
      await db.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      await loadTransactions();
      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật giao dịch: $e';
      debugPrint('Error updating transaction: $e');
      notifyListeners();
      return false;
    }
  }

  /// Xóa giao dịch
  Future<bool> deleteTransaction(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Lấy giao dịch trước khi xóa để cập nhật ngân sách
      final tList = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (tList.isNotEmpty) {
        final t = Transaction.fromMap(tList.first);
        if (t.type == 'expense') {
          await _updateBudgetSpent(
            db: db,
            categoryId: t.categoryId,
            month: _extractMonth(t.date),
            delta: -t.amount, // Trừ đi số tiền đã chi
          );
        }
      }

      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
      await loadTransactions();
      return true;
    } catch (e) {
      _error = 'Lỗi xóa giao dịch: $e';
      debugPrint('Error deleting transaction: $e');
      notifyListeners();
      return false;
    }
  }

  /// Xóa nhiều giao dịch cùng lúc
  Future<bool> deleteMultipleTransactions(List<int> ids) async {
    if (ids.isEmpty) return true;

    try {
      final db = await DatabaseHelper.instance.database;

      // Lấy tất cả giao dịch cần xóa
      final placeholders = ids.map((_) => '?').join(',');
      final tList = await db.query(
        'transactions',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );

      // Cập nhật ngân sách cho từng giao dịch
      for (final map in tList) {
        final t = Transaction.fromMap(map);
        if (t.type == 'expense') {
          await _updateBudgetSpent(
            db: db,
            categoryId: t.categoryId,
            month: _extractMonth(t.date),
            delta: -t.amount,
          );
        }
      }

      // Xóa tất cả
      await db.delete(
        'transactions',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );

      await loadTransactions();
      return true;
    } catch (e) {
      _error = 'Lỗi xóa giao dịch: $e';
      debugPrint('Error deleting multiple transactions: $e');
      notifyListeners();
      return false;
    }
  }

  // === PRIVATE HELPERS ===

  /// Cập nhật spent_amount trong bảng budgets
  /// delta: dương = tăng chi tiêu, âm = giảm chi tiêu
  Future<void> _updateBudgetSpent({
    required dynamic db,
    required int categoryId,
    required String month,
    required double delta,
  }) async {
    try {
      final budgetsMap = await db.query(
        'budgets',
        where: 'category_id = ? AND month = ?',
        whereArgs: [categoryId, month],
      );

      if (budgetsMap.isNotEmpty) {
        final budgetId = budgetsMap.first['id'] as int;
        final limitAmount = (budgetsMap.first['limit_amount'] as num).toDouble();
        final currentSpent = (budgetsMap.first['spent_amount'] as num?)?.toDouble() ?? 0.0;

        // Đảm bảo spent_amount không âm
        final newSpent = (currentSpent + delta).clamp(0.0, double.infinity);

        await db.update(
          'budgets',
          {'spent_amount': newSpent},
          where: 'id = ?',
          whereArgs: [budgetId],
        );

        // Gửi thông báo nếu vượt ngân sách
        if (delta > 0 && newSpent > limitAmount) {
          final spentPercent = (newSpent / limitAmount) * 100;
          NotificationService.showBudgetAlert(
            budgetId: budgetId,
            categoryName: 'Danh mục #$categoryId',
            spentPercent: spentPercent,
          );
        } else if (delta > 0 && newSpent >= limitAmount * 0.8) {
          // Cảnh báo khi đạt 80%
          final spentPercent = (newSpent / limitAmount) * 100;
          NotificationService.showBudgetAlert(
            budgetId: budgetId,
            categoryName: 'Danh mục #$categoryId',
            spentPercent: spentPercent,
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating budget spent: $e');
    }
  }

  /// Trích xuất tháng từ date string (format: yyyy-MM)
  String _extractMonth(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    } catch (_) {
      final now = DateTime.now();
      return '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }
  }

  /// Xóa lỗi
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
