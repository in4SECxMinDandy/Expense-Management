import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/ios_card.dart';
import '../services/auth_service.dart';
import 'settings/budget_settings_screen.dart';
import 'settings/recurring_settings_screen.dart';
import 'settings/savings_goals_screen.dart';
import 'settings/wallet_settings_screen.dart';
import 'settings/category_settings_screen.dart';
import 'settings/ai_insights_screen.dart';
import 'settings/profile_edit_screen.dart';
import '../services/csv_service.dart';
import '../services/pdf_service.dart';
import '../services/sync_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('Cài Đặt', style: AppTheme.headingXL),
                  const SizedBox(height: AppTheme.spaceL),

                  // Profile Section
                  _buildSectionHeader('Tài khoản'),
                  _buildProfileCard(isDark),
                  const SizedBox(height: AppTheme.spaceS),
                  IOSCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.wallet,
                          color: Colors.teal,
                          title: 'Quản lý Ví',
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          isDark: isDark,
                          onTap: () => Navigator.push(context,
                              CupertinoPageRoute(builder: (_) => const WalletSettingsScreen())),
                        ),
                        _buildDivider(isDark),
                        _buildSettingTile(
                          icon: Icons.account_balance_wallet,
                          color: Colors.orange,
                          title: 'Quản lý Ngân sách',
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          isDark: isDark,
                          onTap: () => Navigator.push(context,
                              CupertinoPageRoute(builder: (_) => const BudgetSettingsScreen())),
                        ),
                        _buildDivider(isDark),
                        _buildSettingTile(
                          icon: Icons.savings,
                          color: Colors.green,
                          title: 'Mục tiêu Tiết kiệm',
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          isDark: isDark,
                          onTap: () => Navigator.push(context,
                              CupertinoPageRoute(builder: (_) => const SavingsGoalsScreen())),
                        ),
                        _buildDivider(isDark),
                        _buildSettingTile(
                          icon: Icons.repeat,
                          color: Colors.blue,
                          title: 'Giao dịch định kỳ',
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          isDark: isDark,
                          onTap: () => Navigator.push(context,
                              CupertinoPageRoute(builder: (_) => const RecurringSettingsScreen())),
                        ),
                        _buildDivider(isDark),
                        _buildSettingTile(
                          icon: Icons.category,
                          color: Colors.indigo,
                          title: 'Quản lý Danh mục',
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          isDark: isDark,
                          onTap: () => Navigator.push(context,
                              CupertinoPageRoute(builder: (_) => const CategorySettingsScreen())),
                        ),
                        _buildDivider(isDark),
                        _buildSettingTile(
                          icon: Icons.auto_awesome,
                          color: Colors.deepPurple,
                          title: 'AI Phân tích',
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          isDark: isDark,
                          onTap: () => Navigator.push(context,
                              CupertinoPageRoute(builder: (_) => const AIInsightsScreen())),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceL),

                  // General Section
                  _buildSectionHeader('Chung'),
                  IOSCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.dark_mode,
                          color: Colors.purple,
                          title: 'Giao diện tối',
                          trailing: CupertinoSwitch(
                            value: themeProvider.isDarkMode,
                            activeTrackColor: AppTheme.primaryPurple,
                            onChanged: (val) => themeProvider.toggleTheme(val),
                          ),
                          isDark: isDark,
                        ),
                        _buildDivider(isDark),
                        _buildSettingTile(
                          icon: Icons.notifications,
                          color: Colors.red,
                          title: 'Thông báo',
                          trailing: CupertinoSwitch(
                            value: _notifications,
                            activeTrackColor: AppTheme.primaryPurple,
                            onChanged: (val) => setState(() => _notifications = val),
                          ),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceL),

                  // Data Section
                  _buildSectionHeader('Dữ liệu'),
                  IOSCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.backup,
                          color: Colors.blue,
                          title: 'Sao lưu dữ liệu',
                          trailing: _isExporting
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.chevron_right, color: Colors.grey),
                          isDark: isDark,
                          onTap: _isExporting ? null : _handleBackup,
                        ),
                        _buildDivider(isDark),
                        _buildSettingTile(
                          icon: Icons.file_download,
                          color: Colors.green,
                          title: 'Xuất CSV',
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          isDark: isDark,
                          onTap: _handleExportCsv,
                        ),
                        _buildDivider(isDark),
                        _buildSettingTile(
                          icon: Icons.picture_as_pdf,
                          color: Colors.red,
                          title: 'Xuất PDF',
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          isDark: isDark,
                          onTap: kIsWeb ? null : _handleExportPdf,
                        ),
                        _buildDivider(isDark),
                        _buildSettingTile(
                          icon: Icons.file_upload,
                          color: Colors.orange,
                          title: 'Nhập CSV',
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          isDark: isDark,
                          onTap: _handleImportCsv,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceL),

                  // Logout Section
                  IOSCard(
                    padding: EdgeInsets.zero,
                    child: _buildSettingTile(
                      icon: Icons.logout,
                      color: AppTheme.expenseRed,
                      title: 'Đăng xuất',
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      isDark: isDark,
                      onTap: _handleLogout,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spaceXXL),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === ACTION HANDLERS ===

  Future<void> _handleBackup() async {
    setState(() => _isExporting = true);
    try {
      final stats = await SyncService.getDatabaseStats();
      if (!mounted) return;

      final totalRecords = stats.values.fold(0, (sum, v) => sum + v);
      _showSnackBar(
        'Đã sao lưu $totalRecords bản ghi thành công',
        isSuccess: true,
      );
    } catch (e) {
      _showSnackBar('Lỗi sao lưu: $e', isSuccess: false);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleExportCsv() async {
    try {
      final txProvider = context.read<TransactionProvider>();
      final catProvider = context.read<CategoryProvider>();

      final success = await CsvService.exportTransactions(
        transactions: txProvider.transactions,
        categories: catProvider.categories,
      );

      if (!mounted) return;
      _showSnackBar(
        success ? 'Xuất CSV thành công' : 'Lỗi xuất CSV',
        isSuccess: success,
      );
    } catch (e) {
      _showSnackBar('Lỗi xuất CSV: $e', isSuccess: false);
    }
  }

  Future<void> _handleExportPdf() async {
    try {
      final txProvider = context.read<TransactionProvider>();
      final catProvider = context.read<CategoryProvider>();

      await PdfService.exportTransactionsPdf(
        transactions: txProvider.transactions,
        categories: catProvider.categories,
      );

      if (!mounted) return;
      _showSnackBar('Xuất PDF thành công', isSuccess: true);
    } catch (e) {
      _showSnackBar('Lỗi xuất PDF: $e', isSuccess: false);
    }
  }

  Future<void> _handleImportCsv() async {
    try {
      final catProvider = context.read<CategoryProvider>();
      final txProvider = context.read<TransactionProvider>();

      final imported = await CsvService.importTransactions(
        categories: catProvider.categories,
      );

      if (!mounted) return;

      if (imported.isNotEmpty) {
        int successCount = 0;
        for (final t in imported) {
          final success = await txProvider.addTransaction(t);
          if (success) successCount++;
        }

        if (mounted) {
          _showSnackBar(
            'Đã nhập $successCount/${imported.length} giao dịch',
            isSuccess: true,
          );
        }
      } else {
        _showSnackBar('Không có dữ liệu để nhập', isSuccess: false);
      }
    } catch (e) {
      _showSnackBar('Lỗi nhập CSV: $e', isSuccess: false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Text('Đăng xuất', style: AppTheme.headingS),
        content: Text('Bạn có chắc muốn đăng xuất không?', style: AppTheme.bodyM),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseRed),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppTheme.incomeGreen : AppTheme.expenseRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // === UI BUILDERS ===

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const ProfileEditScreen()),
        );
        if (result == true && mounted) setState(() {});
      },
      child: IOSCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryPurple.withValues(alpha: 0.1),
              child: Text(
                (AuthService.currentUsername ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryPurple,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AuthService.currentUsername ?? 'Người dùng',
                    style: AppTheme.headingM.copyWith(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    AuthService.currentEmail ?? 'Chỉnh sửa thông tin',
                    style: const TextStyle(
                      color: AppTheme.primaryPurple,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color color,
    required String title,
    required Widget trailing,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: Text(
                title,
                style: AppTheme.bodyL.copyWith(
                  color: onTap == null
                      ? Colors.grey
                      : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 60,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }
}
