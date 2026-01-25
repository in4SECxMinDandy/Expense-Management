import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ios_card.dart';
import '../../../models/savings_goal.dart';
import '../../../providers/savings_goal_provider.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavingsGoalProvider>().loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Mục tiêu Tiết kiệm'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Consumer<SavingsGoalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '🎯',
                    style: TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có mục tiêu tiết kiệm',
                    style: AppTheme.bodyL.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo mục tiêu đầu tiên để bắt đầu!',
                    style: AppTheme.bodyS.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            itemCount: provider.goals.length,
            itemBuilder: (context, index) {
              final goal = provider.goals[index];
              return _buildGoalCard(goal, isDark, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGoalCard(SavingsGoal goal, bool isDark, SavingsGoalProvider provider) {
    final progressPercent = (goal.progress * 100).toInt();
    final isCompleted = goal.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: IOSCard(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  goal.icon ?? '🎯',
                  style: const TextStyle(fontSize: 32),
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
                              goal.name,
                              style: AppTheme.bodyL.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.incomeGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Hoàn thành',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.incomeGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatCurrency(goal.currentAmount)} / ${_formatCurrency(goal.targetAmount)}',
                        style: AppTheme.bodyS.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'contribute') {
                      _showContributeDialog(context, goal);
                    } else if (value == 'delete') {
                      _confirmDelete(context, goal, provider);
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isCompleted)
                      const PopupMenuItem(
                        value: 'contribute',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Thêm tiền'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceM),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted
                            ? AppTheme.incomeGreen
                            : AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Text(
                  '$progressPercent%',
                  style: AppTheme.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppTheme.incomeGreen
                        : AppTheme.primaryPurple,
                  ),
                ),
              ],
            ),
            if (goal.daysRemaining != null && !isCompleted) ...[
              const SizedBox(height: AppTheme.spaceS),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: goal.daysRemaining! < 7
                        ? AppTheme.warningOrange
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    goal.daysRemaining == 0
                        ? 'Hạn hôm nay!'
                        : 'Còn ${goal.daysRemaining} ngày',
                    style: AppTheme.caption.copyWith(
                      color: goal.daysRemaining! < 7
                          ? AppTheme.warningOrange
                          : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Còn thiếu ${_formatCurrency(goal.remaining)}',
                    style: AppTheme.caption.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? selectedDate;
    String selectedIcon = '🎯';

    final icons = ['🎯', '🏠', '🚗', '✈️', '📱', '💍', '🎓', '💰', '🏝️', '💻'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusXL),
                ),
              ),
              padding: EdgeInsets.only(
                left: AppTheme.spaceL,
                right: AppTheme.spaceL,
                top: AppTheme.spaceL,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceL,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceL),
                    Center(
                      child: Text('Tạo Mục tiêu mới', style: AppTheme.headingM),
                    ),
                    const SizedBox(height: AppTheme.spaceL),

                    // Icon selector
                    Text('Chọn biểu tượng', style: AppTheme.bodyM),
                    const SizedBox(height: AppTheme.spaceS),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: icons.map((icon) {
                        final isSelected = icon == selectedIcon;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedIcon = icon),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryPurple.withValues(alpha: 0.2)
                                  : (isDark
                                      ? AppTheme.darkBackground
                                      : AppTheme.lightBackground),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: AppTheme.primaryPurple, width: 2)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(icon, style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.spaceL),

                    // Name
                    Text('Tên mục tiêu', style: AppTheme.bodyM),
                    const SizedBox(height: AppTheme.spaceS),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Mua iPhone mới',
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

                    // Amount
                    Text('Số tiền mục tiêu', style: AppTheme.bodyM),
                    const SizedBox(height: AppTheme.spaceS),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '10,000,000',
                        suffixText: 'đ',
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

                    // Date picker
                    Text('Ngày hoàn thành (tùy chọn)', style: AppTheme.bodyM),
                    const SizedBox(height: AppTheme.spaceS),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (date != null) {
                          setModalState(() => selectedDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkBackground
                              : AppTheme.lightBackground,
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedDate != null
                                  ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                                  : 'Chọn ngày',
                              style: AppTheme.bodyM.copyWith(
                                color: selectedDate != null
                                    ? (isDark ? Colors.white : Colors.black)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXL),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final amount = double.tryParse(
                            amountController.text.replaceAll(',', ''),
                          );
                          if (nameController.text.isEmpty || amount == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng nhập đầy đủ thông tin'),
                              ),
                            );
                            return;
                          }

                          context.read<SavingsGoalProvider>().addGoal(
                            SavingsGoal(
                              name: nameController.text,
                              targetAmount: amount,
                              icon: selectedIcon,
                              targetDate: selectedDate?.toIso8601String(),
                            ),
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          ),
                        ),
                        child: const Text(
                          'Tạo mục tiêu',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showContributeDialog(BuildContext context, SavingsGoal goal) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          title: const Text('Thêm tiền vào mục tiêu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                goal.name,
                style: AppTheme.bodyL.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Còn thiếu ${_formatCurrency(goal.remaining)}',
                style: AppTheme.bodyS.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền',
                  suffixText: 'đ',
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.darkBackground
                      : AppTheme.lightBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(
                  amountController.text.replaceAll(',', ''),
                );
                if (amount != null && amount > 0) {
                  context
                      .read<SavingsGoalProvider>()
                      .addContribution(goal.id!, amount);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
              ),
              child: const Text('Thêm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    SavingsGoal goal,
    SavingsGoalProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa mục tiêu?'),
        content: Text('Bạn có chắc muốn xóa "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteGoal(goal.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount);
  }
}
