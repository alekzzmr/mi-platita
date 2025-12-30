import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsProvider with ChangeNotifier {
  late Box _settingsBox;
  bool _isInitialized = false;

  String _languageCode = 'es'; // Default Spanish
  String _currencyCode = 'PEN'; // Default Soles
  String _currencySymbol = 'S/';
  // Period Budgets: 'day', 'week', 'month', 'year'
  Map<String, double> _globalBudgets = {
    'day': 0.0,
    'week': 0.0,
    'month': 0.0,
    'year': 0.0,
  };
  
  bool _isDarkMode = true; // Default to Dark Mode

  // Getters
  String get languageCode => _languageCode;
  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  double getBudget(String period) => _globalBudgets[period] ?? 0.0;
  
  // Deprecated getter for backward compatibility (maps to month)
  double get globalBudgetLimit => _globalBudgets['month'] ?? 0.0;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    _settingsBox = await Hive.openBox('settings');
    _languageCode = _settingsBox.get('languageCode', defaultValue: 'es');
    _currencyCode = _settingsBox.get('currencyCode', defaultValue: 'PEN');
    
    // Migration: Check for old key
    double oldGlobal = _settingsBox.get('globalBudget', defaultValue: 0.0);
    
    // Load new keys
    _globalBudgets['day'] = _settingsBox.get('budget_day', defaultValue: 0.0);
    _globalBudgets['week'] = _settingsBox.get('budget_week', defaultValue: 0.0);
    _globalBudgets['month'] = _settingsBox.get('budget_month', defaultValue: 0.0);
    _globalBudgets['year'] = _settingsBox.get('budget_year', defaultValue: 0.0);

    // If there was an old global budget and no new monthly budget, migrate it
    if (oldGlobal > 0 && _globalBudgets['month'] == 0) {
      _globalBudgets['month'] = oldGlobal;
      await _settingsBox.put('budget_month', oldGlobal);
      await _settingsBox.delete('globalBudget'); // Clean up
    }

    _isDarkMode = _settingsBox.get('isDarkMode', defaultValue: true);
    _updateCurrencySymbol();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    await _settingsBox.put('languageCode', code);
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    _currencyCode = code;
    await _settingsBox.put('currencyCode', code);
    _updateCurrencySymbol();
    notifyListeners();
  }

  Future<void> setBudget(String period, double amount) async {
    if (_globalBudgets.containsKey(period)) {
      _globalBudgets[period] = amount;
      await _settingsBox.put('budget_$period', amount);
      notifyListeners();
    }
  }

  // Deprecated setter
  Future<void> setGlobalBudget(double amount) async {
    await setBudget('month', amount);
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    await _settingsBox.put('isDarkMode', isDark);
    notifyListeners();
  }

  void _updateCurrencySymbol() {
    switch (_currencyCode) {
      case 'PEN':
        _currencySymbol = 'S/';
        break;
      case 'USD':
        _currencySymbol = '\$';
        break;
      case 'EUR':
        _currencySymbol = '€';
        break;
      case 'MXN':
        _currencySymbol = '\$';
        break;
      case 'COP':
        _currencySymbol = '\$';
        break;
      default:
        _currencySymbol = '\$';
    }
  }
}
