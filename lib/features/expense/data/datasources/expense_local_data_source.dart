// This file defines the ExpenseLocalDataSource interface for the data layer.
// It abstracts the details of how expenses are stored and retrieved locally (e.g., using Hive).
// The repository depends on this interface, not on a concrete implementation (Dependency Inversion Principle).

import '../models/expense_model.dart';
import '../../domain/entities/expense.dart';

/// Interface for local data source operations related to expenses.
/// Implemented by a concrete class (e.g., using Hive for local storage).
abstract class ExpenseLocalDataSource {
  /// Initialize the data source (e.g., open Hive boxes).
  Future<void> init();

  /// Get all expenses and income records from local storage.
  Future<List<ExpenseModel>> getAllExpenses();

  /// Get a single expense by its unique ID.
  Future<ExpenseModel?> getExpenseById(String id);

  /// Get all expenses/income in a date range (inclusive).
  Future<List<ExpenseModel>> getExpensesByDateRange(
      DateTime start, DateTime end);

  /// Get all expenses/income for a specific category.
  Future<List<ExpenseModel>> getExpensesByCategory(String category);

  /// Get all expenses/income of a specific type (expense or income).
  Future<List<ExpenseModel>> getExpensesByType(ExpenseType type);

  /// Create a new expense or income record in local storage.
  Future<void> createExpense(ExpenseModel expense);

  /// Update an existing expense or income record in local storage.
  Future<void> updateExpense(ExpenseModel expense);

  /// Delete an expense or income record by ID from local storage.
  Future<void> deleteExpense(String id);
}
