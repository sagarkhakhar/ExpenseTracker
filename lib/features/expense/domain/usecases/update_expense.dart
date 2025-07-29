// Use case for updating an existing expense. Enforces business rules before saving.
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

/// Use case for updating an existing expense.
/// Validates all business rules before calling the repository.
class UpdateExpense {
  /// The repository abstraction (injected).
  final ExpenseRepository repository;

  /// Constructor with dependency injection.
  UpdateExpense(this.repository);

  /// Call this to update an expense. Returns either a Failure or the updated Expense.
  Future<Either<Failure, Expense>> call(Expense expense) async {
    // Business rule: Title must not be empty
    if (expense.title.trim().isEmpty) {
      return Left(ValidationFailure('Title cannot be empty'));
    }
    // Business rule: Category must not be empty
    if (expense.category.trim().isEmpty) {
      return Left(ValidationFailure('Category cannot be empty'));
    }
    // Business rule: Amount must be a positive, finite number
    if (expense.amount.isNaN ||
        expense.amount.isInfinite ||
        expense.amount <= 0) {
      return Left(ValidationFailure('Amount must be positive and finite'));
    }
    // Business rules for recurring expenses
    if (expense.isRecurring) {
      // Recurring frequency must be provided
      if (expense.recurringFrequency == null ||
          expense.recurringFrequency!.isEmpty) {
        return Left(ValidationFailure('Recurring frequency required'));
      }
      // Next occurrence date must be provided
      if (expense.nextOccurrence == null) {
        return Left(ValidationFailure('Next occurrence required'));
      }
      // Next occurrence must not be before the main date
      if (expense.nextOccurrence!.isBefore(expense.date)) {
        return Left(ValidationFailure(
            'Next occurrence must be after or equal to the main date'));
      }
      // End date (if provided) must be after next occurrence
      if (expense.endDate != null &&
          expense.endDate!.isBefore(expense.nextOccurrence!)) {
        return Left(
            ValidationFailure('End date must be after next occurrence'));
      }
    }
    // If all validations pass, call the repository to persist the expense
    return await repository.updateExpense(expense);
  }
}
