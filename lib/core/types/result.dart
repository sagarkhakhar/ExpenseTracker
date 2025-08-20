// Advanced type-safe result handling with sealed classes for exceptional error management
// This demonstrates exhaustive pattern matching and type safety for robust error handling

import 'package:equatable/equatable.dart';
import '../errors/exceptions.dart';

/// Sealed class for representing operation results with exhaustive pattern matching
sealed class Result<T> extends Equatable {
  const Result();

  /// Create a success result
  factory Result.success(T value) = Success<T>;

  /// Create a failure result
  factory Result.failure(AppException exception) = Failure<T>;

  /// Create a loading state (for async operations)
  factory Result.loading([String? message]) = Loading<T>;

  /// Pattern matching for exhaustive handling
  R when<R>({
    required R Function(T value) success,
    required R Function(AppException exception) failure,
    required R Function(String? message) loading,
  }) {
    return switch (this) {
      Success<T> s => success(s.value),
      Failure<T> f => failure(f.exception),
      Loading<T> l => loading(l.message),
    };
  }

  /// Pattern matching with optional handlers
  R maybeWhen<R>({
    R Function(T value)? success,
    R Function(AppException exception)? failure,
    R Function(String? message)? loading,
    required R Function() orElse,
  }) {
    return switch (this) {
      Success<T> s when success != null => success(s.value),
      Failure<T> f when failure != null => failure(f.exception),
      Loading<T> l when loading != null => loading(l.message),
      _ => orElse(),
    };
  }

  /// Map the success value to another type
  Result<R> map<R>(R Function(T value) mapper) {
    return switch (this) {
      Success<T> s => Result.success(mapper(s.value)),
      Failure<T> f => Result.failure(f.exception),
      Loading<T> l => Result.loading(l.message),
    };
  }

  /// FlatMap for chaining operations
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) {
    return switch (this) {
      Success<T> s => mapper(s.value),
      Failure<T> f => Result.failure(f.exception),
      Loading<T> l => Result.loading(l.message),
    };
  }

  /// Handle errors with recovery
  Result<T> recover(T Function(AppException exception) recovery) {
    return switch (this) {
      Success<T> s => s,
      Failure<T> f => Result.success(recovery(f.exception)),
      Loading<T> l => l,
    };
  }

  /// Convert to nullable value (null on failure/loading)
  T? get valueOrNull => switch (this) {
    Success<T> s => s.value,
    _ => null,
  };

  /// Get exception or null
  AppException? get exceptionOrNull => switch (this) {
    Failure<T> f => f.exception,
    _ => null,
  };

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Check if result is loading
  bool get isLoading => this is Loading<T>;
}

/// Success state containing the value
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'Success(value: $value)';
}

/// Failure state containing the exception
final class Failure<T> extends Result<T> {
  final AppException exception;

  const Failure(this.exception);

  @override
  List<Object?> get props => [exception];

  @override
  String toString() => 'Failure(exception: $exception)';
}

/// Loading state for async operations
final class Loading<T> extends Result<T> {
  final String? message;

  const Loading([this.message]);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'Loading(message: $message)';
}

/// Extension methods for Future<Result<T>>
extension FutureResultExtensions<T> on Future<Result<T>> {
  /// Handle async result with callbacks
  Future<void> handle({
    required void Function(T value) onSuccess,
    required void Function(AppException exception) onFailure,
    void Function(String? message)? onLoading,
  }) async {
    final result = await this;
    result.when(
      success: onSuccess,
      failure: onFailure,
      loading: onLoading ?? (_) {},
    );
  }

  /// Map the success value asynchronously
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) mapper) async {
    final result = await this;
    return switch (result) {
      Success<T> s => Result.success(await mapper(s.value)),
      Failure<T> f => Result.failure(f.exception),
      Loading<T> l => Result.loading(l.message),
    };
  }

  /// FlatMap for async chaining
  Future<Result<R>> flatMapAsync<R>(Future<Result<R>> Function(T value) mapper) async {
    final result = await this;
    return switch (result) {
      Success<T> s => await mapper(s.value),
      Failure<T> f => Result.failure(f.exception),
      Loading<T> l => Result.loading(l.message),
    };
  }
}

/// Sealed class for validation states with multiple error types
sealed class ValidationState<T> extends Equatable {
  const ValidationState();

  factory ValidationState.valid(T value) = Valid<T>;
  factory ValidationState.invalid(List<String> errors) = Invalid<T>;
  factory ValidationState.pending() = Pending<T>;

  R when<R>({
    required R Function(T value) valid,
    required R Function(List<String> errors) invalid,
    required R Function() pending,
  }) {
    return switch (this) {
      Valid<T> v => valid(v.value),
      Invalid<T> i => invalid(i.errors),
      Pending<T> _ => pending(),
    };
  }

  bool get isValid => this is Valid<T>;
  bool get isInvalid => this is Invalid<T>;
  bool get isPending => this is Pending<T>;

  T? get valueOrNull => switch (this) {
    Valid<T> v => v.value,
    _ => null,
  };

  List<String> get errorsOrEmpty => switch (this) {
    Invalid<T> i => i.errors,
    _ => <String>[],
  };
}

final class Valid<T> extends ValidationState<T> {
  final T value;
  const Valid(this.value);

  @override
  List<Object?> get props => [value];
}

final class Invalid<T> extends ValidationState<T> {
  final List<String> errors;
  const Invalid(this.errors);

  @override
  List<Object?> get props => [errors];
}

final class Pending<T> extends ValidationState<T> {
  const Pending();

  @override
  List<Object?> get props => [];
}

/// Sealed class for loading states with progress tracking
sealed class LoadingState<T> extends Equatable {
  const LoadingState();

  factory LoadingState.idle() = Idle<T>;
  factory LoadingState.loading([double? progress, String? message]) = LoadingProgress<T>;
  factory LoadingState.success(T data) = LoadingSuccess<T>;
  factory LoadingState.error(AppException exception) = LoadingError<T>;

  R when<R>({
    required R Function() idle,
    required R Function(double? progress, String? message) loading,
    required R Function(T data) success,
    required R Function(AppException exception) error,
  }) {
    return switch (this) {
      Idle<T> _ => idle(),
      LoadingProgress<T> l => loading(l.progress, l.message),
      LoadingSuccess<T> s => success(s.data),
      LoadingError<T> e => error(e.exception),
    };
  }

  bool get isIdle => this is Idle<T>;
  bool get isLoading => this is LoadingProgress<T>;
  bool get isSuccess => this is LoadingSuccess<T>;
  bool get isError => this is LoadingError<T>;
}

final class Idle<T> extends LoadingState<T> {
  const Idle();

  @override
  List<Object?> get props => [];
}

final class LoadingProgress<T> extends LoadingState<T> {
  final double? progress;
  final String? message;

  const LoadingProgress([this.progress, this.message]);

  @override
  List<Object?> get props => [progress, message];
}

final class LoadingSuccess<T> extends LoadingState<T> {
  final T data;

  const LoadingSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

final class LoadingError<T> extends LoadingState<T> {
  final AppException exception;

  const LoadingError(this.exception);

  @override
  List<Object?> get props => [exception];
}

/// Option type for null-safe operations
sealed class Option<T> extends Equatable {
  const Option();

  factory Option.some(T value) = Some<T>;
  factory Option.none() = None<T>;

  /// Create option from nullable value
  factory Option.fromNullable(T? value) {
    return value != null ? Option.some(value) : Option.none();
  }

  R when<R>({
    required R Function(T value) some,
    required R Function() none,
  }) {
    return switch (this) {
      Some<T> s => some(s.value),
      None<T> _ => none(),
    };
  }

  Option<R> map<R>(R Function(T value) mapper) {
    return switch (this) {
      Some<T> s => Option.some(mapper(s.value)),
      None<T> _ => Option.none(),
    };
  }

  Option<R> flatMap<R>(Option<R> Function(T value) mapper) {
    return switch (this) {
      Some<T> s => mapper(s.value),
      None<T> _ => Option.none(),
    };
  }

  T getOrElse(T defaultValue) {
    return switch (this) {
      Some<T> s => s.value,
      None<T> _ => defaultValue,
    };
  }

  bool get isSome => this is Some<T>;
  bool get isNone => this is None<T>;

  T? get valueOrNull => switch (this) {
    Some<T> s => s.value,
    None<T> _ => null,
  };
}

final class Some<T> extends Option<T> {
  final T value;

  const Some(this.value);

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'Some($value)';
}

final class None<T> extends Option<T> {
  const None();

  @override
  List<Object?> get props => [];

  @override
  String toString() => 'None';
}

/// Extension methods for easy usage
extension ResultExtensions on Object {
  /// Wrap any operation in a Result
  Result<T> toResult<T>(T Function() operation) {
    try {
      return Result.success(operation());
    } catch (error) {
      final appException = error is AppException 
          ? error 
          : AppException.create(
              message: 'Operation failed',
              errorCode: 'UNKNOWN_ERROR',
              technicalDetails: error.toString(),
            );
      return Result.failure(appException);
    }
  }

  /// Wrap async operation in a Result
  Future<Result<T>> toResultAsync<T>(Future<T> Function() operation) async {
    try {
      final value = await operation();
      return Result.success(value);
    } catch (error) {
      final appException = error is AppException 
          ? error 
          : AppException.create(
              message: 'Async operation failed',
              errorCode: 'UNKNOWN_ERROR',
              technicalDetails: error.toString(),
            );
      return Result.failure(appException);
    }
  }
}