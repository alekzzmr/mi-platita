import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  late Box<Category> _categoryBox;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  List<Category> get categories {
    if (!_isInitialized) return [];
    return _categoryBox.values.toList();
  }

  Future<void> init() async {
    _categoryBox = await Hive.openBox<Category>('categories');
    
    // Seed default categories if empty
    if (_categoryBox.isEmpty) {
      await _seedDefaultCategories();
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _seedDefaultCategories() async {
    final defaults = [
      Category(id: 'food', name: 'Food', iconCodePoint: Icons.fastfood.codePoint, colorValue: Colors.orange.toARGB32()),
      Category(id: 'transport', name: 'Transport', iconCodePoint: Icons.directions_bus.codePoint, colorValue: Colors.blue.toARGB32()),
      Category(id: 'shopping', name: 'Shopping', iconCodePoint: Icons.shopping_bag.codePoint, colorValue: Colors.pink.toARGB32()),
      Category(id: 'entertainment', name: 'Entertainment', iconCodePoint: Icons.movie.codePoint, colorValue: Colors.purple.toARGB32()),
      Category(id: 'bills', name: 'Bills', iconCodePoint: Icons.receipt.codePoint, colorValue: Colors.red.toARGB32()),
      Category(id: 'salary', name: 'Salary', iconCodePoint: Icons.attach_money.codePoint, colorValue: Colors.green.toARGB32()),
      Category(id: 'other', name: 'Other', iconCodePoint: Icons.category.codePoint, colorValue: Colors.grey.toARGB32()),
    ];
    
    for (var cat in defaults) {
      await _categoryBox.put(cat.id, cat);
    }
  }

  Future<void> addCategory(Category category) async {
    await _categoryBox.put(category.id, category);
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await _categoryBox.delete(id);
    notifyListeners();
  }
}
