import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_helper.dart';

/// SyncService - Đồng bộ dữ liệu đa nền tảng
/// Hiện tại: Local backup/restore qua JSON
/// Tương lai: Có thể mở rộng để sync với cloud (Firebase, Supabase)
class SyncService {
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _backupKey = 'local_backup_data';

  /// Tạo backup dữ liệu toàn bộ
  static Future<Map<String, dynamic>> createBackup() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Lấy tất cả dữ liệu
      final transactions = await db.query('transactions', orderBy: 'date DESC');
      final categories = await db.query('categories');
      final budgets = await db.query('budgets');
      final savingsGoals = await db.query('savings_goals');
      final wallets = await db.query('wallets');
      final recurringTransactions = await db.query('recurring_transactions');

      final backup = {
        'version': 1,
        'created_at': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.name,
        'data': {
          'transactions': transactions,
          'categories': categories,
          'budgets': budgets,
          'savings_goals': savingsGoals,
          'wallets': wallets,
          'recurring_transactions': recurringTransactions,
        },
        'stats': {
          'transaction_count': transactions.length,
          'category_count': categories.length,
          'budget_count': budgets.length,
        },
      };

      // Lưu backup vào SharedPreferences (cho sync nhanh)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupKey, jsonEncode(backup));
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      return backup;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      return {};
    }
  }

  /// Xuất backup ra JSON string
  static Future<String> exportBackupJson() async {
    final backup = await createBackup();
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Nhập backup từ JSON string
  static Future<SyncResult> importBackupJson(String jsonStr) async {
    try {
      final Map<String, dynamic> backup = jsonDecode(jsonStr);

      // Kiểm tra version
      final version = backup['version'] as int? ?? 0;
      if (version < 1) {
        return SyncResult.error('Phiên bản backup không hợp lệ');
      }

      final data = backup['data'] as Map<String, dynamic>?;
      if (data == null) {
        return SyncResult.error('Dữ liệu backup không hợp lệ');
      }

      return await _restoreFromData(data);
    } catch (e) {
      debugPrint('Error importing backup: $e');
      return SyncResult.error('Lỗi nhập backup: $e');
    }
  }

  /// Khôi phục dữ liệu từ backup
  static Future<SyncResult> _restoreFromData(
      Map<String, dynamic> data) async {
    try {
      final db = await DatabaseHelper.instance.database;
      int restoredCount = 0;
      int skippedCount = 0;

      // Khôi phục categories (merge, không xóa existing)
      final categories = data['categories'] as List<dynamic>? ?? [];
      for (final catMap in categories) {
        try {
          final cat = Map<String, dynamic>.from(catMap as Map);
          final existing = await db.query(
            'categories',
            where: 'name = ? AND type = ?',
            whereArgs: [cat['name'], cat['type']],
          );
          if (existing.isEmpty) {
            cat.remove('id'); // Để auto-increment
            await db.insert('categories', cat);
            restoredCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          debugPrint('Error restoring category: $e');
        }
      }

      // Khôi phục wallets
      final wallets = data['wallets'] as List<dynamic>? ?? [];
      for (final walletMap in wallets) {
        try {
          final wallet = Map<String, dynamic>.from(walletMap as Map);
          final existing = await db.query(
            'wallets',
            where: 'name = ?',
            whereArgs: [wallet['name']],
          );
          if (existing.isEmpty) {
            wallet.remove('id');
            await db.insert('wallets', wallet);
            restoredCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          debugPrint('Error restoring wallet: $e');
        }
      }

      // Khôi phục transactions (dựa trên date + amount + type để tránh trùng)
      final transactions = data['transactions'] as List<dynamic>? ?? [];
      for (final txMap in transactions) {
        try {
          final tx = Map<String, dynamic>.from(txMap as Map);
          final existing = await db.query(
            'transactions',
            where: 'date = ? AND amount = ? AND type = ? AND category_id = ?',
            whereArgs: [tx['date'], tx['amount'], tx['type'], tx['category_id']],
          );
          if (existing.isEmpty) {
            tx.remove('id');
            await db.insert('transactions', tx);
            restoredCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          debugPrint('Error restoring transaction: $e');
        }
      }

      // Khôi phục savings goals
      final savingsGoals = data['savings_goals'] as List<dynamic>? ?? [];
      for (final goalMap in savingsGoals) {
        try {
          final goal = Map<String, dynamic>.from(goalMap as Map);
          final existing = await db.query(
            'savings_goals',
            where: 'name = ?',
            whereArgs: [goal['name']],
          );
          if (existing.isEmpty) {
            goal.remove('id');
            await db.insert('savings_goals', goal);
            restoredCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          debugPrint('Error restoring savings goal: $e');
        }
      }

      // Cập nhật thời gian sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      return SyncResult.success(
        restoredCount: restoredCount,
        skippedCount: skippedCount,
      );
    } catch (e) {
      debugPrint('Error restoring data: $e');
      return SyncResult.error('Lỗi khôi phục dữ liệu: $e');
    }
  }

  /// Lấy thời gian sync cuối cùng
  static Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getString(_lastSyncKey);
      if (timeStr == null) return null;
      return DateTime.tryParse(timeStr);
    } catch (e) {
      return null;
    }
  }

  /// Lấy thống kê database
  static Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final stats = <String, int>{};

      final tables = [
        'transactions',
        'categories',
        'budgets',
        'savings_goals',
        'wallets',
        'recurring_transactions',
      ];

      for (final table in tables) {
        try {
          final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
          stats[table] = (result.first['count'] as int?) ?? 0;
        } catch (_) {
          stats[table] = 0;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting database stats: $e');
      return {};
    }
  }

  /// Xóa toàn bộ dữ liệu (reset app)
  static Future<bool> clearAllData() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Xóa theo thứ tự để tránh lỗi foreign key
      await db.delete('transactions');
      await db.delete('budgets');
      await db.delete('recurring_transactions');
      await db.delete('savings_goals');
      await db.delete('ai_insights');
      // Giữ lại categories và wallets mặc định

      return true;
    } catch (e) {
      debugPrint('Error clearing data: $e');
      return false;
    }
  }
}

/// Kết quả đồng bộ
class SyncResult {
  final bool isSuccess;
  final String? errorMessage;
  final int restoredCount;
  final int skippedCount;

  SyncResult._({
    required this.isSuccess,
    this.errorMessage,
    this.restoredCount = 0,
    this.skippedCount = 0,
  });

  factory SyncResult.success({
    required int restoredCount,
    required int skippedCount,
  }) {
    return SyncResult._(
      isSuccess: true,
      restoredCount: restoredCount,
      skippedCount: skippedCount,
    );
  }

  factory SyncResult.error(String message) {
    return SyncResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'SyncResult: Thành công - Đã khôi phục $restoredCount, bỏ qua $skippedCount';
    }
    return 'SyncResult: Lỗi - $errorMessage';
  }
}
