// This file defines the ExpenseSummaryCard widget, which displays financial summaries.
// It shows total expenses, income, balance, and other key financial metrics.
// This demonstrates proper data visualization and financial information display.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/platform_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../budget/presentation/providers/budget_providers.dart';

/// A card widget that displays key financial metrics and summaries.
/// Shows total expenses, income, balance, and other important financial data.
class ExpenseSummaryCard extends ConsumerWidget {
  final Map<String, dynamic> stats;

  const ExpenseSummaryCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    // Extract financial data from the stats map
    final totalExpenses = stats['totalExpenses'] as double? ?? 0.0;
    final totalIncome = stats['totalIncome'] as double? ?? 0.0;
    final balance = stats['balance'] as double? ?? 0.0;
    final monthlyExpenses = stats['monthlyExpenses'] as double? ?? 0.0;
    final monthlyIncome = stats['monthlyIncome'] as double? ?? 0.0;
    final monthlyBalance = stats['monthlyBalance'] as double? ?? 0.0;

    return Card(
      // Add elevation for visual prominence
      elevation: AppConstants.shadowM,
      // Use platform-appropriate styling
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header with title
            _buildHeader(context, localizations),
            const SizedBox(height: AppConstants.paddingL),

            // Overall financial summary
            _buildOverallSummary(
              context,
              totalExpenses,
              totalIncome,
              balance,
              localizations,
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Monthly financial summary
            _buildMonthlySummary(
              context,
              monthlyExpenses,
              monthlyIncome,
              monthlyBalance,
              localizations,
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Budget indicators
            _buildBudgetIndicators(context, ref),
          ],
        ),
      ),
    );
  }

  /// Builds the card header with title and optional action button.
  /// Provides context about what the card displays.
  Widget _buildHeader(BuildContext context, AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Card title
        Text(
          'Financial Summary',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        // Optional refresh button
        IconButton(
          onPressed: () {
            // Trigger a refresh of the financial data
            // This could be implemented to refresh the stats
          },
          icon: Icon(
            PlatformWidgets.isIOS ? CupertinoIcons.refresh : Icons.refresh,
            size: AppConstants.iconSizeM,
          ),
          tooltip: 'Refresh data',
        ),
      ],
    );
  }

  /// Builds the overall financial summary section.
  /// Shows total expenses, income, and balance for all time.
  Widget _buildOverallSummary(
    BuildContext context,
    double totalExpenses,
    double totalIncome,
    double balance,
    AppLocalizations localizations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Overall Summary',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.paddingM),

        // Financial metrics in a grid layout
        Row(
          children: [
            // Total Expenses
            Expanded(
              child: _buildMetricTile(
                context,
                'Total Expenses',
                CurrencyUtils.formatCurrency(totalExpenses),
                const Color(AppConstants.errorColor),
                PlatformWidgets.isIOS
                    ? CupertinoIcons.minus_circle
                    : Icons.remove_circle,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),

            // Total Income
            Expanded(
              child: _buildMetricTile(
                context,
                'Total Income',
                CurrencyUtils.formatCurrency(totalIncome),
                const Color(AppConstants.successColor),
                PlatformWidgets.isIOS
                    ? CupertinoIcons.plus_circle
                    : Icons.add_circle,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),

            // Balance
            Expanded(
              child: _buildMetricTile(
                context,
                'Balance',
                CurrencyUtils.formatCurrency(balance),
                balance >= 0
                    ? const Color(AppConstants.successColor)
                    : const Color(AppConstants.errorColor),
                PlatformWidgets.isIOS
                    ? CupertinoIcons.money_dollar
                    : Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the monthly financial summary section.
  /// Shows monthly expenses, income, and balance for the current month.
  Widget _buildMonthlySummary(
    BuildContext context,
    double monthlyExpenses,
    double monthlyIncome,
    double monthlyBalance,
    AppLocalizations localizations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'This Month',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.paddingM),

        // Monthly financial metrics
        Row(
          children: [
            // Monthly Expenses
            Expanded(
              child: _buildMetricTile(
                context,
                'Expenses',
                CurrencyUtils.formatCurrency(monthlyExpenses),
                const Color(AppConstants.errorColor),
                PlatformWidgets.isIOS
                    ? CupertinoIcons.calendar
                    : Icons.calendar_today,
                isCompact: true,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),

            // Monthly Income
            Expanded(
              child: _buildMetricTile(
                context,
                'Income',
                CurrencyUtils.formatCurrency(monthlyIncome),
                const Color(AppConstants.successColor),
                PlatformWidgets.isIOS
                    ? CupertinoIcons.calendar_badge_plus
                    : Icons.calendar_view_month,
                isCompact: true,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),

            // Monthly Balance
            Expanded(
              child: _buildMetricTile(
                context,
                'Balance',
                CurrencyUtils.formatCurrency(monthlyBalance),
                monthlyBalance >= 0
                    ? const Color(AppConstants.successColor)
                    : const Color(AppConstants.errorColor),
                PlatformWidgets.isIOS
                    ? CupertinoIcons.chart_bar
                    : Icons.trending_up,
                isCompact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds an individual metric tile with icon, label, and value.
  /// Provides a consistent way to display financial metrics.
  Widget _buildMetricTile(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(
          isCompact ? AppConstants.paddingS : AppConstants.paddingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Icon
          Icon(
            icon,
            color: color,
            size: isCompact ? AppConstants.iconSizeS : AppConstants.iconSizeM,
          ),
          SizedBox(
              height:
                  isCompact ? AppConstants.paddingXS : AppConstants.paddingS),

          // Label
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
              height:
                  isCompact ? AppConstants.paddingXS : AppConstants.paddingS),

          // Value
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Builds the budget indicators section showing budget status.
  Widget _buildBudgetIndicators(BuildContext context, WidgetRef ref) {
    return ref.watch(activeBudgetsProvider).when(
          data: (budgets) {
            if (budgets.isEmpty) {
              return const SizedBox.shrink();
            }

            final budgetsWithAlerts = budgets.where((budget) => 
              budget.isApproachingLimit || budget.isExceeded
            ).toList();

            final exceededBudgets = budgets.where((budget) => 
              budget.isExceeded
            ).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                Text(
                  'Budget Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingM),

                // Budget indicators
                Row(
                  children: [
                    // Total budgets
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        'Total Budgets',
                        budgets.length.toString(),
                        Colors.blue,
                        PlatformWidgets.isIOS
                            ? CupertinoIcons.creditcard
                            : Icons.account_balance_wallet,
                        isCompact: true,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingM),

                    // Budgets with alerts
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        'Alerts',
                        budgetsWithAlerts.length.toString(),
                        budgetsWithAlerts.isNotEmpty ? Colors.orange : Colors.green,
                        PlatformWidgets.isIOS
                            ? CupertinoIcons.exclamationmark_triangle
                            : Icons.warning,
                        isCompact: true,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingM),

                    // Exceeded budgets
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        'Exceeded',
                        exceededBudgets.length.toString(),
                        exceededBudgets.isNotEmpty ? Colors.red : Colors.green,
                        PlatformWidgets.isIOS
                            ? CupertinoIcons.xmark_circle
                            : Icons.cancel,
                        isCompact: true,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        );
  }
}
