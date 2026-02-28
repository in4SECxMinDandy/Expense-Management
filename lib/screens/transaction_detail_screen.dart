import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/ios_card.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TextEditingController _notesController;
  late TextEditingController _amountController;
  late TextEditingController _descController;
  String? _receiptPath;
  late String _type;
  late int _categoryId;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.transaction.notes);
    _amountController = TextEditingController(
        text: widget.transaction.amount.toStringAsFixed(0));
    _descController =
        TextEditingController(text: widget.transaction.description ?? '');
    _receiptPath = widget.transaction.receiptPath;
    _type = widget.transaction.type;
    _categoryId = widget.transaction.categoryId;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _receiptPath = pickedFile.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryProvider = context.watch<CategoryProvider>();
    final category = categoryProvider.categories.firstWhere(
      (c) => c.id == widget.transaction.categoryId,
      orElse: () => Category(name: 'Unknown', type: widget.transaction.type),
    );

    return Scaffold(
      backgroundColor: AppTheme.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Chi tiết giao dịch'),
        actions: [
          CupertinoButton(
            child: const Text('Lưu'),
            onPressed: () async {
              final amount = double.tryParse(_amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
                );
                return;
              }

              final updatedTransaction = widget.transaction.copyWith(
                amount: amount,
                description: _descController.text.isNotEmpty
                    ? _descController.text
                    : null,
                notes: _notesController.text.isNotEmpty
                    ? _notesController.text
                    : null,
                receiptPath: _receiptPath,
                type: _type,
                categoryId: _categoryId,
              );
              await context
                  .read<TransactionProvider>()
                  .updateTransaction(updatedTransaction);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã lưu thay đổi')),
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          children: [
            // Amount Card - Editable
            IOSCard(
              child: Column(
                children: [
                  Text(
                    category.icon ?? '📁',
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: AppTheme.spaceM),

                  // Editable Description
                  CupertinoTextField(
                    controller: _descController,
                    placeholder: 'Mô tả giao dịch',
                    textAlign: TextAlign.center,
                    padding: const EdgeInsets.all(AppTheme.spaceS),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkBackground
                          : AppTheme.lightBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    style: AppTheme.headingS.copyWith(
                      color: AppTheme.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceM),

                  // Editable Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _type == 'income' ? '+' : '-',
                        style: AppTheme.headingL.copyWith(
                          color: _type == 'income'
                              ? AppTheme.incomeGreen
                              : AppTheme.expenseRed,
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: CupertinoTextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          padding: const EdgeInsets.all(AppTheme.spaceS),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkBackground
                                : AppTheme.lightBackground,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusS),
                          ),
                          style: AppTheme.headingL.copyWith(
                            color: _type == 'income'
                                ? AppTheme.incomeGreen
                                : AppTheme.expenseRed,
                          ),
                          suffix: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              'đ',
                              style: AppTheme.headingM.copyWith(
                                color: _type == 'income'
                                    ? AppTheme.incomeGreen
                                    : AppTheme.expenseRed,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.calendar,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(DateTime.parse(widget.transaction.date)),
                        style: AppTheme.bodyS.copyWith(
                          color: AppTheme.getTextSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceL),

            // Type Toggle
            _buildSectionHeader('Loại giao dịch'),
            IOSCard(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = 'expense'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'expense'
                              ? AppTheme.expenseRed.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              color: _type == 'expense'
                                  ? AppTheme.expenseRed
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Chi tiêu',
                              style: AppTheme.bodyM.copyWith(
                                color: _type == 'expense'
                                    ? AppTheme.expenseRed
                                    : Colors.grey,
                                fontWeight: _type == 'expense'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = 'income'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == 'income'
                              ? AppTheme.incomeGreen.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              color: _type == 'income'
                                  ? AppTheme.incomeGreen
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Thu nhập',
                              style: AppTheme.bodyM.copyWith(
                                color: _type == 'income'
                                    ? AppTheme.incomeGreen
                                    : Colors.grey,
                                fontWeight: _type == 'income'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceL),

            // Category Selector
            _buildSectionHeader('Danh mục'),
            IOSCard(
              child: SizedBox(
                height: 100,
                child: Consumer<CategoryProvider>(
                  builder: (context, catProvider, _) {
                    final categories = _type == 'expense'
                        ? catProvider.expenseCategories
                        : catProvider.incomeCategories;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = cat.id == _categoryId;
                        return GestureDetector(
                          onTap: () => setState(() => _categoryId = cat.id!),
                          child: Container(
                            width: 70,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryPurple
                                      .withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                              border: isSelected
                                  ? Border.all(
                                      color: AppTheme.primaryPurple, width: 2)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cat.icon ?? '📦',
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat.name,
                                  style: AppTheme.caption.copyWith(
                                    color: isSelected
                                        ? AppTheme.primaryPurple
                                        : Colors.grey,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
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
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceL),

            // Notes Section
            _buildSectionHeader('Ghi chú'),
            IOSCard(
              child: CupertinoTextField(
                controller: _notesController,
                placeholder: 'Thêm ghi chú tại đây...',
                maxLines: 4,
                padding: const EdgeInsets.all(AppTheme.spaceM),
                decoration: const BoxDecoration(color: Colors.transparent),
                style: TextStyle(color: AppTheme.getTextPrimary(isDark)),
              ),
            ),
            const SizedBox(height: AppTheme.spaceL),

            // Receipt Section
            _buildSectionHeader('Ảnh hóa đơn'),
            IOSCard(
              child: Column(
                children: [
                  if (_receiptPath != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          child: kIsWeb
                              ? Image.network(
                                  _receiptPath!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                )
                              : Image.asset(
                                  _receiptPath!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildFileImage(_receiptPath!),
                                ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () =>
                                  setState(() => _receiptPath = null),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    CupertinoButton(
                      onPressed: _pickImage,
                      child: Column(
                        children: [
                          const Icon(
                            CupertinoIcons.camera,
                            size: 40,
                            color: AppTheme.primaryPurple,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Đính kèm hóa đơn',
                            style: AppTheme.bodyM.copyWith(
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spaceXXL),

            // Delete Button
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: AppTheme.expenseRed.withValues(alpha: 0.1),
                onPressed: () => _showDeleteConfirmation(context),
                child: const Text(
                  'Xóa giao dịch',
                  style: TextStyle(color: AppTheme.expenseRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
            'Bạn có chắc chắn muốn xóa giao dịch này? Hành động này không thể hoàn tác.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              context.read<TransactionProvider>().deleteTransaction(
                    widget.transaction.id!,
                  );
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa giao dịch')),
              );
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  /// Build file image widget (platform-safe)
  Widget _buildFileImage(String path) {
    if (kIsWeb) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image, size: 60, color: Colors.grey),
        ),
      );
    }
    // Non-web: use FileImage via Image.file
    return _FileImageWidget(path: path);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

/// Widget hiển thị ảnh từ file path (chỉ dùng trên non-web)
class _FileImageWidget extends StatelessWidget {
  final String path;
  const _FileImageWidget({required this.path});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 60, color: Colors.grey)),
      );
    }
    // Sử dụng Image.network như fallback an toàn
    // Trên mobile/desktop, path là local file path
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 60, color: Colors.grey),
            SizedBox(height: 8),
            Text('Ảnh hóa đơn', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
