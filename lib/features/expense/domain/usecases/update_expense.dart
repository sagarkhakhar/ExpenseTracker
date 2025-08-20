// Use case for updating an existing expense. Enforces business rules before saving.
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';
import '../validators/expense_business_validator.dart';

/// Use case for updating an existing expense.
/// Validates all business rules before calling the repository.
class UpdateExpense {
  /// The repository abstraction (injected).
  final ExpenseRepository repository;

  /// Constructor with dependency injection.
  UpdateExpense(this.repository);

  /// Call this to update an expense. Returns either a Failure or the updated Expense.
  Future<Either<Failure, Expense>> call(Expense expense) async {
    // Validate business rules using centralized validator
    final validationResult = ExpenseBusinessValidator.validateExpense(expense);
    
    // Return validation failure if invalid
    if (validationResult.isLeft()) {
      return validationResult;
    }
    
    // If all validations pass, call the repository to update the expense
    return await repository.updateExpense(expense);
  }
}
