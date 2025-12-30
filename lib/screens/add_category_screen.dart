import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category; // If null, adding new. If set, editing.

  const AddEditCategoryScreen({super.key, this.category});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.category;

  final List<Color> _colors = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown, Colors.grey, Colors.blueGrey,
  ];

  // Extended Icon List
  final List<IconData> _icons = [
    // Food & Drink
    Icons.fastfood, Icons.restaurant, Icons.local_cafe, Icons.local_bar,
    Icons.ramen_dining, Icons.icecream, Icons.bakery_dining, Icons.liquor, 
    // Transport & Travel
    Icons.directions_bus, Icons.directions_car, Icons.flight, Icons.train,
    Icons.directions_bike, Icons.local_taxi, Icons.local_gas_station, Icons.commute,
    // Shopping
    Icons.shopping_bag, Icons.shopping_cart, Icons.credit_card, Icons.receipt,
    Icons.store, Icons.card_giftcard, Icons.loyalty,
    // Entertainment
    Icons.movie, Icons.music_note, Icons.sports_esports, Icons.fitness_center,
    Icons.pool, Icons.theater_comedy, Icons.stadium, Icons.casino,
    // Home & Utilities
    Icons.home, Icons.wifi, Icons.phone, Icons.computer,
    Icons.lightbulb, Icons.water_drop, Icons.build, Icons.delete,
    // Work & Education
    Icons.school, Icons.work, Icons.attach_money, Icons.savings,
    Icons.business_center, Icons.cases, Icons.history_edu,
    // Health & Family
    Icons.pets, Icons.child_care, Icons.medical_services, Icons.local_hospital,
    Icons.medication, Icons.spa, Icons.favorite,
    // Misc
    Icons.category, Icons.star, Icons.redeem, Icons.bolt,
    Icons.lock, Icons.vpn_key, Icons.flag, Icons.map,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _selectedColor = widget.category!.color;
      _selectedIcon = widget.category!.icon;
      if (widget.category!.budgetLimit != null && widget.category!.budgetLimit! > 0) {
        _budgetController.text = widget.category!.budgetLimit!.toString();
      }
    }
  }

  void _saveCategory() {
    if (_nameController.text.isEmpty) return;

    final id = widget.category?.id ?? const Uuid().v4();
    
    final newCategory = Category(
      id: id,
      name: _nameController.text,
      iconCodePoint: _selectedIcon.codePoint,
      colorValue: _selectedColor.toARGB32(),
      budgetLimit: double.tryParse(_budgetController.text),
    );

    Provider.of<CategoryProvider>(context, listen: false).addCategory(newCategory);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.languageCode;
    final isEditing = widget.category != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? AppStrings.get('edit', lang) : AppStrings.get('newCategory', lang))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Input
            Text(AppStrings.get('categoryName', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Category Name',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            
            // Budget Limit Input (Optional)
            Text(AppStrings.get('monthlyLimitOptional', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g. 500.00',
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Color Picker
            const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color 
                          ? Border.all(color: Colors.white, width: 3) 
                          : null,
                    ),
                    child: _selectedColor == color 
                        ? const Icon(Icons.check, color: Colors.white, size: 20) 
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Icon Picker
            const Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((icon) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedIcon == icon ? const Color(0xFF26A69A) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveCategory,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(isEditing ? AppStrings.get('saveTransaction', lang) : AppStrings.get('createCategory', lang), 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
