// This file implements the FilterRepository interface for the data layer.
// It connects the domain layer to the data source (Hive/local storage).
// Implements all methods defined in the domain repository abstraction.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/filter_criteria.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/filter_repository.dart';
import '../../domain/services/filter_service.dart';
import '../datasources/expense_local_data_source.dart';

/// Concrete implementation of FilterRepository for local storage.
/// Uses a data source (e.g., Hive) to persist and retrieve expenses for filtering.
class FilterRepositoryImpl implements FilterRepository {
  // The data source for local storage (injected for testability and flexibility).
  final ExpenseLocalDataSource localDataSource;
  // The filter service for business logic (injected for testability).
  final FilterService filterService;

  /// Constructor with dependency injection.
  FilterRepositoryImpl({
    required this.localDataSource,
    required this.filterService,
  });

  @override
  Future<Either<Failure, SearchResult>> searchExpenses(
    FilterCriteria filterCriteria,
  ) async {
    try {
      // Get all expenses from the data source
      final allExpenses = await localDataSource.getAllExpenses();
      final expenses = allExpenses.map((model) => model.toEntity()).toList();

      // Apply filters using the filter service
      final filteredExpenses =
          filterService.applyFilters(expenses, filterCriteria);

      // Create search result
      final searchResult = filterService.createSearchResult(
        expenses,
        filteredExpenses,
        filterCriteria,
        filterCriteria.searchQuery,
      );

      return Right(searchResult);
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to search expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableCategories() async {
    try {
      final allExpenses = await localDataSource.getAllExpenses();
      final expenses = allExpenses.map((model) => model.toEntity()).toList();
      final categories = filterService.getAvailableCategories(expenses);
      return Right(categories);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get categories: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableExpenseTypes() async {
    try {
      final allExpenses = await localDataSource.getAllExpenses();
      final expenses = allExpenses.map((model) => model.toEntity()).toList();
      final types = filterService.getAvailableExpenseTypes(expenses);
      return Right(types.map((type) => type.name).toList());
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to get expense types: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Range>> getAmountRange() async {
    try {
      final allExpenses = await localDataSource.getAllExpenses();
      final expenses = allExpenses.map((model) => model.toEntity()).toList();
      final amountRange = filterService.getAmountRange(expenses);
      return Right(amountRange);
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to get amount range: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DateTimeRange?>> getDateRange() async {
    try {
      final allExpenses = await localDataSource.getAllExpenses();
      final expenses = allExpenses.map((model) => model.toEntity()).toList();
      final dateRange = filterService.getDateRange(expenses);
      return Right(dateRange);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get date range: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> searchByText(String query) async {
    try {
      final allExpenses = await localDataSource.getAllExpenses();
      final expenses = allExpenses.map((model) => model.toEntity()).toList();
      final filteredExpenses =
          filterService.applyTextSearchFilter(expenses, query);
      return Right(filteredExpenses);
    } catch (e) {
      return Left(DatabaseFailure('Failed to search by text: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final expenses = await localDataSource.getExpensesByDateRange(start, end);
      return Right(expenses.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(
        DatabaseFailure(
          'Failed to get expenses by date range: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByCategories(
    List<String> categories,
  ) async {
    try {
      final allExpenses = await localDataSource.getAllExpenses();
      final expenses = allExpenses.map((model) => model.toEntity()).toList();
      final filteredExpenses =
          filterService.applyCategoryFilter(expenses, categories);
      return Right(filteredExpenses);
    } catch (e) {
      return Left(
        DatabaseFailure(
            'Failed to get expenses by categories: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByAmountRange(
    Range amountRange,
  ) async {
    try {
      final allExpenses = await localDataSource.getAllExpenses();
      final expenses = allExpenses.map((model) => model.toEntity()).toList();
      final filteredExpenses =
          filterService.applyAmountRangeFilter(expenses, amountRange);
      return Right(filteredExpenses);
    } catch (e) {
      return Left(
        DatabaseFailure(
            'Failed to get expenses by amount range: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpensesByType(String type) async {
    try {
      final expenseType = ExpenseType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => ExpenseType.expense,
      );
      final expenses = await localDataSource.getExpensesByType(expenseType);
      return Right(expenses.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to get expenses by type: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getFilteredExpenseCount(
    FilterCriteria filterCriteria,
  ) async {
    try {
      final allExpenses = await localDataSource.getAllExpenses();
      final expenses = allExpenses.map((model) => model.toEntity()).toList();
      final filteredExpenses =
          filterService.applyFilters(expenses, filterCriteria);
      return Right(filteredExpenses.length);
    } catch (e) {
      return Left(
        DatabaseFailure(
            'Failed to get filtered expense count: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> saveFilterCriteria(
    FilterCriteria filterCriteria,
  ) async {
    try {
      // For now, we'll use a simple approach to save filter criteria
      // In a real implementation, you might want to use Hive or SharedPreferences
      // This is a placeholder implementation
      return const Right(true);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to save filter criteria: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, FilterCriteria?>> loadFilterCriteria() async {
    try {
      // For now, we'll return null as a placeholder
      // In a real implementation, you might want to use Hive or SharedPreferences
      return const Right(null);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to load filter criteria: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> clearFilterCriteria() async {
    try {
      // For now, we'll return true as a placeholder
      // In a real implementation, you might want to use Hive or SharedPreferences
      return const Right(true);
    } catch (e) {
      return Left(
        DatabaseFailure('Failed to clear filter criteria: ${e.toString()}'),
      );
    }
  }
}
