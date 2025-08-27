import '../../domain/entities/sync_account.dart';

/// Data source interface for sync-enabled account operations
abstract class SyncAccountLocalDataSource {
  Future<void> init();
  Future<List<SyncAccount>> getAllSyncAccounts();
  Future<SyncAccount?> getSyncAccountById(String id);
  Future<String> createSyncAccount(SyncAccount account);
  Future<void> updateSyncAccount(SyncAccount account);
  Future<void> deleteSyncAccount(String id);
  Future<List<SyncAccount>> getSyncAccountsModifiedSince(DateTime timestamp);
  Future<List<SyncAccount>> getDeletedSyncAccounts();
  Future<void> bulkUpsertSyncAccounts(List<SyncAccount> accounts);
}