import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/entities/filter_criteria.dart';

void main() {
  group('FilterCriteria', () {
    test('should create FilterCriteria with default values', () {
      // Arrange & Act
      const filterCriteria = FilterCriteria();

      // Assert
      expect(filterCriteria.dateRange, isNull);
      expect(filterCriteria.categories, isNull);
      expect(filterCriteria.amountRange, isNull);
      expect(filterCriteria.expenseType, isNull);
      expect(filterCriteria.searchQuery, isNull);
      expect(filterCriteria.isActive, isFalse);
    });

    test('should create FilterCriteria with all parameters', () {
      // Arrange
      final dateRange = DateTimeRange(
        start: DateTime(2024, 1, 1),
        end: DateTime(2024, 12, 31),
      );
      const categories = ['food', 'transport'];
      const amountRange = Range(min: 10.0, max: 100.0);
      const expenseType = ExpenseType.expense;
      const searchQuery = 'lunch';

      // Act
      final filterCriteria = FilterCriteria(
        dateRange: dateRange,
        categories: categories,
        amountRange: amountRange,
        expenseType: expenseType,
        searchQuery: searchQuery,
        isActive: true,
      );

      // Assert
      expect(filterCriteria.dateRange, equals(dateRange));
      expect(filterCriteria.categories, equals(categories));
      expect(filterCriteria.amountRange, equals(amountRange));
      expect(filterCriteria.expenseType, equals(expenseType));
      expect(filterCriteria.searchQuery, equals(searchQuery));
      expect(filterCriteria.isActive, isTrue);
    });

    test('hasActiveFilters should return true when filters are set', () {
      // Arrange
      final filterCriteria = FilterCriteria(
        dateRange: DateTimeRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 12, 31),
        ),
        isActive: true,
      );

      // Act & Assert
      expect(filterCriteria.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters should return true when categories are set', () {
      // Arrange
      const filterCriteria = FilterCriteria(
        categories: ['food'],
        isActive: true,
      );

      // Act & Assert
      expect(filterCriteria.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters should return true when amount range is set', () {
      // Arrange
      final filterCriteria = FilterCriteria(
        amountRange: Range(min: 10.0, max: 100.0),
        isActive: true,
      );

      // Act & Assert
      expect(filterCriteria.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters should return true when expense type is set', () {
      // Arrange
      const filterCriteria = FilterCriteria(
        expenseType: ExpenseType.expense,
        isActive: true,
      );

      // Act & Assert
      expect(filterCriteria.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters should return true when search query is set', () {
      // Arrange
      const filterCriteria = FilterCriteria(
        searchQuery: 'lunch',
        isActive: true,
      );

      // Act & Assert
      expect(filterCriteria.hasActiveFilters, isTrue);
    });

    test('hasActiveFilters should return false when no filters are set', () {
      // Arrange
      const filterCriteria = FilterCriteria(isActive: true);

      // Act & Assert
      expect(filterCriteria.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters should return false when categories list is empty',
        () {
      // Arrange
      const filterCriteria = FilterCriteria(
        categories: [],
        isActive: true,
      );

      // Act & Assert
      expect(filterCriteria.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters should return false when search query is empty', () {
      // Arrange
      const filterCriteria = FilterCriteria(
        searchQuery: '',
        isActive: true,
      );

      // Act & Assert
      expect(filterCriteria.hasActiveFilters, isFalse);
    });

    test('copyWith should return new instance with updated values', () {
      // Arrange
      const original = FilterCriteria(
        searchQuery: 'original',
        isActive: true,
      );

      // Act
      final updated = original.copyWith(
        searchQuery: 'updated',
        expenseType: ExpenseType.income,
      );

      // Assert
      expect(updated.searchQuery, equals('updated'));
      expect(updated.expenseType, equals(ExpenseType.income));
      expect(updated.isActive, equals(true));
      expect(updated, isNot(same(original)));
    });

    test('clear should return new instance with all filters cleared', () {
      // Arrange
      final original = FilterCriteria(
        dateRange: DateTimeRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 12, 31),
        ),
        categories: ['food'],
        amountRange: Range(min: 10.0, max: 100.0),
        expenseType: ExpenseType.expense,
        searchQuery: 'lunch',
        isActive: true,
      );

      // Act
      final cleared = original.clear();

      // Assert
      expect(cleared.dateRange, isNull);
      expect(cleared.categories, isNull);
      expect(cleared.amountRange, isNull);
      expect(cleared.expenseType, isNull);
      expect(cleared.searchQuery, isNull);
      expect(cleared.isActive, isFalse);
    });

    test('should be equal when all properties are the same', () {
      // Arrange
      const filter1 = FilterCriteria(
        searchQuery: 'test',
        isActive: true,
      );
      const filter2 = FilterCriteria(
        searchQuery: 'test',
        isActive: true,
      );

      // Act & Assert
      expect(filter1, equals(filter2));
      expect(filter1.hashCode, equals(filter2.hashCode));
    });

    test('should not be equal when properties are different', () {
      // Arrange
      const filter1 = FilterCriteria(
        searchQuery: 'test1',
        isActive: true,
      );
      const filter2 = FilterCriteria(
        searchQuery: 'test2',
        isActive: true,
      );

      // Act & Assert
      expect(filter1, isNot(equals(filter2)));
    });
  });

  group('Range', () {
    test('should create Range with min and max values', () {
      // Arrange & Act
      const range = Range(min: 10.0, max: 100.0);

      // Assert
      expect(range.min, equals(10.0));
      expect(range.max, equals(100.0));
    });

    test('should create Range with only min value', () {
      // Arrange & Act
      const range = Range(min: 10.0);

      // Assert
      expect(range.min, equals(10.0));
      expect(range.max, isNull);
    });

    test('should create Range with only max value', () {
      // Arrange & Act
      const range = Range(max: 100.0);

      // Assert
      expect(range.min, isNull);
      expect(range.max, equals(100.0));
    });

    test('should be equal when min and max are the same', () {
      // Arrange
      const range1 = Range(min: 10.0, max: 100.0);
      const range2 = Range(min: 10.0, max: 100.0);

      // Act & Assert
      expect(range1, equals(range2));
    });
  });

  group('DateTimeRange', () {
    test('should create DateTimeRange with start and end dates', () {
      // Arrange
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 12, 31);

      // Act
      final dateRange = DateTimeRange(start: start, end: end);

      // Assert
      expect(dateRange.start, equals(start));
      expect(dateRange.end, equals(end));
    });

    test('should be equal when start and end are the same', () {
      // Arrange
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 12, 31);
      final range1 = DateTimeRange(start: start, end: end);
      final range2 = DateTimeRange(start: start, end: end);

      // Act & Assert
      expect(range1, equals(range2));
    });
  });
}
