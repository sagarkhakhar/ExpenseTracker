import '../entities/sync_metadata.dart';
import '../entities/mutation_queue_item.dart';

/// Base interface for local data source operations with sync metadata support
abstract class LocalDataSource {
  /// Initialize the local data source and open Hive boxes
  Future<void> init();

  /// Close the local data source and clean up resources
  Future<void> close();

  // SYNC METADATA OPERATIONS

  /// Get sync metadata for a specific entity type
  Future<SyncMetadata?> getSyncMetadata(String entityType);

  /// Set sync metadata for a specific entity type
  Future<void> setSyncMetadata(SyncMetadata metadata);

  /// Update the last pull cursor for an entity type
  Future<void> updateLastPullCursor(String entityType, DateTime cursor);

  /// Update the last successful sync timestamp for an entity type
  Future<void> updateLastSuccessfulSync(String entityType, DateTime timestamp);

  /// Clear sync metadata for a specific entity type
  Future<void> clearSyncMetadata(String entityType);

  /// Clear all sync metadata
  Future<void> clearAllSyncMetadata();

  // MUTATION QUEUE OPERATIONS

  /// Add a mutation operation to the queue
  Future<void> enqueueOperation(MutationQueueItem item);

  /// Get all pending mutations, ordered by priority and creation time
  Future<List<MutationQueueItem>> getPendingMutations({int? limit});

  /// Get pending mutations for a specific entity type
  Future<List<MutationQueueItem>> getPendingMutationsForEntity(
    String entityType, {
    int? limit,
  });

  /// Remove a mutation from the queue
  Future<void> dequeueMutation(String mutationId);

  /// Remove multiple mutations from the queue
  Future<void> dequeueMutations(List<String> mutationIds);

  /// Increment retry count for a mutation
  Future<void> incrementRetryCount(String mutationId);

  /// Get the count of pending mutations
  Future<int> getPendingMutationCount();

  /// Get the count of pending mutations for a specific entity type
  Future<int> getPendingMutationCountForEntity(String entityType);

  /// Clear all mutations from the queue
  Future<void> clearMutationQueue();

  /// Clear mutations for a specific entity type
  Future<void> clearMutationsForEntity(String entityType);

  /// Get mutations that are ready to be processed (not scheduled for future)
  Future<List<MutationQueueItem>> getReadyMutations({int? limit});

  /// Schedule a mutation for future processing
  Future<void> scheduleMutation(String mutationId, DateTime scheduleFor);

  // BATCH OPERATIONS

  /// Perform multiple operations in a transaction
  Future<void> performBatchOperation(Future<void> Function() operation);

  // UTILITY OPERATIONS

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats();

  /// Perform cleanup operations (e.g., remove old tombstones)
  Future<void> performCleanup({DateTime? olderThan});

  /// Validate data integrity
  Future<bool> validateDataIntegrity();
}