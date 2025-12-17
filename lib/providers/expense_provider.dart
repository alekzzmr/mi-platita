import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';

enum TimeFilter { day, week, month, year, all }

class ExpenseProvider with ChangeNotifier {
  late final Box<Transaction> _transactionBox;
  bool _isInitialized = false;
  TimeFilter _currentFilter = TimeFilter.month; // Default to Month

  ExpenseProvider(this._transactionBox);

  bool get isInitialized => _isInitialized;
  TimeFilter get currentFilter => _currentFilter;

  List<Transaction> get transactions {
    // If we passed box in constructor, we might still want to call init for other async setup if needed, 
    // but here we can just verify box is open.
    if (!_transactionBox.isOpen) return [];
    
    final list = _transactionBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    
    // Filter based on _currentFilter
    final now = DateTime.now();
    return list.where((tx) {
      switch (_currentFilter) {
        case TimeFilter.day:
          return tx.date.year == now.year && 
                 tx.date.month == now.month && 
                 tx.date.day == now.day;
        case TimeFilter.week:
          // Simple "last 7 days" or "this week". Let's do this week (starting Monday or Sunday?)
          // Let's do "last 7 days" for simplicity in rolling window, or matching week number.
          // User asked "Week", often means "This Week".
          // Let's check difference in days < 7 and same week logic?
          // Simplest robust way: Same ISO week or just strictly > now - 7 days.
          // Let's stick to "This Week" (since Monday).
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfNextWeek = startOfWeek.add(const Duration(days: 7));
          return tx.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
                 tx.date.isBefore(startOfNextWeek);
        case TimeFilter.month:
          return tx.date.year == now.year && tx.date.month == now.month;
        case TimeFilter.year:
          return tx.date.year == now.year;
        case TimeFilter.all:
        default:
          return true;
      }
    }).toList();
  }

  void setFilter(TimeFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  double get totalBalance {
    return transactions.fold(0.0, (sum, item) {
      return item.isExpense ? sum - item.amount : sum + item.amount;
    });
  }

  double get totalIncome {
    return transactions
        .where((item) => !item.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return transactions
        .where((item) => item.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> init() async {
    // Box is passed in constructor now
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _transactionBox.add(transaction);
    notifyListeners();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await transaction.delete();
    notifyListeners();
  }
}
