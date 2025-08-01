import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/expense/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';
import 'package:expense_tracker/features/expense/data/repositories/filter_repository_impl.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/entities/filter_criteria.dart';
import 'package:expense_tracker/features/expense/domain/entities/search_result.dart';
import 'package:expense_tracker/features/expense/domain/services/filter_service.dart';

class MockExpenseLocalDataSource extends Mock
    implements ExpenseLocalDataSource {}

class MockFilterService extends Mock implements FilterService {}

void main() {
  setUpAll(() {
    registerFallbackValue(const FilterCriteria());
  });

  group('FilterRepositoryImpl', () {
    late FilterRepositoryImpl repository;
    late MockExpenseLocalDataSource mockLocalDataSource;
    late MockFilterService mockFilterService;

    setUp(() {
      mockLocalDataSource = MockExpenseLocalDataSource();
      mockFilterService = MockFilterService();
      repository = FilterRepositoryImpl(
        localDataSource: mockLocalDataSource,
        filterService: mockFilterService,
      );
    });

    group('searchExpenses', () {
      test('should return SearchResult when successful', () async {
        // Arrange
        final testExpenses = [
          ExpenseModel(
            id: '1',
            title: 'Test Expense',
            description: 'Test Description',
            amount: 100.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];
        final filterCriteria = FilterCriteria(
          searchQuery: 'test',
          isActive: true,
        );
        final filteredExpenses = [testExpenses[0].toEntity()];
        final searchResult = SearchResult(
          expenses: filteredExpenses,
          totalCount: 1,
          filterCriteria: filterCriteria,
          searchQuery: 'test',
        );

        when(() => mockLocalDataSource.getAllExpenses())
            .thenAnswer((_) async => testExpenses);
        when(() => mockFilterService.applyFilters(any(), any()))
            .thenReturn(filteredExpenses);
        when(() => mockFilterService.createSearchResult(
            any(), any(), any(), any())).thenReturn(searchResult);

        // Act
        final result = await repository.searchExpenses(filterCriteria);

        // Assert
        expect(result, Right(searchResult));
        verify(() => mockLocalDataSource.getAllExpenses()).called(1);
        verify(() => mockFilterService.applyFilters(any(), filterCriteria))
            .called(1);
        verify(() => mockFilterService.createSearchResult(
              testExpenses.map((e) => e.toEntity()).toList(),
              filteredExpenses,
              filterCriteria,
              'test',
            )).called(1);
      });

      test('should return DatabaseFailure when localDataSource throws',
          () async {
        // Arrange
        final filterCriteria = FilterCriteria(
          searchQuery: 'test',
          isActive: true,
        );

        when(() => mockLocalDataSource.getAllExpenses())
            .thenThrow(Exception('Database error'));

        // Act
        final result = await repository.searchExpenses(filterCriteria);

        // Assert
        expect(
            result,
            Left(DatabaseFailure(
                'Failed to search expenses: Exception: Database error')));
      });
    });

    group('getAvailableCategories', () {
      test('should return list of categories when successful', () async {
        // Arrange
        final testExpenses = [
          ExpenseModel(
            id: '1',
            title: 'Test Expense',
            description: 'Test Description',
            amount: 100.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];
        const categories = ['food'];

        when(() => mockLocalDataSource.getAllExpenses())
            .thenAnswer((_) async => testExpenses);
        when(() => mockFilterService.getAvailableCategories(any()))
            .thenReturn(categories);

        // Act
        final result = await repository.getAvailableCategories();

        // Assert
        expect(result, Right(categories));
        verify(() => mockLocalDataSource.getAllExpenses()).called(1);
        verify(() => mockFilterService.getAvailableCategories(any())).called(1);
      });

      test('should return DatabaseFailure when localDataSource throws',
          () async {
        // Arrange
        when(() => mockLocalDataSource.getAllExpenses())
            .thenThrow(Exception('Database error'));

        // Act
        final result = await repository.getAvailableCategories();

        // Assert
        expect(
            result,
            Left(DatabaseFailure(
                'Failed to get categories: Exception: Database error')));
      });
    });

    group('getAvailableExpenseTypes', () {
      test('should return list of expense types when successful', () async {
        // Arrange
        final testExpenses = [
          ExpenseModel(
            id: '1',
            title: 'Test Expense',
            description: 'Test Description',
            amount: 100.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];
        final types = [ExpenseType.expense];

        when(() => mockLocalDataSource.getAllExpenses())
            .thenAnswer((_) async => testExpenses);
        when(() => mockFilterService.getAvailableExpenseTypes(any()))
            .thenReturn(types);

        // Act
        final result = await repository.getAvailableExpenseTypes();

        // Assert
        expect(result, isA<Right<Failure, List<String>>>());
        expect(result.fold((l) => null, (r) => r), equals(['expense']));
        verify(() => mockLocalDataSource.getAllExpenses()).called(1);
        verify(() => mockFilterService.getAvailableExpenseTypes(any()))
            .called(1);
      });
    });

    group('getAmountRange', () {
      test('should return Range when successful', () async {
        // Arrange
        final testExpenses = [
          ExpenseModel(
            id: '1',
            title: 'Test Expense',
            description: 'Test Description',
            amount: 100.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];
        const amountRange = Range(min: 100.0, max: 100.0);

        when(() => mockLocalDataSource.getAllExpenses())
            .thenAnswer((_) async => testExpenses);
        when(() => mockFilterService.getAmountRange(any()))
            .thenReturn(amountRange);

        // Act
        final result = await repository.getAmountRange();

        // Assert
        expect(result, Right(amountRange));
        verify(() => mockLocalDataSource.getAllExpenses()).called(1);
        verify(() => mockFilterService.getAmountRange(any())).called(1);
      });
    });

    group('getDateRange', () {
      test('should return DateTimeRange when successful', () async {
        // Arrange
        final testExpenses = [
          ExpenseModel(
            id: '1',
            title: 'Test Expense',
            description: 'Test Description',
            amount: 100.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];
        final dateRange = DateTimeRange(
          start: DateTime(2024, 1, 1),
          end: DateTime(2024, 1, 1),
        );

        when(() => mockLocalDataSource.getAllExpenses())
            .thenAnswer((_) async => testExpenses);
        when(() => mockFilterService.getDateRange(any())).thenReturn(dateRange);

        // Act
        final result = await repository.getDateRange();

        // Assert
        expect(result, Right(dateRange));
        verify(() => mockLocalDataSource.getAllExpenses()).called(1);
        verify(() => mockFilterService.getDateRange(any())).called(1);
      });
    });

    group('searchByText', () {
      test('should return filtered expenses when successful', () async {
        // Arrange
        final testExpenses = [
          ExpenseModel(
            id: '1',
            title: 'Test Expense',
            description: 'Test Description',
            amount: 100.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];
        final filteredExpenses = [testExpenses[0].toEntity()];
        const query = 'test';

        when(() => mockLocalDataSource.getAllExpenses())
            .thenAnswer((_) async => testExpenses);
        when(() => mockFilterService.applyTextSearchFilter(any(), query))
            .thenReturn(filteredExpenses);

        // Act
        final result = await repository.searchByText(query);

        // Assert
        expect(result, Right(filteredExpenses));
        verify(() => mockLocalDataSource.getAllExpenses()).called(1);
        verify(() => mockFilterService.applyTextSearchFilter(any(), query))
            .called(1);
      });
    });

    group('getExpensesByDateRange', () {
      test('should return expenses when successful', () async {
        // Arrange
        final testExpenses = [
          ExpenseModel(
            id: '1',
            title: 'Test Expense',
            description: 'Test Description',
            amount: 100.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);

        when(() => mockLocalDataSource.getExpensesByDateRange(start, end))
            .thenAnswer((_) async => testExpenses);

        // Act
        final result = await repository.getExpensesByDateRange(start, end);

        // Assert
        expect(result, isA<Right<Failure, List<Expense>>>());
        expect(result.fold((l) => null, (r) => r),
            equals(testExpenses.map((e) => e.toEntity()).toList()));
        verify(() => mockLocalDataSource.getExpensesByDateRange(start, end))
            .called(1);
      });
    });

    group('getExpensesByCategories', () {
      test('should return filtered expenses when successful', () async {
        // Arrange
        final testExpenses = [
          ExpenseModel(
            id: '1',
            title: 'Test Expense',
            description: 'Test Description',
            amount: 100.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];
        final filteredExpenses = [testExpenses[0].toEntity()];
        const categories = ['food'];

        when(() => mockLocalDataSource.getAllExpenses())
            .thenAnswer((_) async => testExpenses);
        when(() => mockFilterService.applyCategoryFilter(any(), categories))
            .thenReturn(filteredExpenses);

        // Act
        final result = await repository.getExpensesByCategories(categories);

        // Assert
        expect(result, Right(filteredExpenses));
        verify(() => mockLocalDataSource.getAllExpenses()).called(1);
        verify(() => mockFilterService.applyCategoryFilter(any(), categories))
            .called(1);
      });
    });

    group('getExpensesByAmountRange', () {
      test('should return filtered expenses when successful', () async {
        // Arrange
        final testExpenses = [
          ExpenseModel(
            id: '1',
            title: 'Test Expense',
            description: 'Test Description',
            amount: 100.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];
        final filteredExpenses = [testExpenses[0].toEntity()];
        const amountRange = Range(min: 50.0, max: 150.0);

        when(() => mockLocalDataSource.getAllExpenses())
            .thenAnswer((_) async => testExpenses);
        when(() => mockFilterService.applyAmountRangeFilter(any(), amountRange))
            .thenReturn(filteredExpenses);

        // Act
        final result = await repository.getExpensesByAmountRange(amountRange);

        // Assert
        expect(result, Right(filteredExpenses));
        verify(() => mockLocalDataSource.getAllExpenses()).called(1);
        verify(() =>
                mockFilterService.applyAmountRangeFilter(any(), amountRange))
            .called(1);
      });
    });

    group('getExpensesByType', () {
      test('should return expenses when successful', () async {
        // Arrange
        final testExpenses = [
          ExpenseModel(
            id: '1',
            title: 'Test Expense',
            description: 'Test Description',
            amount: 100.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];

        when(() => mockLocalDataSource.getExpensesByType(ExpenseType.expense))
            .thenAnswer((_) async => testExpenses);

        // Act
        final result = await repository.getExpensesByType('expense');

        // Assert
        expect(result, isA<Right<Failure, List<Expense>>>());
        expect(result.fold((l) => null, (r) => r),
            equals(testExpenses.map((e) => e.toEntity()).toList()));
        verify(() => mockLocalDataSource.getExpensesByType(ExpenseType.expense))
            .called(1);
      });
    });

    group('getFilteredExpenseCount', () {
      test('should return count when successful', () async {
        // Arrange
        final testExpenses = [
          ExpenseModel(
            id: '1',
            title: 'Test Expense',
            description: 'Test Description',
            amount: 100.0,
            category: 'food',
            type: ExpenseType.expense,
            date: DateTime(2024, 1, 1),
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ];
        final filterCriteria = FilterCriteria(
          searchQuery: 'test',
          isActive: true,
        );
        final filteredExpenses = [testExpenses[0].toEntity()];

        when(() => mockLocalDataSource.getAllExpenses())
            .thenAnswer((_) async => testExpenses);
        when(() => mockFilterService.applyFilters(any(), filterCriteria))
            .thenReturn(filteredExpenses);

        // Act
        final result = await repository.getFilteredExpenseCount(filterCriteria);

        // Assert
        expect(result, Right(1));
        verify(() => mockLocalDataSource.getAllExpenses()).called(1);
        verify(() => mockFilterService.applyFilters(any(), filterCriteria))
            .called(1);
      });
    });

    group('saveFilterCriteria', () {
      test('should return true when successful', () async {
        // Arrange
        final filterCriteria = FilterCriteria(
          searchQuery: 'test',
          isActive: true,
        );

        // Act
        final result = await repository.saveFilterCriteria(filterCriteria);

        // Assert
        expect(result, const Right(true));
      });
    });

    group('loadFilterCriteria', () {
      test('should return null when successful', () async {
        // Act
        final result = await repository.loadFilterCriteria();

        // Assert
        expect(result, const Right(null));
      });
    });

    group('clearFilterCriteria', () {
      test('should return true when successful', () async {
        // Act
        final result = await repository.clearFilterCriteria();

        // Assert
        expect(result, const Right(true));
      });
    });
  });
}
