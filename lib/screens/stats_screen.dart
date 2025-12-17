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
           // We'll show last 7 days usually, or group by month if filter is Year.
           // For MVP, let's show Daily Spending for the selected Time Filter range.
           // If "All" or "Year", maybe show Monthly.

           // Simplify: Always show Daily Bar Chart for the filtered transactions.
           // If too many days, it might be crowded. Let's limit to last 7 days chart specifically for trends, 
           // or aggregations.
           
           // Improving: Use the existing _selectedTimeFilter to decide chart granularity.
           // Day -> Hourly? (Too detailed).
           // Week -> Daily (7 bars).
           // Month -> Daily (~30 bars).
           // Year -> Monthly (12 bars).
           
           final transactions = _filterTransactions(provider.transactions);
           if (transactions.isEmpty) return Center(child: Text(AppStrings.get('noData', lang)));

           // Prepare Data
           Map<int, double> groupedData = {}; // Index -> Amount. Index depends on grouping strategy.
           double maxAmount = 0;
           List<String> labels = [];

           // Strategy switch
           if (_selectedTimeFilter == 'year' || _selectedTimeFilter == 'all') {
             // Monthly Grouping
             for (var tx in transactions) {
               // Only show what user selected (Expense vs Income) or both? 
               // usually expenses are tracked. Let's respect _showExpenses toggle from other tab? 
               // Or force expenses? Let's respect the toggle.
               if (tx.isExpense == _showExpenses) {
                  int month = tx.date.month;
                  groupedData[month] = (groupedData[month] ?? 0) + tx.amount;
               }
             }
             // Labels: 1..12
             for(int i=1; i<=12; i++) {
               labels.add(DateFormat('MMM').format(DateTime(2024, i))); // Short Month Name
               if ((groupedData[i] ?? 0) > maxAmount) maxAmount = groupedData[i]!;
             }

           } else {
             // Daily Grouping (Week/Month)
             for (var tx in transactions) {
               if (tx.isExpense == _showExpenses) {
                 // For simplified chart, let's map dates to a simple index list if sorted?
                 // Better: "Last 7 days" style or strict calendar days.
                 
                 // Let's do a strict grouping by "Day of Month" for Month filter, or "Day of Week" for Week filter.
                 int key = tx.date.day; // Simple day key
                 if (_selectedTimeFilter == 'week') {
                   key = tx.date.weekday; // 1..7
                 }
                 
                 // If Month filter, keys are 1..31.
                 groupedData[key] = (groupedData[key] ?? 0) + tx.amount;
               }
             }
              // Calc Max
             groupedData.forEach((_, v) { if(v > maxAmount) maxAmount = v; });
           }

           // Build Bars
           List<BarChartGroupData> barGroups = [];
           
           if (_selectedTimeFilter == 'year' || _selectedTimeFilter == 'all') {
              for (int i = 1; i <= 12; i++) {
                barGroups.add(
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: groupedData[i] ?? 0,
                        color: _showExpenses ? Colors.redAccent : Colors.teal,
                        width: 12,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ],
                  )
                );
              }
           } else if (_selectedTimeFilter == 'week') {
             // 1..7 (Mon..Sun)
              for (int i = 1; i <= 7; i++) {
                barGroups.add(
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: groupedData[i] ?? 0,
                        color: _showExpenses ? Colors.redAccent : Colors.teal,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      )
                    ],
                  )
                );
              }
           } else {
             // Month / Day (Show all days found or 1..31?)
             // 1..31 is a lot of bars. 
             // If data is sparse, only show populated? Or all.
             // FL Chart handles scrolling if needed, but sticky is complex.
             // Let's standard 1..31 for Month.
             int daysInMonth = 30; // approx
             if (transactions.isNotEmpty) {
                // Get month of first tx
                final d = transactions.first.date;
                daysInMonth = DateUtils.getDaysInMonth(d.year, d.month);
             }

             for (int i = 1; i <= daysInMonth; i++) {
                  barGroups.add(
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: groupedData[i] ?? 0,
                          color: _showExpenses ? Colors.redAccent : Colors.teal,
                          width: 4, // thin bars
                          borderRadius: BorderRadius.circular(2),
                        )
                      ],
                    )
                  );
             }
           }

           return Column(
             children: [
               const SizedBox(height: 20),
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 16),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(AppStrings.get(_showExpenses ? 'expense' : 'income', lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     _buildFilterChip(AppStrings.get(_selectedTimeFilter, lang), _selectedTimeFilter), // Just visual indicator or re-use row?
                     // Reuse row in Trends? Usually trends needs its own filter controls if different.
                     // But for simplicity, we share the state `_selectedTimeFilter` across tabs?
                     // Yes, let's share it. But we need the controls here too or move controls to AppBar?
                     // Moving controls to AppBar is complex with TabBar.
                     // Let's duplicate controls row or just put it in common header?
                     // Scaffold body is TabBarView.
                     // We can put the controls ABOVE TabBar? No.
                     // Let's just put the controls inside this tab too.
                   ],
                 ),
               ),
               const SizedBox(height: 10),
               // Control Row (Duplicate for convenience)
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
                const SizedBox(height: 40),
               
               // CHART
               AspectRatio(
                 aspectRatio: 1.5,
                 child: BarChart(
                   BarChartData(
                     alignment: BarChartAlignment.spaceAround,
                     maxY: maxAmount * 1.1, // +10% headroom
                     titlesData: FlTitlesData(
                       show: true,
                       bottomTitles: AxisTitles(
                         sideTitles: SideTitles(
                           showTitles: true,
                           getTitlesWidget: (value, meta) {
                             if (_selectedTimeFilter == 'year' || _selectedTimeFilter == 'all') {
                               // Month Names
                               int idx = value.toInt();
                               if(idx >= 1 && idx <= 12) {
                                  // Show every 2nd or 3rd if crowded?
                                  return Text(DateFormat('MMM').format(DateTime(2024, idx)), style: const TextStyle(fontSize: 10));
                               }
                             } else if (_selectedTimeFilter == 'week') {
                               // Week Names (M, T, W...)
                               const days = ['M','T','W','T','F','S','S'];
                               int idx = value.toInt();
                               if (idx >= 1 && idx <= 7) return Text(days[idx-1], style: const TextStyle(fontSize: 10));
                             } else {
                               // Days 1..31. Show every 5th?
                               int idx = value.toInt();
                               if (idx % 5 == 0 || idx == 1) return Text(idx.toString(), style: const TextStyle(fontSize: 10));
                             }
                             return const Text('');
                           },
                           reservedSize: 30,
                         )
                       ),
                       leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                     ),
                     gridData: const FlGridData(show: false),
                     borderData: FlBorderData(show: false),
                     barGroups: barGroups,
                   )
                 ),
               ),
             ],
           );
        }
     );
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
