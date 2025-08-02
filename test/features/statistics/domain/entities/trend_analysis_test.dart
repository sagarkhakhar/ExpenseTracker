import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/statistics/domain/entities/trend_analysis.dart';

void main() {
  group('TrendAnalysis', () {
    late TrendAnalysis trendAnalysis;

    setUp(() {
      trendAnalysis = TrendAnalysis(
        period: 'monthly',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        totalSpending: 1500.0,
        categoryBreakdown: {
          'Food': 500.0,
          'Transport': 300.0,
          'Entertainment': 200.0,
          'Shopping': 500.0,
        },
        trendDirection: TrendDirection.increasing,
        percentageChange: 15.5,
        createdAt: DateTime(2024, 2, 1),
      );
    });

    group('Constructor', () {
      test('should create a TrendAnalysis with all required fields', () {
        expect(trendAnalysis.period, 'monthly');
        expect(trendAnalysis.startDate, DateTime(2024, 1, 1));
        expect(trendAnalysis.endDate, DateTime(2024, 1, 31));
        expect(trendAnalysis.totalSpending, 1500.0);
        expect(trendAnalysis.categoryBreakdown, {
          'Food': 500.0,
          'Transport': 300.0,
          'Entertainment': 200.0,
          'Shopping': 500.0,
        });
        expect(trendAnalysis.trendDirection, TrendDirection.increasing);
        expect(trendAnalysis.percentageChange, 15.5);
        expect(trendAnalysis.createdAt, DateTime(2024, 2, 1));
      });
    });

    group('Computed Properties', () {
      test('should return correct trend direction booleans', () {
        expect(trendAnalysis.isIncreasing, true);
        expect(trendAnalysis.isDecreasing, false);
        expect(trendAnalysis.isStable, false);

        final decreasingTrend = trendAnalysis.copyWith(
          trendDirection: TrendDirection.decreasing,
        );
        expect(decreasingTrend.isDecreasing, true);
        expect(decreasingTrend.isIncreasing, false);

        final stableTrend = trendAnalysis.copyWith(
          trendDirection: TrendDirection.stable,
        );
        expect(stableTrend.isStable, true);
        expect(stableTrend.isIncreasing, false);
      });

      test('should generate correct trend description', () {
        expect(trendAnalysis.trendDescription, 'Spending increased by 15.5%');

        final decreasingTrend = trendAnalysis.copyWith(
          trendDirection: TrendDirection.decreasing,
          percentageChange: -10.2,
        );
        expect(decreasingTrend.trendDescription, 'Spending decreased by 10.2%');

        final stableTrend = trendAnalysis.copyWith(
          trendDirection: TrendDirection.stable,
          percentageChange: 2.1,
        );
        expect(stableTrend.trendDescription,
            'Spending remained stable (2.1% change)');
      });

      test('should return sorted categories by amount', () {
        final sorted = trendAnalysis.sortedCategories;

        expect(sorted.length, 4);
        expect(sorted[0].key, 'Food');
        expect(sorted[0].value, 500.0);
        expect(sorted[1].key, 'Shopping');
        expect(sorted[1].value, 500.0);
        expect(sorted[2].key, 'Transport');
        expect(sorted[2].value, 300.0);
        expect(sorted[3].key, 'Entertainment');
        expect(sorted[3].value, 200.0);
      });

      test('should return top category information', () {
        expect(trendAnalysis.topCategory, 'Food');
        expect(trendAnalysis.topCategoryAmount, 500.0);
        expect(trendAnalysis.topCategoryPercentage, closeTo(33.33, 0.01));
      });

      test('should handle empty category breakdown', () {
        final emptyTrend = trendAnalysis.copyWith(
          categoryBreakdown: {},
          totalSpending: 0.0,
        );

        expect(emptyTrend.topCategory, 'No data');
        expect(emptyTrend.topCategoryAmount, 0.0);
        expect(emptyTrend.topCategoryPercentage, 0.0);
        expect(emptyTrend.sortedCategories, isEmpty);
      });

      test('should handle zero total spending', () {
        final zeroSpendingTrend = trendAnalysis.copyWith(
          totalSpending: 0.0,
        );

        expect(zeroSpendingTrend.topCategoryPercentage, 0.0);
      });
    });

    group('copyWith', () {
      test('should create a copy with updated fields', () {
        final updatedTrend = trendAnalysis.copyWith(
          totalSpending: 2000.0,
          trendDirection: TrendDirection.decreasing,
        );

        expect(updatedTrend.period, trendAnalysis.period);
        expect(updatedTrend.startDate, trendAnalysis.startDate);
        expect(updatedTrend.endDate, trendAnalysis.endDate);
        expect(updatedTrend.totalSpending, 2000.0);
        expect(updatedTrend.categoryBreakdown, trendAnalysis.categoryBreakdown);
        expect(updatedTrend.trendDirection, TrendDirection.decreasing);
        expect(updatedTrend.percentageChange, trendAnalysis.percentageChange);
        expect(updatedTrend.createdAt, trendAnalysis.createdAt);
      });

      test('should create a copy with all fields updated', () {
        final updatedTrend = trendAnalysis.copyWith(
          period: 'weekly',
          startDate: DateTime(2024, 2, 1),
          endDate: DateTime(2024, 2, 7),
          totalSpending: 800.0,
          categoryBreakdown: {'Food': 400.0, 'Transport': 400.0},
          trendDirection: TrendDirection.stable,
          percentageChange: 5.0,
          createdAt: DateTime(2024, 2, 8),
        );

        expect(updatedTrend.period, 'weekly');
        expect(updatedTrend.startDate, DateTime(2024, 2, 1));
        expect(updatedTrend.endDate, DateTime(2024, 2, 7));
        expect(updatedTrend.totalSpending, 800.0);
        expect(updatedTrend.categoryBreakdown,
            {'Food': 400.0, 'Transport': 400.0});
        expect(updatedTrend.trendDirection, TrendDirection.stable);
        expect(updatedTrend.percentageChange, 5.0);
        expect(updatedTrend.createdAt, DateTime(2024, 2, 8));
      });
    });

    group('Equality', () {
      test('should be equal to itself', () {
        expect(trendAnalysis, equals(trendAnalysis));
      });

      test('should be equal to itself', () {
        expect(trendAnalysis, equals(trendAnalysis));
      });

      test('should be equal to identical trend analysis', () {
        final identicalTrend = trendAnalysis.copyWith();
        expect(trendAnalysis, equals(identicalTrend));
      });

      test('should not be equal to different trend analysis', () {
        final differentTrend = trendAnalysis.copyWith(period: 'weekly');
        expect(trendAnalysis, isNot(equals(differentTrend)));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        final string = trendAnalysis.toString();

        expect(string, contains('TrendAnalysis'));
        expect(string, contains('monthly'));
        expect(string, contains('1500.0'));
        expect(string, contains('TrendDirection.increasing'));
        expect(string, contains('15.5'));
      });
    });
  });

  group('TrendDirection', () {
    test('should have correct enum values', () {
      expect(TrendDirection.values, hasLength(3));
      expect(TrendDirection.values, contains(TrendDirection.increasing));
      expect(TrendDirection.values, contains(TrendDirection.decreasing));
      expect(TrendDirection.values, contains(TrendDirection.stable));
    });
  });
}
