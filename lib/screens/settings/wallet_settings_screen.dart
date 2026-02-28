import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ios_card.dart';
import '../../models/wallet.dart';
import '../../providers/wallet_provider.dart';

class WalletSettingsScreen extends StatefulWidget {
  const WalletSettingsScreen({super.key});

  @override
  State<WalletSettingsScreen> createState() => _WalletSettingsScreenState();
}

class _WalletSettingsScreenState extends State<WalletSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().loadWallets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Quản lý Ví'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Total Balance Card
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                child: IOSCard(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  child: Column(
                    children: [
                      Text(
                        'Tổng số dư',
                        style: AppTheme.bodyM.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatCurrency(provider.totalBalance),
                        style: AppTheme.headingXL.copyWith(
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.wallets.length} ví',
                        style: AppTheme.caption.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              // Wallets List
              Expanded(
                child: provider.wallets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('💼', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có ví nào',
                              style: AppTheme.bodyL.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tạo ví đầu tiên để quản lý tiền',
                              style: AppTheme.bodyS.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
                        itemCount: provider.wallets.length,
                        itemBuilder: (context, index) {
                          final wallet = provider.wallets[index];
                          return _buildWalletCard(wallet, isDark, provider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWalletDialog(context),
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWalletCard(Wallet wallet, bool isDark, WalletProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: IOSCard(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getWalletColor(wallet.type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                wallet.icon ?? _getWalletIcon(wallet.type),
                style: const TextStyle(fontSize: 24),
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
                          wallet.name,
                          style: AppTheme.bodyL.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      if (wallet.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Mặc định',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.primaryPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    wallet.typeDisplayName,
                    style: AppTheme.caption.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(wallet.balance),
                  style: AppTheme.bodyL.copyWith(
                    fontWeight: FontWeight.w600,
                    color: wallet.balance >= 0
                        ? AppTheme.incomeGreen
                        : AppTheme.expenseRed,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditWalletDialog(context, wallet);
                    } else if (value == 'delete') {
                      _confirmDelete(context, wallet, provider);
                    } else if (value == 'default') {
                      provider.updateWallet(wallet.copyWith(isDefault: true));
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    if (!wallet.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(Icons.star_outline, size: 20),
                            SizedBox(width: 8),
                            Text('Đặt làm mặc định'),
                          ],
                        ),
                      ),
                    if (!wallet.isDefault)
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
                  child: const Icon(Icons.more_vert, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    _showWalletFormDialog(context, null);
  }

  void _showEditWalletDialog(BuildContext context, Wallet wallet) {
    _showWalletFormDialog(context, wallet);
  }

  void _showWalletFormDialog(BuildContext context, Wallet? wallet) {
    final nameController = TextEditingController(text: wallet?.name ?? '');
    final balanceController = TextEditingController(
      text: wallet?.balance.toStringAsFixed(0) ?? '',
    );
    String selectedType = wallet?.type ?? 'cash';
    String selectedIcon = wallet?.icon ?? '💵';

    final walletTypes = [
      {'type': 'cash', 'name': 'Tiền mặt', 'icon': '💵'},
      {'type': 'bank', 'name': 'Ngân hàng', 'icon': '🏦'},
      {'type': 'credit_card', 'name': 'Thẻ tín dụng', 'icon': '💳'},
      {'type': 'e_wallet', 'name': 'Ví điện tử', 'icon': '📱'},
    ];

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
                      child: Text(
                        wallet == null ? 'Thêm Ví mới' : 'Chỉnh sửa Ví',
                        style: AppTheme.headingM,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceL),

                    // Wallet Type
                    Text('Loại ví', style: AppTheme.bodyM),
                    const SizedBox(height: AppTheme.spaceS),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: walletTypes.map((type) {
                        final isSelected = type['type'] == selectedType;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedType = type['type'] as String;
                              selectedIcon = type['icon'] as String;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryPurple.withValues(alpha: 0.15)
                                  : (isDark
                                      ? AppTheme.darkBackground
                                      : AppTheme.lightBackground),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: AppTheme.primaryPurple, width: 2)
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(type['icon'] as String, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(
                                  type['name'] as String,
                                  style: AppTheme.bodyS.copyWith(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected
                                        ? AppTheme.primaryPurple
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.spaceL),

                    // Name
                    Text('Tên ví', style: AppTheme.bodyM),
                    const SizedBox(height: AppTheme.spaceS),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: VCB, Momo, Tiền mặt...',
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

                    // Balance
                    Text('Số dư hiện tại', style: AppTheme.bodyM),
                    const SizedBox(height: AppTheme.spaceS),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0',
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
                    const SizedBox(height: AppTheme.spaceXL),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập tên ví')),
                            );
                            return;
                          }

                          final balance = double.tryParse(
                            balanceController.text.replaceAll(',', ''),
                          ) ?? 0;

                          final provider = context.read<WalletProvider>();

                          if (wallet == null) {
                            provider.addWallet(
                              Wallet(
                                name: nameController.text,
                                type: selectedType,
                                balance: balance,
                                icon: selectedIcon,
                                isDefault: provider.wallets.isEmpty,
                              ),
                            );
                          } else {
                            provider.updateWallet(
                              wallet.copyWith(
                                name: nameController.text,
                                type: selectedType,
                                balance: balance,
                                icon: selectedIcon,
                              ),
                            );
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                          ),
                        ),
                        child: Text(
                          wallet == null ? 'Thêm ví' : 'Lưu thay đổi',
                          style: const TextStyle(fontSize: 18, color: Colors.white),
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

  void _confirmDelete(BuildContext context, Wallet wallet, WalletProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ví?'),
        content: Text('Bạn có chắc muốn xóa "${wallet.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteWallet(wallet.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getWalletColor(String type) {
    switch (type) {
      case 'cash':
        return Colors.green;
      case 'bank':
        return Colors.blue;
      case 'credit_card':
        return Colors.orange;
      case 'e_wallet':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getWalletIcon(String type) {
    switch (type) {
      case 'cash':
        return '💵';
      case 'bank':
        return '🏦';
      case 'credit_card':
        return '💳';
      case 'e_wallet':
        return '📱';
      default:
        return '💼';
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount);
  }
}
