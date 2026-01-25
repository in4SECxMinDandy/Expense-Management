import 'package:flutter/foundation.dart' hide Category;
import '../database_helper.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  List<Category> get expenseCategories =>
      _categories.where((c) => c.type == 'expense').toList();
  List<Category> get incomeCategories =>
      _categories.where((c) => c.type == 'income').toList();
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('categories');
      _categories = maps.map((map) => Category.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('categories', category.toMap());
      await loadCategories();
    } catch (e) {
      debugPrint('Error adding category: $e');
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
      await loadCategories();
    } catch (e) {
      debugPrint('Error updating category: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);
      await loadCategories();
    } catch (e) {
      debugPrint('Error deleting category: $e');
    }
  }
}
