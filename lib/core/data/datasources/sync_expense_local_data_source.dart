import '../../domain/entities/sync_expense.dart';

/// Data source interface for sync-enabled expense operations
/// Handles local storage operations for SyncExpense entities
abstract class SyncExpenseLocalDataSource {
  /// Initialize the data source
  Future<void> init();

  /// Get all sync expenses from local storage
  Future<List<SyncExpense>> getAllSyncExpenses();

  /// Get a specific sync expense by ID
  Future<SyncExpense?> getSyncExpenseById(String id);

  /// Create a new sync expense
  Future<String> createSyncExpense(SyncExpense expense);

  /// Update an existing sync expense
  Future<void> updateSyncExpense(SyncExpense expense);

  /// Delete a sync expense (soft delete by setting isDeleted = true)
  Future<void> deleteSyncExpense(String id);

  /// Get sync expenses that have been modified since a given timestamp
  Future<List<SyncExpense>> getSyncExpensesModifiedSince(DateTime timestamp);

  /// Get sync expenses that have been deleted but not yet synced
  Future<List<SyncExpense>> getDeletedSyncExpenses();

  /// Get sync expenses by version (for conflict resolution)
  Future<List<SyncExpense>> getSyncExpensesByVersion(int minVersion);

  /// Bulk insert/update sync expenses (for sync operations)
  Future<void> bulkUpsertSyncExpenses(List<SyncExpense> expenses);

  /// Get count of unsynced changes
  Future<int> getUnsyncedChangeCount();

  /// Clear all sync expenses (for fresh sync)
  Future<void> clearAllSyncExpenses();

  /// Check if expense with ID exists
  Future<bool> syncExpenseExists(String id);
}