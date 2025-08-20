// Advanced exception hierarchy for exceptional error handling
// This demonstrates domain-driven exception design with rich context and recovery strategies

import 'package:equatable/equatable.dart';

/// Base exception class that provides rich context and debugging information
abstract class AppException extends Equatable implements Exception {
  /// Human-readable message for the user
  final String message;
  
  /// Technical details for developers/logging
  final String? technicalDetails;
  
  /// Unique error code for tracking and analytics
  final String errorCode;
  
  /// Stack trace context for debugging
  final StackTrace? stackTrace;
  
  /// Additional context data for advanced debugging
  final Map<String, dynamic>? context;
  
  /// Timestamp when the error occurred
  final DateTime timestamp;
  
  /// Severity level for proper logging and alerting
  final ErrorSeverity severity;

  const AppException({
    required this.message,
    required this.errorCode,
    this.technicalDetails,
    this.stackTrace,
    this.context,
    this.severity = ErrorSeverity.medium,
  }) : timestamp = null; // Will be set in constructor body

  /// Factory constructor that automatically sets timestamp
  factory AppException.create({
    required String message,
    required String errorCode,
    String? technicalDetails,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) {
    final exception = _AppExceptionImpl(
      message: message,
      errorCode: errorCode,
      technicalDetails: technicalDetails,
      stackTrace: stackTrace,
      context: context,
      severity: severity,
      timestamp: DateTime.now(),
    );
    return exception;
  }

  @override
  List<Object?> get props => [message, errorCode, technicalDetails, context, timestamp];

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('$runtimeType: $message');
    buffer.writeln('Error Code: $errorCode');
    buffer.writeln('Timestamp: $timestamp');
    buffer.writeln('Severity: $severity');
    
    if (technicalDetails != null) {
      buffer.writeln('Technical Details: $technicalDetails');
    }
    
    if (context != null && context!.isNotEmpty) {
      buffer.writeln('Context: $context');
    }
    
    if (stackTrace != null) {
      buffer.writeln('Stack Trace: $stackTrace');
    }
    
    return buffer.toString();
  }
}

/// Implementation class for the factory constructor
class _AppExceptionImpl extends AppException {
  @override
  final DateTime timestamp;

  const _AppExceptionImpl({
    required super.message,
    required super.errorCode,
    required this.timestamp,
    super.technicalDetails,
    super.stackTrace,
    super.context,
    super.severity,
  });
}

/// Error severity levels for proper logging and alerting
enum ErrorSeverity {
  low,     // Info/Warning level
  medium,  // Error level  
  high,    // Critical level
  critical // System failure level
}

/// Domain-specific exceptions for expense operations
class ExpenseException extends AppException {
  const ExpenseException({
    required super.message,
    required super.errorCode,
    super.technicalDetails,
    super.stackTrace,
    super.context,
    super.severity,
  });

  factory ExpenseException.validationFailed({
    required String field,
    required String value,
    required String reason,
  }) {
    return ExpenseException(
      message: 'Invalid $field: $reason',
      errorCode: 'EXPENSE_VALIDATION_FAILED',
      technicalDetails: 'Field: $field, Value: $value, Reason: $reason',
      context: {
        'field': field,
        'value': value,
        'reason': reason,
      },
      severity: ErrorSeverity.medium,
    );
  }

  factory ExpenseException.notFound(String expenseId) {
    return ExpenseException(
      message: 'Expense not found',
      errorCode: 'EXPENSE_NOT_FOUND',
      technicalDetails: 'No expense found with ID: $expenseId',
      context: {'expenseId': expenseId},
      severity: ErrorSeverity.medium,
    );
  }

  factory ExpenseException.duplicateFound(String identifier) {
    return ExpenseException(
      message: 'Duplicate expense detected',
      errorCode: 'EXPENSE_DUPLICATE',
      technicalDetails: 'Expense with identifier $identifier already exists',
      context: {'identifier': identifier},
      severity: ErrorSeverity.low,
    );
  }
}

/// Storage-specific exceptions with recovery strategies
class StorageException extends AppException {
  const StorageException({
    required super.message,
    required super.errorCode,
    super.technicalDetails,
    super.stackTrace,
    super.context,
    super.severity,
  });

  factory StorageException.databaseUnavailable() {
    return const StorageException(
      message: 'Database is temporarily unavailable',
      errorCode: 'DATABASE_UNAVAILABLE',
      technicalDetails: 'Local database (Hive) failed to initialize or access',
      severity: ErrorSeverity.high,
    );
  }

  factory StorageException.corruptedData({
    required String dataType,
    required String details,
  }) {
    return StorageException(
      message: 'Data corruption detected',
      errorCode: 'DATA_CORRUPTED',
      technicalDetails: 'Corrupted $dataType: $details',
      context: {
        'dataType': dataType,
        'details': details,
      },
      severity: ErrorSeverity.high,
    );
  }

  factory StorageException.migrationFailed({
    required int fromVersion,
    required int toVersion,
    required String error,
  }) {
    return StorageException(
      message: 'Database migration failed',
      errorCode: 'MIGRATION_FAILED',
      technicalDetails: 'Failed to migrate from v$fromVersion to v$toVersion: $error',
      context: {
        'fromVersion': fromVersion,
        'toVersion': toVersion,
        'error': error,
      },
      severity: ErrorSeverity.critical,
    );
  }
}

/// Network-related exceptions for future API integration
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    required super.errorCode,
    super.technicalDetails,
    super.stackTrace,
    super.context,
    super.severity,
  });

  factory NetworkException.connectionTimeout() {
    return const NetworkException(
      message: 'Connection timed out',
      errorCode: 'CONNECTION_TIMEOUT',
      technicalDetails: 'Network request exceeded timeout limit',
      severity: ErrorSeverity.medium,
    );
  }

  factory NetworkException.serverError({
    required int statusCode,
    required String response,
  }) {
    return NetworkException(
      message: 'Server error occurred',
      errorCode: 'SERVER_ERROR',
      technicalDetails: 'HTTP $statusCode: $response',
      context: {
        'statusCode': statusCode,
        'response': response,
      },
      severity: ErrorSeverity.high,
    );
  }
}

/// Permission-related exceptions for security
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    required super.errorCode,
    super.technicalDetails,
    super.stackTrace,
    super.context,
    super.severity,
  });

  factory PermissionException.cameraAccessDenied() {
    return const PermissionException(
      message: 'Camera access required for receipt photos',
      errorCode: 'CAMERA_PERMISSION_DENIED',
      technicalDetails: 'User denied camera permission for photo capture',
      severity: ErrorSeverity.medium,
    );
  }

  factory PermissionException.storageAccessDenied() {
    return const PermissionException(
      message: 'Storage access required for data management',
      errorCode: 'STORAGE_PERMISSION_DENIED',
      technicalDetails: 'User denied storage permission for file operations',
      severity: ErrorSeverity.medium,
    );
  }
}

/// Extension methods for enhanced error handling
extension ExceptionExtensions on Exception {
  /// Converts any exception to our standardized format
  AppException toAppException() {
    if (this is AppException) {
      return this as AppException;
    }
    
    return AppException.create(
      message: 'An unexpected error occurred',
      errorCode: 'UNKNOWN_ERROR',
      technicalDetails: toString(),
      stackTrace: StackTrace.current,
      severity: ErrorSeverity.medium,
    );
  }
}