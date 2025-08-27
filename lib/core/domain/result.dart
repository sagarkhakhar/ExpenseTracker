/// Generic result type for handling success/failure cases
/// Supports both sync and async operations with detailed error information
sealed class Result<T> {
  const Result();

  /// Create a successful result
  const factory Result.success(T data) = Success<T>;
  
  /// Create a failure result
  const factory Result.failure(AppError error) = Failure<T>;

  /// Check if result is successful
  bool get isSuccess => this is Success<T>;
  
  /// Check if result is a failure
  bool get isFailure => this is Failure<T>;

  /// Get data if success, null if failure
  T? get data => switch (this) {
    Success<T>(data: final data) => data,
    Failure<T>() => null,
  };

  /// Get error if failure, null if success
  AppError? get error => switch (this) {
    Success<T>() => null,
    Failure<T>(error: final error) => error,
  };

  /// Transform success data, preserve failure
  Result<U> map<U>(U Function(T data) transform) => switch (this) {
    Success<T>(data: final data) => Result.success(transform(data)),
    Failure<T>(error: final error) => Result.failure(error),
  };

  /// Transform failure error, preserve success
  Result<T> mapError(AppError Function(AppError error) transform) => switch (this) {
    Success<T>() => this,
    Failure<T>(error: final error) => Result.failure(transform(error)),
  };

  /// Fold result into a single value
  U fold<U>({
    required U Function(T data) onSuccess,
    required U Function(AppError error) onFailure,
  }) => switch (this) {
    Success<T>(data: final data) => onSuccess(data),
    Failure<T>(error: final error) => onFailure(error),
  };

  /// Execute action on success, return original result
  Result<T> onSuccess(void Function(T data) action) {
    if (this case Success<T>(data: final data)) {
      action(data);
    }
    return this;
  }

  /// Execute action on failure, return original result
  Result<T> onFailure(void Function(AppError error) action) {
    if (this case Failure<T>(error: final error)) {
      action(error);
    }
    return this;
  }

  /// Pattern matching method for Result (similar to Rust's match)
  U when<U>({
    required U Function(T data) success,
    required U Function(AppError error) failure,
  }) => switch (this) {
    Success<T>(data: final data) => success(data),
    Failure<T>(error: final error) => failure(error),
  };
}

/// Success case of Result
final class Success<T> extends Result<T> {
  const Success(this.data);
  
  @override
  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Failure case of Result
final class Failure<T> extends Result<T> {
  const Failure(this.error);
  
  @override
  final AppError error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && runtimeType == other.runtimeType && error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}

/// Base class for all application errors
abstract class AppError {
  const AppError({
    required this.code,
    required this.message,
    this.details,
    this.stackTrace,
  });

  /// Error code for programmatic handling
  final String code;
  
  /// Human-readable error message
  final String message;
  
  /// Additional error details
  final Map<String, dynamic>? details;
  
  /// Stack trace for debugging
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppError &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message &&
          details == other.details;

  @override
  int get hashCode => Object.hash(code, message, details);

  @override
  String toString() => 'AppError(code: $code, message: $message, details: $details)';
}