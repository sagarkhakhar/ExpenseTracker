// Test the business validator to ensure it works before integration
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expense/domain/validators/expense_business_validator.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

void main() {
  group('ExpenseBusinessValidator', () {
    test('should return success for valid expense', () {
      final expense = Expense(
        id: '1',
        title: 'Valid Title',
        description: 'Test Description',
        amount: 50.0,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = ExpenseBusinessValidator.validateExpense(expense);
      
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected success but got failure: ${failure.message}'),
        (validExpense) => expect(validExpense.title, 'Valid Title'),
      );
    });

    test('should return error for empty title', () {
      final expense = Expense(
        id: '1',
        title: '',
        description: 'Test Description',
        amount: 50.0,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = ExpenseBusinessValidator.validateExpense(expense);
      
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Title cannot be empty'),
        (expense) => fail('Expected failure but got success'),
      );
    });

    test('should return error for empty category', () {
      final expense = Expense(
        id: '1',
        title: 'Valid Title',
        description: 'Test Description',
        amount: 50.0,
        category: '',
        type: ExpenseType.expense,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = ExpenseBusinessValidator.validateExpense(expense);
      
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Category cannot be empty'),
        (expense) => fail('Expected failure but got success'),
      );
    });

    test('should return error for negative amount', () {
      final expense = Expense(
        id: '1',
        title: 'Valid Title',
        description: 'Test Description',
        amount: -10.0,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = ExpenseBusinessValidator.validateExpense(expense);
      
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Amount must be positive and finite'),
        (expense) => fail('Expected failure but got success'),
      );
    });

    test('should return error for NaN amount', () {
      final expense = Expense(
        id: '1',
        title: 'Valid Title',
        description: 'Test Description',
        amount: double.nan,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = ExpenseBusinessValidator.validateExpense(expense);
      
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Amount must be positive and finite'),
        (expense) => fail('Expected failure but got success'),
      );
    });

    test('should validate recurring expense successfully', () {
      final now = DateTime.now();
      final expense = Expense(
        id: '1',
        title: 'Valid Title',
        description: 'Test Description',
        amount: 50.0,
        category: 'Food',
        type: ExpenseType.expense,
        date: now,
        createdAt: now,
        updatedAt: now,
        isRecurring: true,
        recurringFrequency: 'monthly',
        nextOccurrence: now.add(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 365)),
      );

      final result = ExpenseBusinessValidator.validateExpense(expense);
      
      expect(result.isRight(), true);
    });

    test('should return error for recurring expense without frequency', () {
      final now = DateTime.now();
      final expense = Expense(
        id: '1',
        title: 'Valid Title',
        description: 'Test Description',
        amount: 50.0,
        category: 'Food',
        type: ExpenseType.expense,
        date: now,
        createdAt: now,
        updatedAt: now,
        isRecurring: true,
        recurringFrequency: null, // Missing frequency
        nextOccurrence: now.add(const Duration(days: 30)),
      );

      final result = ExpenseBusinessValidator.validateExpense(expense);
      
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Recurring frequency required'),
        (expense) => fail('Expected failure but got success'),
      );
    });

    test('should return error for recurring expense without next occurrence', () {
      final now = DateTime.now();
      final expense = Expense(
        id: '1',
        title: 'Valid Title',
        description: 'Test Description',
        amount: 50.0,
        category: 'Food',
        type: ExpenseType.expense,
        date: now,
        createdAt: now,
        updatedAt: now,
        isRecurring: true,
        recurringFrequency: 'monthly',
        nextOccurrence: null, // Missing next occurrence
      );

      final result = ExpenseBusinessValidator.validateExpense(expense);
      
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Next occurrence required'),
        (expense) => fail('Expected failure but got success'),
      );
    });
  });
}