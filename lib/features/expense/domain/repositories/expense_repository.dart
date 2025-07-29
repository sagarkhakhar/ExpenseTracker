// This file defines the ExpenseRepository interface (abstraction) for the domain layer.
// It allows the domain and presentation layers to depend on abstractions, not concrete implementations (Dependency Inversion Principle).

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';

/// Repository interface for expense-related operations.
/// This is implemented in the data layer, but used in the domain and presentation layers.
/// All methods return Either<Failure, ...> for robust error handling.
abstract class ExpenseRepository {
  /// Get all expenses and income records.
  Future<Either<Failure, List<Expense>>> getAllExpenses();

  /// Get a single expense by its unique ID.
  Future<Either<Failure, Expense>> getExpenseById(String id);

  /// Get all expenses/income in a date range (inclusive).
  Future<Either<Failure, List<Expense>>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Get all expenses/income for a specific category.
  Future<Either<Failure, List<Expense>>> getExpensesByCategory(
    String category,
  );

  /// Get all expenses/income of a specific type (expense or income).
  Future<Either<Failure, List<Expense>>> getExpensesByType(ExpenseType type);

  /// Create a new expense or income record.
  Future<Either<Failure, Expense>> createExpense(Expense expense);

  /// Update an existing expense or income record.
  Future<Either<Failure, Expense>> updateExpense(Expense expense);

  /// Delete an expense or income record by ID.
  Future<Either<Failure, bool>> deleteExpense(String id);

  /// Get the total amount of expenses in a date range.
  Future<Either<Failure, double>> getTotalExpenses(
    DateTime start,
    DateTime end,
  );

  /// Get the total amount of income in a date range.
  Future<Either<Failure, double>> getTotalIncome(DateTime start, DateTime end);

  /// Get a summary of expenses by category in a date range.
  Future<Either<Failure, Map<String, double>>> getExpensesByCategorySummary(
      DateTime start, DateTime end);
}
