import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ios_card.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all';
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _filters = [
    {'key': 'all', 'label': 'Tất cả'},
    {'key': 'income', 'label': 'Thu nhập'},
    {'key': 'expense', 'label': 'Chi tiêu'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Giao dịch', style: AppTheme.headingS),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppTheme.getSurface(isDark),
            padding: const EdgeInsets.all(AppTheme.spaceM),
            child: Column(
              children: [
                // Search input
                TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                  style: AppTheme.bodyM.copyWith(
                    color: AppTheme.getTextPrimary(isDark),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm giao dịch...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppTheme.getTextSecondary(isDark),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: AppTheme.getTextSecondary(isDark),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : Icon(
                            Icons.mic_outlined,
                            color: AppTheme.getTextSecondary(isDark),
                          ),
                  ),
                ),

                const SizedBox(height: AppTheme.spaceM),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter['key'];
                      return Padding(
                        padding: const EdgeInsets.only(right: AppTheme.spaceS),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedFilter = filter['key']);
                          },
                          child: AnimatedContainer(
                            duration: AppTheme.animNormal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spaceM,
                              vertical: AppTheme.spaceS,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryPurple
                                  : (isDark
                                        ? AppTheme.darkDivider
                                        : AppTheme.lightDivider),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusXXL,
                              ),
                            ),
                            child: Text(
                              filter['label'],
                              style: AppTheme.bodyS.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.getTextSecondary(isDark),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Transactions list
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredTransactions = provider.transactions.where((t) {
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      (t.description?.toLowerCase().contains(_searchQuery) ??
                          false);
                  final matchesFilter =
                      _selectedFilter == 'all' || t.type == _selectedFilter;
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredTransactions.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                      child: _buildTransactionItem(
                        transaction,
                        provider,
                        isDark,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.getTextSecondary(isDark),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            'Không tìm thấy giao dịch',
            style: AppTheme.bodyL.copyWith(
              color: AppTheme.getTextSecondary(isDark),
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
            style: AppTheme.bodyS.copyWith(
              color: AppTheme.getTextSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    Transaction transaction,
    TransactionProvider provider,
    bool isDark,
  ) {
    final isIncome = transaction.type == 'income';

    return Dismissible(
      key: Key('transaction_${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
        padding: const EdgeInsets.only(right: AppTheme.spaceL),
        decoration: BoxDecoration(
          color: AppTheme.expenseRed,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        return await _showDeleteConfirmation(context);
      },
      onDismissed: (direction) {
        final deletedTransaction = transaction;
        provider.deleteTransaction(transaction.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xóa giao dịch'),
            backgroundColor: AppTheme.getTextSecondary(isDark),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Hoàn tác',
              textColor: AppTheme.primaryPurple,
              onPressed: () async {
                await provider.addTransaction(
                  Transaction(
                    categoryId: deletedTransaction.categoryId,
                    amount: deletedTransaction.amount,
                    date: deletedTransaction.date,
                    description: deletedTransaction.description,
                    type: deletedTransaction.type,
                  ),
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã khôi phục giao dịch'),
                    backgroundColor: AppTheme.incomeGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: IOSCard(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed,
                size: 24,
              ),
            ),

            const SizedBox(width: AppTheme.spaceM),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? 'Không có mô tả',
                    style: AppTheme.bodyM.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.getTextPrimary(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spaceXS),
                  Text(
                    isIncome ? 'Thu nhập' : 'Chi tiêu',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.getTextSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              '${isIncome ? '+' : '-'}${_formatCurrency(transaction.amount)}',
              style: AppTheme.bodyM.copyWith(
                fontWeight: FontWeight.w600,
                color: isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            title: Text('Xác nhận xóa', style: AppTheme.headingS),
            content: Text(
              'Bạn có chắc muốn xóa giao dịch này?',
              style: AppTheme.bodyM,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.expenseRed,
                ),
                child: const Text('Xóa', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M ₫';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K ₫';
    return '${amount.toStringAsFixed(0)} ₫';
  }
}
