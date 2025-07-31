import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/usecases/update_expense.dart';
import 'package:expense_tracker/features/expense/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class FakeExpense extends Fake implements Expense {}

void main() {
  late MockExpenseRepository mockRepository;
  late UpdateExpense usecase;
  late Expense validExpense;

  setUpAll(() {
    registerFallbackValue(FakeExpense());
  });

  setUp(() {
    mockRepository = MockExpenseRepository();
    usecase = UpdateExpense(mockRepository);
    validExpense = Expense(
      id: '1',
      title: 'Lunch',
      description: 'Food',
      amount: 10.0,
      category: 'food',
      type: ExpenseType.expense,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  });

  test('returns ValidationFailure if title is empty', () async {
    final expense = validExpense.copyWith(title: ' ');
    final result = await usecase(expense);
    expect(result, equals(const Left(ValidationFailure('Title cannot be empty'))));
  });

  test('returns ValidationFailure if category is empty', () async {
    final expense = validExpense.copyWith(category: ' ');
    final result = await usecase(expense);
    expect(result, equals(const Left(ValidationFailure('Category cannot be empty'))));
  });

  test('returns ValidationFailure if amount is <= 0', () async {
    final expense = validExpense.copyWith(amount: 0.0);
    final result = await usecase(expense);
    expect(result,
        equals(const Left(ValidationFailure('Amount must be positive and finite'))));
  });

  test('returns ValidationFailure if amount is NaN', () async {
    final expense = validExpense.copyWith(amount: double.nan);
    final result = await usecase(expense);
    expect(result,
        equals(const Left(ValidationFailure('Amount must be positive and finite'))));
  });

  test('returns ValidationFailure if amount is infinite', () async {
    final expense = validExpense.copyWith(amount: double.infinity);
    final result = await usecase(expense);
    expect(result,
        equals(const Left(ValidationFailure('Amount must be positive and finite'))));
  });

  group('recurring', () {
    test('returns ValidationFailure if recurringFrequency is null', () async {
      final expense = validExpense.copyWith(
          isRecurring: true,
          recurringFrequency: null,
          nextOccurrence: DateTime.now());
      final result = await usecase(expense);
      expect(result,
          equals(const Left(ValidationFailure('Recurring frequency required'))));
    });
    test('returns ValidationFailure if recurringFrequency is empty', () async {
      final expense = validExpense.copyWith(
          isRecurring: true,
          recurringFrequency: '',
          nextOccurrence: DateTime.now());
      final result = await usecase(expense);
      expect(result,
          equals(const Left(ValidationFailure('Recurring frequency required'))));
    });
    test('returns ValidationFailure if nextOccurrence is null', () async {
      final expense = validExpense.copyWith(
          isRecurring: true,
          recurringFrequency: 'monthly',
          nextOccurrence: null);
      final result = await usecase(expense);
      expect(
          result, equals(const Left(ValidationFailure('Next occurrence required'))));
    });
    test('returns ValidationFailure if nextOccurrence is before date',
        () async {
      final now = DateTime.now();
      final expense = validExpense.copyWith(
        isRecurring: true,
        recurringFrequency: 'monthly',
        nextOccurrence: now.subtract(const Duration(days: 1)),
        date: now,
      );
      final result = await usecase(expense);
      expect(
          result,
          equals(const Left(ValidationFailure(
              'Next occurrence must be after or equal to the main date'))));
    });
    test('returns ValidationFailure if endDate is before nextOccurrence',
        () async {
      final now = DateTime.now();
      final expense = validExpense.copyWith(
        isRecurring: true,
        recurringFrequency: 'monthly',
        nextOccurrence: now,
        endDate: now.subtract(const Duration(days: 1)),
      );
      final result = await usecase(expense);
      expect(
          result,
          equals(const Left(
              ValidationFailure('End date must be after next occurrence'))));
    });
  });

  test('calls repository if all validation passes', () async {
    when(() => mockRepository.updateExpense(any()))
        .thenAnswer((_) async => Right(validExpense));
    final result = await usecase(validExpense);
    expect(result, equals(Right(validExpense)));
    verify(() => mockRepository.updateExpense(validExpense)).called(1);
  });
}
