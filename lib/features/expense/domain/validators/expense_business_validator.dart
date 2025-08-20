// Business validation logic for expenses - eliminates code duplication
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';

/// Centralized business validation for expenses
/// Eliminates code duplication between CreateExpense and UpdateExpense
class ExpenseBusinessValidator {
  /// Validates all business rules for an expense
  /// Returns Left(ValidationFailure) if invalid, Right(expense) if valid
  static Either<ValidationFailure, Expense> validateExpense(Expense expense) {
    // Business rule: Title must not be empty
    if (expense.title.trim().isEmpty) {
      return const Left(ValidationFailure('Title cannot be empty'));
    }
    
    // Business rule: Category must not be empty
    if (expense.category.trim().isEmpty) {
      return const Left(ValidationFailure('Category cannot be empty'));
    }
    
    // Business rule: Amount must be a positive, finite number
    if (expense.amount.isNaN ||
        expense.amount.isInfinite ||
        expense.amount <= 0) {
      return const Left(ValidationFailure('Amount must be positive and finite'));
    }
    
    // Business rules for recurring expenses
    if (expense.isRecurring) {
      final recurringValidation = _validateRecurringExpense(expense);
      if (recurringValidation.isLeft()) {
        return recurringValidation;
      }
    }
    
    // All validations passed
    return Right(expense);
  }
  
  /// Validates recurring expense specific rules
  static Either<ValidationFailure, Expense> _validateRecurringExpense(Expense expense) {
    // Recurring frequency must be provided
    if (expense.recurringFrequency == null ||
        expense.recurringFrequency!.isEmpty) {
      return const Left(ValidationFailure('Recurring frequency required'));
    }
    
    // Next occurrence date must be provided
    if (expense.nextOccurrence == null) {
      return const Left(ValidationFailure('Next occurrence required'));
    }
    
    // Next occurrence must not be before the main date
    if (expense.nextOccurrence!.isBefore(expense.date)) {
      return const Left(ValidationFailure(
          'Next occurrence must be after or equal to the main date'));
    }
    
    // End date (if provided) must be after next occurrence
    if (expense.endDate != null &&
        expense.endDate!.isBefore(expense.nextOccurrence!)) {
      return const Left(
          ValidationFailure('End date must be after next occurrence'));
    }
    
    return Right(expense);
  }
}