// This file defines the EnhancedStatsScreen, which displays enhanced financial statistics and analytics.
// It shows spending trends, financial goals, and advanced visualizations.
// This demonstrates enhanced data visualization and statistical analysis in the presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/platform_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/statistics_providers.dart';
import '../widgets/trend_chart_widget.dart';
import '../widgets/goal_tracker_widget.dart';
import '../widgets/category_breakdown_widget.dart';

/// The enhanced statistics screen that displays advanced financial analysis and charts.
/// This screen provides detailed insights into spending patterns, financial goals, and trends.
class EnhancedStatsScreen extends ConsumerWidget {
  const EnhancedStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    // Watch the enhanced stats provider to get real-time enhanced statistics
    final enhancedStatsAsync = ref.watch(enhancedStatsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Enhanced Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(enhancedStatsNotifierProvider);
            },
          ),
        ],
      ),
      body: enhancedStatsAsync.when(
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
              Text('Error loading enhanced statistics: $error'),
              const SizedBox(height: AppConstants.paddingM),
              PlatformWidgets.buildButton(
                context: context,
                onPressed: () {
                  ref.refresh(enhancedStatsNotifierProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        // Data state: show comprehensive enhanced statistics and charts
        data: (enhancedStats) {
          final goals = enhancedStats['goals'] as List? ?? [];
          final activeGoals = enhancedStats['activeGoals'] as List? ?? [];
          final completedGoals = enhancedStats['completedGoals'] as List? ?? [];
          final trends = enhancedStats['trends'] as List? ?? [];
          final latestTrends = enhancedStats['latestTrends'] as List? ?? [];
          final goalProgress =
              enhancedStats['goalProgress'] as Map<String, dynamic>? ?? {};
          final trendSummary =
              enhancedStats['trendSummary'] as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced financial summary section
                _buildEnhancedFinancialSummary(
                  context,
                  goalProgress,
                  trendSummary,
                ),
                const SizedBox(height: AppConstants.paddingL),

                // Goal tracking section
                if (goals.isNotEmpty) ...[
                  _buildGoalTrackingSection(
                    context,
                    activeGoals,
                    completedGoals,
                    goalProgress,
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                ],

                // Trend analysis section
                if (trends.isNotEmpty) ...[
                  _buildTrendAnalysisSection(
                    context,
                    latestTrends,
                    trendSummary,
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                ],

                // Enhanced category breakdown section
                if (trends.isNotEmpty) ...[
                  _buildEnhancedCategoryBreakdownSection(
                    context,
                    latestTrends,
                  ),
                  const SizedBox(height: AppConstants.paddingL),
                ],

                // Quick actions section
                _buildQuickActionsSection(context, ref),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds the enhanced financial summary section showing goal progress and trend summary.
  Widget _buildEnhancedFinancialSummary(
    BuildContext context,
    Map<String, dynamic> goalProgress,
    Map<String, dynamic> trendSummary,
  ) {
    final totalTargetAmount =
        goalProgress['totalTargetAmount'] as double? ?? 0.0;
    final totalCurrentAmount =
        goalProgress['totalCurrentAmount'] as double? ?? 0.0;
    final overallProgress = goalProgress['overallProgress'] as double? ?? 0.0;
    final latestSpending = trendSummary['latestSpending'] as double? ?? 0.0;
    final latestPercentageChange =
        trendSummary['latestPercentageChange'] as double? ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enhanced Financial Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryTile(
                    context,
                    'Goal Progress',
                    '${overallProgress.toStringAsFixed(1)}%',
                    const Color(AppConstants.successColor),
                  ),
                ),
                Expanded(
                  child: _buildSummaryTile(
                    context,
                    'Latest Spending',
                    CurrencyUtils.formatCurrency(latestSpending),
                    const Color(AppConstants.errorColor),
                  ),
                ),
                Expanded(
                  child: _buildSummaryTile(
                    context,
                    'Trend Change',
                    '${latestPercentageChange.toStringAsFixed(1)}%',
                    latestPercentageChange >= 0
                        ? const Color(AppConstants.errorColor)
                        : const Color(AppConstants.successColor),
                  ),
                ),
              ],
            ),
            if (totalTargetAmount > 0) ...[
              const SizedBox(height: AppConstants.paddingM),
              LinearProgressIndicator(
                value: overallProgress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(AppConstants.successColor),
                ),
              ),
              const SizedBox(height: AppConstants.paddingS),
              Text(
                '${CurrencyUtils.formatCurrency(totalCurrentAmount)} / ${CurrencyUtils.formatCurrency(totalTargetAmount)}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the goal tracking section with active and completed goals.
  Widget _buildGoalTrackingSection(
    BuildContext context,
    List activeGoals,
    List completedGoals,
    Map<String, dynamic> goalProgress,
  ) {
    final activeGoalsCount = goalProgress['activeGoalsCount'] as int? ?? 0;
    final completedGoalsCount =
        goalProgress['completedGoalsCount'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Financial Goals',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$activeGoalsCount Active',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '$completedGoalsCount Completed',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingM),
            if (activeGoals.isNotEmpty) ...[
              Text(
                'Active Goals',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppConstants.paddingS),
              ...activeGoals.take(3).map((goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GoalTrackerWidget(goal: goal),
                  )),
            ],
            if (completedGoals.isNotEmpty) ...[
              const SizedBox(height: AppConstants.paddingM),
              Text(
                'Completed Goals',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppConstants.paddingS),
              ...completedGoals.take(2).map((goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GoalTrackerWidget(goal: goal),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the trend analysis section with charts and trend data.
  Widget _buildTrendAnalysisSection(
    BuildContext context,
    List latestTrends,
    Map<String, dynamic> trendSummary,
  ) {
    final latestPeriod = trendSummary['latestPeriod'] as String? ?? 'Monthly';
    final latestTrendDirection =
        trendSummary['latestTrendDirection'] as String? ?? 'stable';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spending Trends',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _getTrendColor(latestTrendDirection).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _getTrendColor(latestTrendDirection).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getTrendLabel(latestTrendDirection),
                    style: TextStyle(
                      color: _getTrendColor(latestTrendDirection),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingM),
            if (latestTrends.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: TrendChartWidget(trends: latestTrends),
              ),
              const SizedBox(height: AppConstants.paddingM),
              Text(
                '$latestPeriod Trend Analysis',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the enhanced category breakdown section.
  Widget _buildEnhancedCategoryBreakdownSection(
    BuildContext context,
    List latestTrends,
  ) {
    if (latestTrends.isEmpty) return const SizedBox.shrink();

    // Get category breakdown from the latest trend
    final latestTrend = latestTrends.first;
    final categoryBreakdown =
        latestTrend.categoryBreakdown as Map<String, double>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Breakdown',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.paddingM),
            if (categoryBreakdown.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: CategoryBreakdownWidget(
                  categoryBreakdown: categoryBreakdown,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the quick actions section for common tasks.
  Widget _buildQuickActionsSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.paddingM),
            Row(
              children: [
                Expanded(
                  child: PlatformWidgets.buildButton(
                    context: context,
                    onPressed: () {
                      // TODO: Navigate to add goal screen
                    },
                    child: const Text('Add Goal'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: PlatformWidgets.buildButton(
                    context: context,
                    onPressed: () {
                      ref.refresh(enhancedStatsNotifierProvider);
                    },
                    child: const Text('Refresh'),
                  ),
                ),
              ],
            ),
          ],
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

  /// Gets the color for trend direction.
  Color _getTrendColor(String trendDirection) {
    switch (trendDirection.toLowerCase()) {
      case 'increasing':
        return const Color(AppConstants.errorColor);
      case 'decreasing':
        return const Color(AppConstants.successColor);
      case 'stable':
      default:
        return const Color(AppConstants.warningColor);
    }
  }

  /// Gets the label for trend direction.
  String _getTrendLabel(String trendDirection) {
    switch (trendDirection.toLowerCase()) {
      case 'increasing':
        return 'Increasing';
      case 'decreasing':
        return 'Decreasing';
      case 'stable':
      default:
        return 'Stable';
    }
  }
}
