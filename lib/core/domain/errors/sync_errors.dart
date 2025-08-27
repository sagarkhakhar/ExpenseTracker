import '../result.dart';

/// Sync-specific errors for offline-first operations
sealed class SyncError extends AppError {
  const SyncError({
    required super.code,
    required super.message,
    super.details,
    super.stackTrace,
  });
}

/// Network connectivity errors
final class NetworkError extends SyncError {
  const NetworkError({
    required super.message,
    super.details,
    super.stackTrace,
  }) : super(code: 'NETWORK_ERROR');

  /// No internet connection
  const NetworkError.noConnection()
      : super(
          code: 'NO_CONNECTION',
          message: 'No internet connection available',
        );

  /// Connection timeout
  const NetworkError.timeout()
      : super(
          code: 'CONNECTION_TIMEOUT',
          message: 'Connection timed out',
        );

  /// Connection refused
  const NetworkError.connectionRefused()
      : super(
          code: 'CONNECTION_REFUSED',
          message: 'Connection refused by server',
        );
}

/// Authentication and authorization errors
final class AuthError extends SyncError {
  const AuthError({
    required super.message,
    super.details,
    super.stackTrace,
  }) : super(code: 'AUTH_ERROR');

  /// Invalid credentials
  const AuthError.invalidCredentials()
      : super(
          code: 'INVALID_CREDENTIALS',
          message: 'Invalid authentication credentials',
        );

  /// Access denied
  const AuthError.accessDenied()
      : super(
          code: 'ACCESS_DENIED',
          message: 'Access denied - insufficient permissions',
        );

  /// Session expired
  const AuthError.sessionExpired()
      : super(
          code: 'SESSION_EXPIRED',
          message: 'Authentication session has expired',
        );
}

/// Supabase-specific errors
final class SupabaseError extends SyncError {
  const SupabaseError({
    required super.message,
    super.details,
    super.stackTrace,
  }) : super(code: 'SUPABASE_ERROR');

  /// RLS policy violation
  SupabaseError.rlsViolation({String? details})
      : super(
          code: 'RLS_VIOLATION',
          message: 'Row Level Security policy violation',
          details: details != null ? {'policy': details} : null,
        );

  /// Database constraint violation
  SupabaseError.constraintViolation({String? constraint})
      : super(
          code: 'CONSTRAINT_VIOLATION',
          message: 'Database constraint violation',
          details: constraint != null ? {'constraint': constraint} : null,
        );

  /// Schema mismatch
  SupabaseError.schemaMismatch({String? expected, String? actual})
      : super(
          code: 'SCHEMA_MISMATCH',
          message: 'Database schema does not match expected version',
          details: {
            if (expected != null) 'expected': expected,
            if (actual != null) 'actual': actual,
          },
        );
}

/// Conflict resolution errors
final class ConflictError extends SyncError {
  const ConflictError({
    required super.message,
    super.details,
    super.stackTrace,
  }) : super(code: 'CONFLICT_ERROR');

  /// Version conflict during sync
  ConflictError.versionConflict({
    required String entityId,
    required int localVersion,
    required int remoteVersion,
  }) : super(
          code: 'VERSION_CONFLICT',
          message: 'Version conflict detected during sync',
          details: {
            'entityId': entityId,
            'localVersion': localVersion,
            'remoteVersion': remoteVersion,
          },
        );

  /// Concurrent modification
  ConflictError.concurrentModification({String? entityId})
      : super(
          code: 'CONCURRENT_MODIFICATION',
          message: 'Entity was modified by another process',
          details: entityId != null ? {'entityId': entityId} : null,
        );
}

/// Local storage errors
final class StorageError extends SyncError {
  const StorageError({
    required super.message,
    super.details,
    super.stackTrace,
  }) : super(code: 'STORAGE_ERROR');

  /// Hive box not initialized
  StorageError.boxNotInitialized({String? boxName})
      : super(
          code: 'BOX_NOT_INITIALIZED',
          message: 'Hive box not initialized',
          details: boxName != null ? {'boxName': boxName} : null,
        );

  /// Storage quota exceeded
  const StorageError.quotaExceeded()
      : super(
          code: 'QUOTA_EXCEEDED',
          message: 'Local storage quota exceeded',
        );

  /// Corrupted data
  StorageError.corruptedData({String? details})
      : super(
          code: 'CORRUPTED_DATA',
          message: 'Local storage data is corrupted',
          details: details != null ? {'details': details} : null,
        );
}

/// Validation errors
final class ValidationError extends SyncError {
  const ValidationError({
    required super.message,
    super.details,
    super.stackTrace,
  }) : super(code: 'VALIDATION_ERROR');

  /// Invalid entity data
  ValidationError.invalidEntity({
    String? field,
    String? reason,
  }) : super(
          code: 'INVALID_ENTITY',
          message: 'Entity validation failed',
          details: {
            if (field != null) 'field': field,
            if (reason != null) 'reason': reason,
          },
        );

  /// Invalid ID format
  ValidationError.invalidId({String? id})
      : super(
          code: 'INVALID_ID',
          message: 'Invalid entity ID format',
          details: id != null ? {'id': id} : null,
        );

  /// Missing required field
  ValidationError.requiredField({required String field})
      : super(
          code: 'REQUIRED_FIELD',
          message: 'Required field is missing or empty',
          details: {'field': field},
        );
}

/// Sync operation errors
final class SyncOperationError extends SyncError {
  const SyncOperationError({
    required super.message,
    super.details,
    super.stackTrace,
  }) : super(code: 'SYNC_OPERATION_ERROR');

  /// Sync already in progress
  const SyncOperationError.syncInProgress()
      : super(
          code: 'SYNC_IN_PROGRESS',
          message: 'Sync operation already in progress',
        );

  /// Sync queue full
  SyncOperationError.queueFull({int? maxSize})
      : super(
          code: 'SYNC_QUEUE_FULL',
          message: 'Sync queue is full',
          details: maxSize != null ? {'maxSize': maxSize} : null,
        );

  /// Batch size exceeded
  SyncOperationError.batchSizeExceeded({
    required int size,
    required int maxSize,
  }) : super(
          code: 'BATCH_SIZE_EXCEEDED',
          message: 'Batch size exceeds maximum allowed',
          details: {'size': size, 'maxSize': maxSize},
        );
}