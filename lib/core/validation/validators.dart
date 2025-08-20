// Advanced validation system with composable validators and rich error reporting
// This demonstrates exceptional validation practices with type safety and extensibility

import 'package:dartz/dartz.dart';
import '../errors/exceptions.dart';

/// Result type for validation operations
typedef ValidationResult<T> = Either<ValidationError, T>;

/// Validation error with detailed context
class ValidationError extends AppException {
  final String field;
  final dynamic value;
  final List<String> violations;

  const ValidationError({
    required this.field,
    required this.value,
    required this.violations,
    required super.message,
    required super.errorCode,
    super.technicalDetails,
    super.context,
  });

  factory ValidationError.create({
    required String field,
    required dynamic value,
    required List<String> violations,
  }) {
    final message = violations.length == 1 
        ? violations.first
        : 'Multiple validation errors for $field';
        
    return ValidationError(
      field: field,
      value: value,
      violations: violations,
      message: message,
      errorCode: 'VALIDATION_ERROR',
      technicalDetails: 'Field: $field, Violations: ${violations.join(', ')}',
      context: {
        'field': field,
        'value': value?.toString(),
        'violations': violations,
      },
    );
  }
}

/// Generic validator interface
abstract class Validator<T> {
  ValidationResult<T> validate(T value);
  
  /// Combine this validator with another using AND logic
  Validator<T> and(Validator<T> other) => AndValidator(this, other);
  
  /// Combine this validator with another using OR logic  
  Validator<T> or(Validator<T> other) => OrValidator(this, other);
  
  /// Apply a transformation before validation
  Validator<R> contraMap<R>(T Function(R) mapper) => ContramapValidator(this, mapper);
}

/// String validators
class StringValidators {
  /// Validates that string is not null or empty
  static Validator<String?> required({String? message}) => 
      RequiredStringValidator(message ?? 'This field is required');

  /// Validates minimum length
  static Validator<String> minLength(int min, {String? message}) =>
      MinLengthValidator(min, message ?? 'Must be at least $min characters');

  /// Validates maximum length
  static Validator<String> maxLength(int max, {String? message}) =>
      MaxLengthValidator(max, message ?? 'Must be at most $max characters');

  /// Validates exact length
  static Validator<String> exactLength(int length, {String? message}) =>
      ExactLengthValidator(length, message ?? 'Must be exactly $length characters');

  /// Validates regex pattern
  static Validator<String> pattern(RegExp regex, {String? message}) =>
      PatternValidator(regex, message ?? 'Invalid format');

  /// Validates email format
  static Validator<String> email({String? message}) =>
      PatternValidator(
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
        message ?? 'Invalid email format',
      );

  /// Validates phone number format
  static Validator<String> phoneNumber({String? message}) =>
      PatternValidator(
        RegExp(r'^\+?[\d\s\-\(\)]{10,}$'),
        message ?? 'Invalid phone number format',
      );

  /// Validates that string is alphanumeric
  static Validator<String> alphanumeric({String? message}) =>
      PatternValidator(
        RegExp(r'^[a-zA-Z0-9]+$'),
        message ?? 'Must contain only letters and numbers',
      );

  /// Validates that string contains only alphabetic characters
  static Validator<String> alphabetic({String? message}) =>
      PatternValidator(
        RegExp(r'^[a-zA-Z]+$'),
        message ?? 'Must contain only letters',
      );

  /// Validates that string is numeric
  static Validator<String> numeric({String? message}) =>
      PatternValidator(
        RegExp(r'^\d+$'),
        message ?? 'Must contain only numbers',
      );
}

/// Number validators
class NumberValidators {
  /// Validates minimum value
  static Validator<num> min(num minimum, {String? message}) =>
      MinValueValidator(minimum, message ?? 'Must be at least $minimum');

  /// Validates maximum value
  static Validator<num> max(num maximum, {String? message}) =>
      MaxValueValidator(maximum, message ?? 'Must be at most $maximum');

  /// Validates range
  static Validator<num> range(num min, num max, {String? message}) =>
      RangeValidator(min, max, message ?? 'Must be between $min and $max');

  /// Validates positive number
  static Validator<num> positive({String? message}) =>
      MinValueValidator(0.000001, message ?? 'Must be positive');

  /// Validates non-negative number
  static Validator<num> nonNegative({String? message}) =>
      MinValueValidator(0, message ?? 'Must be non-negative');

  /// Validates integer
  static Validator<num> integer({String? message}) =>
      IntegerValidator(message ?? 'Must be a whole number');
}

/// Date validators
class DateValidators {
  /// Validates future date
  static Validator<DateTime> future({String? message}) =>
      FutureDateValidator(message ?? 'Must be a future date');

  /// Validates past date
  static Validator<DateTime> past({String? message}) =>
      PastDateValidator(message ?? 'Must be a past date');

  /// Validates date range
  static Validator<DateTime> range(DateTime start, DateTime end, {String? message}) =>
      DateRangeValidator(start, end, message ?? 'Must be between ${start.toIso8601String()} and ${end.toIso8601String()}');

  /// Validates minimum age
  static Validator<DateTime> minAge(int years, {String? message}) =>
      MinAgeValidator(years, message ?? 'Must be at least $years years old');

  /// Validates maximum age  
  static Validator<DateTime> maxAge(int years, {String? message}) =>
      MaxAgeValidator(years, message ?? 'Must be at most $years years old');
}

/// List validators
class ListValidators {
  /// Validates minimum length
  static Validator<List<T>> minLength<T>(int min, {String? message}) =>
      ListMinLengthValidator<T>(min, message ?? 'Must contain at least $min items');

  /// Validates maximum length
  static Validator<List<T>> maxLength<T>(int max, {String? message}) =>
      ListMaxLengthValidator<T>(max, message ?? 'Must contain at most $max items');

  /// Validates that list is not empty
  static Validator<List<T>> notEmpty<T>({String? message}) =>
      ListMinLengthValidator<T>(1, message ?? 'Must not be empty');

  /// Validates each item in list
  static Validator<List<T>> each<T>(Validator<T> itemValidator, {String? message}) =>
      ListItemValidator<T>(itemValidator, message ?? 'Contains invalid items');
}

/// Expense-specific validators
class ExpenseValidators {
  /// Validates expense amount
  static Validator<double> amount() {
    return NumberValidators.positive(message: 'Amount must be positive')
        .and(NumberValidators.max(1000000, message: 'Amount cannot exceed \$1,000,000'));
  }

  /// Validates expense title
  static Validator<String?> title() {
    return StringValidators.required(message: 'Title is required')
        .contraMap<String?>((s) => s ?? '')
        .and(StringValidators.minLength(1, message: 'Title cannot be empty'))
        .and(StringValidators.maxLength(100, message: 'Title cannot exceed 100 characters'));
  }

  /// Validates expense category
  static Validator<String?> category() {
    return StringValidators.required(message: 'Category is required')
        .contraMap<String?>((s) => s ?? '')
        .and(StringValidators.minLength(1, message: 'Category cannot be empty'))
        .and(StringValidators.maxLength(50, message: 'Category cannot exceed 50 characters'));
  }

  /// Validates expense description
  static Validator<String> description() {
    return StringValidators.maxLength(500, message: 'Description cannot exceed 500 characters');
  }

  /// Validates expense date
  static Validator<DateTime> date() {
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    final oneYearFromNow = DateTime.now().add(const Duration(days: 365));
    
    return DateValidators.range(
      oneYearAgo, 
      oneYearFromNow,
      message: 'Date must be within one year of today',
    );
  }
}

/// Validation composer for complex objects
class ValidationComposer<T> {
  final Map<String, List<ValidationResult<dynamic>>> _results = {};
  final T _object;

  ValidationComposer(this._object);

  /// Validate a field
  ValidationComposer<T> field<F>(
    String fieldName,
    F Function(T) getter,
    Validator<F> validator,
  ) {
    final value = getter(_object);
    final result = validator.validate(value);
    
    _results[fieldName] = [result];
    return this;
  }

  /// Get all validation results
  ValidationResult<T> build() {
    final errors = <String>[];
    final errorDetails = <String, List<String>>{};
    
    for (final entry in _results.entries) {
      final fieldName = entry.key;
      final results = entry.value;
      
      for (final result in results) {
        result.fold(
          (error) {
            if (error is ValidationError) {
              errors.addAll(error.violations.map((v) => '$fieldName: $v'));
              errorDetails[fieldName] = error.violations;
            } else {
              errors.add('$fieldName: ${error.message}');
              errorDetails[fieldName] = [error.message];
            }
          },
          (_) {}, // Success case
        );
      }
    }
    
    if (errors.isNotEmpty) {
      return left(ValidationError.create(
        field: 'object',
        value: _object,
        violations: errors,
      ));
    }
    
    return right(_object);
  }
}

// Implementation classes for validators

class RequiredStringValidator implements Validator<String?> {
  final String message;
  
  const RequiredStringValidator(this.message);
  
  @override
  ValidationResult<String?> validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return left(ValidationError.create(
        field: 'string',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class MinLengthValidator implements Validator<String> {
  final int minLength;
  final String message;
  
  const MinLengthValidator(this.minLength, this.message);
  
  @override
  ValidationResult<String> validate(String value) {
    if (value.length < minLength) {
      return left(ValidationError.create(
        field: 'string',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class MaxLengthValidator implements Validator<String> {
  final int maxLength;
  final String message;
  
  const MaxLengthValidator(this.maxLength, this.message);
  
  @override
  ValidationResult<String> validate(String value) {
    if (value.length > maxLength) {
      return left(ValidationError.create(
        field: 'string',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class ExactLengthValidator implements Validator<String> {
  final int exactLength;
  final String message;
  
  const ExactLengthValidator(this.exactLength, this.message);
  
  @override
  ValidationResult<String> validate(String value) {
    if (value.length != exactLength) {
      return left(ValidationError.create(
        field: 'string',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class PatternValidator implements Validator<String> {
  final RegExp pattern;
  final String message;
  
  const PatternValidator(this.pattern, this.message);
  
  @override
  ValidationResult<String> validate(String value) {
    if (!pattern.hasMatch(value)) {
      return left(ValidationError.create(
        field: 'string',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class MinValueValidator implements Validator<num> {
  final num minimum;
  final String message;
  
  const MinValueValidator(this.minimum, this.message);
  
  @override
  ValidationResult<num> validate(num value) {
    if (value < minimum) {
      return left(ValidationError.create(
        field: 'number',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class MaxValueValidator implements Validator<num> {
  final num maximum;
  final String message;
  
  const MaxValueValidator(this.maximum, this.message);
  
  @override
  ValidationResult<num> validate(num value) {
    if (value > maximum) {
      return left(ValidationError.create(
        field: 'number',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class RangeValidator implements Validator<num> {
  final num min;
  final num max;
  final String message;
  
  const RangeValidator(this.min, this.max, this.message);
  
  @override
  ValidationResult<num> validate(num value) {
    if (value < min || value > max) {
      return left(ValidationError.create(
        field: 'number',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class IntegerValidator implements Validator<num> {
  final String message;
  
  const IntegerValidator(this.message);
  
  @override
  ValidationResult<num> validate(num value) {
    if (value != value.truncate()) {
      return left(ValidationError.create(
        field: 'number',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class FutureDateValidator implements Validator<DateTime> {
  final String message;
  
  const FutureDateValidator(this.message);
  
  @override
  ValidationResult<DateTime> validate(DateTime value) {
    if (value.isBefore(DateTime.now())) {
      return left(ValidationError.create(
        field: 'date',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class PastDateValidator implements Validator<DateTime> {
  final String message;
  
  const PastDateValidator(this.message);
  
  @override
  ValidationResult<DateTime> validate(DateTime value) {
    if (value.isAfter(DateTime.now())) {
      return left(ValidationError.create(
        field: 'date',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class DateRangeValidator implements Validator<DateTime> {
  final DateTime start;
  final DateTime end;
  final String message;
  
  const DateRangeValidator(this.start, this.end, this.message);
  
  @override
  ValidationResult<DateTime> validate(DateTime value) {
    if (value.isBefore(start) || value.isAfter(end)) {
      return left(ValidationError.create(
        field: 'date',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class MinAgeValidator implements Validator<DateTime> {
  final int years;
  final String message;
  
  const MinAgeValidator(this.years, this.message);
  
  @override
  ValidationResult<DateTime> validate(DateTime birthDate) {
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    if (age < years) {
      return left(ValidationError.create(
        field: 'birthDate',
        value: birthDate,
        violations: [message],
      ));
    }
    return right(birthDate);
  }
}

class MaxAgeValidator implements Validator<DateTime> {
  final int years;
  final String message;
  
  const MaxAgeValidator(this.years, this.message);
  
  @override
  ValidationResult<DateTime> validate(DateTime birthDate) {
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    if (age > years) {
      return left(ValidationError.create(
        field: 'birthDate',
        value: birthDate,
        violations: [message],
      ));
    }
    return right(birthDate);
  }
}

class ListMinLengthValidator<T> implements Validator<List<T>> {
  final int minLength;
  final String message;
  
  const ListMinLengthValidator(this.minLength, this.message);
  
  @override
  ValidationResult<List<T>> validate(List<T> value) {
    if (value.length < minLength) {
      return left(ValidationError.create(
        field: 'list',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class ListMaxLengthValidator<T> implements Validator<List<T>> {
  final int maxLength;
  final String message;
  
  const ListMaxLengthValidator(this.maxLength, this.message);
  
  @override
  ValidationResult<List<T>> validate(List<T> value) {
    if (value.length > maxLength) {
      return left(ValidationError.create(
        field: 'list',
        value: value,
        violations: [message],
      ));
    }
    return right(value);
  }
}

class ListItemValidator<T> implements Validator<List<T>> {
  final Validator<T> itemValidator;
  final String message;
  
  const ListItemValidator(this.itemValidator, this.message);
  
  @override
  ValidationResult<List<T>> validate(List<T> value) {
    final errors = <String>[];
    
    for (int i = 0; i < value.length; i++) {
      final itemResult = itemValidator.validate(value[i]);
      itemResult.fold(
        (error) {
          if (error is ValidationError) {
            errors.addAll(error.violations.map((v) => 'Item $i: $v'));
          } else {
            errors.add('Item $i: ${error.message}');
          }
        },
        (_) {}, // Success case
      );
    }
    
    if (errors.isNotEmpty) {
      return left(ValidationError.create(
        field: 'list',
        value: value,
        violations: errors,
      ));
    }
    
    return right(value);
  }
}

class AndValidator<T> implements Validator<T> {
  final Validator<T> first;
  final Validator<T> second;
  
  const AndValidator(this.first, this.second);
  
  @override
  ValidationResult<T> validate(T value) {
    return first.validate(value).fold(
      (error) => left(error),
      (validValue) => second.validate(validValue),
    );
  }
}

class OrValidator<T> implements Validator<T> {
  final Validator<T> first;
  final Validator<T> second;
  
  const OrValidator(this.first, this.second);
  
  @override
  ValidationResult<T> validate(T value) {
    return first.validate(value).fold(
      (firstError) => second.validate(value).fold(
        (secondError) => left(firstError), // Return first error if both fail
        (validValue) => right(validValue),
      ),
      (validValue) => right(validValue),
    );
  }
}

class ContramapValidator<T, R> implements Validator<R> {
  final Validator<T> validator;
  final T Function(R) mapper;
  
  const ContramapValidator(this.validator, this.mapper);
  
  @override
  ValidationResult<R> validate(R value) {
    final mappedValue = mapper(value);
    return validator.validate(mappedValue).fold(
      (error) => left(error),
      (_) => right(value),
    );
  }
}

/// Extension methods for easy validation
extension ValidationExtensions<T> on T {
  /// Start a validation chain
  ValidationComposer<T> validate() => ValidationComposer(this);
}