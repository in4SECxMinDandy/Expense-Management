import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';

// Conditional imports cho platform-specific file operations
import 'csv_service_io.dart' if (dart.library.html) 'csv_service_web.dart';

/// CsvService - Xuất/nhập dữ liệu CSV
/// Hỗ trợ đa nền tảng: Mobile, Desktop, Web
class CsvService {
  /// Xuất giao dịch ra file CSV với tên danh mục
  static Future<bool> exportTransactions({
    required List<Transaction> transactions,
    required List<Category> categories,
    String? fileName,
  }) async {
    try {
      // Tạo map danh mục để tra cứu nhanh
      final categoryMap = {for (final c in categories) c.id: c};

      final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '');
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      List<List<dynamic>> rows = [];

      // Header tiếng Việt
      rows.add([
        'ID',
        'Ngày',
        'Loại',
        'Danh mục',
        'Số tiền (đ)',
        'Mô tả',
        'Ghi chú',
        'Tạo lúc',
      ]);

      for (final t in transactions) {
        final category = categoryMap[t.categoryId];
        final categoryName = category?.name ?? 'Không xác định';

        DateTime txDate;
        try {
          txDate = DateTime.parse(t.date);
        } catch (_) {
          txDate = DateTime.now();
        }

        rows.add([
          t.id ?? '',
          dateFormat.format(txDate),
          t.type == 'income' ? 'Thu nhập' : 'Chi tiêu',
          categoryName,
          currencyFormat.format(t.amount),
          t.description ?? '',
          t.notes ?? '',
          t.createdAt != null
              ? dateFormat.format(DateTime.tryParse(t.createdAt!) ?? DateTime.now())
              : '',
        ]);
      }

      // Thêm dòng tổng kết
      rows.add([]);
      final totalIncome = transactions
          .where((t) => t.type == 'income')
          .fold(0.0, (sum, t) => sum + t.amount);
      final totalExpense = transactions
          .where((t) => t.type == 'expense')
          .fold(0.0, (sum, t) => sum + t.amount);

      rows.add(['', '', '', 'Tổng thu nhập:', currencyFormat.format(totalIncome), '', '', '']);
      rows.add(['', '', '', 'Tổng chi tiêu:', currencyFormat.format(totalExpense), '', '', '']);
      rows.add(['', '', '', 'Số dư:', currencyFormat.format(totalIncome - totalExpense), '', '', '']);

      final csv = const ListToCsvConverter().convert(rows);
      final safeFileName = fileName ??
          'SpendWise_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

      if (kIsWeb) {
        // Web: Download file
        await downloadCsvWeb(csv, safeFileName);
        return true;
      } else {
        // Mobile/Desktop: Share file
        return await _shareFile(csv, safeFileName);
      }
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      return false;
    }
  }

  /// Chia sẻ file CSV (Mobile/Desktop)
  static Future<bool> _shareFile(String csv, String fileName) async {
    try {
      return await saveCsvAndShare(csv, fileName);
    } catch (e) {
      debugPrint('Error sharing CSV file: $e');
      return false;
    }
  }

  /// Nhập giao dịch từ file CSV
  static Future<List<Transaction>> importTransactions({
    required List<Category> categories,
  }) async {
    try {
      if (kIsWeb) {
        return await importCsvWeb(categories);
      } else {
        return await importCsvIo(categories);
      }
    } catch (e) {
      debugPrint('Error importing CSV: $e');
      return [];
    }
  }

  /// Parse CSV content thành danh sách Transaction
  static List<Transaction> parseCsvContent(
    String csvContent,
    List<Category> categories,
  ) {
    try {
      final List<List<dynamic>> rows =
          const CsvToListConverter().convert(csvContent);

      // Skip header
      if (rows.length <= 1) return [];

      // Tạo map danh mục theo tên
      final categoryByName = <String, Category>{};
      for (final c in categories) {
        categoryByName[c.name.toLowerCase()] = c;
      }

      List<Transaction> transactions = [];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 4) continue;

        // Bỏ qua dòng tổng kết
        final firstCell = row[0]?.toString() ?? '';
        if (firstCell.isEmpty && row.length > 3) {
          final label = row[3]?.toString() ?? '';
          if (label.contains('Tổng') || label.contains('Số dư')) continue;
        }

        try {
          // Parse ngày
          String dateStr = row[1]?.toString() ?? '';
          DateTime date;
          try {
            // Thử parse format dd/MM/yyyy HH:mm
            date = DateFormat('dd/MM/yyyy HH:mm').parse(dateStr);
          } catch (_) {
            try {
              date = DateTime.parse(dateStr);
            } catch (_) {
              date = DateTime.now();
            }
          }

          // Parse loại giao dịch
          final typeStr = row[2]?.toString() ?? '';
          final type = typeStr.contains('Thu') ? 'income' : 'expense';

          // Tìm danh mục theo tên
          final categoryName = (row[3]?.toString() ?? '').toLowerCase();
          final category = categoryByName[categoryName];
          final categoryId = category?.id ?? 1;

          // Parse số tiền (loại bỏ dấu phẩy và khoảng trắng)
          final amountStr = row[4]?.toString().replaceAll(RegExp(r'[,\s]'), '') ?? '0';
          final amount = double.tryParse(amountStr) ?? 0.0;

          if (amount <= 0) continue;

          transactions.add(Transaction(
            categoryId: categoryId,
            amount: amount,
            date: date.toIso8601String(),
            description: row.length > 5 ? row[5]?.toString() : null,
            type: type,
            notes: row.length > 6 ? row[6]?.toString() : null,
          ));
        } catch (e) {
          debugPrint('Error parsing row $i: $e');
          continue;
        }
      }

      return transactions;
    } catch (e) {
      debugPrint('Error parsing CSV content: $e');
      return [];
    }
  }
}
