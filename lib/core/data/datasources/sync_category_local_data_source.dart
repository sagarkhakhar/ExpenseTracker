import '../../domain/entities/sync_category.dart';

/// Data source interface for sync-enabled category operations
abstract class SyncCategoryLocalDataSource {
  Future<void> init();
  Future<List<SyncCategory>> getAllSyncCategories();
  Future<SyncCategory?> getSyncCategoryById(String id);
  Future<String> createSyncCategory(SyncCategory category);
  Future<void> updateSyncCategory(SyncCategory category);
  Future<void> deleteSyncCategory(String id);
  Future<List<SyncCategory>> getSyncCategoriesModifiedSince(DateTime timestamp);
  Future<List<SyncCategory>> getDeletedSyncCategories();
  Future<void> bulkUpsertSyncCategories(List<SyncCategory> categories);
}