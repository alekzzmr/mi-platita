import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';
import 'manage_categories_screen.dart';
import 'manage_recurring_screen.dart';
import '../services/backup_service.dart'; // Import
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';
import '../providers/recurring_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _budgetController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _budgetController = TextEditingController(
      text: settings.globalBudgetLimit > 0 ? settings.globalBudgetLimit.toStringAsFixed(2) : ''
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final amount = double.tryParse(_budgetController.text) ?? 0.0;
    settings.setGlobalBudget(amount);
    
    settings.setGlobalBudget(amount);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.get('budgetSaved', settings.languageCode)), backgroundColor: Colors.green),
    );
    
    // Hide keyboard
    FocusScope.of(context).unfocus();
  }

  Future<void> _backupData() async {
    try {
      final service = BackupService();
      // Create JSON
      final jsonString = await service.createBackupJson();
      // Share file
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      await service.shareFile(jsonString, 'money_track_backup_$dateStr.json');
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup ready to share...'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _restoreData() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final lang = settings.languageCode;

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('restoreConfirmTitle', lang)),
        content: Text(AppStrings.get('restoreConfirmMsg', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.get('confirm', lang), style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final service = BackupService();
      final file = await service.pickFile();
      
      if (file != null) {
        try {
          await service.restoreBackup(file);
          
          // Refresh Providers
          if (mounted) {
            await Provider.of<ExpenseProvider>(context, listen: false).init();
            await Provider.of<CategoryProvider>(context, listen: false).init();
            await Provider.of<RecurringProvider>(context, listen: false).init();
            await settings.init(); // Refresh settings from Hive
             
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppStrings.get('restoreSuccess', lang)), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        }
      }
    }
  }

  Future<void> _exportCsv() async {
    try {
      final service = BackupService();
      final csvString = await service.generateCsv();
      final dateStr = DateTime.now().toIso8601String().split('T').first;
      await service.shareFile(csvString, 'money_track_export_$dateStr.csv');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('settings', lang)),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(AppStrings.get('language', lang)),
          _buildRadioOption(
            title: 'English',
            value: 'en',
            groupValue: settings.languageCode,
            onChanged: (val) => settings.setLanguage(val!),
          ),
          _buildRadioOption(
            title: 'Español',
            value: 'es',
            groupValue: settings.languageCode,
            onChanged: (val) => settings.setLanguage(val!),
          ),
          const Divider(color: Colors.white24),
          _buildSectionHeader(AppStrings.get('currency', lang)),
          _buildRadioOption(
            title: 'Peruvian Sol (S/)',
            value: 'PEN',
            groupValue: settings.currencyCode,
            onChanged: (val) => settings.setCurrency(val!),
          ),
          _buildRadioOption(
            title: 'US Dollar (\$)',
            value: 'USD',
            groupValue: settings.currencyCode,
            onChanged: (val) => settings.setCurrency(val!),
          ),
          _buildRadioOption(
            title: 'Euro (€)',
            value: 'EUR',
            groupValue: settings.currencyCode,
            onChanged: (val) => settings.setCurrency(val!),
          ),
          _buildRadioOption(
            title: 'Mexican Peso (\$)',
            value: 'MXN',
            groupValue: settings.currencyCode,
            onChanged: (val) => settings.setCurrency(val!),
          ),
          _buildRadioOption(
            title: 'Colombian Peso (\$)',
            value: 'COP',
            groupValue: settings.currencyCode,
            onChanged: (val) => settings.setCurrency(val!),
          ),

          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(AppStrings.get('globalBudget', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          
          _buildBudgetInput(context, settings, 'day', AppStrings.get('budgetDay', lang)),
          _buildBudgetInput(context, settings, 'week', AppStrings.get('budgetWeek', lang)),
          _buildBudgetInput(context, settings, 'month', AppStrings.get('budgetMonth', lang)),
          _buildBudgetInput(context, settings, 'year', AppStrings.get('budgetYear', lang)),

          const SizedBox(height: 10),

          SwitchListTile(
              title: Text(AppStrings.get('darkMode', lang)), 
              value: settings.isDarkMode, 
              onChanged: (val) => settings.setTheme(val),
              activeThumbColor: const Color(0xFF26A69A),
              secondary: Icon(settings.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            ),
            const Divider(color: Colors.white24),
            
            // Manage Categories
            ListTile(
              leading: const Icon(Icons.category),
              title: Text(AppStrings.get('manageCategories', lang)), 
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()));
              },
            ),

            // Manage Recurring
            ListTile(
              leading: const Icon(Icons.event_repeat),
              title: Text(AppStrings.get('recurringTransactions', lang)), 
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageRecurringScreen()));
              },
            ),

            const Divider(color: Colors.white24),

            // Data Management
            _buildSectionHeader(AppStrings.get('dataManagement', lang)),
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(AppStrings.get('backupData', lang)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _backupData,
            ),
            ListTile(
              leading: const Icon(Icons.upload),
              title: Text(AppStrings.get('restoreData', lang)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _restoreData,
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: Text(AppStrings.get('exportCsv', lang)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _exportCsv,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: const Color(0xFF26A69A),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildBudgetInput(BuildContext context, SettingsProvider settings, String period, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
          SizedBox(
            width: 120,
            child: TextField(
              controller: TextEditingController(text: settings.getBudget(period) > 0 ? settings.getBudget(period).toStringAsFixed(0) : ''),
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: settings.currencySymbol,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onSubmitted: (val) {
                 final amount = double.tryParse(val) ?? 0.0;
                 settings.setBudget(period, amount);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: const Color(0xFF26A69A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
