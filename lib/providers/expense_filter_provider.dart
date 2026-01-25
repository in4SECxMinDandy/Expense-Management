import 'package:flutter/foundation.dart';
import '../models/transaction.dart';

/// Provider quản lý bộ lọc thời gian cho màn hình Báo cáo
class ExpenseFilterProvider extends ChangeNotifier {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _filterByMonth = false; // true = lọc theo tháng, false = lọc theo năm

  // Getters
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  bool get filterByMonth => _filterByMonth;

  // Danh sách năm có sẵn (5 năm gần nhất)
  List<int> get availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(5, (index) => currentYear - index);
  }

  // Danh sách tháng
  List<int> get availableMonths => List.generate(12, (index) => index + 1);

  // Cập nhật tháng đã chọn
  void setSelectedMonth(int month) {
    _selectedMonth = month;
    notifyListeners();
  }

  // Cập nhật năm đã chọn
  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
  }

  // Bật/tắt chế độ lọc theo tháng
  void setFilterByMonth(bool value) {
    _filterByMonth = value;
    notifyListeners();
  }

  // Cập nhật cả tháng và năm cùng lúc
  void setMonthAndYear(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    notifyListeners();
  }

  /// Lọc giao dịch theo tháng và năm đã chọn
  List<Transaction> filterExpensesByMonth(
    List<Transaction> transactions,
    int month,
    int year,
  ) {
    return transactions.where((t) {
      try {
        final date = DateTime.parse(t.date);
        return date.month == month && date.year == year;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Lọc giao dịch theo năm
  List<Transaction> filterExpensesByYear(
    List<Transaction> transactions,
    int year,
  ) {
    return transactions.where((t) {
      try {
        final date = DateTime.parse(t.date);
        return date.year == year;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Lọc giao dịch dựa trên chế độ hiện tại (theo tháng hoặc năm)
  List<Transaction> filterTransactions(List<Transaction> transactions) {
    if (_filterByMonth) {
      return filterExpensesByMonth(transactions, _selectedMonth, _selectedYear);
    } else {
      return filterExpensesByYear(transactions, _selectedYear);
    }
  }

  /// Tính chi tiêu theo ngày trong tháng (cho biểu đồ)
  Map<int, double> getExpensesByDayInMonth(
    List<Transaction> transactions,
    int month,
    int year,
  ) {
    final filtered = filterExpensesByMonth(transactions, month, year);
    final Map<int, double> dailyExpenses = {};

    for (final t in filtered) {
      if (t.type == 'expense') {
        try {
          final date = DateTime.parse(t.date);
          final day = date.day;
          dailyExpenses[day] = (dailyExpenses[day] ?? 0) + t.amount;
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    return dailyExpenses;
  }

  /// Tính chi tiêu theo tuần trong tháng (cho biểu đồ)
  Map<int, double> getExpensesByWeekInMonth(
    List<Transaction> transactions,
    int month,
    int year,
  ) {
    final filtered = filterExpensesByMonth(transactions, month, year);
    final Map<int, double> weeklyExpenses = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final t in filtered) {
      if (t.type == 'expense') {
        try {
          final date = DateTime.parse(t.date);
          final day = date.day;
          // Tính tuần: ngày 1-7 = tuần 1, 8-14 = tuần 2, ...
          final week = ((day - 1) ~/ 7) + 1;
          final weekKey = week > 5 ? 5 : week; // Max 5 tuần
          weeklyExpenses[weekKey] =
              (weeklyExpenses[weekKey] ?? 0) + t.amount;
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    return weeklyExpenses;
  }

  /// Tính chi tiêu theo tháng trong năm (cho biểu đồ)
  Map<int, double> getExpensesByMonthInYear(
    List<Transaction> transactions,
    int year,
  ) {
    final filtered = filterExpensesByYear(transactions, year);
    final Map<int, double> monthlyExpenses = {};

    for (int i = 1; i <= 12; i++) {
      monthlyExpenses[i] = 0;
    }

    for (final t in filtered) {
      if (t.type == 'expense') {
        try {
          final date = DateTime.parse(t.date);
          monthlyExpenses[date.month] =
              (monthlyExpenses[date.month] ?? 0) + t.amount;
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    return monthlyExpenses;
  }

  /// Lấy số ngày trong tháng
  int getDaysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Lấy tiêu đề báo cáo
  String getReportTitle() {
    if (_filterByMonth) {
      final monthStr = _selectedMonth.toString().padLeft(2, '0');
      return 'Báo cáo chi tiêu Tháng $monthStr/$_selectedYear';
    } else {
      return 'Báo cáo chi tiêu năm $_selectedYear';
    }
  }
}
