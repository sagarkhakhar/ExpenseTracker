import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/budget/domain/entities/budget.dart';
import 'package:expense_tracker/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budget/domain/services/budget_service.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/core/errors/failures.dart';

class MockBudgetRepository extends Mock implements BudgetRepository {}
class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  group('BudgetService', () {
    late BudgetService budgetService;
    late MockBudgetRepository mockBudgetRepository;
    late MockExpenseRepository mockExpenseRepository;

    setUp(() {
      mockBudgetRepository = MockBudgetRepository();
      mockExpenseRepository = MockExpenseRepository();
      budgetService = BudgetService(
        repository: mockBudgetRepository,
        expenseRepository: mockExpenseRepository,
      );
    });

    group('getBudgetsWithAlerts', () {
      test('should return budgets with alerts', () async {
        // arrange
        final budgets = [
          Budget(
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
          ),
          Budget(
            id: '2',
            categoryId: 'transport',
            amount: 50.0,
            period: 'monthly',
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
            spentAmount: 60.0,
            alertThreshold: 80.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Budget(
            id: '3',
            categoryId: 'entertainment',
            amount: 75.0,
            period: 'monthly',
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
            spentAmount: 30.0,
            alertThreshold: 80.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(() => mockBudgetRepository.getActiveBudgets())
            .thenAnswer((_) async => budgets);

        // act
        final result = await budgetService.getBudgetsWithAlerts();

        // assert
        expect(result.length, 2);
        expect(result.first.id, '1');
        expect(result.last.id, '2');
        verify(() => mockBudgetRepository.getActiveBudgets()).called(1);
      });

      test('should return empty list when no budgets have alerts', () async {
        // arrange
        final budgets = [
          Budget(
            id: '1',
            categoryId: 'food',
            amount: 100.0,
            period: 'monthly',
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
            spentAmount: 30.0,
            alertThreshold: 80.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(() => mockBudgetRepository.getActiveBudgets())
            .thenAnswer((_) async => budgets);

        // act
        final result = await budgetService.getBudgetsWithAlerts();

        // assert
        expect(result, isEmpty);
        verify(() => mockBudgetRepository.getActiveBudgets()).called(1);
      });
    });

    group('getBudgetsApproachingLimit', () {
      test('should return only budgets approaching limit', () async {
        // arrange
        final budgets = [
          Budget(
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
          ),
          Budget(
            id: '2',
            categoryId: 'transport',
            amount: 50.0,
            period: 'monthly',
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
            spentAmount: 60.0,
            alertThreshold: 80.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(() => mockBudgetRepository.getActiveBudgets())
            .thenAnswer((_) async => budgets);

        // act
        final result = await budgetService.getBudgetsApproachingLimit();

        // assert
        expect(result.length, 1);
        expect(result.first.id, '1');
        verify(() => mockBudgetRepository.getActiveBudgets()).called(1);
      });
    });

    group('getBudgetsExceeded', () {
      test('should return only exceeded budgets', () async {
        // arrange
        final budgets = [
          Budget(
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
          ),
          Budget(
            id: '2',
            categoryId: 'transport',
            amount: 50.0,
            period: 'monthly',
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 31),
            spentAmount: 30.0,
            alertThreshold: 80.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(() => mockBudgetRepository.getActiveBudgets())
            .thenAnswer((_) async => budgets);

        // act
        final result = await budgetService.getBudgetsExceeded();

        // assert
        expect(result.length, 1);
        expect(result.first.id, '1');
        verify(() => mockBudgetRepository.getActiveBudgets()).called(1);
      });
    });

    group('calculateSpentAmount', () {
      test('should calculate spent amount from expenses', () async {
        // arrange
        final expenses = [
          Expense(
            id: '1',
            title: 'Lunch',
            description: 'Lunch at restaurant',
            amount: 25.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 15),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Expense(
            id: '2',
            title: 'Dinner',
            description: 'Dinner at restaurant',
            amount: 35.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 16),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Expense(
            id: '3',
            title: 'Salary',
            description: 'Monthly salary',
            amount: 1000.0,
            category: 'income',
            type: ExpenseType.income,
            date: DateTime(2024, 1, 15),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(() => mockExpenseRepository.getExpensesByDateRange(
          any(),
          any(),
        )).thenAnswer((_) async => Right(expenses));

        // act
        final result = await budgetService.calculateSpentAmount(
          'budget1',
          'food',
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 31),
        );

        // assert
        expect(result, 60.0);
        verify(() => mockExpenseRepository.getExpensesByDateRange(
          any(),
          any(),
        )).called(1);
      });

      test('should return 0.0 when repository fails', () async {
        // arrange
        when(() => mockExpenseRepository.getExpensesByDateRange(
          any(),
          any(),
        )).thenAnswer((_) async => const Left(DatabaseFailure('Database error')));

        // act
        final result = await budgetService.calculateSpentAmount(
          'budget1',
          'food',
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 31),
        );

        // assert
        expect(result, 0.0);
      });
    });

    group('isBudgetPeriodCurrent', () {
      test('should return true for current period', () {
        // arrange
        final now = DateTime.now();
        final budget = Budget(
          id: '1',
          categoryId: 'food',
          amount: 100.0,
          period: 'monthly',
          startDate: now.subtract(const Duration(days: 15)),
          endDate: now.add(const Duration(days: 15)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // act
        final result = budgetService.isBudgetPeriodCurrent(budget);

        // assert
        expect(result, isTrue);
      });

      test('should return false for past period', () {
        // arrange
        final budget = Budget(
          id: '1',
          categoryId: 'food',
          amount: 100.0,
          period: 'monthly',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // act
        final result = budgetService.isBudgetPeriodCurrent(budget);

        // assert
        expect(result, isFalse);
      });
    });
  });
} 