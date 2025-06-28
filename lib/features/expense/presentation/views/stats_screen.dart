import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_providers.dart';
import '../widgets/expense_summary_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(expenseStatsNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: statsAsync.when(
        data: (stats) => ExpenseSummaryCard(stats: stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
