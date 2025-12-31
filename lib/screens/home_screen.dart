import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'budgets_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final lang = settings.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('appTitle', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet), // Budget Icon
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: !provider.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Filter Selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: TimeFilter.values.map((filter) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(_getFilterName(filter, lang)),
                            selected: provider.currentFilter == filter,
                            onSelected: (selected) {
                              if (selected) provider.setFilter(filter);
                            },
                            selectedColor: const Color(0xFF26A69A),
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            labelStyle: TextStyle(
                              color: provider.currentFilter == filter ? Colors.white : Colors.white70,
                            ),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Budget Alert
                  _buildBudgetAlert(context, provider, settings),
                  const SizedBox(height: 16),

                  // Balance Card
                  _buildBalanceCard(context, provider),
                  const SizedBox(height: 24),
                  
                  // Transactions Header
                  Text(AppStrings.get('recentTransactions', lang), 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // Transactions List
                  if (provider.transactions.isEmpty)
                     Center(child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(AppStrings.get('noTransactions', lang), style: const TextStyle(color: Colors.grey)),
                    ))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.transactions.length,
                      itemBuilder: (context, index) {
                        return TransactionCard(transaction: provider.transactions[index]);
                      },
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        label: Text(AppStrings.get('addTransaction', lang)),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, ExpenseProvider provider) {
    // NumberFormat needs locale if we were using it fully, 
    // but for now we manually prefix symbol or use simple currency with explicit name.
    // However, basic NumberFormat.currency works well.
    final settings = Provider.of<SettingsProvider>(context);
    final currencyFormat = NumberFormat.currency(symbol: settings.currencySymbol, decimalDigits: 2);
    final lang = settings.languageCode;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF00897B), const Color(0xFF26A69A)], // Teal gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00897B).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(AppStrings.get('totalBalance', lang),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(currencyFormat.format(provider.totalBalance),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                label: AppStrings.get('income', lang),
                amount: currencyFormat.format(provider.totalIncome),
                icon: Icons.arrow_downward,
                color: Colors.greenAccent,
              ),
              _buildSummaryItem(
                label: AppStrings.get('expense', lang),
                amount: currencyFormat.format(provider.totalExpense),
                icon: Icons.arrow_upward,
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFilterName(TimeFilter filter, String lang) {
    switch (filter) {
      case TimeFilter.day: return AppStrings.get('filterDay', lang);
      case TimeFilter.week: return AppStrings.get('filterWeek', lang);
      case TimeFilter.month: return AppStrings.get('filterMonth', lang);
      case TimeFilter.year: return AppStrings.get('filterYear', lang);
      case TimeFilter.all: return AppStrings.get('filterAll', lang);
    }
  }

  Widget _buildSummaryItem({required String label, required String amount, required IconData icon, required Color color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetAlert(BuildContext context, ExpenseProvider provider, SettingsProvider settings) {
    // Map TimeFilter to budget key
    String? periodKey;
    switch (provider.currentFilter) {
      case TimeFilter.day: periodKey = 'day'; break;
      case TimeFilter.week: periodKey = 'week'; break;
      case TimeFilter.month: periodKey = 'month'; break;
      case TimeFilter.year: periodKey = 'year'; break;
      default: periodKey = null;
    }

    if (periodKey == null) return const SizedBox.shrink();

    final limit = settings.getBudget(periodKey);
    if (limit <= 0) return const SizedBox.shrink();

    final totalExpense = provider.totalExpense;
    if (totalExpense > limit) {
      final excess = totalExpense - limit;
      final lang = settings.languageCode;
      
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          border: Border.all(color: Colors.redAccent, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.get('budgetExceeded', lang), 
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)
                  ),
                  Text('${AppStrings.get('youHaveExceeded', lang)} ${settings.currencySymbol}${excess.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
