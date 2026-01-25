import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/ios_card.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/transaction.dart' as tx;

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _filterByMonth = false;
  late List<int> _availableYears;

  // Tên tháng tiếng Việt
  static const List<String> _monthNames = [
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _availableYears = List.generate(5, (index) => currentYear - index);
  }

  // Lọc giao dịch theo tháng
  List<tx.Transaction> _filterTransactionsByMonth(
      List<tx.Transaction> transactions) {
    return transactions.where((t) {
      try {
        final date = DateTime.parse(t.date);
        return date.month == _selectedMonth && date.year == _selectedYear;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Lọc giao dịch theo năm
  List<tx.Transaction> _filterTransactionsByYear(
      List<tx.Transaction> transactions) {
    return transactions.where((t) {
      try {
        final date = DateTime.parse(t.date);
        return date.year == _selectedYear;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Lọc giao dịch dựa trên chế độ hiện tại
  List<tx.Transaction> _filterTransactions(List<tx.Transaction> transactions) {
    if (_filterByMonth) {
      return _filterTransactionsByMonth(transactions);
    } else {
      return _filterTransactionsByYear(transactions);
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
        child: Consumer2<TransactionProvider, CategoryProvider>(
          builder: (context, txProvider, catProvider, child) {
            final transactions =
                _filterTransactions(txProvider.transactions);
            final categories = catProvider.categories;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header với tiêu đề động
                      _buildHeader(isDark),
                      const SizedBox(height: AppTheme.spaceM),

                      // Bộ lọc thời gian
                      _buildTimeFilter(isDark),
                      const SizedBox(height: AppTheme.spaceL),

                      // Biểu đồ chi tiêu theo thời gian (Bar Chart)
                      if (_filterByMonth) ...[
                        Text('Chi tiêu theo ngày', style: AppTheme.headingS),
                        const SizedBox(height: AppTheme.spaceM),
                        _buildBarChart(isDark, txProvider.transactions),
                        const SizedBox(height: AppTheme.spaceL),
                      ],

                      // 1. Pie Chart - Chi tiêu theo danh mục
                      Text('Phân bổ chi tiêu', style: AppTheme.headingS),
                      const SizedBox(height: AppTheme.spaceM),
                      _buildPieChart(isDark, transactions, categories),

                      const SizedBox(height: AppTheme.spaceL),

                      // 2. Spending by Category (List with Icons)
                      Text('Chi tiết danh mục', style: AppTheme.headingS),
                      const SizedBox(height: AppTheme.spaceM),
                      _buildCategoryList(isDark, transactions, categories),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget Header với tiêu đề động
  Widget _buildHeader(bool isDark) {
    String title;
    if (_filterByMonth) {
      final monthStr = _selectedMonth.toString().padLeft(2, '0');
      title = 'Báo cáo Tháng $monthStr/$_selectedYear';
    } else {
      title = 'Báo cáo năm $_selectedYear';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTheme.headingL.copyWith(
              color: isDark ? Colors.white : Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Widget bộ lọc thời gian
  Widget _buildTimeFilter(bool isDark) {
    return IOSCard(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle giữa lọc theo Năm và Tháng
          Row(
            children: [
              _buildFilterToggle(
                label: 'Theo năm',
                isSelected: !_filterByMonth,
                onTap: () => setState(() => _filterByMonth = false),
                isDark: isDark,
              ),
              const SizedBox(width: AppTheme.spaceS),
              _buildFilterToggle(
                label: 'Theo tháng',
                isSelected: _filterByMonth,
                onTap: () => setState(() => _filterByMonth = true),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),

          // Row chứa Dropdown năm và Dropdown/Scroll tháng
          Row(
            children: [
              // Dropdown chọn năm
              _buildYearDropdown(isDark),
              if (_filterByMonth) ...[
                const SizedBox(width: AppTheme.spaceM),
                // Dropdown chọn tháng
                Expanded(child: _buildMonthDropdown(isDark)),
              ],
            ],
          ),

          // Horizontal scroll list tháng (hiển thị khi lọc theo tháng)
          if (_filterByMonth) ...[
            const SizedBox(height: AppTheme.spaceM),
            _buildMonthScrollList(isDark),
          ],
        ],
      ),
    );
  }

  // Toggle button cho bộ lọc
  Widget _buildFilterToggle({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceM,
          vertical: AppTheme.spaceS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryPurple
              : (isDark ? AppTheme.darkSurfaceElevated : AppTheme.lightSurfaceSecondary),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryPurple
                : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.bodyS.copyWith(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // Dropdown chọn năm
  Widget _buildYearDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
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
          dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          style: AppTheme.bodyS.copyWith(
            color: AppTheme.primaryPurple,
            fontWeight: FontWeight.w600,
          ),
          items: _availableYears.map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text(
                '$year',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedYear = value;
              });
            }
          },
        ),
      ),
    );
  }

  // Dropdown chọn tháng
  Widget _buildMonthDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.primaryPurple.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMonth,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppTheme.primaryPurple, size: 20),
          isDense: true,
          isExpanded: true,
          dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          style: AppTheme.bodyS.copyWith(
            color: AppTheme.primaryPurple,
            fontWeight: FontWeight.w600,
          ),
          items: List.generate(12, (index) {
            final month = index + 1;
            return DropdownMenuItem<int>(
              value: month,
              child: Text(
                _monthNames[index],
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            );
          }),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMonth = value;
              });
            }
          },
        ),
      ),
    );
  }

  // Horizontal scroll list tháng
  Widget _buildMonthScrollList(bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          final isSelected = month == _selectedMonth;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMonth = month;
              });
            },
            child: AnimatedContainer(
              duration: AppTheme.animFast,
              margin: const EdgeInsets.only(right: AppTheme.spaceS),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceM,
                vertical: AppTheme.spaceS,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryPurple
                    : (isDark
                        ? AppTheme.darkSurfaceElevated
                        : AppTheme.lightSurfaceSecondary),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryPurple
                      : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  'T${month.toString().padLeft(2, '0')}',
                  style: AppTheme.bodyS.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Bar Chart hiển thị chi tiêu theo ngày trong tháng
  Widget _buildBarChart(bool isDark, List<tx.Transaction> allTransactions) {
    // Lọc giao dịch theo tháng đã chọn
    final filteredTransactions = _filterTransactionsByMonth(allTransactions);

    // Tính chi tiêu theo ngày
    final Map<int, double> dailyExpenses = {};
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;

    for (final t in filteredTransactions) {
      if (t.type == 'expense') {
        try {
          final date = DateTime.parse(t.date);
          dailyExpenses[date.day] = (dailyExpenses[date.day] ?? 0) + t.amount;
        } catch (e) {
          // Skip invalid dates
        }
      }
    }

    // Tìm giá trị max để scale
    final maxValue = dailyExpenses.values.isEmpty
        ? 100.0
        : dailyExpenses.values.reduce((a, b) => a > b ? a : b);

    // Tạo các điểm hiển thị (1, 5, 10, 15, 20, 25, 30)
    final displayDays = [1, 5, 10, 15, 20, 25, 30].where((d) => d <= daysInMonth).toList();

    if (dailyExpenses.isEmpty) {
      return IOSCard(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'Chưa có dữ liệu chi tiêu trong tháng này',
              style: AppTheme.bodyM.copyWith(color: AppTheme.textSecondaryLight),
            ),
          ),
        ),
      );
    }

    return IOSCard(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? AppTheme.darkSurfaceElevated
                        : Colors.white,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = displayDays[group.x.toInt()];
                      return BarTooltipItem(
                        'Ngày $day\n${_formatCompact(rod.toY)}',
                        AppTheme.bodyS.copyWith(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < displayDays.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${displayDays[index]}',
                              style: AppTheme.caption.copyWith(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatCompact(value),
                          style: AppTheme.caption.copyWith(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: List.generate(displayDays.length, (index) {
                  final day = displayDays[index];
                  final value = dailyExpenses[day] ?? 0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        color: AppTheme.primaryPurple,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Chi tiêu theo ngày trong ${_monthNames[_selectedMonth - 1]}',
            style: AppTheme.caption.copyWith(
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Danh sách màu cho biểu đồ tròn
  static const List<Color> _chartColors = [
    Color(0xFF7C3AED), // Purple
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Orange
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF8B5CF6), // Violet
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Deep Orange
  ];

  Widget _buildPieChart(
      bool isDark, List<tx.Transaction> transactions, List categories) {
    // Tính chi tiêu theo danh mục
    final categorySpending = <int, double>{};
    for (final t in transactions) {
      if (t.type == 'expense') {
        categorySpending[t.categoryId] =
            (categorySpending[t.categoryId] ?? 0) + t.amount;
      }
    }

    // Lọc và sắp xếp danh mục có chi tiêu
    final sortedCategories = categories
        .where((c) => c.type == 'expense' && categorySpending.containsKey(c.id))
        .toList()
      ..sort((a, b) => (categorySpending[b.id] ?? 0)
          .compareTo(categorySpending[a.id] ?? 0));

    if (sortedCategories.isEmpty) {
      return IOSCard(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'Chưa có dữ liệu chi tiêu',
              style: AppTheme.bodyM.copyWith(color: AppTheme.textSecondaryLight),
            ),
          ),
        ),
      );
    }

    // Tính tổng chi tiêu
    final totalExpense =
        categorySpending.values.fold(0.0, (sum, amount) => sum + amount);

    return IOSCard(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      child: Column(
        children: [
          // Pie Chart - Thu nhỏ lại
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: sortedCategories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final cat = entry.value;
                  final amount = categorySpending[cat.id] ?? 0;
                  final percentage = (amount / totalExpense * 100);
                  final color = _chartColors[index % _chartColors.length];

                  return PieChartSectionData(
                    color: color,
                    value: amount,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 45,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    titlePositionPercentageOffset: 0.6,
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spaceM),

          // Chú thích (Legend) - Compact hơn
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: sortedCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final cat = entry.value;
              final amount = categorySpending[cat.id] ?? 0;
              final color = _chartColors[index % _chartColors.length];
              final formatted = _formatCompact(amount);

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      cat.icon ?? '📦',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      cat.name,
                      style: AppTheme.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatted,
                      style: AppTheme.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppTheme.spaceS),

          // Tổng chi tiêu - Compact
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tổng: ',
                  style: AppTheme.bodyS.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: 'đ',
                    decimalDigits: 0,
                  ).format(totalExpense),
                  style: AppTheme.bodyM.copyWith(
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return '${amount.toStringAsFixed(0)}đ';
  }

  Widget _buildCategoryList(bool isDark, List<tx.Transaction> transactions, List categories) {
    // Calculate spending per category
    final categorySpending = <int, double>{};
    for (final t in transactions) {
      if (t.type == 'expense') {
        categorySpending[t.categoryId] = (categorySpending[t.categoryId] ?? 0) + t.amount;
      }
    }

    // Sort by spending amount (highest first)
    final sortedCategories = categories
        .where((c) => c.type == 'expense' && categorySpending.containsKey(c.id))
        .toList()
      ..sort((a, b) => (categorySpending[b.id] ?? 0).compareTo(categorySpending[a.id] ?? 0));

    if (sortedCategories.isEmpty) {
      return IOSCard(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        child: Center(
          child: Text(
            'Chưa có giao dịch chi tiêu',
            style: AppTheme.bodyM.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: sortedCategories.map((cat) {
        final spent = categorySpending[cat.id] ?? 0;
        final formatted = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: 'đ',
          decimalDigits: 0,
        ).format(spent);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
          child: IOSCard(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            child: Row(
              children: [
                Text(
                  cat.icon ?? '📦',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: Text(
                    cat.name,
                    style: AppTheme.bodyL.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Text(
                  formatted,
                  style: AppTheme.bodyM.copyWith(color: AppTheme.expenseRed),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
