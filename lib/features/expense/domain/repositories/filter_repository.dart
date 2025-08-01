// This file defines the FilterRepository interface (abstraction) for the domain layer.
// It allows the domain and presentation layers to depend on abstractions, not concrete implementations (Dependency Inversion Principle).

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../entities/filter_criteria.dart';
import '../entities/search_result.dart';

/// Repository interface for expense filtering and search operations.
/// This is implemented in the data layer, but used in the domain and presentation layers.
/// All methods return Either<Failure, ...> for robust error handling.
abstract class FilterRepository {
  /// Search expenses using filter criteria.
  /// Returns a SearchResult with filtered expenses and metadata.
  Future<Either<Failure, SearchResult>> searchExpenses(
    FilterCriteria filterCriteria,
  );

  /// Get all available categories from existing expenses.
  /// Returns a sorted list of unique categories.
  Future<Either<Failure, List<String>>> getAvailableCategories();

  /// Get all available expense types from existing expenses.
  /// Returns a list of unique expense types.
  Future<Either<Failure, List<String>>> getAvailableExpenseTypes();

  /// Get the amount range (min/max) from all existing expenses.
  /// Returns a Range object with min and max amounts.
  Future<Either<Failure, Range>> getAmountRange();

  /// Get the date range (earliest/latest) from all existing expenses.
  /// Returns a DateTimeRange object with start and end dates.
  Future<Either<Failure, DateTimeRange?>> getDateRange();

  /// Get expenses that match a text search query.
  /// Returns a list of expenses that contain the query in title or description.
  Future<Either<Failure, List<Expense>>> searchByText(String query);

  /// Get expenses within a specific date range.
  /// Returns a list of expenses that fall within the specified dates.
  Future<Either<Failure, List<Expense>>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Get expenses for specific categories.
  /// Returns a list of expenses that match any of the specified categories.
  Future<Either<Failure, List<Expense>>> getExpensesByCategories(
    List<String> categories,
  );

  /// Get expenses within a specific amount range.
  /// Returns a list of expenses that fall within the specified amount range.
  Future<Either<Failure, List<Expense>>> getExpensesByAmountRange(
    Range amountRange,
  );

  /// Get expenses of a specific type (expense or income).
  /// Returns a list of expenses that match the specified type.
  Future<Either<Failure, List<Expense>>> getExpensesByType(String type);

  /// Get the total count of expenses matching the filter criteria.
  /// Returns the number of expenses that match the specified criteria.
  Future<Either<Failure, int>> getFilteredExpenseCount(
    FilterCriteria filterCriteria,
  );

  /// Save filter criteria for later use.
  /// Returns true if the filter criteria was saved successfully.
  Future<Either<Failure, bool>> saveFilterCriteria(
    FilterCriteria filterCriteria,
  );

  /// Load previously saved filter criteria.
  /// Returns the saved filter criteria or null if none exists.
  Future<Either<Failure, FilterCriteria?>> loadFilterCriteria();

  /// Clear saved filter criteria.
  /// Returns true if the filter criteria was cleared successfully.
  Future<Either<Failure, bool>> clearFilterCriteria();
}
