import 'package:flutter/foundation.dart';
import '../database_helper.dart';
import '../models/wallet.dart';

class WalletProvider extends ChangeNotifier {
  List<Wallet> _wallets = [];
  bool _isLoading = false;
  int? _selectedWalletId;

  List<Wallet> get wallets => _wallets;
  bool get isLoading => _isLoading;
  int? get selectedWalletId => _selectedWalletId;

  Wallet? get selectedWallet => _selectedWalletId != null
      ? _wallets.firstWhere(
          (w) => w.id == _selectedWalletId,
          orElse: () => _wallets.isNotEmpty ? _wallets.first : Wallet(name: 'Chưa có ví', type: 'cash'),
        )
      : (_wallets.isNotEmpty ? _wallets.first : null);

  Wallet? get defaultWallet => _wallets.firstWhere(
        (w) => w.isDefault,
        orElse: () => _wallets.isNotEmpty ? _wallets.first : Wallet(name: 'Chưa có ví', type: 'cash'),
      );

  double get totalBalance => _wallets.fold(0, (sum, w) => sum + w.balance);

  void selectWallet(int? walletId) {
    _selectedWalletId = walletId;
    notifyListeners();
  }

  Future<void> loadWallets() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'wallets',
        orderBy: 'is_default DESC, name ASC',
      );
      _wallets = maps.map((map) => Wallet.fromMap(map)).toList();

      // Auto-select default wallet if none selected
      if (_selectedWalletId == null && _wallets.isNotEmpty) {
        final defaultW = _wallets.firstWhere(
          (w) => w.isDefault,
          orElse: () => _wallets.first,
        );
        _selectedWalletId = defaultW.id;
      }
    } catch (e) {
      debugPrint('Error loading wallets: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWallet(Wallet wallet) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // If this is the first wallet or set as default, ensure only one default
      if (wallet.isDefault || _wallets.isEmpty) {
        await db.update('wallets', {'is_default': 0});
      }

      await db.insert('wallets', wallet.toMap());
      await loadWallets();
    } catch (e) {
      debugPrint('Error adding wallet: $e');
    }
  }

  Future<void> updateWallet(Wallet wallet) async {
    try {
      final db = await DatabaseHelper.instance.database;

      // If setting as default, clear other defaults
      if (wallet.isDefault) {
        await db.update('wallets', {'is_default': 0});
      }

      await db.update(
        'wallets',
        wallet.toMap(),
        where: 'id = ?',
        whereArgs: [wallet.id],
      );
      await loadWallets();
    } catch (e) {
      debugPrint('Error updating wallet: $e');
    }
  }

  Future<void> updateBalance(int walletId, double amount, {bool isExpense = true}) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final result = await db.query(
        'wallets',
        where: 'id = ?',
        whereArgs: [walletId],
      );

      if (result.isNotEmpty) {
        final currentBalance = (result.first['balance'] as num).toDouble();
        final newBalance = isExpense
            ? currentBalance - amount
            : currentBalance + amount;

        await db.update(
          'wallets',
          {'balance': newBalance},
          where: 'id = ?',
          whereArgs: [walletId],
        );
        await loadWallets();
      }
    } catch (e) {
      debugPrint('Error updating wallet balance: $e');
    }
  }

  Future<void> deleteWallet(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
      await loadWallets();
    } catch (e) {
      debugPrint('Error deleting wallet: $e');
    }
  }
}
