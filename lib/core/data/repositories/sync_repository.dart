import '../../domain/entities/sync_expense.dart';
import '../../domain/entities/sync_category.dart';
import '../../domain/entities/sync_account.dart';
import '../../domain/entities/sync_budget.dart';
import '../dtos/expense_dto.dart';
import '../dtos/category_dto.dart';
import '../dtos/account_dto.dart';
import '../dtos/budget_dto.dart';

/// Repository interface for sync operations
/// Handles synchronization between local and remote data
abstract class SyncRepository {
  
  // ==================== EXPENSE SYNC OPERATIONS ====================
  
  /// Push local expense changes to remote
  Future<List<SyncExpense>> pushExpenseChanges(List<SyncExpense> expenses);
  
  /// Pull remote expense changes to local
  Future<List<SyncExpense>> pullExpenseChanges({DateTime? lastSync});
  
  /// Sync expense bidirectionally  
  Future<SyncResult<SyncExpense>> syncExpenses({DateTime? lastSync});
  
  // ==================== CATEGORY SYNC OPERATIONS ====================
  
  /// Push local category changes to remote
  Future<List<SyncCategory>> pushCategoryChanges(List<SyncCategory> categories);
  
  /// Pull remote category changes to local
  Future<List<SyncCategory>> pullCategoryChanges({DateTime? lastSync});
  
  /// Sync categories bidirectionally
  Future<SyncResult<SyncCategory>> syncCategories({DateTime? lastSync});
  
  // ==================== ACCOUNT SYNC OPERATIONS ====================
  
  /// Push local account changes to remote
  Future<List<SyncAccount>> pushAccountChanges(List<SyncAccount> accounts);
  
  /// Pull remote account changes to local
  Future<List<SyncAccount>> pullAccountChanges({DateTime? lastSync});
  
  /// Sync accounts bidirectionally
  Future<SyncResult<SyncAccount>> syncAccounts({DateTime? lastSync});
  
  // ==================== BUDGET SYNC OPERATIONS ====================
  
  /// Push local budget changes to remote
  Future<List<SyncBudget>> pushBudgetChanges(List<SyncBudget> budgets);
  
  /// Pull remote budget changes to local
  Future<List<SyncBudget>> pullBudgetChanges({DateTime? lastSync});
  
  /// Sync budgets bidirectionally
  Future<SyncResult<SyncBudget>> syncBudgets({DateTime? lastSync});
  
  // ==================== FULL SYNC OPERATIONS ====================
  
  /// Perform full bidirectional sync of all entities
  Future<FullSyncResult> performFullSync({DateTime? lastSync});
  
  /// Get the timestamp of the last successful sync
  Future<DateTime?> getLastSyncTimestamp();
  
  /// Update the last sync timestamp
  Future<void> updateLastSyncTimestamp(DateTime timestamp);
  
  // ==================== CONFLICT RESOLUTION ====================
  
  /// Resolve conflicts using Last Write Wins (LWW) strategy
  Future<T> resolveConflict<T>(T local, T remote);
  
  /// Get conflict resolution strategy
  ConflictResolutionStrategy get conflictResolutionStrategy;
}

/// Result of a sync operation for a specific entity type
class SyncResult<T> {
  const SyncResult({
    required this.pushedToRemote,
    required this.pulledFromRemote,
    required this.conflicts,
    required this.errors,
    this.syncTimestamp,
  });

  /// Entities that were successfully pushed to remote
  final List<T> pushedToRemote;
  
  /// Entities that were successfully pulled from remote
  final List<T> pulledFromRemote;
  
  /// Conflicts that were encountered and resolved
  final List<SyncConflict<T>> conflicts;
  
  /// Errors that occurred during sync
  final List<SyncError> errors;
  
  /// Timestamp when sync completed
  final DateTime? syncTimestamp;
  
  /// Whether sync was successful (no errors)
  bool get isSuccessful => errors.isEmpty;
  
  /// Total number of entities synced
  int get totalSynced => pushedToRemote.length + pulledFromRemote.length;
}

/// Result of a full sync operation across all entity types
class FullSyncResult {
  const FullSyncResult({
    required this.expenseResult,
    required this.categoryResult,
    required this.accountResult,
    required this.budgetResult,
    required this.syncTimestamp,
  });

  final SyncResult<SyncExpense> expenseResult;
  final SyncResult<SyncCategory> categoryResult;
  final SyncResult<SyncAccount> accountResult;
  final SyncResult<SyncBudget> budgetResult;
  final DateTime syncTimestamp;
  
  /// Whether all syncs were successful
  bool get isSuccessful => 
      expenseResult.isSuccessful &&
      categoryResult.isSuccessful &&
      accountResult.isSuccessful &&
      budgetResult.isSuccessful;
      
  /// Total entities synced across all types
  int get totalSynced =>
      expenseResult.totalSynced +
      categoryResult.totalSynced +
      accountResult.totalSynced +
      budgetResult.totalSynced;
      
  /// All errors from all sync operations
  List<SyncError> get allErrors => [
    ...expenseResult.errors,
    ...categoryResult.errors,
    ...accountResult.errors,
    ...budgetResult.errors,
  ];
}

/// Represents a sync conflict between local and remote entities
class SyncConflict<T> {
  const SyncConflict({
    required this.entityId,
    required this.localEntity,
    required this.remoteEntity,
    required this.resolvedEntity,
    required this.resolutionStrategy,
  });

  final String entityId;
  final T localEntity;
  final T remoteEntity;
  final T resolvedEntity;
  final ConflictResolutionStrategy resolutionStrategy;
}

/// Represents an error that occurred during sync
class SyncError {
  const SyncError({
    required this.entityId,
    required this.entityType,
    required this.operation,
    required this.message,
    this.exception,
  });

  final String? entityId;
  final String entityType;
  final SyncOperation operation;
  final String message;
  final Exception? exception;
  
  @override
  String toString() => 'SyncError($entityType/$operation): $message';
}

/// Types of sync operations
enum SyncOperation {
  push,
  pull,
  conflictResolution,
  validation,
}

/// Strategies for resolving conflicts
enum ConflictResolutionStrategy {
  lastWriteWins,
  firstWriteWins,
  manual,
  serverWins,
  clientWins,
}