import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/platform_widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';

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

/// Pie chart for expense/income breakdown by category.
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
        height: AppConstants.height120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.paddingM),
            Text(AppLocalizations.of(context)!.noData),
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
        const SizedBox(height: AppConstants.paddingM),
        SizedBox(
          height: AppConstants.height220,
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
                  radius: isTouched ? 70.0 : 60.0, // Ensure double
                  titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  badgeWidget: isTouched
                      ? _buildTooltip(context, entry.key, entry.value, percent,
                          color, currencyFormat)
                      : null,
                  badgePositionPercentageOffset: 1.2,
                );
              }),
              sectionsSpace: 2.0, // Ensure double
              centerSpaceRadius: 32.0, // Ensure double
            ),
            swapAnimationDuration: const Duration(milliseconds: 600),
            swapAnimationCurve: Curves.easeInOut,
          ),
        ),
        const SizedBox(height: AppConstants.paddingL),
        // Horizontal, scrollable legend with icons and tap-to-highlight
        SizedBox(
          height: AppConstants.height56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppConstants.paddingM),
            itemBuilder: (context, i) {
              final entry = entries[i];
              final percent = (entry.value / total * 100).toStringAsFixed(1);
              final amount =
                  CurrencyUtils.formatAbbreviatedCurrency(entry.value);
              final color = kCategoryColors[entry.key] ?? Colors.grey;
              final icon = kCategoryIcons[entry.key] ?? Icons.category;
              final isSelected = i == _touchedIndex;
              return Semantics(
                label: '${_capitalize(entry.key)}, $amount, $percent%',
                button: true,
                child: PlatformWidgets.isIOS
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            _touchedIndex = i;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingM,
                              vertical: AppConstants.paddingS),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppConstants.radiusL),
                            border: Border.all(
                                color: color.withAlpha(
                                    ((isSelected ? 0.9 : 0.5) * 255).toInt()),
                                width: isSelected ? 2.0 : 1.0),
                            color: isSelected
                                ? color.withAlpha((0.12 * 255).toInt())
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: color, size: 20),
                              const SizedBox(width: AppConstants.paddingS),
                              Text(
                                _capitalize(entry.key),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: AppConstants.paddingS),
                              Text(
                                amount,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(width: AppConstants.paddingXS),
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
                      )
                    : Material(
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
                                horizontal: AppConstants.paddingM,
                                vertical: AppConstants.paddingS),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppConstants.radiusL),
                              border: Border.all(
                                  color: color.withAlpha(
                                      ((isSelected ? 0.9 : 0.5) * 255).toInt()),
                                  width: isSelected ? 2.0 : 1.0),
                              color: isSelected
                                  ? color.withAlpha((0.12 * 255).toInt())
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, color: color, size: 20),
                                const SizedBox(width: AppConstants.paddingS),
                                Text(
                                  _capitalize(entry.key),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: AppConstants.paddingS),
                                Text(
                                  amount,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(width: AppConstants.paddingXS),
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
    if (PlatformWidgets.isIOS) {
      return Container(
        decoration: BoxDecoration(
          color: color.withAlpha((0.95 * 255).toInt()),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM, vertical: AppConstants.paddingS),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: AppConstants.paddingS),
            Text(
              _capitalize(category),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Text(
              CurrencyUtils.formatAbbreviatedCurrency(value),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(width: AppConstants.paddingS),
            Text(
              '($percent%)',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      );
    } else {
      return Card(
        color: color.withAlpha((0.95 * 255).toInt()),
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingS),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: AppConstants.paddingS),
              Text(
                _capitalize(category),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Text(
                CurrencyUtils.formatAbbreviatedCurrency(value),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(width: AppConstants.paddingS),
              Text(
                '($percent%)',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Line chart for daily expense/income/balance trends.
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
    final localizations = AppLocalizations.of(context)!;
    if (dailyTotals.isEmpty) {
      return SizedBox(
        height: AppConstants.height120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.paddingM),
            Text(localizations.noData),
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
        const SizedBox(height: AppConstants.paddingM),
        SizedBox(
          height: AppConstants.height220,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (days.length / 6).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= days.length) {
                        return const SizedBox.shrink();
                      }
                      final d = days[idx];
                      return Text('${d.day}/${d.month}',
                          style: Theme.of(context).textTheme.bodySmall);
                    },
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  dotData: const FlDotData(show: false),
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
                  dotData: const FlDotData(show: false),
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
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                    isStrokeCapRound: true,
                    // Balance
                  ),
              ],
              minY: 0,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.paddingL),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _LegendDot(color: Colors.red, label: 'Expense'),
            const SizedBox(width: AppConstants.paddingM),
            const _LegendDot(color: Colors.green, label: 'Income'),
            if (showBalance) ...[
              const SizedBox(width: AppConstants.paddingM),
              // TODO: Add 'balance' to ARB/localizations if needed
              const _LegendDot(color: Colors.blue, label: 'Balance'),
            ],
          ],
        ),
      ],
    );
  }
}

/// Legend dot for chart legends.
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: AppConstants.iconSizeS,
            height: AppConstants.iconSizeS,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: AppConstants.paddingXS),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
