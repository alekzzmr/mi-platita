import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../models/recurring_transaction.dart';

class BackupService {
  
  // Helper to ensure boxes are open
  Future<Map<String, Box>> _getBoxes() async {
    final transactionBox = await Hive.openBox<Transaction>('transactions');
    final categoryBox = await Hive.openBox<Category>('categories');
    final recurringBox = await Hive.openBox<RecurringTransaction>('recurring_transactions');
    final settingsBox = await Hive.openBox('settings');
    
    return {
      'transactions': transactionBox,
      'categories': categoryBox,
      'recurring': recurringBox,
      'settings': settingsBox,
    };
  }

  // --- JSON BACKUP ---

  Future<String> createBackupJson() async {
    final boxes = await _getBoxes();
    final _settingsBox = boxes['settings']!;
    final _categoryBox = boxes['categories'] as Box<Category>;
    final _transactionBox = boxes['transactions'] as Box<Transaction>;
    final _recurringBox = boxes['recurring'] as Box<RecurringTransaction>;

    final Map<String, dynamic> backupData = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'settings': {
        'currencyCode': _settingsBox.get('currencyCode', defaultValue: 'USD'),
        'languageCode': _settingsBox.get('languageCode', defaultValue: 'en'),
        'globalBudget': _settingsBox.get('globalBudget', defaultValue: 0.0),
      },
      'categories': _categoryBox.values.map((c) => c.toJson()).toList(),
      'transactions': _transactionBox.values.map((t) => t.toJson()).toList(),
      'recurring': _recurringBox.values.map((r) => r.toJson()).toList(),
    };

    return jsonEncode(backupData);
  }

  Future<void> restoreBackup(File file) async {
    final boxes = await _getBoxes();
    final _settingsBox = boxes['settings']!;
    final _categoryBox = boxes['categories'] as Box<Category>;
    final _transactionBox = boxes['transactions'] as Box<Transaction>;
    final _recurringBox = boxes['recurring'] as Box<RecurringTransaction>;

    final String jsonString = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(jsonString);

    // Validate version
    // if (data['version'] != 1) ... handle migration

    // 1. Settings
    if (data.containsKey('settings')) {
      final settings = data['settings'];
      await _settingsBox.put('currencyCode', settings['currencyCode']);
      await _settingsBox.put('languageCode', settings['languageCode']);
      await _settingsBox.put('globalBudget', settings['globalBudget']);
    }

    // 2. Categories
    if (data.containsKey('categories')) {
      await _categoryBox.clear();
      final List cats = data['categories'];
      for (var c in cats) {
        final category = Category.fromMap(c);
        await _categoryBox.put(category.id, category);
      }
    }

    // 3. Transactions
    if (data.containsKey('transactions')) {
      await _transactionBox.clear();
      final List txs = data['transactions'];
      for (var t in txs) {
        final transaction = Transaction.fromMap(t);
        await _transactionBox.put(transaction.id, transaction);
      }
    }

    // 4. Recurring
    if (data.containsKey('recurring')) {
      await _recurringBox.clear();
      final List recs = data['recurring'];
      for (var r in recs) {
        final recurring = RecurringTransaction.fromMap(r);
        await _recurringBox.put(recurring.id, recurring);
      }
    }
  }

  // --- CSV EXPORT ---

  Future<String> generateCsv() async {
    final boxes = await _getBoxes();
    final _settingsBox = boxes['settings']!;
    final _categoryBox = boxes['categories'] as Box<Category>;
    final _transactionBox = boxes['transactions'] as Box<Transaction>;

    List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      'Date',
      'Title',
      'Category',
      'Type',
      'Amount',
      'Currency'
    ]);

    final transactions = _transactionBox.values.toList();
    // Sort by date desc
    transactions.sort((a, b) => b.date.compareTo(a.date));

    final currency = _settingsBox.get('currencyCode', defaultValue: 'USD');

    for (var tx in transactions) {
      // Find category name
      final cat = _categoryBox.get(tx.categoryId);
      final catName = cat?.name ?? 'Unknown';

      rows.add([
        DateFormat('yyyy-MM-dd').format(tx.date),
        tx.title,
        catName,
        tx.isExpense ? 'Expense' : 'Income',
        tx.amount.toStringAsFixed(2),
        currency
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  // --- FILE OPERATIONS ---

  Future<void> shareFile(String content, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);

    await Share.shareXFiles([XFile(file.path)], text: 'MiPlatita Data');
  }

  Future<File?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }
}
