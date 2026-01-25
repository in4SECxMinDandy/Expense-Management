import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/budget.dart';

class BudgetProvider extends ChangeNotifier {
  List<Budget> _budgets = [];
  bool _isLoading = false;

  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;

  Future<void> loadBudgets(String month) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'budgets',
        where: 'month = ?',
        whereArgs: [month],
      );
      _budgets = maps.map((map) => Budget.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading budgets: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addOrUpdateBudget(Budget budget) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Check if budget exists for this category/month
      final existing = await db.query(
        'budgets',
        where: 'category_id = ? AND month = ?',
        whereArgs: [budget.categoryId, budget.month],
      );

      if (existing.isNotEmpty) {
        await db.update(
          'budgets',
          budget.toMap(),
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        await db.insert('budgets', budget.toMap());
      }

      await loadBudgets(budget.month);
    } catch (e) {
      debugPrint('Error saving budget: $e');
    }
  }

  Future<void> deleteBudget(int id, String month) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
      await loadBudgets(month);
    } catch (e) {
      debugPrint('Error deleting budget: $e');
    }
  }

  /// Update spent amount based on current transactions
  Future<void> updateSpentAmount(
    int categoryId,
    String month,
    double amount,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final budgets = await db.query(
        'budgets',
        where: 'category_id = ? AND month = ?',
        whereArgs: [categoryId, month],
      );

      if (budgets.isNotEmpty) {
        final currentBudget = Budget.fromMap(budgets.first);
        final newSpent = currentBudget.spentAmount + amount;

        await db.update(
          'budgets',
          {'spent_amount': newSpent},
          where: 'id = ?',
          whereArgs: [currentBudget.id],
        );

        await loadBudgets(month);
      }
    } catch (e) {
      debugPrint('Error updating spent amount: $e');
    }
  }
}
