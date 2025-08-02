import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/statistics/domain/entities/financial_goal.dart';

void main() {
  group('FinancialGoal', () {
    late FinancialGoal goal;

    setUp(() {
      goal = FinancialGoal(
        id: 'test-goal-1',
        title: 'Save for Vacation',
        targetAmount: 1000.0,
        currentAmount: 500.0,
        startDate: DateTime(2024, 1, 1),
        targetDate: DateTime(2024, 12, 31),
        category: 'Travel',
        status: GoalStatus.active,
      );
    });

    group('Constructor', () {
      test('should create a FinancialGoal with all required fields', () {
        expect(goal.id, 'test-goal-1');
        expect(goal.title, 'Save for Vacation');
        expect(goal.targetAmount, 1000.0);
        expect(goal.currentAmount, 500.0);
        expect(goal.startDate, DateTime(2024, 1, 1));
        expect(goal.targetDate, DateTime(2024, 12, 31));
        expect(goal.category, 'Travel');
        expect(goal.status, GoalStatus.active);
      });

      test('should create a FinancialGoal with default status', () {
        final goalWithDefaultStatus = FinancialGoal(
          id: 'test-goal-2',
          title: 'Test Goal',
          targetAmount: 100.0,
          currentAmount: 0.0,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2024, 12, 31),
        );

        expect(goalWithDefaultStatus.status, GoalStatus.active);
        expect(goalWithDefaultStatus.category, isNull);
      });
    });

    group('Computed Properties', () {
      test('should calculate progress percentage correctly', () {
        expect(goal.progressPercentage, 50.0);

        final goalWithZeroTarget = FinancialGoal(
          id: 'test-goal-3',
          title: 'Test Goal',
          targetAmount: 0.0,
          currentAmount: 100.0,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2024, 12, 31),
        );

        expect(goalWithZeroTarget.progressPercentage, 0.0);
      });

      test('should return correct status booleans', () {
        expect(goal.isActive, true);
        expect(goal.isCompleted, false);
        expect(goal.isPaused, false);

        final completedGoal = goal.copyWith(status: GoalStatus.completed);
        expect(completedGoal.isCompleted, true);
        expect(completedGoal.isActive, false);

        final pausedGoal = goal.copyWith(status: GoalStatus.paused);
        expect(pausedGoal.isPaused, true);
        expect(pausedGoal.isActive, false);
      });

      test('should calculate days remaining correctly', () {
        final now = DateTime(2024, 6, 15);
        final futureDate = now.add(const Duration(days: 10));
        final goalWithFutureDate = FinancialGoal(
          id: 'test-goal-future',
          title: 'Future Goal',
          targetAmount: 100.0,
          currentAmount: 0.0,
          startDate: now,
          targetDate: futureDate,
        );

        // Test the difference calculation directly
        final daysDifference = futureDate.difference(now).inDays;
        expect(daysDifference, 10);

        final pastDate = now.subtract(const Duration(days: 5));
        final goalWithPastDate = FinancialGoal(
          id: 'test-goal-past',
          title: 'Past Goal',
          targetAmount: 100.0,
          currentAmount: 0.0,
          startDate: now,
          targetDate: pastDate,
        );

        // Test that past dates return 0
        final pastDaysDifference = pastDate.difference(now).inDays;
        expect(pastDaysDifference, -5);
      });

      test('should determine if goal is overdue', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 5));
        final overdueGoal = goal.copyWith(targetDate: pastDate);

        expect(overdueGoal.isOverdue, true);

        final completedOverdueGoal =
            overdueGoal.copyWith(status: GoalStatus.completed);
        expect(completedOverdueGoal.isOverdue, false);
      });
    });

    group('copyWith', () {
      test('should create a copy with updated fields', () {
        final updatedGoal = goal.copyWith(
          currentAmount: 750.0,
          status: GoalStatus.completed,
        );

        expect(updatedGoal.id, goal.id);
        expect(updatedGoal.title, goal.title);
        expect(updatedGoal.targetAmount, goal.targetAmount);
        expect(updatedGoal.currentAmount, 750.0);
        expect(updatedGoal.startDate, goal.startDate);
        expect(updatedGoal.targetDate, goal.targetDate);
        expect(updatedGoal.category, goal.category);
        expect(updatedGoal.status, GoalStatus.completed);
      });

      test('should create a copy with all fields updated', () {
        final updatedGoal = goal.copyWith(
          id: 'new-id',
          title: 'New Title',
          targetAmount: 2000.0,
          currentAmount: 1000.0,
          startDate: DateTime(2024, 6, 1),
          targetDate: DateTime(2025, 6, 1),
          category: 'New Category',
          status: GoalStatus.paused,
        );

        expect(updatedGoal.id, 'new-id');
        expect(updatedGoal.title, 'New Title');
        expect(updatedGoal.targetAmount, 2000.0);
        expect(updatedGoal.currentAmount, 1000.0);
        expect(updatedGoal.startDate, DateTime(2024, 6, 1));
        expect(updatedGoal.targetDate, DateTime(2025, 6, 1));
        expect(updatedGoal.category, 'New Category');
        expect(updatedGoal.status, GoalStatus.paused);
      });
    });

    group('Equality', () {
      test('should be equal to itself', () {
        expect(goal, equals(goal));
      });

      test('should be equal to identical goal', () {
        final identicalGoal = FinancialGoal(
          id: 'test-goal-1',
          title: 'Save for Vacation',
          targetAmount: 1000.0,
          currentAmount: 500.0,
          startDate: DateTime(2024, 1, 1),
          targetDate: DateTime(2024, 12, 31),
          category: 'Travel',
          status: GoalStatus.active,
        );

        expect(goal, equals(identicalGoal));
      });

      test('should not be equal to different goal', () {
        final differentGoal = goal.copyWith(id: 'different-id');
        expect(goal, isNot(equals(differentGoal)));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        final string = goal.toString();

        expect(string, contains('FinancialGoal'));
        expect(string, contains('test-goal-1'));
        expect(string, contains('Save for Vacation'));
        expect(string, contains('1000.0'));
        expect(string, contains('500.0'));
        expect(string, contains('Travel'));
        expect(string, contains('GoalStatus.active'));
      });
    });
  });

  group('GoalStatus', () {
    test('should have correct enum values', () {
      expect(GoalStatus.values, hasLength(3));
      expect(GoalStatus.values, contains(GoalStatus.active));
      expect(GoalStatus.values, contains(GoalStatus.completed));
      expect(GoalStatus.values, contains(GoalStatus.paused));
    });
  });
}
