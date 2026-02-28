import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/recurring_transaction.dart';
import '../services/notification_service.dart';

/// RecurringProvider - Quản lý giao dịch định kỳ
/// Tự động xử lý và gửi thông báo nhắc nhở
class RecurringProvider extends ChangeNotifier {
  List<RecurringTransaction> _recurringTransactions = [];
  bool _isLoading = false;
  String? _error;

  List<RecurringTransaction> get recurringTransactions =>
      _recurringTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Lấy các giao dịch đang hoạt động
  List<RecurringTransaction> get activeTransactions =>
      _recurringTransactions.where((r) => r.isActive).toList();

  /// Lấy các giao dịch đến hạn
  List<RecurringTransaction> get dueTransactions =>
      _recurringTransactions.where((r) => r.isDue).toList();

  /// Lấy các giao dịch sắp đến hạn (trong 3 ngày tới)
  List<RecurringTransaction> get upcomingTransactions =>
      _recurringTransactions.where((r) {
        if (!r.isActive) return false;
        final days = r.daysUntilNextRun;
        return days >= 0 && days <= 3;
      }).toList();

  /// Tải danh sách giao dịch định kỳ
  Future<void> loadRecurring() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'recurring_transactions',
        orderBy: 'next_run_date ASC',
      );
      _recurringTransactions = maps
          .map((map) => RecurringTransaction.fromMap(map))
          .toList();
    } catch (e) {
      _error = 'Lỗi tải giao dịch định kỳ: $e';
      debugPrint('Error loading recurring: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm giao dịch định kỳ mới
  Future<bool> addRecurring(RecurringTransaction recurring) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('recurring_transactions', recurring.toMap());
      await loadRecurring();

      // Gửi thông báo nếu sắp đến hạn
      await _scheduleReminderIfNeeded(recurring);

      return true;
    } catch (e) {
      _error = 'Lỗi thêm giao dịch định kỳ: $e';
      debugPrint('Error adding recurring: $e');
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật giao dịch định kỳ
  Future<bool> updateRecurring(RecurringTransaction recurring) async {
    if (recurring.id == null) return false;

    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'recurring_transactions',
        recurring.toMap(),
        where: 'id = ?',
        whereArgs: [recurring.id],
      );
      await loadRecurring();
      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật giao dịch định kỳ: $e';
      debugPrint('Error updating recurring: $e');
      notifyListeners();
      return false;
    }
  }

  /// Xóa giao dịch định kỳ
  Future<bool> deleteRecurring(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'recurring_transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      // Hủy thông báo liên quan
      await NotificationService.cancelNotification(id + 2000);
      await loadRecurring();
      return true;
    } catch (e) {
      _error = 'Lỗi xóa giao dịch định kỳ: $e';
      debugPrint('Error deleting recurring: $e');
      notifyListeners();
      return false;
    }
  }

  /// Bật/tắt giao dịch định kỳ
  Future<bool> toggleActive(int id, bool isActive) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'recurring_transactions',
        {'is_active': isActive ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadRecurring();
      return true;
    } catch (e) {
      debugPrint('Error toggling recurring: $e');
      return false;
    }
  }

  /// Xử lý các giao dịch định kỳ đến hạn
  /// Tạo giao dịch thực tế và cập nhật ngày chạy tiếp theo
  Future<int> processRecurring() async {
    int processedCount = 0;

    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();

      final due = _recurringTransactions
          .where((r) => r.isActive && r.nextRunDate.isBefore(now))
          .toList();

      for (final r in due) {
        try {
          // Tạo giao dịch thực tế
          await db.insert('transactions', {
            'category_id': r.categoryId,
            'amount': r.amount,
            'date': r.nextRunDate.toIso8601String(),
            'description': '${r.description} (Định kỳ)',
            'type': r.type,
            'created_at': now.toIso8601String(),
          });

          // Cập nhật ngân sách nếu là chi tiêu
          if (r.type == 'expense') {
            final month = '${r.nextRunDate.year}-${r.nextRunDate.month.toString().padLeft(2, '0')}';
            await db.rawUpdate(
              'UPDATE budgets SET spent_amount = MAX(0, spent_amount + ?) WHERE category_id = ? AND month = ?',
              [r.amount, r.categoryId, month],
            );
          }

          // Tính ngày chạy tiếp theo sử dụng extension method
          final nextDate = r.interval.nextDate(r.nextRunDate);

          // Cập nhật next_run_date và last_run_date
          await db.update(
            'recurring_transactions',
            {
              'next_run_date': nextDate.toIso8601String(),
              'last_run_date': r.nextRunDate.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [r.id],
          );

          processedCount++;
        } catch (e) {
          debugPrint('Error processing recurring ${r.id}: $e');
        }
      }

      if (due.isNotEmpty) {
        await loadRecurring();
      }

      // Gửi thông báo nhắc nhở cho các giao dịch sắp đến hạn
      await _sendUpcomingReminders();

    } catch (e) {
      debugPrint('Error processing recurring transactions: $e');
    }

    return processedCount;
  }

  /// Gửi thông báo nhắc nhở cho giao dịch sắp đến hạn
  Future<void> _sendUpcomingReminders() async {
    for (final r in upcomingTransactions) {
      if (r.notificationEnabled && r.id != null) {
        await NotificationService.showRecurringReminder(
          recurringId: r.id!,
          description: r.description,
          amount: r.amount,
          type: r.type,
          daysUntil: r.daysUntilNextRun,
        );
      }
    }
  }

  /// Gửi thông báo nhắc nhở nếu giao dịch sắp đến hạn
  Future<void> _scheduleReminderIfNeeded(RecurringTransaction recurring) async {
    if (!recurring.notificationEnabled) return;

    final days = recurring.daysUntilNextRun;
    if (days >= 0 && days <= 3 && recurring.id != null) {
      await NotificationService.showRecurringReminder(
        recurringId: recurring.id!,
        description: recurring.description,
        amount: recurring.amount,
        type: recurring.type,
        daysUntil: days,
      );
    }
  }

  /// Xóa lỗi
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
