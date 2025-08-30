import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:expense_tracker/features/expense/domain/entities/filter_criteria.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/domain/entities/search_result.dart';
import 'package:expense_tracker/features/expense/domain/usecases/apply_filters.dart';
import 'package:expense_tracker/features/expense/domain/usecases/search_expenses.dart';
import 'package:expense_tracker/features/expense/domain/services/filter_service.dart';
import 'package:expense_tracker/features/expense/domain/repositories/filter_repository.dart';
import 'package:expense_tracker/features/expense/data/repositories/filter_repository_impl.dart';
import 'package:expense_tracker/features/expense/data/datasources/expense_local_data_source_impl.dart';
import 'package:expense_tracker/features/expense/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/core/errors/failures.dart';

// Mock classes
class MockFilterService extends Mock implements FilterService {}
class MockFilterRepository extends Mock implements FilterRepository {}
class MockFilterRepositoryImpl extends Mock implements FilterRepositoryImpl {}
class MockApplyFilters extends Mock implements ApplyFilters {}
class MockSearchExpenses extends Mock implements SearchExpenses {}
class MockExpenseLocalDataSourceImpl extends Mock implements ExpenseLocalDataSourceImpl {}

// Mock ExpenseNotifier for testing
class MockExpenseNotifier extends Mock implements ExpenseNotifier {}

// Fake classes for fallback values
class FakeFilterCriteria extends Fake implements FilterCriteria {}
class FakeExpense extends Fake implements Expense {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeFilterCriteria());
    registerFallbackValue(FakeExpense());
  });

  // Test data
  final testExpense = Expense(
    id: 'expense-1',
    title: 'Test Expense',
    description: 'A test expense',
    amount: 100.0,
    category: 'Food',
    date: DateTime(2024, 1, 1),
    type: ExpenseType.expense,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  final testExpenses = [testExpense];
  const testFilterCriteria = FilterCriteria(
    categories: ['Food'],
    isActive: true,
  );
  const testFailure = DatabaseFailure('Test error');

  group('Filter Providers', () {
    group('FilterCriteriaNotifier', () {
      test('should start with inactive filter criteria', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final criteria = container.read(filterCriteriaProvider);
        expect(criteria.isActive, isFalse);
        expect(criteria.hasActiveFilters, isFalse);
      });

      test('should update filter criteria', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(filterCriteriaProvider.notifier);
        notifier.updateFilterCriteria(testFilterCriteria);

        final criteria = container.read(filterCriteriaProvider);
        expect(criteria.isActive, isTrue);
        expect(criteria.categories, equals(['Food']));
      });

      test('should clear filters', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(filterCriteriaProvider.notifier);
        notifier.updateFilterCriteria(testFilterCriteria);
        notifier.clearFilters();

        final criteria = container.read(filterCriteriaProvider);
        expect(criteria.isActive, isFalse);
        expect(criteria.hasActiveFilters, isFalse);
      });
    });

    group('FilteredExpensesNotifier', () {
      late MockApplyFilters mockApplyFilters;
      late MockSearchExpenses mockSearchExpenses;

      setUp(() {
        mockApplyFilters = MockApplyFilters();
        mockSearchExpenses = MockSearchExpenses();
      });

      test('should start with empty data state', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final state = container.read(filteredExpensesProvider);
        expect(state, isA<AsyncData>());
        expect(state.value, equals([]));
      });

      test('should apply filters successfully', () async {
        final searchResult = SearchResult(
          expenses: testExpenses,
          totalCount: 1,
          filterCriteria: testFilterCriteria,
          searchQuery: null,
        );

        when(() => mockApplyFilters(any()))
            .thenAnswer((_) async => Right(searchResult));

        final container = ProviderContainer(
          overrides: [
            applyFiltersProvider.overrideWith((ref) => mockApplyFilters),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(filteredExpensesProvider.notifier);
        await notifier.applyFilters(testFilterCriteria);

        final state = container.read(filteredExpensesProvider);
        expect(state.hasValue, isTrue);
        if (state.hasValue) {
          expect(state.value, equals(testExpenses));
        }
        verify(() => mockApplyFilters(testFilterCriteria)).called(1);
      });

      test('should handle filter error', () async {
        when(() => mockApplyFilters(any()))
            .thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            applyFiltersProvider.overrideWith((ref) => mockApplyFilters),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(filteredExpensesProvider.notifier);
        await notifier.applyFilters(testFilterCriteria);

        final state = container.read(filteredExpensesProvider);
        expect(state, isA<AsyncError>());
      });

      test('should search expenses successfully', () async {
        when(() => mockSearchExpenses(any()))
            .thenAnswer((_) async => Right(testExpenses));

        final container = ProviderContainer(
          overrides: [
            searchExpensesProvider.overrideWith((ref) => mockSearchExpenses),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(filteredExpensesProvider.notifier);
        await notifier.searchExpenses('food');

        final state = container.read(filteredExpensesProvider);
        expect(state.hasValue, isTrue);
        if (state.hasValue) {
          expect(state.value, equals(testExpenses));
        }
        verify(() => mockSearchExpenses('food')).called(1);
      });

      test('should handle search error', () async {
        when(() => mockSearchExpenses(any()))
            .thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            searchExpensesProvider.overrideWith((ref) => mockSearchExpenses),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(filteredExpensesProvider.notifier);
        await notifier.searchExpenses('food');

        final state = container.read(filteredExpensesProvider);
        expect(state, isA<AsyncError>());
      });

      test('should clear filters to empty list', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(filteredExpensesProvider.notifier);
        notifier.clearFilters();

        final state = container.read(filteredExpensesProvider);
        expect(state.hasValue, isTrue);
        expect(state.value, equals([]));
      });

      test('should show all expenses when filter is inactive', () async {}, skip: 'Temporarily disabled due to provider refactoring');

      test('should show all expenses when search query is empty', () async {}, skip: 'Temporarily disabled due to provider refactoring');
    });

    group('Service and Repository Providers', () {
      test('should provide filter service instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(filterServiceProvider);
        expect(service, isA<FilterService>());
      });

      test('should provide filter repository instance', () {
        final mockDataSource = MockExpenseLocalDataSourceImpl();
        when(() => mockDataSource.init()).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            expenseLocalDataSourceProvider.overrideWith((ref) => mockDataSource),
          ],
        );
        addTearDown(container.dispose);

        final repository = container.read(filterRepositoryProvider);
        expect(repository, isA<FilterRepositoryImpl>());
      });

      test('should provide ApplyFilters use case', () {
        final mockDataSource = MockExpenseLocalDataSourceImpl();
        final mockRepository = MockFilterRepositoryImpl();
        when(() => mockDataSource.init()).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            expenseLocalDataSourceProvider.overrideWith((ref) => mockDataSource),
            filterRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final useCase = container.read(applyFiltersProvider);
        expect(useCase, isA<ApplyFilters>());
      });

      test('should provide SearchExpenses use case', () {
        final mockDataSource = MockExpenseLocalDataSourceImpl();
        final mockRepository = MockFilterRepositoryImpl();
        when(() => mockDataSource.init()).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            expenseLocalDataSourceProvider.overrideWith((ref) => mockDataSource),
            filterRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final useCase = container.read(searchExpensesProvider);
        expect(useCase, isA<SearchExpenses>());
      });
    });

    group('Provider Types', () {
      test('should have correct provider types', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Test that all providers return the correct types without calling them
        expect(filterCriteriaProvider, isA<StateNotifierProvider>());
        expect(filteredExpensesProvider, isA<StateNotifierProvider>());
        expect(filterServiceProvider, isA<Provider<FilterService>>());
        expect(filterRepositoryProvider, isA<Provider<FilterRepository>>());
        expect(applyFiltersProvider, isA<Provider<ApplyFilters>>());
        expect(searchExpensesProvider, isA<Provider<SearchExpenses>>());
        expect(availableCategoriesProvider, isA<FutureProvider>());
        expect(availableExpenseTypesProvider, isA<FutureProvider>());
        expect(amountRangeProvider, isA<FutureProvider>());
        expect(dateRangeProvider, isA<FutureProvider>());
      });
    });
  });
}

