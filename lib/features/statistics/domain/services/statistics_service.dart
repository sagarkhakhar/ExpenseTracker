import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/statistics/domain/entities/financial_goal.dart';
import 'package:expense_tracker/features/statistics/domain/entities/trend_analysis.dart';

class StatisticsService {
  /// Calculates spending trends for a given time period
  TrendAnalysis calculateTrendAnalysis({
    required List<Expense> expenses,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    required List<Expense> previousPeriodExpenses,
    required DateTime previousStartDate,
    required DateTime previousEndDate,
  }) {
    // Calculate total spending for current period
    final currentPeriodExpenses = expenses
        .where((expense) =>
            expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final totalSpending = currentPeriodExpenses.fold<double>(
        0, (sum, expense) => sum + expense.amount);

    // Calculate category breakdown
    final categoryBreakdown = <String, double>{};
    for (final expense in currentPeriodExpenses) {
      categoryBreakdown[expense.category] =
          (categoryBreakdown[expense.category] ?? 0) + expense.amount;
    }

    // Calculate previous period spending for comparison
    final previousPeriodTotal = previousPeriodExpenses.fold<double>(
        0, (sum, expense) => sum + expense.amount);

    // Calculate percentage change
    double percentageChange = 0;
    if (previousPeriodTotal > 0) {
      percentageChange =
          ((totalSpending - previousPeriodTotal) / previousPeriodTotal) * 100;
    }

    // Determine trend direction
    TrendDirection trendDirection;
    if (percentageChange > 5) {
      trendDirection = TrendDirection.increasing;
    } else if (percentageChange < -5) {
      trendDirection = TrendDirection.decreasing;
    } else {
      trendDirection = TrendDirection.stable;
    }

    return TrendAnalysis(
      period: period,
      startDate: startDate,
      endDate: endDate,
      totalSpending: totalSpending,
      categoryBreakdown: categoryBreakdown,
      trendDirection: trendDirection,
      percentageChange: percentageChange,
      createdAt: DateTime.now(),
    );
  }

  /// Calculates spending trends for different time periods
  List<TrendAnalysis> calculateTrendsForPeriods({
    required List<Expense> expenses,
    required String period,
    required int numberOfPeriods,
  }) {
    final trends = <TrendAnalysis>[];
    final now = DateTime.now();

    for (int i = 0; i < numberOfPeriods; i++) {
      final currentPeriodEnd = _getPeriodEndDate(now, period, i);
      final currentPeriodStart = _getPeriodStartDate(currentPeriodEnd, period);
      final previousPeriodEnd =
          currentPeriodStart.subtract(const Duration(days: 1));
      final previousPeriodStart =
          _getPeriodStartDate(previousPeriodEnd, period);

      final currentPeriodExpenses = expenses
          .where((expense) =>
              expense.date.isAfter(
                  currentPeriodStart.subtract(const Duration(days: 1))) &&
              expense.date
                  .isBefore(currentPeriodEnd.add(const Duration(days: 1))))
          .toList();

      final previousPeriodExpenses = expenses
          .where((expense) =>
              expense.date.isAfter(
                  previousPeriodStart.subtract(const Duration(days: 1))) &&
              expense.date
                  .isBefore(previousPeriodEnd.add(const Duration(days: 1))))
          .toList();

      final trend = calculateTrendAnalysis(
        expenses: expenses,
        period: period,
        startDate: currentPeriodStart,
        endDate: currentPeriodEnd,
        previousPeriodExpenses: previousPeriodExpenses,
        previousStartDate: previousPeriodStart,
        previousEndDate: previousPeriodEnd,
      );

      trends.add(trend);
    }

    return trends;
  }

  /// Updates financial goal progress based on expenses
  FinancialGoal updateGoalProgress({
    required FinancialGoal goal,
    required List<Expense> expenses,
  }) {
    if (goal.isCompleted || goal.isPaused) {
      return goal;
    }

    // Calculate spending for the goal's category if specified
    double currentAmount = 0;
    if (goal.category != null) {
      currentAmount = expenses
          .where((expense) =>
              expense.category == goal.category &&
              expense.date
                  .isAfter(goal.startDate.subtract(const Duration(days: 1))) &&
              expense.date
                  .isBefore(goal.targetDate.add(const Duration(days: 1))))
          .fold<double>(0, (sum, expense) => sum + expense.amount);
    } else {
      // If no category specified, use total spending
      currentAmount = expenses
          .where((expense) =>
              expense.date
                  .isAfter(goal.startDate.subtract(const Duration(days: 1))) &&
              expense.date
                  .isBefore(goal.targetDate.add(const Duration(days: 1))))
          .fold<double>(0, (sum, expense) => sum + expense.amount);
    }

    // Check if goal is completed
    GoalStatus status = goal.status;
    if (currentAmount >= goal.targetAmount) {
      status = GoalStatus.completed;
    }

    return goal.copyWith(
      currentAmount: currentAmount,
      status: status,
    );
  }

  /// Calculates goal progress for all goals
  List<FinancialGoal> updateAllGoalsProgress({
    required List<FinancialGoal> goals,
    required List<Expense> expenses,
  }) {
    return goals
        .map((goal) => updateGoalProgress(
              goal: goal,
              expenses: expenses,
            ))
        .toList();
  }

  /// Gets spending data for chart visualization
  Map<String, double> getChartData({
    required List<Expense> expenses,
    required String period,
    required int numberOfPeriods,
  }) {
    final chartData = <String, double>{};
    final now = DateTime.now();

    for (int i = 0; i < numberOfPeriods; i++) {
      final periodEnd = _getPeriodEndDate(now, period, i);
      final periodStart = _getPeriodStartDate(periodEnd, period);

      final periodExpenses = expenses
          .where((expense) =>
              expense.date
                  .isAfter(periodStart.subtract(const Duration(days: 1))) &&
              expense.date.isBefore(periodEnd.add(const Duration(days: 1))))
          .toList();

      final totalSpending = periodExpenses.fold<double>(
          0, (sum, expense) => sum + expense.amount);

      final periodLabel = _getPeriodLabel(periodEnd, period);
      chartData[periodLabel] = totalSpending;
    }

    return chartData;
  }

  /// Gets category breakdown for a specific period
  Map<String, double> getCategoryBreakdown({
    required List<Expense> expenses,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final periodExpenses = expenses
        .where((expense) =>
            expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();

    final categoryBreakdown = <String, double>{};
    for (final expense in periodExpenses) {
      categoryBreakdown[expense.category] =
          (categoryBreakdown[expense.category] ?? 0) + expense.amount;
    }

    return categoryBreakdown;
  }

  /// Helper method to get period end date
  DateTime _getPeriodEndDate(DateTime now, String period, int offset) {
    switch (period) {
      case 'daily':
        return DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: offset));
      case 'weekly':
        final daysFromMonday = now.weekday - 1;
        return DateTime(now.year, now.month, now.day - daysFromMonday)
            .subtract(Duration(days: offset * 7));
      case 'monthly':
        return DateTime(now.year, now.month, 1)
            .subtract(Duration(days: offset * 30));
      case 'yearly':
        return DateTime(now.year, 1, 1).subtract(Duration(days: offset * 365));
      default:
        return now;
    }
  }

  /// Helper method to get period start date
  DateTime _getPeriodStartDate(DateTime periodEnd, String period) {
    switch (period) {
      case 'daily':
        return periodEnd;
      case 'weekly':
        return periodEnd.subtract(const Duration(days: 6));
      case 'monthly':
        return periodEnd.subtract(const Duration(days: 29));
      case 'yearly':
        return periodEnd.subtract(const Duration(days: 364));
      default:
        return periodEnd;
    }
  }

  /// Helper method to get period label for charts
  String _getPeriodLabel(DateTime date, String period) {
    switch (period) {
      case 'daily':
        return '${date.month}/${date.day}';
      case 'weekly':
        return 'Week ${date.difference(DateTime(date.year, 1, 1)).inDays ~/ 7}';
      case 'monthly':
        return '${date.month}/${date.year}';
      case 'yearly':
        return '${date.year}';
      default:
        return '${date.month}/${date.day}/${date.year}';
    }
  }

  /// Generates enhanced statistics data combining goals and trends
  Future<Map<String, dynamic>> generateEnhancedStats(
    List<FinancialGoal> goals,
    List<TrendAnalysis> trends,
  ) async {
    final enhancedStats = <String, dynamic>{};

    // Add goals data
    enhancedStats['goals'] = goals;
    enhancedStats['activeGoals'] =
        goals.where((goal) => goal.status == GoalStatus.active).toList();
    enhancedStats['completedGoals'] =
        goals.where((goal) => goal.status == GoalStatus.completed).toList();

    // Add trends data
    enhancedStats['trends'] = trends;
    enhancedStats['latestTrends'] = trends.take(5).toList(); // Latest 5 trends

    // Calculate goal progress summary
    if (goals.isNotEmpty) {
      final totalTargetAmount =
          goals.fold<double>(0, (sum, goal) => sum + goal.targetAmount);
      final totalCurrentAmount =
          goals.fold<double>(0, (sum, goal) => sum + goal.currentAmount);
      final overallProgress = totalTargetAmount > 0
          ? (totalCurrentAmount / totalTargetAmount) * 100
          : 0;

      enhancedStats['goalProgress'] = {
        'totalTargetAmount': totalTargetAmount,
        'totalCurrentAmount': totalCurrentAmount,
        'overallProgress': overallProgress,
        'goalsCount': goals.length,
        'activeGoalsCount':
            goals.where((goal) => goal.status == GoalStatus.active).length,
        'completedGoalsCount':
            goals.where((goal) => goal.status == GoalStatus.completed).length,
      };
    }

    // Calculate trend summary
    if (trends.isNotEmpty) {
      final latestTrend = trends.first;
      enhancedStats['trendSummary'] = {
        'latestPeriod': latestTrend.period,
        'latestSpending': latestTrend.totalSpending,
        'latestTrendDirection': latestTrend.trendDirection,
        'latestPercentageChange': latestTrend.percentageChange,
        'trendsCount': trends.length,
      };
    }

    return enhancedStats;
  }
}
