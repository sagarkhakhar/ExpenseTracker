import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/entities/filter_criteria.dart';

import 'package:expense_tracker/features/expense/domain/services/filter_service.dart';

void main() {
  group('FilterService', () {
    late FilterService filterService;
    late List<Expense> testExpenses;

    setUp(() {
      filterService = FilterService();

      testExpenses = [
        Expense(
          id: '1',
          title: 'Lunch',
          description: 'Business lunch',
          amount: 25.0,
          category: 'food',
          type: ExpenseType.expense,
          date: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        ),
        Expense(
          id: '2',
          title: 'Gas',
          description: 'Fuel for car',
          amount: 50.0,
          category: 'transport',
          type: ExpenseType.expense,
          date: DateTime(2024, 1, 20),
          createdAt: DateTime(2024, 1, 20),
          updatedAt: DateTime(2024, 1, 20),
        ),
        Expense(
          id: '3',
          title: 'Salary',
          description: 'Monthly salary',
          amount: 3000.0,
          category: 'income',
          type: ExpenseType.income,
          date: DateTime(2024, 1, 25),
          createdAt: DateTime(2024, 1, 25),
          updatedAt: DateTime(2024, 1, 25),
        ),
        Expense(
          id: '4',
          title: 'Dinner',
          description: 'Restaurant dinner',
          amount: 75.0,
          category: 'food',
          type: ExpenseType.expense,
          date: DateTime(2024, 2, 1),
          createdAt: DateTime(2024, 2, 1),
          updatedAt: DateTime(2024, 2, 1),
        ),
      ];
    });

    group('applyDateRangeFilter', () {
      test('should filter expenses within date range', () {
        // Arrange
        final dateRange = DateTimeRange(
          start: DateTime(2024, 1, 10),
          end: DateTime(2024, 1, 25),
        );

        // Act
        final result =
            filterService.applyDateRangeFilter(testExpenses, dateRange);

        // Assert
        expect(result.length, equals(3));
        expect(result.map((e) => e.id), containsAll(['1', '2', '3']));
      });

      test('should return empty list when no expenses in date range', () {
        // Arrange
        final dateRange = DateTimeRange(
          start: DateTime(2024, 3, 1),
          end: DateTime(2024, 3, 31),
        );

        // Act
        final result =
            filterService.applyDateRangeFilter(testExpenses, dateRange);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('applyCategoryFilter', () {
      test('should filter expenses by category', () {
        // Arrange
        const categories = ['food'];

        // Act
        final result =
            filterService.applyCategoryFilter(testExpenses, categories);

        // Assert
        expect(result.length, equals(2));
        expect(result.map((e) => e.category), everyElement(equals('food')));
      });

      test('should filter expenses by multiple categories', () {
        // Arrange
        const categories = ['food', 'transport'];

        // Act
        final result =
            filterService.applyCategoryFilter(testExpenses, categories);

        // Assert
        expect(result.length, equals(3));
        expect(
            result.map((e) => e.category), containsAll(['food', 'transport']));
      });

      test('should return all expenses when categories list is empty', () {
        // Arrange
        const categories = <String>[];

        // Act
        final result =
            filterService.applyCategoryFilter(testExpenses, categories);

        // Assert
        expect(result.length, equals(testExpenses.length));
      });
    });

    group('applyAmountRangeFilter', () {
      test('should filter expenses within amount range', () {
        // Arrange
        const amountRange = Range(min: 20.0, max: 80.0);

        // Act
        final result =
            filterService.applyAmountRangeFilter(testExpenses, amountRange);

        // Assert
        expect(result.length, equals(3));
        expect(result.map((e) => e.id), containsAll(['1', '2', '4']));
      });

      test('should filter expenses with only min amount', () {
        // Arrange
        const amountRange = Range(min: 50.0);

        // Act
        final result =
            filterService.applyAmountRangeFilter(testExpenses, amountRange);

        // Assert
        expect(result.length, equals(3));
        expect(result.map((e) => e.id), containsAll(['2', '3', '4']));
      });

      test('should filter expenses with only max amount', () {
        // Arrange
        const amountRange = Range(max: 50.0);

        // Act
        final result =
            filterService.applyAmountRangeFilter(testExpenses, amountRange);

        // Assert
        expect(result.length, equals(2));
        expect(result.map((e) => e.id), containsAll(['1', '2']));
      });
    });

    group('applyExpenseTypeFilter', () {
      test('should filter expenses by type', () {
        // Arrange
        const expenseType = ExpenseType.expense;

        // Act
        final result =
            filterService.applyExpenseTypeFilter(testExpenses, expenseType);

        // Assert
        expect(result.length, equals(3));
        expect(result.map((e) => e.type),
            everyElement(equals(ExpenseType.expense)));
      });

      test('should filter income transactions', () {
        // Arrange
        const expenseType = ExpenseType.income;

        // Act
        final result =
            filterService.applyExpenseTypeFilter(testExpenses, expenseType);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.type, equals(ExpenseType.income));
      });
    });

    group('applyTextSearchFilter', () {
      test('should filter expenses by title', () {
        // Arrange
        const searchQuery = 'lunch';

        // Act
        final result =
            filterService.applyTextSearchFilter(testExpenses, searchQuery);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.title.toLowerCase(), contains('lunch'));
      });

      test('should filter expenses by description', () {
        // Arrange
        const searchQuery = 'business';

        // Act
        final result =
            filterService.applyTextSearchFilter(testExpenses, searchQuery);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.description.toLowerCase(), contains('business'));
      });

      test('should filter expenses by both title and description', () {
        // Arrange
        const searchQuery = 'dinner';

        // Act
        final result =
            filterService.applyTextSearchFilter(testExpenses, searchQuery);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.title.toLowerCase(), contains('dinner'));
      });

      test('should return all expenses when search query is empty', () {
        // Arrange
        const searchQuery = '';

        // Act
        final result =
            filterService.applyTextSearchFilter(testExpenses, searchQuery);

        // Assert
        expect(result.length, equals(testExpenses.length));
      });

      test('should return all expenses when search query is whitespace only',
          () {
        // Arrange
        const searchQuery = '   ';

        // Act
        final result =
            filterService.applyTextSearchFilter(testExpenses, searchQuery);

        // Assert
        expect(result.length, equals(testExpenses.length));
      });
    });

    group('applyFilters', () {
      test('should apply multiple filters', () {
        // Arrange
        const filterCriteria = FilterCriteria(
          categories: ['food'],
          amountRange: Range(max: 50.0),
          isActive: true,
        );

        // Act
        final result = filterService.applyFilters(testExpenses, filterCriteria);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.id, equals('1')); // Lunch expense
      });

      test('should return all expenses when no filters are active', () {
        // Arrange
        const filterCriteria = FilterCriteria(isActive: false);

        // Act
        final result = filterService.applyFilters(testExpenses, filterCriteria);

        // Assert
        expect(result.length, equals(testExpenses.length));
      });

      test('should apply all filter types', () {
        // Arrange
        final filterCriteria = FilterCriteria(
          dateRange: DateTimeRange(
            start: DateTime(2024, 1, 10),
            end: DateTime(2024, 1, 25),
          ),
          categories: const ['food'],
          amountRange: const Range(min: 20.0, max: 80.0),
          expenseType: ExpenseType.expense,
          searchQuery: 'lunch',
          isActive: true,
        );

        // Act
        final result = filterService.applyFilters(testExpenses, filterCriteria);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.id, equals('1')); // Lunch expense
      });
    });

    group('createSearchResult', () {
      test('should create search result with correct data', () {
        // Arrange
        final filteredExpenses = [testExpenses[0], testExpenses[1]];
        const filterCriteria = FilterCriteria(
          categories: ['food', 'transport'],
          isActive: true,
        );
        const searchQuery = 'test';

        // Act
        final result = filterService.createSearchResult(
          testExpenses,
          filteredExpenses,
          filterCriteria,
          searchQuery,
        );

        // Assert
        expect(result.expenses, equals(filteredExpenses));
        expect(result.totalCount, equals(2));
        expect(result.filterCriteria, equals(filterCriteria));
        expect(result.searchQuery, equals(searchQuery));
      });
    });

    group('getAvailableCategories', () {
      test('should return sorted unique categories', () {
        // Act
        final result = filterService.getAvailableCategories(testExpenses);

        // Assert
        expect(result, equals(['food', 'income', 'transport']));
      });
    });

    group('getAvailableExpenseTypes', () {
      test('should return unique expense types', () {
        // Act
        final result = filterService.getAvailableExpenseTypes(testExpenses);

        // Assert
        expect(result, containsAll([ExpenseType.expense, ExpenseType.income]));
      });
    });

    group('getAmountRange', () {
      test('should return correct amount range', () {
        // Act
        final result = filterService.getAmountRange(testExpenses);

        // Assert
        expect(result.min, equals(25.0));
        expect(result.max, equals(3000.0));
      });

      test('should return empty range for empty list', () {
        // Act
        final result = filterService.getAmountRange([]);

        // Assert
        expect(result.min, isNull);
        expect(result.max, isNull);
      });
    });

    group('getDateRange', () {
      test('should return correct date range', () {
        // Act
        final result = filterService.getDateRange(testExpenses);

        // Assert
        expect(result!.start, equals(DateTime(2024, 1, 15)));
        expect(result.end, equals(DateTime(2024, 2, 1)));
      });

      test('should return null for empty list', () {
        // Act
        final result = filterService.getDateRange([]);

        // Assert
        expect(result, isNull);
      });
    });

    group('isValidFilterCriteria', () {
      test('should return true for valid filter criteria', () {
        // Arrange
        final filterCriteria = FilterCriteria(
          dateRange: DateTimeRange(
            start: DateTime(2024, 1, 1),
            end: DateTime(2024, 12, 31),
          ),
          amountRange: const Range(min: 10.0, max: 100.0),
          searchQuery: 'test',
          isActive: true,
        );

        // Act
        final result = filterService.isValidFilterCriteria(filterCriteria);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for invalid date range', () {
        // Arrange
        final filterCriteria = FilterCriteria(
          dateRange: DateTimeRange(
            start: DateTime(2024, 12, 31),
            end: DateTime(2024, 1, 1),
          ),
          isActive: true,
        );

        // Act
        final result = filterService.isValidFilterCriteria(filterCriteria);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for invalid amount range', () {
        // Arrange
        const filterCriteria = FilterCriteria(
          amountRange: Range(min: 100.0, max: 10.0),
          isActive: true,
        );

        // Act
        final result = filterService.isValidFilterCriteria(filterCriteria);

        // Assert
        expect(result, isFalse);
      });

      test('should return false for empty search query', () {
        // Arrange
        const filterCriteria = FilterCriteria(
          searchQuery: '   ',
          isActive: true,
        );

        // Act
        final result = filterService.isValidFilterCriteria(filterCriteria);

        // Assert
        expect(result, isFalse);
      });
    });

    group('getFilterSummary', () {
      test('should return summary for all filter types', () {
        // Arrange
        final filterCriteria = FilterCriteria(
          dateRange: DateTimeRange(
            start: DateTime(2024, 1, 1),
            end: DateTime(2024, 12, 31),
          ),
          categories: const ['food', 'transport'],
          amountRange: const Range(min: 10.0, max: 100.0),
          expenseType: ExpenseType.expense,
          searchQuery: 'lunch',
          isActive: true,
        );

        // Act
        final result = filterService.getFilterSummary(filterCriteria);

        // Assert
        expect(result, contains('Date: 2024-01-01 - 2024-12-31'));
        expect(result, contains('Categories: food, transport'));
        expect(result, contains('Amount: \$10.0 - 100.0'));
        expect(result, contains('Type: expense'));
        expect(result, contains('Search: "lunch"'));
      });

      test('should return "No filters applied" for empty criteria', () {
        // Arrange
        const filterCriteria = FilterCriteria(isActive: false);

        // Act
        final result = filterService.getFilterSummary(filterCriteria);

        // Assert
        expect(result, equals('No filters applied'));
      });
    });
  });
}
