import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/transaction.dart';
import '../services/notification_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  double get totalIncome {
    return _transactions
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        orderBy: 'date DESC',
      );
      _transactions = maps.map((map) => Transaction.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('transactions', transaction.toMap());

      // Update budget if it exists
      if (transaction.type == 'expense') {
        final month = transaction.date.substring(0, 7);
        final budgetsMap = await db.query(
          'budgets',
          where: 'category_id = ? AND month = ?',
          whereArgs: [transaction.categoryId, month],
        );

        if (budgetsMap.isNotEmpty) {
          final id = budgetsMap.first['id'] as int;
          final limitAmount = budgetsMap.first['limit_amount'] as double;
          final currentSpent = budgetsMap.first['spent_amount'] as double;
          final newSpent = currentSpent + transaction.amount;

          await db.update(
            'budgets',
            {'spent_amount': newSpent},
            where: 'id = ?',
            whereArgs: [id],
          );

          // Alert if over budget
          if (newSpent > limitAmount) {
            NotificationService.showNotification(
              id: id,
              title: 'Cảnh báo vượt hạn mức!',
              body: 'Bạn đã tiêu vượt mức ngân sách cho danh mục này.',
            );
          }
        }
      }

      await loadTransactions();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Get old transaction to adjust budget
      final oldList = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      if (oldList.isNotEmpty) {
        final oldTx = Transaction.fromMap(oldList.first);
        final oldMonth = oldTx.date.substring(0, 7);
        final newMonth = transaction.date.substring(0, 7);

        // Revert old budget if it was expense
        if (oldTx.type == 'expense') {
          final oldBudgets = await db.query(
            'budgets',
            where: 'category_id = ? AND month = ?',
            whereArgs: [oldTx.categoryId, oldMonth],
          );
          if (oldBudgets.isNotEmpty) {
            final budgetId = oldBudgets.first['id'] as int;
            final currentSpent = oldBudgets.first['spent_amount'] as double;
            await db.update(
              'budgets',
              {'spent_amount': currentSpent - oldTx.amount},
              where: 'id = ?',
              whereArgs: [budgetId],
            );
          }
        }

        // Apply new budget if expense
        if (transaction.type == 'expense') {
          final newBudgets = await db.query(
            'budgets',
            where: 'category_id = ? AND month = ?',
            whereArgs: [transaction.categoryId, newMonth],
          );
          if (newBudgets.isNotEmpty) {
            final budgetId = newBudgets.first['id'] as int;
            final limitAmount = newBudgets.first['limit_amount'] as double;
            final currentSpent = newBudgets.first['spent_amount'] as double;
            final newSpent = currentSpent + transaction.amount;

            await db.update(
              'budgets',
              {'spent_amount': newSpent},
              where: 'id = ?',
              whereArgs: [budgetId],
            );

            if (newSpent > limitAmount) {
              NotificationService.showNotification(
                id: budgetId,
                title: 'Cảnh báo vượt hạn mức!',
                body: 'Bạn đã tiêu vượt mức ngân sách cho danh mục này.',
              );
            }
          }
        }
      }

      // Update transaction
      await db.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      await loadTransactions();
    } catch (e) {
      debugPrint('Error updating transaction: $e');
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Get transaction before deleting to update budget
      final tList = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (tList.isNotEmpty) {
        final t = Transaction.fromMap(tList.first);
        if (t.type == 'expense') {
          final month = t.date.substring(0, 7);
          final budgetsMap = await db.query(
            'budgets',
            where: 'category_id = ? AND month = ?',
            whereArgs: [t.categoryId, month],
          );

          if (budgetsMap.isNotEmpty) {
            final budgetId = budgetsMap.first['id'] as int;
            final currentSpent = budgetsMap.first['spent_amount'] as double;
            await db.update(
              'budgets',
              {'spent_amount': currentSpent - t.amount},
              where: 'id = ?',
              whereArgs: [budgetId],
            );
          }
        }
      }

      await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
      await loadTransactions();
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
    }
  }
}
