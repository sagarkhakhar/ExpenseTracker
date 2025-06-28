import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_providers.dart';
import '../widgets/expense_summary_card.dart';
import '../widgets/expense_pie_chart.dart';
import '../../domain/entities/expense.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(expenseStatsNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: statsAsync.when(
        data: (stats) {
          final expenseBreakdown = stats['categoryExpenseBreakdown']
                  as Map<ExpenseCategory, double>? ??
              {};
          final incomeBreakdown = stats['categoryIncomeBreakdown']
                  as Map<ExpenseCategory, double>? ??
              {};
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
