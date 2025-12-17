import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import 'expense_provider.dart';

class RecurringProvider with ChangeNotifier {
  late Box<RecurringTransaction> _recurringBox;
  final ExpenseProvider _expenseProvider;
  bool _isInitialized = false;

  RecurringProvider(this._expenseProvider);

  bool get isInitialized => _isInitialized;

  List<RecurringTransaction> get recurringTransactions {
    if (!_isInitialized) return [];
    return _recurringBox.values.toList();
  }

  Future<void> init() async {
    _recurringBox = await Hive.openBox<RecurringTransaction>('recurring_transactions');
    _isInitialized = true;
    
    await _checkAndProcessRecurring();
    
    notifyListeners();
  }

  Future<void> _checkAndProcessRecurring() async {
    final now = DateTime.now();
    bool changesMade = false;

    for (var recurring in _recurringBox.values) {
      if (recurring.nextRun.isBefore(now) || recurring.nextRun.isAtSameMomentAs(now)) {
        // Time to run!
        // We might need to run multiple times if missed (e.g. app closed for 2 months)
        // or just once. Let's do simple catch-up.
        
        DateTime runner = recurring.nextRun;
        while (runner.isBefore(now) || runner.isAtSameMomentAs(now)) {
          // Create Transaction
          final newTx = Transaction(
            id: const Uuid().v4(), 
            title: '${recurring.title} (Auto)', 
            amount: recurring.amount, 
            date: runner, // Use the scheduled date, not now, to keep history accurate
            categoryId: recurring.categoryId, 
            isExpense: recurring.isExpense
          );

          await _expenseProvider.addTransaction(newTx);
          
          // Advance runner
          switch (recurring.frequency) {
            case Frequency.daily:
              runner = runner.add(const Duration(days: 1));
              break;
            case Frequency.weekly:
              runner = runner.add(const Duration(days: 7));
              break;
            case Frequency.monthly:
              // Handle end of months safely (e.g. Jan 31 -> Feb 28/29)
              // Simple approach: Add days or use logic. 
              // DateTime default add month logic in Dart handles it but can skip days if source is 31 and target month has 30.
              // Let's keep it simple for now: increment month.
              runner = DateTime(runner.year, runner.month + 1, runner.day);
              break;
            case Frequency.yearly:
              runner = DateTime(runner.year + 1, runner.month, runner.day);
              break;
          }
        }
        
        // Update nextRun
        recurring.nextRun = runner;
        await recurring.save();
        changesMade = true;
      }
    }

    if (changesMade) {
      // Notify?
    }
  }

  Future<void> addRecurring(RecurringTransaction item) async {
    await _recurringBox.put(item.id, item);
    // Should we verify immediately?
    await _checkAndProcessRecurring();
    notifyListeners();
  }

  Future<void> deleteRecurring(String id) async {
    await _recurringBox.delete(id);
    notifyListeners();
  }
}
