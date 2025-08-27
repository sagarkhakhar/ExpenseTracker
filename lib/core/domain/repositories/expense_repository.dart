import '../entities/sync_expense.dart';
import '../result.dart';

/// Repository interface for sync-enabled expense operations
/// Follows offline-first pattern with local storage and remote sync
abstract class IExpenseRepository {
  
  // ==================== LOCAL OPERATIONS ====================
  
  /// Get all expenses from local storage (active only)
  Future<Result<List<SyncExpense>>> getAllExpenses();
  
  /// Get expense by ID from local storage
  Future<Result<SyncExpense?>> getExpenseById(String id);
  
  /// Create new expense (local first, queued for sync)
  Future<Result<String>> createExpense(SyncExpense expense);
  
  /// Update existing expense (local first, queued for sync)
  Future<Result<void>> updateExpense(SyncExpense expense);
  
  /// Delete expense (soft delete, queued for sync)
  Future<Result<void>> deleteExpense(String id);
  
  // ==================== QUERY OPERATIONS ====================
  
  /// Get expenses by date range
  Future<Result<List<SyncExpense>>> getExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });
  
  /// Get expenses by category
  Future<Result<List<SyncExpense>>> getExpensesByCategory(String categoryId);
  
  /// Get expenses by account
  Future<Result<List<SyncExpense>>> getExpensesByAccount(String accountId);
  
  /// Search expenses by title/description
  Future<Result<List<SyncExpense>>> searchExpenses(String query);
  
  /// Get expenses modified since timestamp (for sync)
  Future<Result<List<SyncExpense>>> getExpensesModifiedSince(DateTime timestamp);
  
  /// Get deleted expenses (tombstones for sync)
  Future<Result<List<SyncExpense>>> getDeletedExpenses();
  
  // ==================== SYNC OPERATIONS ====================
  
  /// Push local changes to remote (returns synced entities)
  Future<Result<List<SyncExpense>>> pushLocalChanges(List<SyncExpense> expenses);
  
  /// Pull remote changes and merge with local
  Future<Result<List<SyncExpense>>> pullRemoteChanges({DateTime? cursor});
  
  /// Perform bidirectional sync
  Future<Result<SyncResult>> syncExpenses({DateTime? lastSync});
  
  /// Get pending sync items count
  Future<Result<int>> getPendingSyncCount();
  
  /// Clear sync queue (use with caution)
  Future<Result<void>> clearSyncQueue();
  
  // ==================== BATCH OPERATIONS ====================
  
  /// Bulk create expenses
  Future<Result<List<String>>> createExpenses(List<SyncExpense> expenses);
  
  /// Bulk update expenses
  Future<Result<void>> updateExpenses(List<SyncExpense> expenses);
  
  /// Bulk delete expenses
  Future<Result<void>> deleteExpenses(List<String> ids);
  
  // ==================== STREAM OPERATIONS ====================
  
  /// Watch all expenses for real-time updates
  Stream<Result<List<SyncExpense>>> watchAllExpenses();
  
  /// Watch expense by ID for real-time updates
  Stream<Result<SyncExpense?>> watchExpenseById(String id);
  
  /// Watch sync status changes
  Stream<SyncStatus> watchSyncStatus();
}

/// Result of a sync operation
class SyncResult {
  const SyncResult({
    required this.pushedCount,
    required this.pulledCount,
    required this.conflictsResolved,
    required this.errors,
    this.lastSyncTime,
  });

  /// Number of local changes pushed to remote
  final int pushedCount;
  
  /// Number of remote changes pulled to local
  final int pulledCount;
  
  /// Number of conflicts resolved during sync
  final int conflictsResolved;
  
  /// Errors encountered during sync
  final List<String> errors;
  
  /// Timestamp of successful sync completion
  final DateTime? lastSyncTime;
  
  /// Whether sync was completely successful
  bool get isSuccessful => errors.isEmpty;
  
  /// Total items synced
  int get totalSynced => pushedCount + pulledCount;

  @override
  String toString() => 'SyncResult('
      'pushed: $pushedCount, '
      'pulled: $pulledCount, '
      'conflicts: $conflictsResolved, '
      'errors: ${errors.length}, '
      'successful: $isSuccessful)';
}

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  error,
  offline,
}

/// Sync statistics for monitoring
class SyncStats {
  const SyncStats({
    required this.lastSyncTime,
    required this.pendingChanges,
    required this.totalSynced,
    required this.conflictsResolved,
    required this.lastError,
  });

  final DateTime? lastSyncTime;
  final int pendingChanges;
  final int totalSynced;
  final int conflictsResolved;
  final String? lastError;
}