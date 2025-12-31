import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import '../models/transaction.dart'; // Import Transaction
import '../l10n/app_strings.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // Current Filter State
  String _selectedTimeFilter = 'month'; // day, week, month, year, all
  bool _showExpenses = true; // Toggle between Expense and Income

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final textTheme = Theme.of(context).textTheme;
    final lang = settings.languageCode;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('analysis', lang)),
          bottom: TabBar(
            indicatorColor: const Color(0xFF26A69A), // Teal accent
            labelColor: const Color(0xFF26A69A),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: AppStrings.get('overview', lang)),
              Tab(text: AppStrings.get('trends', lang)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(context, settings, lang),
            _buildTrendsTab(context, settings, lang),
          ],
        ),
      ),
    );
  }

  // --- OVERVIEW TAB ---
  Widget _buildOverviewTab(BuildContext context, SettingsProvider settings, String lang) {
    return Column(
      children: [
        const SizedBox(height: 10),
        // 1. Time Filters Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip(AppStrings.get('day', lang), 'day'),
              const SizedBox(width: 8),
              _buildFilterChip(AppStrings.get('week', lang), 'week'),
              const SizedBox(width: 8),
              _buildFilterChip(AppStrings.get('month', lang), 'month'),
              const SizedBox(width: 8),
              _buildFilterChip(AppStrings.get('year', lang), 'year'),
              const SizedBox(width: 8),
              _buildFilterChip(AppStrings.get('all', lang), 'all'),
            ],
          ),
        ),
        
        const SizedBox(height: 10),
        
        // 2. Type Toggle (Income/Expense)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<bool>(
            segments: [
               ButtonSegment(value: true, label: Text(AppStrings.get('expense', lang)), icon: const Icon(Icons.arrow_downward)),
               ButtonSegment(value: false, label: Text(AppStrings.get('income', lang)), icon: const Icon(Icons.arrow_upward)),
            ],
            selected: {_showExpenses},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _showExpenses = newSelection.first;
              });
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 3. Chart & List
        Expanded(
          child: Consumer<ExpenseProvider>(
            builder: (context, provider, _) {
              final transactions = _filterTransactions(provider.transactions);
              
              if (transactions.isEmpty) {
                return Center(child: Text(AppStrings.get('noData', lang)));
              }

              // Group by category
              Map<String, double> categoryTotals = {};
              double totalAmount = 0;
              for (var tx in transactions) {
                if (tx.isExpense == _showExpenses) {
                   categoryTotals[tx.categoryId] = (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
                   totalAmount += tx.amount;
                }
              }

              if (categoryTotals.isEmpty) {
                 return Center(child: Text(AppStrings.get('noData', lang)));
              }
              
              // Sort by value desc
              var sortedEntries = categoryTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return CustomScrollView(
                slivers: [
                   // Pie Chart Section
                   SliverToBoxAdapter(
                     child: SizedBox(
                       height: 220,
                       child: Stack(
                         alignment: Alignment.center,
                         children: [
                           PieChart(
                             PieChartData(
                               sectionsSpace: 2,
                               centerSpaceRadius: 50,
                               startDegreeOffset: -90,
                               sections: sortedEntries.map((entry) {
                                  final cat = Provider.of<CategoryProvider>(context, listen: false)
                                      .categories
                                      .firstWhere((c) => c.id == entry.key, 
                                        orElse: () => Category(id: 'unknown', name: '?', iconCodePoint: 0, colorValue: 0xFF9E9E9E));
                                  
                                  return PieChartSectionData(
                                    color: cat.color,
                                    value: entry.value,
                                    title: '${((entry.value / totalAmount) * 100).toStringAsFixed(0)}%',
                                    radius: 25, // Thinner ring
                                    showTitle: true,
                                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                  );
                               }).toList(),
                             ),
                           ),
                           Column(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Text(
                                 AppStrings.get(_showExpenses ? 'expense' : 'income', lang),
                                 style: const TextStyle(fontSize: 12, color: Colors.grey),
                               ),
                               Text(
                                 '${settings.currencySymbol}${totalAmount.toStringAsFixed(0)}',
                                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                               ),
                             ],
                           )
                         ],
                       ),
                     ),
                   ),
                   
                   // List Section
                   SliverPadding(
                     padding: const EdgeInsets.all(16),
                     sliver: SliverList(
                       delegate: SliverChildBuilderDelegate(
                         (context, index) {
                            final entry = sortedEntries[index];
                            final cat = Provider.of<CategoryProvider>(context, listen: false)
                                      .categories
                                      .firstWhere((c) => c.id == entry.key, 
                                        orElse: () => Category(id: 'unknown', name: '?', iconCodePoint: Icons.error.codePoint, colorValue: Colors.grey.toARGB32()));
                            
                            final percentage = entry.value / totalAmount;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.2), shape: BoxShape.circle),
                                        child: Icon(cat.icon, size: 16, color: cat.color),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      Text('${settings.currencySymbol}${entry.value.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                                    color: cat.color,
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 6,
                                  ),
                                ],
                              ),
                            );
                         },
                         childCount: sortedEntries.length,
                       ),
                     ),
                   )
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TRENDS TAB ---
  Widget _buildTrendsTab(BuildContext context, SettingsProvider settings, String lang) {
     return Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
           final transactions = _filterTransactions(provider.transactions);
           if (transactions.isEmpty) return Center(child: Text(AppStrings.get('noData', lang)));

           // Data Preparation
           Map<int, double> incomeData = {};
           Map<int, double> expenseData = {};
           double maxAmount = 0;
           
           bool isYearly = _selectedTimeFilter == 'year' || _selectedTimeFilter == 'all';
           int maxX = isYearly ? 12 : 31; 

           if (isYearly) {
             for (var tx in transactions) {
               int month = tx.date.month;
               if (tx.isExpense) {
                 expenseData[month] = (expenseData[month] ?? 0) + tx.amount;
               } else {
                 incomeData[month] = (incomeData[month] ?? 0) + tx.amount;
               }
             }
           } else {
             // Daily or Weekly
             for (var tx in transactions) {
               int key = tx.date.day;
               if (_selectedTimeFilter == 'week') {
                  key = tx.date.weekday;
                  maxX = 7;
               }
               
               if (tx.isExpense) {
                 expenseData[key] = (expenseData[key] ?? 0) + tx.amount;
               } else {
                 incomeData[key] = (incomeData[key] ?? 0) + tx.amount;
               }
             }
           }

           // Calculate Max for Y-Axis
           incomeData.forEach((_, v) { if(v > maxAmount) maxAmount = v; });
           expenseData.forEach((_, v) { if(v > maxAmount) maxAmount = v; });
           if (maxAmount == 0) maxAmount = 100; 

           // Build Bar Groups
           List<BarChartGroupData> barGroups = [];
           for (int i = 1; i <= maxX; i++) {
             // Only add group if there is data for this x? Or add all for correct spacing?
             // Adding all ensures correct date alignment
             final income = incomeData[i] ?? 0;
             final expense = expenseData[i] ?? 0;
             
             barGroups.add(
               BarChartGroupData(
                 x: i,
                 barRods: [
                   BarChartRodData(
                     toY: income,
                     color: Colors.tealAccent,
                     width: 6,
                     borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                   ),
                   BarChartRodData(
                     toY: expense,
                     color: Colors.redAccent,
                     width: 6,
                     borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                   ),
                 ],
               ),
             );
           }

           return Column(
             children: [
               const SizedBox(height: 20),
               // Legend
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   _buildLegendItem(AppStrings.get('income', lang), Colors.tealAccent),
                   const SizedBox(width: 20),
                   _buildLegendItem(AppStrings.get('expense', lang), Colors.redAccent),
                 ],
               ),
               const SizedBox(height: 20),
               
               // Controls
               SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip(AppStrings.get('week', lang), 'week'),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppStrings.get('month', lang), 'month'),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppStrings.get('year', lang), 'year'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

               Expanded(
                 child: Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16),
                   child: BarChart(
                     BarChartData(
                       gridData: FlGridData(
                         show: true, 
                         drawVerticalLine: false,
                         getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
                       ),
                       titlesData: FlTitlesData(
                         show: true,
                         rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                         topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                         bottomTitles: AxisTitles(
                           sideTitles: SideTitles(
                             showTitles: true,
                             reservedSize: 30,
                             interval: 1, // Show all logic handles skipping if filtered
                             getTitlesWidget: (value, meta) {
                               int idx = value.toInt();
                               if (idx < 1 || idx > maxX) return const Text('');
                               
                               // Optimization: Skip labels if too crowded (e.g. month view with 31 days)
                               if (_selectedTimeFilter == 'month' && idx % 5 != 0 && idx != 1 && idx != maxX) {
                                 return const Text('');
                               }

                               if (isYearly) {
                                 return Text(DateFormat('MMM').format(DateTime(2024, idx)), style: const TextStyle(fontSize: 10, color: Colors.grey));
                               } else if (_selectedTimeFilter == 'week') {
                                 const days = ['M','T','W','T','F','S','S'];
                                 return Text(days[idx-1], style: const TextStyle(fontSize: 10, color: Colors.grey));
                               } else {
                                 return Text(idx.toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
                               }
                             },
                           ),
                         ),
                         leftTitles: AxisTitles(
                           sideTitles: SideTitles(
                             showTitles: true,
                             reservedSize: 40,
                             getTitlesWidget: (value, meta) {
                               if (value == 0) return const Text('');
                               // Optimize Y axis labels
                               if (value > maxAmount) return const Text('');
                               return Text(compactNumber(value), style: const TextStyle(fontSize: 10, color: Colors.grey));
                             },
                           )
                         ),
                       ),
                       borderData: FlBorderData(show: false),
                       barGroups: barGroups,
                       maxY: maxAmount * 1.1,
                       barTouchData: BarTouchData(
                         touchTooltipData: BarTouchTooltipData(
                           getTooltipItem: (group, groupIndex, rod, rodIndex) {
                             final isExpense = rodIndex == 1;
                             return BarTooltipItem(
                               '${isExpense ? "Exp" : "Inc"}: ${settings.currencySymbol}${rod.toY.toStringAsFixed(0)}',
                               TextStyle(
                                 color: isExpense ? Colors.redAccent : Colors.tealAccent, 
                                 fontWeight: FontWeight.bold
                               ),
                             );
                           },
                         ),
                       ),
                     ),
                   ),
                 ),
               ),
               const SizedBox(height: 10),
             ],
           );
        }
     );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String compactNumber(double value) {
    if (value >= 1000000) return '${(value/1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value/1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _selectedTimeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF26A69A) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // Helper to filter transactions
  List<Transaction> _filterTransactions(List<Transaction> allTxs) {
    if (allTxs.isEmpty) return [];
    
    final now = DateTime.now();
    return allTxs.where((tx) {
      switch (_selectedTimeFilter) {
        case 'day':
          return tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day;
        case 'week':
           // Advanced week check (ISO week or last 7 days). Let's do ISO week logic approx
           // Get start of week (Monday)
           final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
           final endOfWeek = startOfWeek.add(const Duration(days: 7));
           return tx.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && tx.date.isBefore(endOfWeek);
        case 'month':
          return tx.date.year == now.year && tx.date.month == now.month;
        case 'year':
          return tx.date.year == now.year;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }
}
