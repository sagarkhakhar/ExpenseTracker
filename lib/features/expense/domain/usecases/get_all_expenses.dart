// Use case for retrieving all expenses and income records.
// This follows the Clean Architecture pattern and handles all business logic for fetching expenses.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

/// Use case for getting all expenses and income records.
/// This encapsulates the business logic for retrieving all financial transactions.
/// Returns either a Failure (if something went wrong) or a List<Expense> (if successful).
class GetAllExpenses {
  /// The repository abstraction for accessing expense data.
  /// This is injected as a dependency to maintain loose coupling.
  final ExpenseRepository repository;

  /// Constructor that accepts the repository dependency.
  /// This allows for easy testing by injecting mock repositories.
  GetAllExpenses(this.repository);

  /// Executes the use case to retrieve all expenses and income records.
  /// 
  /// Returns:
  /// - Left(Failure): If there was an error accessing the data
  /// - Right(List<Expense>): If successful, contains all expense records
  /// 
  /// The list may be empty if no expenses have been recorded yet.
  Future<Either<Failure, List<Expense>>> call() async {
    // Delegate to the repository to fetch all expenses
    // No additional business logic is needed for this simple retrieval
    return await repository.getAllExpenses();
  }
}
