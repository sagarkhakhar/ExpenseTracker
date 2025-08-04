import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/statistics/domain/entities/financial_goal.dart';
import 'package:expense_tracker/features/statistics/domain/entities/trend_analysis.dart';
import 'package:expense_tracker/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

void main() {
  setUpAll(() async {
    final testDir = Directory('./test/hive_testing').absolute;
    if (!testDir.existsSync()) {
      testDir.createSync(recursive: true);
    }
    Hive.init(testDir.path);
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(ExpenseTypeAdapter());
    Hive.registerAdapter(FinancialGoalAdapter());
    Hive.registerAdapter(GoalStatusAdapter());
    Hive.registerAdapter(TrendAnalysisAdapter());
    Hive.registerAdapter(TrendDirectionAdapter());
  });

  group('StatisticsRepositoryImpl', () {
    late StatisticsRepositoryImpl repository;

    setUp(() async {
      repository = StatisticsRepositoryImpl();
    });

    tearDown(() async {
      await repository.close();
    });

    group('Constructor', () {
      test('should create repository instance', () {
        expect(repository, isA<StatisticsRepositoryImpl>());
      });
    });

    group('Financial Goal Operations', () {
      late FinancialGoal testGoal;

      setUp(() {
        testGoal = FinancialGoal(
          id: 'test-goal-1',
          title: 'Save for Vacation',
          targetAmount: 1000.0,
          currentAmount: 500.0,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2024, 12, 31),
          category: 'Travel',
        );
      });

      test('should have correct goal properties', () {
        expect(testGoal.id, 'test-goal-1');
        expect(testGoal.title, 'Save for Vacation');
        expect(testGoal.targetAmount, 1000.0);
        expect(testGoal.currentAmount, 500.0);
        expect(testGoal.category, 'Travel');
        expect(testGoal.status, GoalStatus.active);
      });

      test('should calculate progress percentage correctly', () {
        expect(testGoal.progressPercentage, 50.0);
      });

      test('should handle goal status correctly', () {
        expect(testGoal.isActive, true);
        expect(testGoal.isCompleted, false);
        expect(testGoal.isPaused, false);
      });
    });

    group('Trend Analysis Operations', () {
      late TrendAnalysis testTrend;

      setUp(() {
        testTrend = TrendAnalysis(
          period: 'weekly',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 7),
          totalSpending: 500.0,
          categoryBreakdown: {'Food': 300.0, 'Transport': 200.0},
          trendDirection: TrendDirection.increasing,
          percentageChange: 15.5,
          createdAt: DateTime(2024, 1, 8),
        );
      });

      test('should have correct trend properties', () {
        expect(testTrend.period, 'weekly');
        expect(testTrend.totalSpending, 500.0);
        expect(testTrend.trendDirection, TrendDirection.increasing);
        expect(testTrend.percentageChange, 15.5);
      });

      test('should handle trend direction correctly', () {
        expect(testTrend.isIncreasing, true);
        expect(testTrend.isDecreasing, false);
        expect(testTrend.isStable, false);
      });

      test('should generate correct trend description', () {
        expect(testTrend.trendDescription, 'Spending increased by 15.5%');
      });

      test('should return sorted categories', () {
        final sorted = testTrend.sortedCategories;
        expect(sorted.length, 2);
        expect(sorted[0].key, 'Food');
        expect(sorted[0].value, 300.0);
        expect(sorted[1].key, 'Transport');
        expect(sorted[1].value, 200.0);
      });

      test('should return top category information', () {
        expect(testTrend.topCategory, 'Food');
        expect(testTrend.topCategoryAmount, 300.0);
        expect(testTrend.topCategoryPercentage, 60.0);
      });
    });

    group('Entity Equality', () {
      test('should compare financial goals correctly', () {
        final goal1 = FinancialGoal(
          id: 'goal-1',
          title: 'Test Goal',
          targetAmount: 100.0,
          currentAmount: 50.0,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2024, 12, 31),
        );

        final goal2 = FinancialGoal(
          id: 'goal-1',
          title: 'Test Goal',
          targetAmount: 100.0,
          currentAmount: 50.0,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2024, 12, 31),
        );

        expect(goal1, equals(goal2));
      });

      test('should compare trend analysis correctly', () {
        final trend1 = TrendAnalysis(
          period: 'weekly',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 7),
          totalSpending: 100.0,
          categoryBreakdown: {'Food': 100.0},
          trendDirection: TrendDirection.increasing,
          percentageChange: 10.0,
          createdAt: DateTime(2024, 1, 8),
        );

        final trend2 = trend1.copyWith();

        expect(trend1, equals(trend2));
      });
    });
  });
}
