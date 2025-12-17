import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart'; // Import
import '../providers/recurring_provider.dart';
import '../providers/settings_provider.dart';

import '../screens/add_transaction_screen.dart'; // Import

class ManageRecurringScreen extends StatelessWidget {
  const ManageRecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('recurringTransactions', settings.languageCode))),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
        },
        tooltip: 'Add New',
        child: const Icon(Icons.add),
      ),
      body: Consumer<RecurringProvider>(
        builder: (context, provider, _) {
          final list = provider.recurringTransactions;

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_repeat, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(AppStrings.get('noRecurring', settings.languageCode), style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.get('addRecurringHint', settings.languageCode),
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                color: Colors.white.withValues(alpha: 0.05),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.isExpense ? Colors.redAccent.withValues(alpha: 0.2) : Colors.greenAccent.withValues(alpha: 0.2),
                    child: Icon(
                      item.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                      color: item.isExpense ? Colors.redAccent : Colors.greenAccent,
                      size: 20
                    ),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${AppStrings.get(item.frequency.name.toLowerCase(), settings.languageCode)} • ${AppStrings.get('next', settings.languageCode)} ${dateFormat.format(item.nextRun)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${settings.currencySymbol} ${item.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                        onPressed: () {
                          // Confirm delete?
                          provider.deleteRecurring(item.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
