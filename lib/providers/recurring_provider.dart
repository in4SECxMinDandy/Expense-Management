import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/recurring_transaction.dart';

class RecurringProvider extends ChangeNotifier {
  List<RecurringTransaction> _recurringTransactions = [];
  bool _isLoading = false;

  List<RecurringTransaction> get recurringTransactions =>
      _recurringTransactions;
  bool get isLoading => _isLoading;

  Future<void> loadRecurring() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'recurring_transactions',
      );
      _recurringTransactions = maps
          .map((map) => RecurringTransaction.fromMap(map))
          .toList();
    } catch (e) {
      debugPrint('Error loading recurring: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecurring(RecurringTransaction recurring) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('recurring_transactions', recurring.toMap());
      await loadRecurring();
    } catch (e) {
      debugPrint('Error adding recurring: $e');
    }
  }

  /// Process due recurring transactions and create main transactions
  Future<void> processRecurring() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();

      final due = _recurringTransactions
          .where((r) => r.isActive && r.nextRunDate.isBefore(now))
          .toList();

      for (var r in due) {
        // Create main transaction
        await db.insert('transactions', {
          'category_id': r.categoryId,
          'amount': r.amount,
          'date': r.nextRunDate.toIso8601String(),
          'description': '${r.description} (Recurring)',
          'type': r.type,
        });

        // Update budget if needed (simplified: just call it here or let TransactionProvider handle it if we used its method)
        // For simplicity, we'll assume budgets are updated by TransactionProvider load or similar,
        // but here we should manually update it since we use raw db.

        final month = r.nextRunDate.toIso8601String().substring(0, 7);
        if (r.type == 'expense') {
          await db.rawUpdate(
            'UPDATE budgets SET spent_amount = spent_amount + ? WHERE category_id = ? AND month = ?',
            [r.amount, r.categoryId, month],
          );
        }

        // Schedule next run
        DateTime nextDate;
        switch (r.interval) {
          case RepeatInterval.daily:
            nextDate = r.nextRunDate.add(const Duration(days: 1));
            break;
          case RepeatInterval.weekly:
            nextDate = r.nextRunDate.add(const Duration(days: 7));
            break;
          case RepeatInterval.monthly:
            nextDate = DateTime(
              r.nextRunDate.year,
              r.nextRunDate.month + 1,
              r.nextRunDate.day,
            );
            break;
          case RepeatInterval.yearly:
            nextDate = DateTime(
              r.nextRunDate.year + 1,
              r.nextRunDate.month,
              r.nextRunDate.day,
            );
            break;
        }

        await db.update(
          'recurring_transactions',
          {'next_run_date': nextDate.toIso8601String()},
          where: 'id = ?',
          whereArgs: [r.id],
        );
      }

      if (due.isNotEmpty) {
        await loadRecurring();
      }
    } catch (e) {
      debugPrint('Error processing recurring: $e');
    }
  }
}
