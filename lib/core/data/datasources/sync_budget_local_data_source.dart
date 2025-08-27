import '../../domain/entities/sync_budget.dart';

/// Data source interface for sync-enabled budget operations
abstract class SyncBudgetLocalDataSource {
  Future<void> init();
  Future<List<SyncBudget>> getAllSyncBudgets();
  Future<SyncBudget?> getSyncBudgetById(String id);
  Future<String> createSyncBudget(SyncBudget budget);
  Future<void> updateSyncBudget(SyncBudget budget);
  Future<void> deleteSyncBudget(String id);
  Future<List<SyncBudget>> getSyncBudgetsModifiedSince(DateTime timestamp);
  Future<List<SyncBudget>> getDeletedSyncBudgets();
  Future<void> bulkUpsertSyncBudgets(List<SyncBudget> budgets);
}