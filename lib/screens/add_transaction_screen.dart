import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart'; // Import intl
import '../models/transaction.dart';
import '../models/recurring_transaction.dart'; // Import
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/recurring_provider.dart'; // Import
import '../l10n/app_strings.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  bool _isExpense = true;
  String _selectedCategoryId = 'food';
  DateTime _selectedDate = DateTime.now();
  
  bool _isRecurring = false;
  Frequency _selectedFrequency = Frequency.monthly;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text);

    if (title.isEmpty || amount == null || amount <= 0) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('enterValidData', settings.languageCode))),
      );
      return;
    }

    final newTransaction = Transaction(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      date: _selectedDate,
      isExpense: _isExpense,
      categoryId: _selectedCategoryId,
    );

    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    provider.addTransaction(newTransaction);

    // Handle Recurring
    if (_isRecurring) {
      // Calculate next run immediately (e.g. next month) 
      // OR should the first run be now? Usually repeat means "Also do this in future".
      // The current transaction is already added above. 
      // So the recurring rule should start from "next" occurance.
      
      DateTime nextRun = _selectedDate;
      switch (_selectedFrequency) {
        case Frequency.daily: nextRun = nextRun.add(const Duration(days: 1)); break;
        case Frequency.weekly: nextRun = nextRun.add(const Duration(days: 7)); break;
        case Frequency.monthly: nextRun = DateTime(nextRun.year, nextRun.month + 1, nextRun.day); break;
        case Frequency.yearly: nextRun = DateTime(nextRun.year + 1, nextRun.month, nextRun.day); break;
      }

      final recurringTx = RecurringTransaction(
        id: const Uuid().v4(),
        title: _titleController.text,
        amount: amount,
        categoryId: _selectedCategoryId,
        isExpense: _isExpense,
        frequency: _selectedFrequency,
        nextRun: nextRun,
      );
      
      Provider.of<RecurringProvider>(context, listen: false).addRecurring(recurringTx);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('addTransaction', lang)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle Type
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTypeButton(AppStrings.get('expense', lang), true)),
                  Expanded(child: _buildTypeButton(AppStrings.get('income', lang), false)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '${settings.currencySymbol} ',
                hintText: '0.00',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 24),

            // Title Input
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: AppStrings.get('description', lang),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date Picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: const Color(0xFF26A69A),
                          onPrimary: Colors.white,
                          surface: Color(0xFF1E1E1E),
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white70),
                    const SizedBox(width: 12),
                    Text(
                      'Date: ${DateFormat('MMM d, yyyy').format(_selectedDate)}', // Requires intl
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Colors.white54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Category Selection
            Text(AppStrings.get('category', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Consumer<CategoryProvider>(
              builder: (context, catProvider, _) {
                final categories = catProvider.categories;
                if (categories.isEmpty) return const SizedBox();
                
                // Ensure _selectedCategoryId is valid
                if (!categories.any((c) => c.id == _selectedCategoryId)) {
                  if (categories.isNotEmpty) _selectedCategoryId = categories.first.id;
                }

                return SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category.id == _selectedCategoryId;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategoryId = category.id),
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? category.color : category.color.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(category.icon, 
                                  color: isSelected ? Colors.white : category.color,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(category.name, 
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            ),
            const SizedBox(height: 24),

            // Recurring Toggle
            SwitchListTile(
              title: Text(AppStrings.get('repeatTransaction', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_isRecurring ? AppStrings.get('repeatSubtitle', lang) : AppStrings.get('oneTime', lang)),
              value: _isRecurring,
              activeThumbColor: const Color(0xFF26A69A),
              onChanged: (val) {
                setState(() => _isRecurring = val);
              },
            ),
            
            if (_isRecurring) ...[
              const SizedBox(height: 12),
              Text(AppStrings.get('frequency', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Frequency>(
                    value: _selectedFrequency,
                    isExpanded: true,
                    items: Frequency.values.map((f) {
                      final label = AppStrings.get(f.name.toLowerCase(), lang);
                      return DropdownMenuItem(value: f, child: Text(label));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFrequency = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isExpense ? Colors.redAccent : Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(AppStrings.get('saveTransaction', lang), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, bool isExpenseVal) {
    final isSelected = _isExpense == isExpenseVal;
    final color = isExpenseVal ? Colors.redAccent : Colors.greenAccent;
    return GestureDetector(
      onTap: () => setState(() => _isExpense = isExpenseVal),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(label,
          style: TextStyle(
            color: isSelected ? color : Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
