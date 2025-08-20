// Simple, working validation system that actually compiles and works
import 'package:dartz/dartz.dart';

/// Simple validation result
typedef ValidationResult<T> = Either<String, T>;

/// Simple expense validation that actually works
class ExpenseValidators {
  /// Validate expense title
  static ValidationResult<String> validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return left('Title is required');
    }
    if (title.trim().length > 100) {
      return left('Title cannot exceed 100 characters');
    }
    return right(title.trim());
  }

  /// Validate expense amount
  static ValidationResult<double> validateAmount(double? amount) {
    if (amount == null || amount <= 0) {
      return left('Amount must be positive');
    }
    if (amount > 1000000) {
      return left('Amount cannot exceed \$1,000,000');
    }
    return right(amount);
  }

  /// Validate expense category
  static ValidationResult<String> validateCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      return left('Category is required');
    }
    if (category.trim().length > 50) {
      return left('Category cannot exceed 50 characters');
    }
    return right(category.trim());
  }

  /// Validate expense date
  static ValidationResult<DateTime> validateDate(DateTime? date) {
    if (date == null) {
      return left('Date is required');
    }
    
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final oneYearFromNow = now.add(const Duration(days: 365));
    
    if (date.isBefore(oneYearAgo) || date.isAfter(oneYearFromNow)) {
      return left('Date must be within one year of today');
    }
    
    return right(date);
  }
}