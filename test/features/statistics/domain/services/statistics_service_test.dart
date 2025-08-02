import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/statistics/domain/entities/financial_goal.dart';
import 'package:expense_tracker/features/statistics/domain/entities/trend_analysis.dart';
import 'package:expense_tracker/features/statistics/domain/services/statistics_service.dart';

void main() {
  group('StatisticsService', () {
    late StatisticsService statisticsService;
    late List<Expense> testExpenses;

    setUp(() {
      statisticsService = StatisticsService();
      testExpenses = [
        Expense(
          id: '1',
          title: 'Food Expense',
          description: 'Lunch at restaurant',
          amount: 50.0,
          category: 'Food',
          type: ExpenseType.expense,
          date: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        ),
        Expense(
          id: '2',
          title: 'Transport Expense',
          description: 'Bus fare',
          amount: 30.0,
          category: 'Transport',
          type: ExpenseType.expense,
          date: DateTime(2024, 1, 16),
          createdAt: DateTime(2024, 1, 16),
          updatedAt: DateTime(2024, 1, 16),
        ),
        Expense(
          id: '3',
          title: 'Entertainment Expense',
          description: 'Movie tickets',
          amount: 20.0,
          category: 'Entertainment',
          type: ExpenseType.expense,
          date: DateTime(2024, 1, 17),
          createdAt: DateTime(2024, 1, 17),
          updatedAt: DateTime(2024, 1, 17),
        ),
        Expense(
          id: '4',
          title: 'Food Expense 2',
          description: 'Dinner at restaurant',
          amount: 40.0,
          category: 'Food',
          type: ExpenseType.expense,
          date: DateTime(2024, 1, 18),
          createdAt: DateTime(2024, 1, 18),
          updatedAt: DateTime(2024, 1, 18),
        ),
      ];
    });

    group('calculateTrendAnalysis', () {
      test('should calculate trend analysis correctly', () {
        final previousExpenses = [
          Expense(
            id: '5',
            title: 'Previous Food',
            description: 'Previous food expense',
            amount: 30.0,
            category: 'Food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 8),
            createdAt: DateTime(2024, 1, 8),
            updatedAt: DateTime(2024, 1, 8),
          ),
        ];

        final trend = statisticsService.calculateTrendAnalysis(
          expenses: testExpenses,
          period: 'weekly',
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 1, 21),
          previousPeriodExpenses: previousExpenses,
          previousStartDate: DateTime(2024, 1, 8),
          previousEndDate: DateTime(2024, 1, 14),
        );

        expect(trend.period, 'weekly');
        expect(trend.totalSpending, 140.0);
        expect(trend.categoryBreakdown['Food'], 90.0);
        expect(trend.categoryBreakdown['Transport'], 30.0);
        expect(trend.categoryBreakdown['Entertainment'], 20.0);
        expect(trend.percentageChange, closeTo(366.67, 0.01));
        expect(trend.trendDirection, TrendDirection.increasing);
      });

      test('should handle decreasing trend', () {
        final previousExpenses = [
          Expense(
            id: '5',
            title: 'Previous High',
            description: 'Previous high expense',
            amount: 200.0,
            category: 'Food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 8),
            createdAt: DateTime(2024, 1, 8),
            updatedAt: DateTime(2024, 1, 8),
          ),
        ];

        final trend = statisticsService.calculateTrendAnalysis(
          expenses: testExpenses,
          period: 'weekly',
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 1, 21),
          previousPeriodExpenses: previousExpenses,
          previousStartDate: DateTime(2024, 1, 8),
          previousEndDate: DateTime(2024, 1, 14),
        );

        expect(trend.percentageChange, -30.0);
        expect(trend.trendDirection, TrendDirection.decreasing);
      });

      test('should handle stable trend', () {
        final previousExpenses = [
          Expense(
            id: '5',
            title: 'Previous Similar',
            description: 'Previous similar expense',
            amount: 145.0,
            category: 'Food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 8),
            createdAt: DateTime(2024, 1, 8),
            updatedAt: DateTime(2024, 1, 8),
          ),
        ];

        final trend = statisticsService.calculateTrendAnalysis(
          expenses: testExpenses,
          period: 'weekly',
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 1, 21),
          previousPeriodExpenses: previousExpenses,
          previousStartDate: DateTime(2024, 1, 8),
          previousEndDate: DateTime(2024, 1, 14),
        );

        expect(trend.percentageChange, closeTo(-3.45, 0.01));
        expect(trend.trendDirection, TrendDirection.stable);
      });

      test('should handle zero previous spending', () {
        final trend = statisticsService.calculateTrendAnalysis(
          expenses: testExpenses,
          period: 'weekly',
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 1, 21),
          previousPeriodExpenses: [],
          previousStartDate: DateTime(2024, 1, 8),
          previousEndDate: DateTime(2024, 1, 14),
        );

        expect(trend.percentageChange, 0.0);
        expect(trend.trendDirection, TrendDirection.stable);
      });
    });

    group('updateGoalProgress', () {
      test('should update goal progress correctly', () {
        final goal = FinancialGoal(
          id: 'goal-1',
          title: 'Save on Food',
          targetAmount: 100.0,
          currentAmount: 0.0,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2024, 12, 31),
          category: 'Food',
        );

        final updatedGoal = statisticsService.updateGoalProgress(
          goal: goal,
          expenses: testExpenses,
        );

        expect(updatedGoal.currentAmount, 90.0);
        expect(updatedGoal.progressPercentage, 90.0);
        expect(updatedGoal.status, GoalStatus.active);
      });

      test('should complete goal when target reached', () {
        final goal = FinancialGoal(
          id: 'goal-1',
          title: 'Save on Food',
          targetAmount: 80.0,
          currentAmount: 0.0,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2024, 12, 31),
          category: 'Food',
        );

        final updatedGoal = statisticsService.updateGoalProgress(
          goal: goal,
          expenses: testExpenses,
        );

        expect(updatedGoal.currentAmount, 90.0);
        expect(updatedGoal.status, GoalStatus.completed);
      });

      test('should not update completed goals', () {
        final goal = FinancialGoal(
          id: 'goal-1',
          title: 'Completed Goal',
          targetAmount: 50.0,
          currentAmount: 50.0,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2024, 12, 31),
          category: 'Food',
          status: GoalStatus.completed,
        );

        final updatedGoal = statisticsService.updateGoalProgress(
          goal: goal,
          expenses: testExpenses,
        );

        expect(updatedGoal.currentAmount, 50.0);
        expect(updatedGoal.status, GoalStatus.completed);
      });

      test('should not update paused goals', () {
        final goal = FinancialGoal(
          id: 'goal-1',
          title: 'Paused Goal',
          targetAmount: 100.0,
          currentAmount: 0.0,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2024, 12, 31),
          category: 'Food',
          status: GoalStatus.paused,
        );

        final updatedGoal = statisticsService.updateGoalProgress(
          goal: goal,
          expenses: testExpenses,
        );

        expect(updatedGoal.currentAmount, 0.0);
        expect(updatedGoal.status, GoalStatus.paused);
      });

      test('should handle goals without category', () {
        final goal = FinancialGoal(
          id: 'goal-1',
          title: 'Total Spending Goal',
          targetAmount: 200.0,
          currentAmount: 0.0,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2024, 12, 31),
        );

        final updatedGoal = statisticsService.updateGoalProgress(
          goal: goal,
          expenses: testExpenses,
        );

        expect(updatedGoal.currentAmount, 140.0);
        expect(updatedGoal.progressPercentage, 70.0);
      });
    });

    group('updateAllGoalsProgress', () {
      test('should update all goals progress', () {
        final goals = [
          FinancialGoal(
            id: 'goal-1',
            title: 'Food Goal',
            targetAmount: 100.0,
            currentAmount: 0.0,
            startDate: DateTime(2024, 1, 1),
            targetDate: DateTime(2024, 12, 31),
            category: 'Food',
          ),
          FinancialGoal(
            id: 'goal-2',
            title: 'Transport Goal',
            targetAmount: 50.0,
            currentAmount: 0.0,
            startDate: DateTime(2024, 1, 1),
            targetDate: DateTime(2024, 12, 31),
            category: 'Transport',
          ),
        ];

        final updatedGoals = statisticsService.updateAllGoalsProgress(
          goals: goals,
          expenses: testExpenses,
        );

        expect(updatedGoals.length, 2);
        expect(updatedGoals[0].currentAmount, 90.0);
        expect(updatedGoals[1].currentAmount, 30.0);
      });
    });

    group('getCategoryBreakdown', () {
      test('should return correct category breakdown', () {
        final breakdown = statisticsService.getCategoryBreakdown(
          expenses: testExpenses,
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 1, 21),
        );

        expect(breakdown['Food'], 90.0);
        expect(breakdown['Transport'], 30.0);
        expect(breakdown['Entertainment'], 20.0);
        expect(breakdown.length, 3);
      });

      test('should handle empty expenses list', () {
        final breakdown = statisticsService.getCategoryBreakdown(
          expenses: [],
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 1, 21),
        );

        expect(breakdown, isEmpty);
      });
    });

    group('getChartData', () {
      test('should return chart data for daily period', () {
        final chartData = statisticsService.getChartData(
          expenses: testExpenses,
          period: 'daily',
          numberOfPeriods: 3,
        );

        expect(chartData, isNotEmpty);
        expect(chartData.values.every((value) => value is double), true);
      });

      test('should return chart data for weekly period', () {
        final chartData = statisticsService.getChartData(
          expenses: testExpenses,
          period: 'weekly',
          numberOfPeriods: 2,
        );

        expect(chartData, isNotEmpty);
        expect(chartData.values.every((value) => value is double), true);
      });

      test('should return chart data for monthly period', () {
        final chartData = statisticsService.getChartData(
          expenses: testExpenses,
          period: 'monthly',
          numberOfPeriods: 2,
        );

        expect(chartData, isNotEmpty);
        expect(chartData.values.every((value) => value is double), true);
      });
    });

    group('calculateTrendsForPeriods', () {
      test('should calculate trends for multiple periods', () {
        final trends = statisticsService.calculateTrendsForPeriods(
          expenses: testExpenses,
          period: 'weekly',
          numberOfPeriods: 2,
        );

        expect(trends.length, 2);
        expect(trends.every((trend) => trend is TrendAnalysis), true);
      });
    });
  });
}
