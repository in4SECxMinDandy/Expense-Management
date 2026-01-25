import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ios_card.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/budget.dart';
import '../../models/category.dart';

class BudgetSettingsScreen extends StatefulWidget {
  const BudgetSettingsScreen({super.key});

  @override
  State<BudgetSettingsScreen> createState() => _BudgetSettingsScreenState();
}

class _BudgetSettingsScreenState extends State<BudgetSettingsScreen> {
  final String _currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      context.read<BudgetProvider>().loadBudgets(_currentMonth);
    });
  }

  void _showAddBudgetDialog([Budget? budget]) {
    final categories = context.read<CategoryProvider>().expenseCategories;
    int? selectedCategoryId =
        budget?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : null);
    final amountController = TextEditingController(
      text: budget?.limitAmount.toString() ?? '',
    );

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => CupertinoActionSheet(
          title: Text(budget == null ? 'Thêm Ngân Sách' : 'Sửa Ngân Sách'),
          message: Column(
            children: [
              const SizedBox(height: AppTheme.spaceM),
              // Category Picker (simplified)
              if (budget == null)
                SizedBox(
                  height: 100,
                  child: CupertinoPicker(
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      setModalState(
                        () => selectedCategoryId = categories[index].id,
                      );
                    },
                    children: categories.map((c) => Text(c.name)).toList(),
                  ),
                )
              else
                Text(
                  'Danh mục: ${categories.firstWhere((c) => c.id == budget.categoryId).name}',
                ),

              const SizedBox(height: AppTheme.spaceM),
              CupertinoTextField(
                controller: amountController,
                placeholder: 'Số tiền giới hạn',
                keyboardType: TextInputType.number,
                padding: const EdgeInsets.all(AppTheme.spaceM),
                decoration: BoxDecoration(
                  color: CupertinoColors.extraLightBackgroundGray,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
            ],
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                if (selectedCategoryId != null &&
                    amountController.text.isNotEmpty) {
                  final limit = double.tryParse(amountController.text) ?? 0.0;
                  context.read<BudgetProvider>().addOrUpdateBudget(
                    Budget(
                      id: budget?.id,
                      categoryId: selectedCategoryId,
                      month: _currentMonth,
                      limitAmount: limit,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgetProvider = context.watch<BudgetProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Quản lý Ngân sách'),
        actions: [
          CupertinoButton(
            child: const Icon(CupertinoIcons.add),
            onPressed: () => _showAddBudgetDialog(),
          ),
        ],
      ),
      body: budgetProvider.isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final budget = budgetProvider.budgets[index];
                      final category = categoryProvider.categories.firstWhere(
                        (c) => c.id == budget.categoryId,
                        orElse: () =>
                            Category(name: 'Unknown', type: 'expense'),
                      );
                      final percent = (budget.spentAmount / budget.limitAmount)
                          .clamp(0.0, 1.0);
                      final isOver = budget.spentAmount > budget.limitAmount;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                        child: IOSCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(
                                          AppTheme.spaceS,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(category.icon ?? '📁'),
                                      ),
                                      const SizedBox(width: AppTheme.spaceM),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category.name,
                                            style: AppTheme.headingS.copyWith(
                                              color: AppTheme.getTextPrimary(
                                                isDark,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Tháng $_currentMonth',
                                            style: AppTheme.bodyS.copyWith(
                                              color: AppTheme.getTextSecondary(
                                                isDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: const Icon(
                                      CupertinoIcons.ellipsis_vertical,
                                    ),
                                    onPressed: () {
                                      showCupertinoModalPopup(
                                        context: context,
                                        builder: (context) =>
                                            CupertinoActionSheet(
                                              actions: [
                                                CupertinoActionSheetAction(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _showAddBudgetDialog(
                                                      budget,
                                                    );
                                                  },
                                                  child: const Text('Sửa'),
                                                ),
                                                CupertinoActionSheetAction(
                                                  isDestructiveAction: true,
                                                  onPressed: () {
                                                    context
                                                        .read<BudgetProvider>()
                                                        .deleteBudget(
                                                          budget.id!,
                                                          _currentMonth,
                                                        );
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Xóa'),
                                                ),
                                              ],
                                              cancelButton:
                                                  CupertinoActionSheetAction(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Hủy'),
                                                  ),
                                            ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${NumberFormat.compact().format(budget.spentAmount)} / ${NumberFormat.compact().format(budget.limitAmount)}',
                                    style: AppTheme.bodyM.copyWith(
                                      color: isOver
                                          ? AppTheme.expenseRed
                                          : AppTheme.getTextPrimary(isDark),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${(percent * 100).toInt()}%',
                                    style: AppTheme.bodyS.copyWith(
                                      color: AppTheme.getTextSecondary(isDark),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spaceS),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isOver
                                        ? AppTheme.expenseRed
                                        : AppTheme.primaryPurple,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: budgetProvider.budgets.length),
                  ),
                ),
              ],
            ),
    );
  }
}
