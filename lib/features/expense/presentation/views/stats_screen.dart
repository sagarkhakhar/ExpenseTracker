// This file defines the StatsScreen, which displays detailed financial statistics and charts.
// It shows spending patterns, category breakdowns, and trends over time.
// This demonstrates data visualization and statistical analysis in the presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/platform_widgets.dart';
import '../providers/expense_providers.dart';
import '../widgets/expense_pie_chart.dart';
import '../../../../l10n/app_localizations.dart';

/// The statistics screen that displays detailed financial analysis and charts.
/// This screen provides insights into spending patterns and financial trends.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    // Watch the stats provider to get real-time financial statistics
    final statsAsync = ref.watch(expenseStatsNotifierProvider);

    return statsAsync.when(
      // Loading state: show a loading indicator
      loading: () => Center(
        child: PlatformWidgets.isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      ),
      // Error state: show error message with retry option
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(localizations.errorLoadingExpenses),
            const SizedBox(height: AppConstants.paddingM),
            PlatformWidgets.buildButton(
              context: context,
              onPressed: () {
                // Retry loading statistics
                ref.refresh(expenseStatsNotifierProvider);
              },
              child: Text(localizations.retry),
            ),
          ],
        ),
      ),
      // Data state: show comprehensive statistics and charts
      data: (stats) {
        final totalExpenses = stats['totalExpenses'] as double? ?? 0.0;
        final totalIncome = stats['totalIncome'] as double? ?? 0.0;
        final balance = stats['balance'] as double? ?? 0.0;
        final categoryExpenseBreakdown =
            stats['categoryExpenseBreakdown'] as Map<String, double>? ?? {};
        final categoryIncomeBreakdown =
            stats['categoryIncomeBreakdown'] as Map<String, double>? ?? {};
        final dailyTotals =
            stats['dailyTotals'] as Map<DateTime, Map<String, double>>? ?? {};
        final weeklyTotals =
            stats['weeklyTotals'] as Map<int, Map<String, double>>? ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main financial summary section
              _buildFinancialSummary(
                  context, localizations, totalExpenses, totalIncome, balance),
              const SizedBox(height: AppConstants.paddingL),

              // Expense category breakdown with pie chart
              if (categoryExpenseBreakdown.isNotEmpty) ...[
                _buildCategorySection(
                  context,
                  localizations,
                  categoryExpenseBreakdown,
                  'Expense Categories',
                  const Color(AppConstants.errorColor),
                ),
                const SizedBox(height: AppConstants.paddingL),
              ],

              // Income category breakdown
              if (categoryIncomeBreakdown.isNotEmpty) ...[
                _buildCategorySection(
                  context,
                  localizations,
                  categoryIncomeBreakdown,
                  'Income Categories',
                  const Color(AppConstants.successColor),
                ),
                const SizedBox(height: AppConstants.paddingL),
              ],

              // Daily trend analysis
              if (dailyTotals.isNotEmpty) ...[
                _buildTrendSection(
                  context,
                  localizations,
                  dailyTotals,
                  'Daily Trend',
                ),
                const SizedBox(height: AppConstants.paddingL),
              ],

              // Weekly trend analysis
              if (weeklyTotals.isNotEmpty) ...[
                _buildTrendSection(
                  context,
                  localizations,
                  weeklyTotals,
                  'Weekly Trend',
                ),
                const SizedBox(height: AppConstants.paddingL),
              ],

              // Smart tips section
              _buildSmartTipsSection(context, ref, localizations),
            ],
          ),
        );
      },
    );
  }

  /// Builds the main financial summary section showing total expenses, income, and balance.
  Widget _buildFinancialSummary(
    BuildContext context,
    AppLocalizations localizations,
    double totalExpenses,
    double totalIncome,
    double balance,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    context,
                    'Total Expenses',
                    CurrencyUtils.formatCurrency(totalExpenses),
                    const Color(AppConstants.errorColor),
                  ),
                ),
                Expanded(
                  child: _buildSummaryTile(
                    context,
                    'Total Income',
                    CurrencyUtils.formatCurrency(totalIncome),
                    const Color(AppConstants.successColor),
                  ),
                ),
                Expanded(
                  child: _buildSummaryTile(
                    context,
                    'Balance',
                    CurrencyUtils.formatCurrency(balance),
                    balance >= 0
                        ? const Color(AppConstants.successColor)
                        : const Color(AppConstants.errorColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a category breakdown section with pie chart visualization.
  Widget _buildCategorySection(
    BuildContext context,
    AppLocalizations localizations,
    Map<String, double> categoryData,
    String title,
    Color primaryColor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.paddingM),

            // Pie chart visualization with proper constraints
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: ExpensePieChart(
                categoryBreakdown: categoryData,
                title: title,
              ),
            ),
            const SizedBox(height: AppConstants.paddingM),

            // Category list with amounts
            ...categoryData.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingXS),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(
                        CurrencyUtils.formatCurrency(entry.value),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Builds a trend analysis section showing spending patterns over time.
  Widget _buildTrendSection(
    BuildContext context,
    AppLocalizations localizations,
    Map<dynamic, Map<String, double>> trendData,
    String title,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.paddingM),

            // Simple bar chart representation
            ...trendData.entries.take(7).map((entry) {
              final data = entry.value;
              final expenses = data['expenses'] ?? 0.0;
              final income = data['income'] ?? 0.0;
              final maxValue =
                  [expenses, income].reduce((a, b) => a > b ? a : b);

              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.paddingXS),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            _formatDateForTrend(entry.key),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              if (expenses > 0) ...[
                                Expanded(
                                  flex: (expenses / maxValue * 100).round(),
                                  child: Container(
                                    height: 20,
                                    color: const Color(AppConstants.errorColor),
                                    child: Center(
                                      child: Text(
                                        CurrencyUtils.formatAbbreviatedCurrency(
                                            expenses),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (income > 0) ...[
                                Expanded(
                                  flex: (income / maxValue * 100).round(),
                                  child: Container(
                                    height: 20,
                                    color: const Color(AppConstants.successColor),
                                    child: Center(
                                      child: Text(
                                        CurrencyUtils.formatAbbreviatedCurrency(
                                            income),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Builds the smart tips section that provides personalized financial advice.
  Widget _buildSmartTipsSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localizations,
  ) {
    return ref.watch(smartTipsNotifierProvider).when(
          data: (tips) => Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.smartTips,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  ...tips.map((tip) => Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.paddingXS),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Color(AppConstants.warningColor),
                              size: 16,
                            ),
                            const SizedBox(width: AppConstants.paddingS),
                            Expanded(
                              child: Text(tip),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingM),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Text('Error loading tips: $error'),
            ),
          ),
        );
  }

  /// Builds a summary tile showing a label and value with color coding.
  Widget _buildSummaryTile(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.paddingXS),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Formats date for trend display to prevent text wrapping.
  /// Returns a compact date format suitable for small spaces.
  String _formatDateForTrend(dynamic dateKey) {
    if (dateKey is DateTime) {
      return '${dateKey.month}/${dateKey.day}';
    } else if (dateKey is String) {
      // Handle string dates by parsing them
      try {
        final date = DateTime.parse(dateKey);
        return '${date.month}/${date.day}';
      } catch (e) {
        // Fallback to original string if parsing fails
        return dateKey.toString().split(' ').first;
      }
    }
    // Fallback for other types
    return dateKey.toString().split(' ').first;
  }

  /// Formats week number for trend display to prevent text wrapping.
  /// Returns a compact week format suitable for small spaces.
  String _formatWeekForTrend(dynamic weekKey) {
    if (weekKey is int) {
      return 'Week $weekKey';
    } else if (weekKey is String) {
      // If it's already a formatted string, return as is
      return weekKey;
    }
    // Fallback for other types
    return weekKey.toString();
  }
}
