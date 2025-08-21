// Simple, working validation system that actually compiles and works
import 'package:dartz/dartz.dart';
import '../../l10n/app_localizations.dart';

/// Simple validation result
typedef ValidationResult<T> = Either<String, T>;

/// Simple expense validation that actually works
class ExpenseValidators {
  /// Validate expense title with localization support
  static ValidationResult<String> validateTitle(String? title, [AppLocalizations? l10n]) {
    if (title == null || title.trim().isEmpty) {
      return left(l10n?.titleRequired ?? 'Title is required');
    }
    if (title.trim().length > 100) {
      return left(l10n?.titleTooLong ?? 'Title cannot exceed 100 characters');
    }
    return right(title.trim());
  }

  /// Validate expense amount with localization support
  static ValidationResult<double> validateAmount(double? amount, [AppLocalizations? l10n]) {
    if (amount == null || amount <= 0) {
      return left(l10n?.amountMustBePositive ?? 'Amount must be positive');
    }
    if (amount > 1000000) {
      return left(l10n?.amountTooLarge ?? 'Amount cannot exceed \$1,000,000');
    }
    return right(amount);
  }

  /// Validate expense category with localization support
  static ValidationResult<String> validateCategory(String? category, [AppLocalizations? l10n]) {
    if (category == null || category.trim().isEmpty) {
      return left(l10n?.categoryRequired ?? 'Category is required');
    }
    if (category.trim().length > 50) {
      return left(l10n?.categoryTooLong ?? 'Category cannot exceed 50 characters');
    }
    return right(category.trim());
  }

  /// Validate expense date with localization support
  static ValidationResult<DateTime> validateDate(DateTime? date, [AppLocalizations? l10n]) {
    if (date == null) {
      return left(l10n?.dateRequired ?? 'Date is required');
    }
    
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final oneYearFromNow = now.add(const Duration(days: 365));
    
    if (date.isBefore(oneYearAgo) || date.isAfter(oneYearFromNow)) {
      return left(l10n?.dateOutOfRange ?? 'Date must be within one year of today');
    }
    
    return right(date);
  }
}