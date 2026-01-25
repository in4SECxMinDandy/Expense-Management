import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ios_card.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/recurring_provider.dart';
import 'transaction_detail_screen.dart';

// Enum cho chế độ lọc thời gian
enum FilterMode { week, day, month, year }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Dummy user data for now
  final String _userName = 'Người dùng';
  final String _userAvatarUrl =
      'https://i.pravatar.cc/150?img=12'; // Placeholder

  // Bộ lọc năm
  int _selectedYear = DateTime.now().year;
  late List<int> _availableYears;

  // Bộ lọc thời gian nâng cao
  FilterMode _filterMode = FilterMode.week; // week, day, month, year
  DateTime _selectedFilterDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Tạo danh sách 5 năm gần nhất
    final currentYear = DateTime.now().year;
    _availableYears =
        List.generate(5, (index) => currentYear - index);
    _selectedYear = currentYear;

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final month = DateFormat('yyyy-MM').format(DateTime.now());
      context.read<TransactionProvider>().loadTransactions();
      context.read<CategoryProvider>().loadCategories();
      context.read<BudgetProvider>().loadBudgets(month);
      context.read<RecurringProvider>().loadRecurring().then((_) {
        if (!mounted) return;
        context.read<RecurringProvider>().processRecurring();
      });
    });
  }

  // Format ngày tháng tiếng Việt
  String _formatVietnameseDate() {
    final now = DateTime.now();
    final weekdays = [
      'Chủ Nhật',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy'
    ];
    final weekday = weekdays[now.weekday % 7];
    final day = now.day;
    final month = now.month;
    final year = now.year;
    return '$weekday, $day tháng $month, $year';
  }

  // Lấy tiêu đề biểu đồ theo chế độ lọc
  String _getChartTitle() {
    switch (_filterMode) {
      case FilterMode.day:
        final day = _selectedFilterDate.day.toString().padLeft(2, '0');
        final month = _selectedFilterDate.month.toString().padLeft(2, '0');
        final year = _selectedFilterDate.year;
        return 'Chi tiêu ngày $day/$month/$year';
      case FilterMode.month:
        final month = _selectedFilterDate.month;
        final year = _selectedFilterDate.year;
        return 'Chi tiêu tháng $month/$year';
      case FilterMode.year:
        return 'Chi tiêu năm $_selectedYear';
      case FilterMode.week:
        return 'Chi tiêu tuần này';
    }
  }

  // Lọc giao dịch theo chế độ lọc hiện tại
  List<Transaction> _filterTransactionsByMode(List<Transaction> transactions) {
    return transactions.where((t) {
      try {
        final date = DateTime.parse(t.date);
        switch (_filterMode) {
          case FilterMode.day:
            return date.year == _selectedFilterDate.year &&
                   date.month == _selectedFilterDate.month &&
                   date.day == _selectedFilterDate.day;
          case FilterMode.month:
            return date.year == _selectedFilterDate.year &&
                   date.month == _selectedFilterDate.month;
          case FilterMode.year:
            return date.year == _selectedYear;
          case FilterMode.week:
            // Lọc theo tuần hiện tại
            final now = DateTime.now();
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
            final weekEndDate = weekStartDate.add(const Duration(days: 7));
            final txDateOnly = DateTime(date.year, date.month, date.day);
            return !txDateOnly.isBefore(weekStartDate) && txDateOnly.isBefore(weekEndDate);
        }
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Hiển thị bottom sheet chọn chế độ lọc
  void _showFilterOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: AppTheme.spaceL),
              Text('Chọn khoảng thời gian', style: AppTheme.headingM),
              const SizedBox(height: AppTheme.spaceL),

              // Tuần này
              _buildFilterOption(
                icon: Icons.view_week,
                label: 'Tuần này',
                isSelected: _filterMode == FilterMode.week,
                onTap: () {
                  setState(() {
                    _filterMode = FilterMode.week;
                  });
                  Navigator.pop(context);
                },
              ),

              // Chọn ngày
              _buildFilterOption(
                icon: Icons.today,
                label: 'Chọn ngày cụ thể',
                isSelected: _filterMode == FilterMode.day,
                onTap: () async {
                  Navigator.pop(context);
                  await _selectFilterDate();
                },
              ),

              // Chọn tháng
              _buildFilterOption(
                icon: Icons.calendar_month,
                label: 'Chọn tháng',
                isSelected: _filterMode == FilterMode.month,
                onTap: () async {
                  Navigator.pop(context);
                  await _selectFilterMonth();
                },
              ),

              // Cả năm
              _buildFilterOption(
                icon: Icons.calendar_today,
                label: 'Cả năm $_selectedYear',
                isSelected: _filterMode == FilterMode.year,
                onTap: () {
                  setState(() {
                    _filterMode = FilterMode.year;
                  });
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: AppTheme.spaceM),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceM,
          vertical: AppTheme.spaceM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPurple.withValues(alpha: 0.1)
              : (isDark ? AppTheme.darkBackground : AppTheme.lightBackground),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: isSelected
              ? Border.all(color: AppTheme.primaryPurple, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryPurple : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Text(
                label,
                style: AppTheme.bodyM.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppTheme.primaryPurple
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryPurple,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Chọn ngày cụ thể
  Future<void> _selectFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedFilterDate = picked;
        _filterMode = FilterMode.day;
        _selectedYear = picked.year;
      });
    }
  }

  // Chọn tháng
  Future<void> _selectFilterMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('vi', 'VN'),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedFilterDate = picked;
        _filterMode = FilterMode.month;
        _selectedYear = picked.year;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      body: SafeArea(
        child: Consumer<TransactionProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Profile & Header
                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  sliver: SliverToBoxAdapter(
                    child: _buildProfileHeader(provider, isDark),
                  ),
                ),

                // 2. Main Chart Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceM,
                    ),
                    child: _buildMainChartCard(provider, isDark),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spaceL),
                ),

                // 3. Stat Cards (Income / Expense / Savings)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceM,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildStatCards(provider, isDark),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spaceL),
                ),

                // 4. Budget Overview
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceM,
                    ),
                    child: _buildBudgetOverview(isDark),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spaceL),
                ),

                // 4. Recent Transactions Header
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceM,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _filterMode == FilterMode.week
                              ? 'Giao dịch gần đây'
                              : 'Giao dịch trong kỳ',
                          style: AppTheme.headingS,
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to transactions tab logic is handled by main nav
                          },
                          child: Text(
                            'Xem tất cả',
                            style: AppTheme.bodyM.copyWith(
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 5. Recent Transactions List (filtered)
                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  sliver: Builder(
                    builder: (context) {
                      final filteredList = _filterTransactionsByMode(provider.transactions);
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= filteredList.length) return null;
                            final transaction = filteredList[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.spaceS,
                              ),
                              child: _buildTransactionTile(transaction, isDark),
                            );
                          },
                          childCount: filteredList.length > 5
                              ? 5
                              : filteredList.length,
                        ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ), // Fab space
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context),
        backgroundColor: AppTheme.primaryPurple,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProfileHeader(TransactionProvider provider, bool isDark) {
    // Calculate spending based on current filter mode
    final filteredTransactions = _filterTransactionsByMode(provider.transactions);
    final totalSpent = filteredTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    // Lấy label hiển thị phù hợp với filter mode
    String spendingLabel;
    switch (_filterMode) {
      case FilterMode.day:
        spendingLabel = 'Chi tiêu hôm nay';
        break;
      case FilterMode.month:
        spendingLabel = 'Chi tiêu tháng này';
        break;
      case FilterMode.year:
        spendingLabel = 'Chi tiêu năm $_selectedYear';
        break;
      case FilterMode.week:
        spendingLabel = 'Chi tiêu tuần này';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ngày tháng thời gian thực
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.lightPurple,
                  backgroundImage: NetworkImage(_userAvatarUrl),
                  onBackgroundImageError: (exception, stackTrace) {},
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, $_userName',
                      style: AppTheme.headingS.copyWith(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      spendingLabel,
                      style: AppTheme.caption.copyWith(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              _formatCurrency(totalSpent),
              style: AppTheme.headingM.copyWith(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceM),
        // Hiển thị ngày tháng tiếng Việt
        Text(
          _formatVietnameseDate(),
          style: AppTheme.bodyM.copyWith(
            color: AppTheme.primaryPurple,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMainChartCard(TransactionProvider provider, bool isDark) {
    // Lọc giao dịch theo chế độ lọc hiện tại
    final filteredTransactions = _filterTransactionsByMode(provider.transactions);
    final weeklyData = _filterMode == FilterMode.week
        ? _calculateWeeklySpending(filteredTransactions)
        : _calculateDailySpendingForPeriod(filteredTransactions);
    final maxY = weeklyData.isEmpty
        ? 1.0
        : weeklyData.reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxY == 0 ? 1.0 : maxY * 1.2;

    return IOSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với tiêu đề động và các nút lọc
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(_getChartTitle(), style: AppTheme.headingS),
              ),
              // Nút chọn thời gian (Calendar Action Button)
              GestureDetector(
                onTap: _showFilterOptions,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: AppTheme.primaryPurple,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Dropdown bộ lọc năm
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBackground
                      : AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: AppTheme.primaryPurple, size: 20),
                    isDense: true,
                    style: AppTheme.bodyS.copyWith(
                      color: AppTheme.primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _availableYears.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text('$year'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedYear = value;
                          _selectedFilterDate = DateTime(value, _selectedFilterDate.month, 1);
                          if (_filterMode == FilterMode.week) {
                            _filterMode = FilterMode.year;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),

          // Area Chart với Gradient
          AspectRatio(
            aspectRatio: 1.7,
            child: weeklyData.every((v) => v == 0)
                ? Center(
                    child: Text(
                      'Chưa có dữ liệu chi tiêu trong tuần',
                      style: AppTheme.bodyM.copyWith(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: chartMaxY / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withValues(alpha: 0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final labels = _getChartLabels();
                              final index = value.toInt();
                              if (index >= 0 && index < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    labels[index],
                                    style: AppTheme.caption.copyWith(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                      fontSize: labels.length > 7 ? 8 : 12,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            interval: chartMaxY / 4,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatCompactCurrency(value),
                                style: AppTheme.caption.copyWith(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (weeklyData.length - 1).toDouble(),
                      minY: 0,
                      maxY: chartMaxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: weeklyData.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value);
                          }).toList(),
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: AppTheme.primaryPurple,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: isDark ? AppTheme.darkSurface : Colors.white,
                                strokeWidth: 2,
                                strokeColor: AppTheme.primaryPurple,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryPurple.withValues(alpha: 0.4),
                                AppTheme.primaryPurple.withValues(alpha: 0.1),
                                AppTheme.primaryPurple.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${_formatCurrency(spot.y)}đ',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Tính chi tiêu theo tuần
  List<double> _calculateWeeklySpending(List<Transaction> transactions) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate =
        DateTime(weekStart.year, weekStart.month, weekStart.day);

    final dailySpending = List<double>.filled(7, 0);

    for (final t in transactions) {
      if (t.type == 'expense') {
        try {
          final txDate = DateTime.parse(t.date);
          final txDateOnly = DateTime(txDate.year, txDate.month, txDate.day);
          final daysDiff = txDateOnly.difference(weekStartDate).inDays;

          if (daysDiff >= 0 && daysDiff < 7) {
            dailySpending[daysDiff] += t.amount;
          }
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    return dailySpending;
  }

  // Tính chi tiêu theo thời kỳ đã lọc (cho ngày/tháng/năm)
  List<double> _calculateDailySpendingForPeriod(List<Transaction> transactions) {
    switch (_filterMode) {
      case FilterMode.day:
        // Chia ngày thành 4 khoảng thời gian
        final hourlySpending = List<double>.filled(4, 0);
        for (final t in transactions) {
          if (t.type == 'expense') {
            try {
              final txDate = DateTime.parse(t.date);
              final hourIndex = (txDate.hour / 6).floor().clamp(0, 3);
              hourlySpending[hourIndex] += t.amount;
            } catch (e) {
              // Skip invalid
            }
          }
        }
        return hourlySpending;

      case FilterMode.month:
        // Chia tháng thành 4 tuần
        final weeklySpending = List<double>.filled(4, 0);
        for (final t in transactions) {
          if (t.type == 'expense') {
            try {
              final txDate = DateTime.parse(t.date);
              final weekIndex = ((txDate.day - 1) / 7).floor().clamp(0, 3);
              weeklySpending[weekIndex] += t.amount;
            } catch (e) {
              // Skip invalid
            }
          }
        }
        return weeklySpending;

      case FilterMode.year:
        // Chia năm thành 12 tháng
        final monthlySpending = List<double>.filled(12, 0);
        for (final t in transactions) {
          if (t.type == 'expense') {
            try {
              final txDate = DateTime.parse(t.date);
              final monthIndex = txDate.month - 1;
              monthlySpending[monthIndex] += t.amount;
            } catch (e) {
              // Skip invalid
            }
          }
        }
        return monthlySpending;

      case FilterMode.week:
        return _calculateWeeklySpending(transactions);
    }
  }

  // Lấy nhãn trục X cho biểu đồ
  List<String> _getChartLabels() {
    switch (_filterMode) {
      case FilterMode.day:
        return ['0-6h', '6-12h', '12-18h', '18-24h'];
      case FilterMode.month:
        return ['Tuần 1', 'Tuần 2', 'Tuần 3', 'Tuần 4'];
      case FilterMode.year:
        return ['T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'];
      case FilterMode.week:
        return ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    }
  }

  Widget _buildStatCards(TransactionProvider provider, bool isDark) {
    final filteredTransactions = _filterTransactionsByMode(provider.transactions);
    final totalIncome = filteredTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = filteredTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final savings = totalIncome - totalExpense;

    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'Thu nhập',
            totalIncome,
            AppTheme.incomeGreen,
            isDark,
          ),
        ),
        const SizedBox(width: AppTheme.spaceS),
        Expanded(
          child: _buildInfoCard(
            'Chi tiêu',
            totalExpense,
            AppTheme.expenseRed,
            isDark,
          ),
        ),
        const SizedBox(width: AppTheme.spaceS),
        Expanded(
          child: _buildInfoCard(
            'Tiết kiệm',
            savings,
            AppTheme.primaryPurple,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, double amount, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.shadowXS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.caption.copyWith(
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCompactCurrency(amount),
            style: AppTheme.headingS.copyWith(color: color, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(Transaction t, bool isDark) {
    final isIncome = t.type == 'income';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => TransactionDetailScreen(transaction: t),
          ),
        );
      },
      child: IOSCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceM,
          vertical: AppTheme.spaceM,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.shopping_bag_outlined,
                color: isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.description ?? 'Giao dịch',
                          style: AppTheme.bodyM.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (t.receiptPath != null)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.attach_file,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    t.date,
                    style: AppTheme.caption.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${_formatCurrency(t.amount)}',
              style: AppTheme.bodyM.copyWith(
                color: isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === HELPER METHODS ===
  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }

  Widget _buildBudgetOverview(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ngân sách tháng này', style: AppTheme.headingS),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
        const SizedBox(height: AppTheme.spaceM),
        Consumer2<BudgetProvider, CategoryProvider>(
          builder: (context, budgetProvider, categoryProvider, child) {
            if (budgetProvider.budgets.isEmpty) {
              return IOSCard(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                child: Center(
                  child: Text(
                    'Chưa thiết lập ngân sách',
                    style: AppTheme.bodyS.copyWith(color: Colors.grey),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: budgetProvider.budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgetProvider.budgets[index];
                  final category = categoryProvider.categories.firstWhere(
                    (c) => c.id == budget.categoryId,
                    orElse: () => Category(name: '?', type: 'expense'),
                  );
                  final percent = (budget.spentAmount / budget.limitAmount)
                      .clamp(0.0, 1.0);
                  final isNearLimit = percent >= 0.8;
                  final isOver = budget.spentAmount > budget.limitAmount;

                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: AppTheme.spaceM),
                    child: IOSCard(
                      padding: const EdgeInsets.all(AppTheme.spaceM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                category.icon ?? '📁',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: AppTheme.bodyS.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(percent * 100).toInt()}%',
                                style: AppTheme.caption.copyWith(
                                  color: isOver
                                      ? AppTheme.expenseRed
                                      : (isNearLimit
                                            ? AppTheme.warningOrange
                                            : AppTheme.textSecondaryLight),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatCompactCurrency(budget.limitAmount),
                                style: AppTheme.caption.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 4,
                              backgroundColor: Colors.grey.withValues(
                                alpha: 0.1,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOver
                                    ? AppTheme.expenseRed
                                    : (isNearLimit
                                          ? AppTheme.warningOrange
                                          : AppTheme.primaryPurple),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}

// === ADD TRANSACTION SHEET ===
class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _type = 'expense';
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  // Format ngày tiếng Việt
  String _formatSelectedDate() {
    final day = _selectedDate.day.toString().padLeft(2, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final year = _selectedDate.year;
    return '$day/$month/$year';
  }

  // Hiển thị DatePicker
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
              surface: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkSurface
                  : AppTheme.lightSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Consumer<CategoryProvider>(
        builder: (context, catProvider, child) {
          // Filter categories based on type
          final categories = _type == 'expense'
              ? catProvider.expenseCategories
              : catProvider.incomeCategories;

          // Auto-select first category if none selected
          if (_selectedCategoryId == null && categories.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedCategoryId = categories.first.id;
                });
              }
            });
          }

          return Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: AppTheme.spaceL),
              Text(
                'Thêm Giao Dịch',
                style: AppTheme.headingM.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: AppTheme.spaceL),

              // Type Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBackground
                      : AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Row(
                  children: [
                    _buildToggleBtn('Chi tiêu', 'expense'),
                    _buildToggleBtn('Thu nhập', 'income'),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceL),

              // Amount
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTheme.headingXL.copyWith(color: AppTheme.primaryPurple),
                decoration: const InputDecoration(
                  hintText: '0',
                  border: InputBorder.none,
                  suffixText: 'đ',
                ),
              ),

              const SizedBox(height: AppTheme.spaceM),

              // Description
              TextField(
                controller: _descController,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Mô tả (ví dụ: Ăn trưa)',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.darkBackground
                      : AppTheme.lightBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spaceL),

              // Date Picker Row
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceM,
                    vertical: AppTheme.spaceM,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkBackground
                        : AppTheme.lightBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: AppTheme.primaryPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ngày giao dịch',
                              style: AppTheme.caption.copyWith(
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatSelectedDate(),
                              style: AppTheme.bodyM.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.primaryPurple,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spaceL),

              // Category Selector
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Danh mục',
                  style: AppTheme.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceS),

              // Category Grid
              Expanded(
                child: categories.isEmpty
                    ? Center(
                        child: Text(
                          'Không có danh mục',
                          style: AppTheme.bodyM.copyWith(color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = cat.id == _selectedCategoryId;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = cat.id;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryPurple.withValues(alpha: 0.15)
                                    : (isDark
                                        ? AppTheme.darkBackground
                                        : AppTheme.lightBackground),
                                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                border: isSelected
                                    ? Border.all(
                                        color: AppTheme.primaryPurple,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    cat.icon ?? '📦',
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cat.name,
                                    style: AppTheme.caption.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppTheme.primaryPurple
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: AppTheme.spaceM),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedCategoryId != null ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    ),
                  ),
                  child: const Text(
                    'Lưu',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToggleBtn(String label, String value) {
    final isSelected = _type == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = value;
            _selectedCategoryId = null; // Reset category when type changes
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightSurface)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusM - 2),
            boxShadow: isSelected ? AppTheme.shadowXS : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTheme.bodyM.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _selectedCategoryId == null) return;

    context.read<TransactionProvider>().addTransaction(
      Transaction(
        amount: amount,
        description: _descController.text.isEmpty ? null : _descController.text,
        date: _selectedDate.toIso8601String(),
        type: _type,
        categoryId: _selectedCategoryId!,
      ),
    );
    Navigator.pop(context);
  }
}
