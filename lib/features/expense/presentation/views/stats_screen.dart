import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_providers.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/expense_pie_chart.dart' show ExpenseTrendChart;
import '../../domain/entities/expense.dart';

class SmartTipsCard extends ConsumerWidget {
  const SmartTipsCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipsAsync = ref.watch(smartTipsNotifierProvider);
    return tipsAsync.when(
      data: (tips) => Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        margin: const EdgeInsets.only(bottom: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb,
                      color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: 8),
                  Text('Smart Tips',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 10),
              ...tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 18)),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(expenseStatsNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: statsAsync.when(
        data: (stats) {
          final expenseBreakdown =
              stats['categoryExpenseBreakdown'] as Map<String, double>? ?? {};
          final incomeBreakdown =
              stats['categoryIncomeBreakdown'] as Map<String, double>? ?? {};
          final dailyTotals =
              stats['dailyTotals'] as Map<DateTime, Map<String, double>>? ?? {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SmartTipsCard(),
                ExpenseTrendChart(
                    dailyTotals: dailyTotals, title: 'Daily Cash Flow Trend'),
                const SizedBox(height: 32),
                ExpenseSummaryCard(stats: stats),
                const SizedBox(height: 24),
                ExpensePieChart(
                  categoryBreakdown: expenseBreakdown,
                  title: 'Expenses by Category',
                ),
                const SizedBox(height: 32),
                ExpensePieChart(
                  categoryBreakdown: incomeBreakdown,
                  title: 'Income by Category',
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
