import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SettingsProvider with ChangeNotifier {
  late Box _settingsBox;
  bool _isInitialized = false;

  String _languageCode = 'es'; // Default Spanish
  String _currencyCode = 'PEN'; // Default Soles
  String _currencySymbol = 'S/';
  double _globalBudgetLimit = 0.0; // 0.0 means no limit
  bool _isDarkMode = true; // Default to Dark Mode

  String get languageCode => _languageCode;
  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  double get globalBudgetLimit => _globalBudgetLimit; // 0.0 means no limit
  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    _settingsBox = await Hive.openBox('settings');
    _languageCode = _settingsBox.get('languageCode', defaultValue: 'es');
    _currencyCode = _settingsBox.get('currencyCode', defaultValue: 'PEN');
    _globalBudgetLimit = _settingsBox.get('globalBudget', defaultValue: 0.0);
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

  Future<void> setGlobalBudget(double amount) async {
    _globalBudgetLimit = amount;
    await _settingsBox.put('globalBudget', amount);
    notifyListeners();
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
