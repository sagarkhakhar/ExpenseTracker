import '../entities/sync_category.dart';
import '../result.dart';

/// Repository interface for sync-enabled category operations
abstract class ICategoryRepository {
  
  // ==================== LOCAL OPERATIONS ====================
  
  /// Get all categories from local storage (active only)
  Future<Result<List<SyncCategory>>> getAllCategories();
  
  /// Get category by ID from local storage
  Future<Result<SyncCategory?>> getCategoryById(String id);
  
  /// Create new category (local first, queued for sync)
  Future<Result<String>> createCategory(SyncCategory category);
  
  /// Update existing category (local first, queued for sync)
  Future<Result<void>> updateCategory(SyncCategory category);
  
  /// Delete category (soft delete, queued for sync)
  Future<Result<void>> deleteCategory(String id);
  
  // ==================== QUERY OPERATIONS ====================
  
  /// Get default/system categories
  Future<Result<List<SyncCategory>>> getDefaultCategories();
  
  /// Get user-created categories
  Future<Result<List<SyncCategory>>> getUserCategories();
  
  /// Search categories by name
  Future<Result<List<SyncCategory>>> searchCategories(String query);
  
  /// Get categories by color
  Future<Result<List<SyncCategory>>> getCategoriesByColor(String color);
  
  /// Get categories modified since timestamp (for sync)
  Future<Result<List<SyncCategory>>> getCategoriesModifiedSince(DateTime timestamp);
  
  /// Get deleted categories (tombstones for sync)
  Future<Result<List<SyncCategory>>> getDeletedCategories();
  
  // ==================== SYNC OPERATIONS ====================
  
  /// Push local changes to remote
  Future<Result<List<SyncCategory>>> pushLocalChanges(List<SyncCategory> categories);
  
  /// Pull remote changes and merge with local
  Future<Result<List<SyncCategory>>> pullRemoteChanges({DateTime? cursor});
  
  /// Perform bidirectional sync
  Future<Result<SyncResult>> syncCategories({DateTime? lastSync});
  
  /// Get pending sync items count
  Future<Result<int>> getPendingSyncCount();
  
  // ==================== BATCH OPERATIONS ====================
  
  /// Bulk create categories
  Future<Result<List<String>>> createCategories(List<SyncCategory> categories);
  
  /// Bulk update categories
  Future<Result<void>> updateCategories(List<SyncCategory> categories);
  
  /// Initialize default categories if not present
  Future<Result<void>> initializeDefaultCategories();
  
  // ==================== STREAM OPERATIONS ====================
  
  /// Watch all categories for real-time updates
  Stream<Result<List<SyncCategory>>> watchAllCategories();
  
  /// Watch category by ID for real-time updates
  Stream<Result<SyncCategory?>> watchCategoryById(String id);
}

/// Sync result for category operations
class SyncResult {
  const SyncResult({
    required this.pushedCount,
    required this.pulledCount,
    required this.conflictsResolved,
    required this.errors,
    this.lastSyncTime,
  });

  final int pushedCount;
  final int pulledCount;
  final int conflictsResolved;
  final List<String> errors;
  final DateTime? lastSyncTime;
  
  bool get isSuccessful => errors.isEmpty;
  int get totalSynced => pushedCount + pulledCount;
}