import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart'; // Import

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  String _selectedPeriod = 'month'; // 'day', 'week', 'month', 'year'

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.languageCode;
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    
    // Filter Transactions based on Period
    final now = DateTime.now();
    final periodTransactions = expenseProvider.transactions.where((tx) {
      if (!tx.isExpense) return false;

      switch (_selectedPeriod) {
        case 'day':
          return tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day;
        case 'week':
           // Simpler week logic: same week number (requires package or custom logic)
           // Or just last 7 days? Or ISO week.
           // Let's us ISO week approximation for now or simple "Start of week"
           final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Mon
           final endOfWeek = startOfWeek.add(const Duration(days: 7));
           return tx.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && tx.date.isBefore(endOfWeek);
        case 'month':
          return tx.date.year == now.year && tx.date.month == now.month;
        case 'year':
          return tx.date.year == now.year;
        default:
          return false;
      }
    }).toList();

    double totalSpent = 0;
    Map<String, double> categorySpent = {};

    for (var tx in periodTransactions) {
      totalSpent += tx.amount;
      categorySpent[tx.categoryId] = (categorySpent[tx.categoryId] ?? 0) + tx.amount;
    }

    final globalLimit = settings.getBudget(_selectedPeriod);
    final categoriesWithLimit = categoryProvider.categories.where((c) => c.budgetLimit != null && c.budgetLimit! > 0).toList();

    // Map strings for selector
    final periodLabels = {
      'day': AppStrings.get('filterDay', lang),
      'week': AppStrings.get('filterWeek', lang),
      'month': AppStrings.get('filterMonth', lang),
      'year': AppStrings.get('filterYear', lang),
    };

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('budgets', lang))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['day', 'week', 'month', 'year'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(periodLabels[period]!),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedPeriod = period);
                      },
                      selectedColor: const Color(0xFF26A69A),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Global Budget Card
            if (globalLimit > 0) ...[
              Text(AppStrings.get('globalBudget', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildBudgetCard(
                context, 
                name: AppStrings.get('totalSpending', lang), 
                spent: totalSpent, 
                limit: globalLimit, 
                color: const Color(0xFF26A69A),
                icon: Icons.account_balance_wallet
              ),
              const SizedBox(height: 32),
            ] else ...[
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.white.withValues(alpha: 0.05),
                   borderRadius: BorderRadius.circular(16)
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.info_outline, color: Colors.blue),
                     const SizedBox(width: 12),
                     Expanded(child: Text(AppStrings.get('setGlobalBudget', lang))),
                   ],
                 ),
               ),
               const SizedBox(height: 32),
            ],

            // Category Budgets
            // Note: Category Budgets are usually monthly. Do we scale them? 
            // For now, let's keep them as "Monthly Limits" shown only when 'month' is selected?
            // Or scale them? Scaling is complex. 
            // Let's show them ONLY if 'month' is selected for now, to avoid confusion.
            if (_selectedPeriod == 'month') ...[
              if (categoriesWithLimit.isNotEmpty) ...[
                Text(AppStrings.get('categoryBudgets', lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...categoriesWithLimit.map((cat) {
                   final spent = categorySpent[cat.id] ?? 0.0;
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 16.0),
                     child: _buildBudgetCard(
                       context,
                       name: cat.name,
                       spent: spent,
                       limit: cat.budgetLimit!,
                       color: cat.color,
                       icon: cat.icon
                     ),
                   );
                }),
              ]
            ] else ...[
               // Optional: Show message or hide logic
               Center(child: Text('Category budgets are monthly.', style: TextStyle(color: Colors.grey.withValues(alpha: 0.5)))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, {
    required String name, 
    required double spent, 
    required double limit, 
    required Color color,
    required IconData icon
  }) {
    final settings = Provider.of<SettingsProvider>(context);
    final progress = (spent / limit).clamp(0.0, 1.0);
    final isOverLimit = spent > limit;
    final isNearLimit = spent > (limit * 0.85);
    
    Color statusColor = Colors.greenAccent;
    if (isOverLimit) {
      statusColor = Colors.redAccent;
    } else if (isNearLimit) statusColor = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: isOverLimit ? Border.all(color: Colors.redAccent.withValues(alpha: 0.5)) : null
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
                 child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Text(
                '${settings.currencySymbol}${spent.toStringAsFixed(0)} / ${settings.currencySymbol}${limit.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade800,
            color: statusColor,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isOverLimit)
                Text('${AppStrings.get('overBy', settings.languageCode)} ${settings.currencySymbol}${(spent - limit).toStringAsFixed(0)}', 
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)
                )
              else
                 Text('${settings.currencySymbol}${(limit - spent).toStringAsFixed(0)} ${AppStrings.get('left', settings.languageCode)}', 
                  style: TextStyle(color: Colors.greenAccent.shade100, fontSize: 12)
                )
            ],
          )
        ],
      ),
    );
  }
}

