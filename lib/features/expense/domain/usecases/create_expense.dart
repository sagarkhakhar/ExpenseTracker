// Use case for creating a new expense. Enforces business rules before saving.
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';
import '../validators/expense_business_validator.dart';

/// Use case for creating a new expense.
/// Validates all business rules before calling the repository.
class CreateExpense {
  /// The repository abstraction (injected).
  final ExpenseRepository repository;

  /// Constructor with dependency injection.
  CreateExpense(this.repository);

  /// Call this to create an expense. Returns either a Failure or the created Expense.
  Future<Either<Failure, Expense>> call(Expense expense) async {
    // Validate business rules using centralized validator
    final validationResult = ExpenseBusinessValidator.validateExpense(expense);
    
    // Return validation failure if invalid
    if (validationResult.isLeft()) {
      return validationResult;
    }
    
    // If all validations pass, call the repository to persist the expense
    return await repository.createExpense(expense);
  }
}
