import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ios_card.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/recurring_transaction.dart';
import '../../models/category.dart';

class RecurringSettingsScreen extends StatefulWidget {
  const RecurringSettingsScreen({super.key});

  @override
  State<RecurringSettingsScreen> createState() =>
      _RecurringSettingsScreenState();
}

class _RecurringSettingsScreenState extends State<RecurringSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecurringProvider>().loadRecurring();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  void _showAddRecurringDialog() {
    final categories = context.read<CategoryProvider>().categories;
    int? selectedCategoryId = categories.isNotEmpty
        ? categories.first.id
        : null;
    final amountController = TextEditingController();
    final descController = TextEditingController();
    RepeatInterval selectedInterval = RepeatInterval.monthly;
    String type = 'expense';

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => CupertinoActionSheet(
          title: const Text('Thêm Giao Dịch Định Kỳ'),
          message: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: AppTheme.spaceM),
                CupertinoSegmentedControl<String>(
                  groupValue: type,
                  onValueChanged: (val) => setModalState(() => type = val),
                  children: const {
                    'expense': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Chi'),
                    ),
                    'income': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Thu'),
                    ),
                  },
                ),
                const SizedBox(height: AppTheme.spaceM),
                CupertinoTextField(
                  controller: amountController,
                  placeholder: 'Số tiền',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  decoration: BoxDecoration(
                    color: CupertinoColors.extraLightBackgroundGray,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                CupertinoTextField(
                  controller: descController,
                  placeholder: 'Mô tả',
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  decoration: BoxDecoration(
                    color: CupertinoColors.extraLightBackgroundGray,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                const Text('Tần suất:'),
                SizedBox(
                  height: 100,
                  child: CupertinoPicker(
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      setModalState(
                        () => selectedInterval = RepeatInterval.values[index],
                      );
                    },
                    children: RepeatInterval.values
                        .map((v) => Text(v.name.toUpperCase()))
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                const Text('Danh mục:'),
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
                ),
              ],
            ),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                if (selectedCategoryId != null &&
                    amountController.text.isNotEmpty) {
                  final amount = double.tryParse(amountController.text) ?? 0.0;
                  context.read<RecurringProvider>().addRecurring(
                    RecurringTransaction(
                      amount: amount,
                      categoryId: selectedCategoryId!,
                      description: descController.text,
                      type: type,
                      interval: selectedInterval,
                      nextRunDate: DateTime.now().add(
                        const Duration(minutes: 1),
                      ), // For testing
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
    final recurringProvider = context.watch<RecurringProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Giao dịch định kỳ'),
        actions: [
          CupertinoButton(
            child: const Icon(CupertinoIcons.add),
            onPressed: () => _showAddRecurringDialog(),
          ),
        ],
      ),
      body: recurringProvider.isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              itemCount: recurringProvider.recurringTransactions.length,
              itemBuilder: (context, index) {
                final r = recurringProvider.recurringTransactions[index];
                final category = categoryProvider.categories.firstWhere(
                  (c) => c.id == r.categoryId,
                  orElse: () => Category(name: '?', type: 'expense'),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                  child: IOSCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceS),
                          decoration: BoxDecoration(
                            color:
                                (r.type == 'income'
                                        ? AppTheme.incomeGreen
                                        : AppTheme.expenseRed)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(category.icon ?? '📋'),
                        ),
                        const SizedBox(width: AppTheme.spaceM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.description,
                                style: AppTheme.headingS.copyWith(
                                  color: AppTheme.getTextPrimary(isDark),
                                ),
                              ),
                              Text(
                                '${r.interval.name.toUpperCase()} • Tới: ${DateFormat('dd/MM/yyyy').format(r.nextRunDate)}',
                                style: AppTheme.bodyS.copyWith(
                                  color: AppTheme.getTextSecondary(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${r.type == 'income' ? '+' : '-'}${NumberFormat.compact().format(r.amount)}',
                          style: AppTheme.bodyM.copyWith(
                            color: r.type == 'income'
                                ? AppTheme.incomeGreen
                                : AppTheme.expenseRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
