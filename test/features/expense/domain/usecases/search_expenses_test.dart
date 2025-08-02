import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/repositories/filter_repository.dart';
import 'package:expense_tracker/features/expense/domain/usecases/search_expenses.dart';

class MockFilterRepository extends Mock implements FilterRepository {}

void main() {
  group('SearchExpenses', () {
    late SearchExpenses useCase;
    late MockFilterRepository mockRepository;

    setUp(() {
      mockRepository = MockFilterRepository();
      useCase = SearchExpenses(mockRepository);
    });

    test('should return list of expenses when repository call is successful',
        () async {
      // Arrange
      const query = 'test';
      final testExpense = Expense(
        id: '1',
        title: 'Test Expense',
        description: 'Test Description',
        amount: 100.0,
        category: 'food',
        type: ExpenseType.expense,
        date: DateTime(2024, 1, 1),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final expenses = [testExpense];

      when(() => mockRepository.searchByText(query))
          .thenAnswer((_) async => Right(expenses));

      // Act
      final result = await useCase(query);

      // Assert
      expect(result, Right(expenses));
      verify(() => mockRepository.searchByText(query)).called(1);
    });

    test('should return empty list when query is empty', () async {
      // Arrange
      const query = '';

      // Act
      final result = await useCase(query);

      // Assert
      expect(result, isA<Right<Failure, List<Expense>>>());
      expect(result.fold((l) => null, (r) => r), equals([]));
      verifyNever(() => mockRepository.searchByText(any()));
    });

    test('should return empty list when query is whitespace only', () async {
      // Arrange
      const query = '   ';

      // Act
      final result = await useCase(query);

      // Assert
      expect(result, isA<Right<Failure, List<Expense>>>());
      expect(result.fold((l) => null, (r) => r), equals([]));
      verifyNever(() => mockRepository.searchByText(any()));
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const query = 'test';
      const failure = DatabaseFailure('Database error');

      when(() => mockRepository.searchByText(query))
          .thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(query);

      // Assert
      expect(result, Left(failure));
      verify(() => mockRepository.searchByText(query)).called(1);
    });
  });
}
