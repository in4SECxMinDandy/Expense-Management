import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ios_card.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';

class CategorySettingsScreen extends StatefulWidget {
  const CategorySettingsScreen({super.key});

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const List<String> _iconOptions = [
    '💰', '💵', '🍲', '🚗', '🛍️', '🏠', '💡', '📱',
    '🎮', '🎬', '✈️', '🏥', '📚', '💼', '🎁', '💳',
    '🛒', '⛽', '🚌', '👕', '💊', '🏋️', '🎵', '☕',
  ];

  static const List<String> _colorOptions = [
    '#4CAF50', '#F44336', '#2196F3', '#9C27B0',
    '#FF9800', '#00BCD4', '#E91E63', '#607D8B',
    '#795548', '#3F51B5', '#009688', '#FFC107',
  ];

  void _showAddCategoryDialog(bool isIncome) {
    final nameController = TextEditingController();
    String selectedIcon = _iconOptions[0];
    String selectedColor = _colorOptions[0];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                Text(
                  'Thêm danh mục ${isIncome ? "Thu nhập" : "Chi tiêu"}',
                  style: AppTheme.headingM.copyWith(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                CupertinoTextField(
                  controller: nameController,
                  placeholder: 'Tên danh mục',
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                Text(
                  'Chọn icon',
                  style: AppTheme.bodyM.copyWith(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceS),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _iconOptions.length,
                    itemBuilder: (context, index) {
                      final icon = _iconOptions[index];
                      final isSelected = icon == selectedIcon;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = icon),
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryPurple.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: AppTheme.primaryPurple, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(icon, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                Text(
                  'Chọn màu',
                  style: AppTheme.bodyM.copyWith(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceS),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorOptions.length,
                    itemBuilder: (context, index) {
                      final colorHex = _colorOptions[index];
                      final color = Color(
                        int.parse(colorHex.replaceFirst('#', '0xFF')),
                      );
                      final isSelected = colorHex == selectedColor;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedColor = colorHex),
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) return;
                      final category = Category(
                        name: nameController.text.trim(),
                        type: isIncome ? 'income' : 'expense',
                        icon: selectedIcon,
                        color: selectedColor,
                      );
                      await context
                          .read<CategoryProvider>()
                          .addCategory(category);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Thêm danh mục'),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    final nameController = TextEditingController(text: category.name);
    String selectedIcon = category.icon ?? _iconOptions[0];
    String selectedColor = category.color ?? _colorOptions[0];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXL),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                Text(
                  'Sửa danh mục',
                  style: AppTheme.headingM.copyWith(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                CupertinoTextField(
                  controller: nameController,
                  placeholder: 'Tên danh mục',
                  padding: const EdgeInsets.all(AppTheme.spaceM),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                Text(
                  'Chọn icon',
                  style: AppTheme.bodyM.copyWith(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceS),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _iconOptions.length,
                    itemBuilder: (context, index) {
                      final icon = _iconOptions[index];
                      final isSelected = icon == selectedIcon;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = icon),
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryPurple.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: AppTheme.primaryPurple, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(icon, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spaceL),
                Text(
                  'Chọn màu',
                  style: AppTheme.bodyM.copyWith(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceS),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorOptions.length,
                    itemBuilder: (context, index) {
                      final colorHex = _colorOptions[index];
                      final color = Color(
                        int.parse(colorHex.replaceFirst('#', '0xFF')),
                      );
                      final isSelected = colorHex == selectedColor;
                      return GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedColor = colorHex),
                        child: Container(
                          width: 44,
                          height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXL),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        color: AppTheme.expenseRed.withValues(alpha: 0.1),
                        onPressed: () async {
                          await context
                              .read<CategoryProvider>()
                              .deleteCategory(category.id!);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text(
                          'Xóa',
                          style: TextStyle(color: AppTheme.expenseRed),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceM),
                    Expanded(
                      flex: 2,
                      child: CupertinoButton.filled(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) return;
                          final updated = category.copyWith(
                            name: nameController.text.trim(),
                            icon: selectedIcon,
                            color: selectedColor,
                          );
                          await context
                              .read<CategoryProvider>()
                              .updateCategory(updated);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Lưu'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceM),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Quản lý Danh mục'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chi tiêu'),
            Tab(text: 'Thu nhập'),
          ],
        ),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(provider.expenseCategories, false, isDark),
              _buildCategoryList(provider.incomeCategories, true, isDark),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCategoryDialog(_tabController.index == 1);
        },
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryList(
      List<Category> categories, bool isIncome, bool isDark) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIncome ? Icons.trending_up : Icons.trending_down,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              'Chưa có danh mục ${isIncome ? "thu nhập" : "chi tiêu"}',
              style: AppTheme.bodyL.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              'Nhấn + để thêm danh mục mới',
              style: AppTheme.bodyS.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final color = category.color != null
            ? Color(int.parse(category.color!.replaceFirst('#', '0xFF')))
            : (isIncome ? AppTheme.incomeGreen : AppTheme.expenseRed);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
          child: IOSCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    category.icon ?? '📁',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              title: Text(
                category.name,
                style: AppTheme.bodyL.copyWith(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                isIncome ? 'Thu nhập' : 'Chi tiêu',
                style: AppTheme.bodyS.copyWith(color: color),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
              onTap: () => _showEditCategoryDialog(category),
            ),
          ),
        );
      },
    );
  }
}
