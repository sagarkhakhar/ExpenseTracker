import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budget/domain/entities/budget.dart';

void main() {
  group('Budget Entity Tests', () {
    test('should calculate progress percentage correctly', () {
      final budget = Budget(
        id: '1',
        categoryId: 'food',
        amount: 100.0,
        period: 'monthly',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        spentAmount: 75.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.progressPercentage, 75.0);
    });

    test('should detect approaching limit correctly', () {
      final budget = Budget(
        id: '1',
        categoryId: 'food',
        amount: 100.0,
        period: 'monthly',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        spentAmount: 85.0,
        alertThreshold: 80.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.isApproachingLimit, isTrue);
      expect(budget.isExceeded, isFalse);
      expect(budget.isWithinLimit, isFalse);
    });

    test('should detect exceeded limit correctly', () {
      final budget = Budget(
        id: '1',
        categoryId: 'food',
        amount: 100.0,
        period: 'monthly',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        spentAmount: 110.0,
        alertThreshold: 80.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.isExceeded, isTrue);
      expect(budget.isApproachingLimit, isFalse);
      expect(budget.isWithinLimit, isFalse);
    });

    test('should detect within limit correctly', () {
      final budget = Budget(
        id: '1',
        categoryId: 'food',
        amount: 100.0,
        period: 'monthly',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        spentAmount: 50.0,
        alertThreshold: 80.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.isWithinLimit, isTrue);
      expect(budget.isApproachingLimit, isFalse);
      expect(budget.isExceeded, isFalse);
    });

    test('should handle zero amount correctly', () {
      final budget = Budget(
        id: '1',
        categoryId: 'food',
        amount: 0.0,
        period: 'monthly',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        spentAmount: 50.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(budget.progressPercentage, 0.0);
    });

    test('should copy with new values correctly', () {
      final originalBudget = Budget(
        id: '1',
        categoryId: 'food',
        amount: 100.0,
        period: 'monthly',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        spentAmount: 50.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedBudget = originalBudget.copyWith(
        amount: 150.0,
        spentAmount: 75.0,
      );

      expect(updatedBudget.id, originalBudget.id);
      expect(updatedBudget.amount, 150.0);
      expect(updatedBudget.spentAmount, 75.0);
      expect(updatedBudget.categoryId, originalBudget.categoryId);
    });
  });
} 