import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/savings_goal.dart';
import '../services/notification_service.dart';

class SavingsGoalProvider extends ChangeNotifier {
  List<SavingsGoal> _goals = [];
  bool _isLoading = false;

  List<SavingsGoal> get goals => _goals;
  List<SavingsGoal> get activeGoals => _goals.where((g) => !g.isCompleted).toList();
  List<SavingsGoal> get completedGoals => _goals.where((g) => g.isCompleted).toList();
  bool get isLoading => _isLoading;

  double get totalSaved => _goals.fold(0, (sum, g) => sum + g.currentAmount);
  double get totalTarget => _goals.fold(0, (sum, g) => sum + g.targetAmount);

  Future<void> loadGoals() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'savings_goals',
        orderBy: 'is_completed ASC, target_date ASC',
      );
      _goals = maps.map((map) => SavingsGoal.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading savings goals: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoal(SavingsGoal goal) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('savings_goals', goal.toMap());
      await loadGoals();
    } catch (e) {
      debugPrint('Error adding savings goal: $e');
    }
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'savings_goals',
        goal.toMap(),
        where: 'id = ?',
        whereArgs: [goal.id],
      );
      await loadGoals();
    } catch (e) {
      debugPrint('Error updating savings goal: $e');
    }
  }

  Future<void> addContribution(int goalId, double amount) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Get current goal
      final result = await db.query(
        'savings_goals',
        where: 'id = ?',
        whereArgs: [goalId],
      );

      if (result.isNotEmpty) {
        final goal = SavingsGoal.fromMap(result.first);
        final newAmount = goal.currentAmount + amount;
        final wasCompleted = goal.isCompleted;
        final isCompleted = newAmount >= goal.targetAmount;

        await db.update(
          'savings_goals',
          {
            'current_amount': newAmount,
            'is_completed': isCompleted ? 1 : 0,
          },
          where: 'id = ?',
          whereArgs: [goalId],
        );

        // Gửi thông báo khi đạt mục tiêu lần đầu
        if (isCompleted && !wasCompleted) {
          await NotificationService.showSavingsGoalAchieved(
            goalId: goalId,
            goalName: goal.name,
            targetAmount: goal.targetAmount,
          );
        }

        await loadGoals();
      }
    } catch (e) {
      debugPrint('Error adding contribution: $e');
    }
  }

  Future<void> deleteGoal(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
      await loadGoals();
    } catch (e) {
      debugPrint('Error deleting savings goal: $e');
    }
  }
}
