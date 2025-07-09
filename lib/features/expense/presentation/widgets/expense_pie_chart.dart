import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/expense.dart';
import '../../../../core/utils/currency_utils.dart';

// Fixed color mapping for each default category (string)
const Map<String, Color> kCategoryColors = {
  'food': Colors.blue,
  'transportation': Colors.red,
  'entertainment': Colors.green,
  'shopping': Colors.orange,
  'health': Colors.purple,
  'education': Colors.teal,
  'utilities': Colors.brown,
  'rent': Colors.pink,
  'insurance': Colors.indigo,
  'other': Colors.cyan,
};

// Icon mapping for each default category (string)
const Map<String, IconData> kCategoryIcons = {
  'food': Icons.restaurant,
  'transportation': Icons.directions_car,
  'entertainment': Icons.movie,
  'shopping': Icons.shopping_bag,
  'health': Icons.health_and_safety,
  'education': Icons.school,
  'utilities': Icons.lightbulb,
  'rent': Icons.home,
  'insurance': Icons.security,
  'other': Icons.category,
};

class ExpensePieChart extends StatefulWidget {
  final Map<String, double> categoryBreakdown;
  final String title;

  const ExpensePieChart({
    super.key,
    required this.categoryBreakdown,
    required this.title,
  });

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.categoryBreakdown.values.fold(0.0, (a, b) => a + b);
    final currencyFormat = NumberFormat.simpleCurrency(
        locale: Localizations.localeOf(context).toString());
    if (total == 0) {
      return SizedBox(
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            const Text('No data to display'),
          ],
        ),
      );
    }
    final entries = widget.categoryBreakdown.entries
        .where((entry) => entry.value.abs() <= 1e7)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex =
                        response?.touchedSection?.touchedSectionIndex;
                  });
                },
              ),
              sections: List.generate(entries.length, (i) {
                final entry = entries[i];
                final percent = (entry.value / total * 100).toStringAsFixed(1);
                final color = kCategoryColors[entry.key] ?? Colors.grey;
                final isTouched = i == _touchedIndex;
                return PieChartSectionData(
                  color: color,
                  value: entry.value,
                  title: isTouched ? '' : '$percent%',
                  radius: isTouched ? 70 : 60,
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  badgeWidget: isTouched
                      ? _buildTooltip(context, entry.key, entry.value, percent,
                          color, currencyFormat)
                      : null,
                  badgePositionPercentageOffset: 1.2,
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 32,
            ),
            swapAnimationDuration: const Duration(milliseconds: 600),
            swapAnimationCurve: Curves.easeInOut,
          ),
        ),
        const SizedBox(height: 20),
        // Horizontal, scrollable legend with icons and tap-to-highlight
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final entry = entries[i];
              final percent = (entry.value / total * 100).toStringAsFixed(1);
              final amount =
                  CurrencyUtils.formatAbbreviatedCurrency(entry.value);
              final color = kCategoryColors[entry.key] ?? Colors.grey;
              final icon = kCategoryIcons[entry.key] ?? Icons.category;
              final isSelected = i == _touchedIndex;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    setState(() {
                      _touchedIndex = i;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: color.withOpacity(isSelected ? 0.9 : 0.5),
                          width: isSelected ? 2 : 1),
                      color: isSelected ? color.withOpacity(0.12) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          _capitalize(entry.key),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          amount,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($percent%)',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTooltip(BuildContext context, String category, double value,
      String percent, Color color, NumberFormat currencyFormat) {
    final icon = kCategoryIcons[category] ?? Icons.category;
    return Card(
      color: color.withOpacity(0.95),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              _capitalize(category),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              CurrencyUtils.formatAbbreviatedCurrency(value),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 6),
            Text(
              '($percent%)',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class ExpenseTrendChart extends StatelessWidget {
  final Map<DateTime, Map<String, double>> dailyTotals;
  final String title;
  final bool showBalance;

  const ExpenseTrendChart({
    super.key,
    required this.dailyTotals,
    this.title = 'Daily Trend',
    this.showBalance = true,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyTotals.isEmpty) {
      return SizedBox(
        height: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            const Text('No data to display'),
          ],
        ),
      );
    }
    final days = dailyTotals.keys.toList()..sort();
    final expenses =
        days.map((d) => dailyTotals[d]!['expenses'] ?? 0.0).toList();
    final income = days.map((d) => dailyTotals[d]!['income'] ?? 0.0).toList();
    final balance = days.map((d) => dailyTotals[d]!['balance'] ?? 0.0).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (days.length / 6).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= days.length)
                        return const SizedBox.shrink();
                      final d = days[idx];
                      return Text('${d.day}/${d.month}',
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (int i = 0; i < expenses.length; i++)
                      FlSpot(i.toDouble(), expenses[i])
                  ],
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                  isStrokeCapRound: true,
                  dashArray: [4, 2],
                  // Expenses
                ),
                LineChartBarData(
                  spots: [
                    for (int i = 0; i < income.length; i++)
                      FlSpot(i.toDouble(), income[i])
                  ],
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                  isStrokeCapRound: true,
                  // Income
                ),
                if (showBalance)
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < balance.length; i++)
                        FlSpot(i.toDouble(), balance[i])
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                    isStrokeCapRound: true,
                    // Balance
                  ),
              ],
              minY: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: Colors.red, label: 'Expenses'),
            const SizedBox(width: 12),
            _LegendDot(color: Colors.green, label: 'Income'),
            if (showBalance) ...[
              const SizedBox(width: 12),
              _LegendDot(color: Colors.blue, label: 'Balance'),
            ],
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
