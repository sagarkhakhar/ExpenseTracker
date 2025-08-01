import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/expense/domain/entities/filter_criteria.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

import 'package:expense_tracker/features/expense/domain/usecases/apply_filters.dart';
import 'package:expense_tracker/features/expense/domain/usecases/search_expenses.dart';
import 'package:expense_tracker/features/expense/domain/services/filter_service.dart';
import 'package:expense_tracker/features/expense/domain/repositories/filter_repository.dart';
import 'package:expense_tracker/features/expense/data/repositories/filter_repository_impl.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_providers.dart';

// Provider for current filter criteria
class FilterCriteriaNotifier extends StateNotifier<FilterCriteria> {
  FilterCriteriaNotifier() : super(const FilterCriteria(isActive: false));

  void updateFilterCriteria(FilterCriteria criteria) {
    state = criteria;
  }

  void clearFilters() {
    state = const FilterCriteria(isActive: false);
  }
}

final filterCriteriaProvider =
    StateNotifierProvider<FilterCriteriaNotifier, FilterCriteria>(
  (ref) => FilterCriteriaNotifier(),
);

// Provider for filtered expenses
class FilteredExpensesNotifier
    extends StateNotifier<AsyncValue<List<Expense>>> {
  final Ref _ref;

  FilteredExpensesNotifier(this._ref) : super(const AsyncValue.data([]));

  Future<void> applyFilters(FilterCriteria criteria) async {
    if (!criteria.isActive) {
      // If no filters are active, show all expenses
      final allExpensesAsync = _ref.read(expenseNotifierProvider);
      state = allExpensesAsync;
      return;
    }

    state = const AsyncValue.loading();

    try {
      final applyFilters = await _ref.read(applyFiltersProvider.future);
      final result = await applyFilters(criteria);

      state = result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (searchResult) => AsyncValue.data(searchResult.expenses),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchExpenses(String query) async {
    if (query.trim().isEmpty) {
      // If search query is empty, show all expenses
      final allExpensesAsync = _ref.read(expenseNotifierProvider);
      state = allExpensesAsync;
      return;
    }

    state = const AsyncValue.loading();

    try {
      final searchExpenses = await _ref.read(searchExpensesProvider.future);
      final result = await searchExpenses(query);

      state = result.fold(
        (failure) => AsyncValue.error(failure, StackTrace.current),
        (expenses) => AsyncValue.data(expenses),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearFilters() {
    state = const AsyncValue.data([]);
  }
}

final filteredExpensesProvider =
    StateNotifierProvider<FilteredExpensesNotifier, AsyncValue<List<Expense>>>(
  (ref) => FilteredExpensesNotifier(ref),
);

// Provider for available categories
final availableCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final filterService = ref.read(filterServiceProvider);
  final expenses = ref.read(expenseNotifierProvider);
  return expenses.when(
    data: (expenseList) => filterService.getAvailableCategories(expenseList),
    loading: () => <String>[],
    error: (_, __) => <String>[],
  );
});

// Provider for available expense types
final availableExpenseTypesProvider = FutureProvider<List<String>>((ref) async {
  final filterService = ref.read(filterServiceProvider);
  final expenses = ref.read(expenseNotifierProvider);
  return expenses.when(
    data: (expenseList) => filterService
        .getAvailableExpenseTypes(expenseList)
        .map((e) => e.name)
        .toList(),
    loading: () => <String>[],
    error: (_, __) => <String>[],
  );
});

// Provider for amount range
final amountRangeProvider = FutureProvider<Range>((ref) async {
  final filterService = ref.read(filterServiceProvider);
  final expenses = ref.read(expenseNotifierProvider);
  return expenses.when(
    data: (expenseList) => filterService.getAmountRange(expenseList),
    loading: () => const Range(),
    error: (_, __) => const Range(),
  );
});

// Provider for date range
final dateRangeProvider = FutureProvider<DateTimeRange?>((ref) async {
  final filterService = ref.read(filterServiceProvider);
  final expenses = ref.read(expenseNotifierProvider);
  return expenses.when(
    data: (expenseList) => filterService.getDateRange(expenseList),
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provider for FilterService
final filterServiceProvider = Provider<FilterService>((ref) {
  return FilterService();
});

// Provider for FilterRepository
final filterRepositoryProvider = FutureProvider<FilterRepository>((ref) async {
  final dataSource = await ref.read(expenseLocalDataSourceProvider.future);
  final filterService = ref.read(filterServiceProvider);
  return FilterRepositoryImpl(
    localDataSource: dataSource,
    filterService: filterService,
  );
});

// Provider for ApplyFilters use case
final applyFiltersProvider = FutureProvider<ApplyFilters>((ref) async {
  final repository = await ref.read(filterRepositoryProvider.future);
  return ApplyFilters(repository);
});

// Provider for SearchExpenses use case
final searchExpensesProvider = FutureProvider<SearchExpenses>((ref) async {
  final repository = await ref.read(filterRepositoryProvider.future);
  return SearchExpenses(repository);
});
