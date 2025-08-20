// Use case for retrieving expenses within a specific date range.
// This is commonly used for monthly reports, weekly summaries, and filtering operations.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

/// Use case for getting expenses and income records within a date range.
/// This is essential for generating reports, calculating totals for specific periods,
/// and implementing date-based filtering in the UI.
class GetExpensesByDateRange {
  /// The repository abstraction for accessing expense data.
  /// Injected as a dependency for loose coupling and testability.
  final ExpenseRepository repository;

  /// Constructor that accepts the repository dependency.
  /// Enables dependency injection for better testing and maintainability.
  GetExpensesByDateRange(this.repository);

  /// Executes the use case to retrieve expenses within the specified date range.
  /// 
  /// Parameters:
  /// - [start]: The start date (inclusive) for the range
  /// - [end]: The end date (inclusive) for the range
  /// 
  /// Returns:
  /// - Left(Failure): If there was an error accessing the data
  /// - Right(List<Expense>): If successful, contains expenses within the date range
  /// 
  /// The date range is inclusive on both ends, meaning expenses on the start
  /// and end dates will be included in the results.
  Future<Either<Failure, List<Expense>>> call(
    DateTime start,
    DateTime end,
  ) async {
    // Business rule validation could be added here if needed
    // For example, ensuring start date is not after end date
    
    // Delegate to the repository to fetch expenses within the date range
    return await repository.getExpensesByDateRange(start, end);
  }
}
