import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/entities/filter_criteria.dart';
import 'package:expense_tracker/features/expense/domain/entities/search_result.dart';
import 'package:expense_tracker/features/expense/domain/repositories/filter_repository.dart';
import 'package:expense_tracker/features/expense/domain/usecases/apply_filters.dart';

class MockFilterRepository extends Mock implements FilterRepository {}

void main() {
  group('ApplyFilters', () {
    late ApplyFilters useCase;
    late MockFilterRepository mockRepository;

    setUp(() {
      mockRepository = MockFilterRepository();
      useCase = ApplyFilters(mockRepository);
    });

    test('should return SearchResult when repository call is successful',
        () async {
      // Arrange
      const filterCriteria = FilterCriteria(
        searchQuery: 'test',
        isActive: true,
      );
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
      final searchResult = SearchResult(
        expenses: [testExpense],
        totalCount: 1,
        filterCriteria: filterCriteria,
        searchQuery: 'test',
      );

      when(() => mockRepository.searchExpenses(filterCriteria))
          .thenAnswer((_) async => Right(searchResult));

      // Act
      final result = await useCase(filterCriteria);

      // Assert
      expect(result, Right(searchResult));
      verify(() => mockRepository.searchExpenses(filterCriteria)).called(1);
    });

    test('should return Failure when repository call fails', () async {
      // Arrange
      const filterCriteria = FilterCriteria(
        searchQuery: 'test',
        isActive: true,
      );
      const failure = DatabaseFailure('Database error');

      when(() => mockRepository.searchExpenses(filterCriteria))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(filterCriteria);

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.searchExpenses(filterCriteria)).called(1);
    });
  });
}
