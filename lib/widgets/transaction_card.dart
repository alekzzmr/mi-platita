import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: settings.currencySymbol, decimalDigits: 2);
    final dateFormat = DateFormat('MMM d, yyyy');
    
    // Find category info
    final categoryProvider = Provider.of<CategoryProvider>(context);
    // Safe lookup or fallback
    final category = categoryProvider.categories.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => Category(id: 'unknown', name: 'Unknown', iconCodePoint: 57522, colorValue: 4280361249), // Fallback
    );

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade900,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        Provider.of<ExpenseProvider>(context, listen: false).deleteTransaction(transaction);
      },
      confirmDismiss: (direction) async {
        // TODO: Add confirmation dialog?
        return true; 
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, color: category.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.title, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(dateFormat.format(transaction.date),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              transaction.isExpense 
                ? '- ${currencyFormat.format(transaction.amount)}'
                : '+ ${currencyFormat.format(transaction.amount)}',
              style: TextStyle(
                color: transaction.isExpense ? Colors.redAccent : Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
