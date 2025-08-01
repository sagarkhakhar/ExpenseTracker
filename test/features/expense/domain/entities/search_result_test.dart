import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/entities/filter_criteria.dart';
import 'package:expense_tracker/features/expense/domain/entities/search_result.dart';

void main() {
  group('SearchResult', () {
    late Expense testExpense;
    late FilterCriteria testFilterCriteria;

    setUp(() {
      testExpense = Expense(
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

      testFilterCriteria = const FilterCriteria(
        searchQuery: 'test',
        isActive: true,
      );
    });

    test('should create SearchResult with all parameters', () {
      // Arrange
      final expenses = [testExpense];
      const totalCount = 1;
      const searchQuery = 'test';

      // Act
      final searchResult = SearchResult(
        expenses: expenses,
        totalCount: totalCount,
        filterCriteria: testFilterCriteria,
        searchQuery: searchQuery,
      );

      // Assert
      expect(searchResult.expenses, equals(expenses));
      expect(searchResult.totalCount, equals(totalCount));
      expect(searchResult.filterCriteria, equals(testFilterCriteria));
      expect(searchResult.searchQuery, equals(searchQuery));
    });

    test('should create SearchResult without search query', () {
      // Arrange
      final expenses = [testExpense];
      const totalCount = 1;

      // Act
      final searchResult = SearchResult(
        expenses: expenses,
        totalCount: totalCount,
        filterCriteria: testFilterCriteria,
      );

      // Assert
      expect(searchResult.expenses, equals(expenses));
      expect(searchResult.totalCount, equals(totalCount));
      expect(searchResult.filterCriteria, equals(testFilterCriteria));
      expect(searchResult.searchQuery, isNull);
    });

    test('hasResults should return true when expenses list is not empty', () {
      // Arrange
      final searchResult = SearchResult(
        expenses: [testExpense],
        totalCount: 1,
        filterCriteria: testFilterCriteria,
      );

      // Act & Assert
      expect(searchResult.hasResults, isTrue);
    });

    test('hasResults should return false when expenses list is empty', () {
      // Arrange
      final searchResult = SearchResult(
        expenses: [],
        totalCount: 0,
        filterCriteria: testFilterCriteria,
      );

      // Act & Assert
      expect(searchResult.hasResults, isFalse);
    });

    test(
        'wasFiltered should return true when filter criteria has active filters',
        () {
      // Arrange
      final filterCriteria = FilterCriteria(
        searchQuery: 'test',
        isActive: true,
      );
      final searchResult = SearchResult(
        expenses: [testExpense],
        totalCount: 1,
        filterCriteria: filterCriteria,
      );

      // Act & Assert
      expect(searchResult.wasFiltered, isTrue);
    });

    test(
        'wasFiltered should return false when filter criteria has no active filters',
        () {
      // Arrange
      final filterCriteria = const FilterCriteria(isActive: false);
      final searchResult = SearchResult(
        expenses: [testExpense],
        totalCount: 1,
        filterCriteria: filterCriteria,
      );

      // Act & Assert
      expect(searchResult.wasFiltered, isFalse);
    });

    test('copyWith should return new instance with updated values', () {
      // Arrange
      final original = SearchResult(
        expenses: [testExpense],
        totalCount: 1,
        filterCriteria: testFilterCriteria,
        searchQuery: 'original',
      );

      // Act
      final updated = original.copyWith(
        totalCount: 2,
        searchQuery: 'updated',
      );

      // Assert
      expect(updated.expenses, equals(original.expenses));
      expect(updated.totalCount, equals(2));
      expect(updated.filterCriteria, equals(original.filterCriteria));
      expect(updated.searchQuery, equals('updated'));
      expect(updated, isNot(same(original)));
    });

    test('should be equal when all properties are the same', () {
      // Arrange
      final result1 = SearchResult(
        expenses: [testExpense],
        totalCount: 1,
        filterCriteria: testFilterCriteria,
        searchQuery: 'test',
      );
      final result2 = SearchResult(
        expenses: [testExpense],
        totalCount: 1,
        filterCriteria: testFilterCriteria,
        searchQuery: 'test',
      );

      // Act & Assert
      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test('should not be equal when properties are different', () {
      // Arrange
      final result1 = SearchResult(
        expenses: [testExpense],
        totalCount: 1,
        filterCriteria: testFilterCriteria,
        searchQuery: 'test1',
      );
      final result2 = SearchResult(
        expenses: [testExpense],
        totalCount: 1,
        filterCriteria: testFilterCriteria,
        searchQuery: 'test2',
      );

      // Act & Assert
      expect(result1, isNot(equals(result2)));
    });

    test('toString should return meaningful representation', () {
      // Arrange
      final searchResult = SearchResult(
        expenses: [testExpense],
        totalCount: 1,
        filterCriteria: testFilterCriteria,
        searchQuery: 'test',
      );

      // Act
      final result = searchResult.toString();

      // Assert
      expect(result, contains('SearchResult'));
      expect(result, contains('expenses: 1'));
      expect(result, contains('totalCount: 1'));
      expect(result, contains('searchQuery: test'));
    });
  });
}
