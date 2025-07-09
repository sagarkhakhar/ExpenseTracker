import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/expense.dart';

// Fixed color mapping for each category
const Map<ExpenseCategory, Color> kCategoryColors = {
  ExpenseCategory.food: Colors.blue,
  ExpenseCategory.transportation: Colors.red,
  ExpenseCategory.entertainment: Colors.green,
  ExpenseCategory.shopping: Colors.orange,
  ExpenseCategory.health: Colors.purple,
  ExpenseCategory.education: Colors.teal,
  ExpenseCategory.utilities: Colors.brown,
  ExpenseCategory.rent: Colors.pink,
  ExpenseCategory.insurance: Colors.indigo,
  ExpenseCategory.other: Colors.cyan,
};

// Icon mapping for each category
const Map<ExpenseCategory, IconData> kCategoryIcons = {
  ExpenseCategory.food: Icons.restaurant,
  ExpenseCategory.transportation: Icons.directions_car,
  ExpenseCategory.entertainment: Icons.movie,
  ExpenseCategory.shopping: Icons.shopping_bag,
  ExpenseCategory.health: Icons.health_and_safety,
  ExpenseCategory.education: Icons.school,
  ExpenseCategory.utilities: Icons.lightbulb,
  ExpenseCategory.rent: Icons.home,
  ExpenseCategory.insurance: Icons.security,
  ExpenseCategory.other: Icons.category,
};

class ExpensePieChart extends StatefulWidget {
  final Map<ExpenseCategory, double> categoryBreakdown;
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
      return Column(
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          const Text('No data to display'),
        ],
      );
    }
    final entries = widget.categoryBreakdown.entries.toList();
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
              final amount = currencyFormat.format(entry.value);
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
                          '${entry.key.name[0].toUpperCase()}${entry.key.name.substring(1)}',
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

  Widget _buildTooltip(BuildContext context, ExpenseCategory category,
      double value, String percent, Color color, NumberFormat currencyFormat) {
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
              '${category.name[0].toUpperCase()}${category.name.substring(1)}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              currencyFormat.format(value),
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
}
