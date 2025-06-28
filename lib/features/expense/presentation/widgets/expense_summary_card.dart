import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/expense.dart';

class ExpenseSummaryCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const ExpenseSummaryCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalExpenses = stats['totalExpenses'] ?? 0.0;
    final totalIncome = stats['totalIncome'] ?? 0.0;
    final balance = stats['balance'] ?? 0.0;
    final categoryBreakdown =
        stats['categoryBreakdown'] as Map<ExpenseCategory, double>? ?? {};

    return Card(
      margin: const EdgeInsets.all(AppConstants.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryTile(
                  label: 'Expenses',
                  value: CurrencyUtils.formatCurrency(totalExpenses),
                  color: AppConstants.errorColor,
                ),
                _SummaryTile(
                  label: 'Income',
                  value: CurrencyUtils.formatCurrency(totalIncome),
                  color: AppConstants.successColor,
                ),
                _SummaryTile(
                  label: 'Balance',
                  value: CurrencyUtils.formatCurrency(balance),
                  color: AppConstants.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingM),
            Text('By Category', style: AppTextStyles.body2),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  categoryBreakdown.entries.map((entry) {
                    return Chip(
                      label: Text(
                        '${entry.key.name}: ${CurrencyUtils.formatCurrency(entry.value)}',
                      ),
                      backgroundColor: AppConstants.primaryColor.withOpacity(
                        0.1,
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.heading3.copyWith(color: color)),
      ],
    );
  }
}
