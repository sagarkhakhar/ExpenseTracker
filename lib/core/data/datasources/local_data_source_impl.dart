import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../entities/sync_metadata.dart';
import '../entities/mutation_queue_item.dart';
import 'local_data_source.dart';

/// Hive-based implementation of LocalDataSource
/// Manages sync metadata and mutation queue for offline-first operations
class LocalDataSourceImpl implements LocalDataSource {
  static const String _syncMetadataBoxName = 'sync_metadata';
  static const String _mutationQueueBoxName = 'mutation_queue';

  late Box<SyncMetadata> _syncMetadataBox;
  late Box<MutationQueueItem> _mutationQueueBox;

  @override
  Future<void> init() async {
    debugPrint('Initializing LocalDataSourceImpl...');

    // Initialize sync metadata box
    if (!Hive.isBoxOpen(_syncMetadataBoxName)) {
      _syncMetadataBox = await Hive.openBox<SyncMetadata>(_syncMetadataBoxName);
      debugPrint('Opened sync metadata box');
    } else {
      _syncMetadataBox = Hive.box<SyncMetadata>(_syncMetadataBoxName);
    }

    // Initialize mutation queue box
    if (!Hive.isBoxOpen(_mutationQueueBoxName)) {
      _mutationQueueBox = await Hive.openBox<MutationQueueItem>(_mutationQueueBoxName);
      debugPrint('Opened mutation queue box');
    } else {
      _mutationQueueBox = Hive.box<MutationQueueItem>(_mutationQueueBoxName);
    }

    debugPrint('LocalDataSourceImpl initialized successfully');
  }

  @override
  Future<void> close() async {
    debugPrint('Closing LocalDataSourceImpl...');
    
    if (_syncMetadataBox.isOpen) {
      await _syncMetadataBox.close();
    }
    if (_mutationQueueBox.isOpen) {
      await _mutationQueueBox.close();
    }
    
    debugPrint('LocalDataSourceImpl closed');
  }

  // SYNC METADATA OPERATIONS

  @override
  Future<SyncMetadata?> getSyncMetadata(String entityType) async {
    try {
      final metadata = _syncMetadataBox.get(entityType);
      debugPrint('Retrieved sync metadata for $entityType: ${metadata != null ? 'found' : 'not found'}');
      return metadata;
    } catch (e) {
      debugPrint('Error getting sync metadata for $entityType: $e');
      rethrow;
    }
  }

  @override
  Future<void> setSyncMetadata(SyncMetadata metadata) async {
    try {
      await _syncMetadataBox.put(metadata.entityType, metadata);
      debugPrint('Set sync metadata for ${metadata.entityType}');
    } catch (e) {
      debugPrint('Error setting sync metadata: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateLastPullCursor(String entityType, DateTime cursor) async {
    try {
      final existing = await getSyncMetadata(entityType);
      final updated = existing?.copyWith(lastPullCursor: cursor) ??
          SyncMetadata(entityType: entityType, lastPullCursor: cursor);
      await setSyncMetadata(updated);
      debugPrint('Updated last pull cursor for $entityType to $cursor');
    } catch (e) {
      debugPrint('Error updating last pull cursor: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateLastSuccessfulSync(String entityType, DateTime timestamp) async {
    try {
      final existing = await getSyncMetadata(entityType);
      final updated = existing?.copyWith(
        lastSuccessfulSync: timestamp,
        syncVersion: (existing.syncVersion) + 1,
      ) ?? SyncMetadata(
        entityType: entityType,
        lastSuccessfulSync: timestamp,
        syncVersion: 1,
      );
      await setSyncMetadata(updated);
      debugPrint('Updated last successful sync for $entityType to $timestamp');
    } catch (e) {
      debugPrint('Error updating last successful sync: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearSyncMetadata(String entityType) async {
    try {
      await _syncMetadataBox.delete(entityType);
      debugPrint('Cleared sync metadata for $entityType');
    } catch (e) {
      debugPrint('Error clearing sync metadata for $entityType: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAllSyncMetadata() async {
    try {
      await _syncMetadataBox.clear();
      debugPrint('Cleared all sync metadata');
    } catch (e) {
      debugPrint('Error clearing all sync metadata: $e');
      rethrow;
    }
  }

  // MUTATION QUEUE OPERATIONS

  @override
  Future<void> enqueueOperation(MutationQueueItem item) async {
    try {
      await _mutationQueueBox.put(item.id, item);
      debugPrint('Enqueued mutation: ${item.operation} for ${item.entityType}:${item.entityId}');
    } catch (e) {
      debugPrint('Error enqueuing mutation: $e');
      rethrow;
    }
  }

  @override
  Future<List<MutationQueueItem>> getPendingMutations({int? limit}) async {
    try {
      final now = DateTime.now();
      var mutations = _mutationQueueBox.values
          .where((item) => item.scheduledFor == null || item.scheduledFor!.isBefore(now))
          .toList();

      // Sort by priority (higher first) then by creation time (older first)
      mutations.sort((a, b) {
        final priorityComparison = b.priority.compareTo(a.priority);
        if (priorityComparison != 0) return priorityComparison;
        return a.createdAt.compareTo(b.createdAt);
      });

      if (limit != null && mutations.length > limit) {
        mutations = mutations.take(limit).toList();
      }

      debugPrint('Retrieved ${mutations.length} pending mutations');
      return mutations;
    } catch (e) {
      debugPrint('Error getting pending mutations: $e');
      rethrow;
    }
  }

  @override
  Future<List<MutationQueueItem>> getPendingMutationsForEntity(
    String entityType, {
    int? limit,
  }) async {
    try {
      final now = DateTime.now();
      var mutations = _mutationQueueBox.values
          .where((item) =>
              item.entityType == entityType &&
              (item.scheduledFor == null || item.scheduledFor!.isBefore(now)))
          .toList();

      // Sort by priority then creation time
      mutations.sort((a, b) {
        final priorityComparison = b.priority.compareTo(a.priority);
        if (priorityComparison != 0) return priorityComparison;
        return a.createdAt.compareTo(b.createdAt);
      });

      if (limit != null && mutations.length > limit) {
        mutations = mutations.take(limit).toList();
      }

      debugPrint('Retrieved ${mutations.length} pending mutations for $entityType');
      return mutations;
    } catch (e) {
      debugPrint('Error getting pending mutations for entity: $e');
      rethrow;
    }
  }

  @override
  Future<void> dequeueMutation(String mutationId) async {
    try {
      await _mutationQueueBox.delete(mutationId);
      debugPrint('Dequeued mutation: $mutationId');
    } catch (e) {
      debugPrint('Error dequeuing mutation: $e');
      rethrow;
    }
  }

  @override
  Future<void> dequeueMutations(List<String> mutationIds) async {
    try {
      await _mutationQueueBox.deleteAll(mutationIds);
      debugPrint('Dequeued ${mutationIds.length} mutations');
    } catch (e) {
      debugPrint('Error dequeuing mutations: $e');
      rethrow;
    }
  }

  @override
  Future<void> incrementRetryCount(String mutationId) async {
    try {
      final mutation = _mutationQueueBox.get(mutationId);
      if (mutation != null) {
        final updated = mutation.copyWith(retryCount: mutation.retryCount + 1);
        await _mutationQueueBox.put(mutationId, updated);
        debugPrint('Incremented retry count for mutation $mutationId to ${updated.retryCount}');
      }
    } catch (e) {
      debugPrint('Error incrementing retry count: $e');
      rethrow;
    }
  }

  @override
  Future<int> getPendingMutationCount() async {
    try {
      final now = DateTime.now();
      final count = _mutationQueueBox.values
          .where((item) => item.scheduledFor == null || item.scheduledFor!.isBefore(now))
          .length;
      debugPrint('Pending mutation count: $count');
      return count;
    } catch (e) {
      debugPrint('Error getting pending mutation count: $e');
      rethrow;
    }
  }

  @override
  Future<int> getPendingMutationCountForEntity(String entityType) async {
    try {
      final now = DateTime.now();
      final count = _mutationQueueBox.values
          .where((item) =>
              item.entityType == entityType &&
              (item.scheduledFor == null || item.scheduledFor!.isBefore(now)))
          .length;
      debugPrint('Pending mutation count for $entityType: $count');
      return count;
    } catch (e) {
      debugPrint('Error getting pending mutation count for entity: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearMutationQueue() async {
    try {
      await _mutationQueueBox.clear();
      debugPrint('Cleared mutation queue');
    } catch (e) {
      debugPrint('Error clearing mutation queue: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearMutationsForEntity(String entityType) async {
    try {
      final keysToDelete = _mutationQueueBox.values
          .where((item) => item.entityType == entityType)
          .map((item) => item.id)
          .toList();
      await _mutationQueueBox.deleteAll(keysToDelete);
      debugPrint('Cleared mutations for entity type: $entityType');
    } catch (e) {
      debugPrint('Error clearing mutations for entity: $e');
      rethrow;
    }
  }

  @override
  Future<List<MutationQueueItem>> getReadyMutations({int? limit}) async {
    // Same as getPendingMutations since we filter by scheduledFor
    return getPendingMutations(limit: limit);
  }

  @override
  Future<void> scheduleMutation(String mutationId, DateTime scheduleFor) async {
    try {
      final mutation = _mutationQueueBox.get(mutationId);
      if (mutation != null) {
        final updated = mutation.copyWith(scheduledFor: scheduleFor);
        await _mutationQueueBox.put(mutationId, updated);
        debugPrint('Scheduled mutation $mutationId for $scheduleFor');
      }
    } catch (e) {
      debugPrint('Error scheduling mutation: $e');
      rethrow;
    }
  }

  // BATCH OPERATIONS

  @override
  Future<void> performBatchOperation(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (e) {
      debugPrint('Error performing batch operation: $e');
      rethrow;
    }
  }

  // UTILITY OPERATIONS

  @override
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final stats = {
        'syncMetadata': {
          'count': _syncMetadataBox.length,
          'isOpen': _syncMetadataBox.isOpen,
        },
        'mutationQueue': {
          'count': _mutationQueueBox.length,
          'isOpen': _mutationQueueBox.isOpen,
          'pendingCount': await getPendingMutationCount(),
        },
      };
      debugPrint('Storage stats: $stats');
      return stats;
    } catch (e) {
      debugPrint('Error getting storage stats: $e');
      rethrow;
    }
  }

  @override
  Future<void> performCleanup({DateTime? olderThan}) async {
    try {
      olderThan ??= DateTime.now().subtract(const Duration(days: 30));
      
      // Could implement cleanup of old tombstones or failed mutations here
      // For now, just log the operation
      debugPrint('Performed cleanup for items older than $olderThan');
    } catch (e) {
      debugPrint('Error performing cleanup: $e');
      rethrow;
    }
  }

  @override
  Future<bool> validateDataIntegrity() async {
    try {
      // Basic validation - check if boxes are accessible
      final syncMetadataAccessible = _syncMetadataBox.isOpen && _syncMetadataBox.length >= 0;
      final mutationQueueAccessible = _mutationQueueBox.isOpen && _mutationQueueBox.length >= 0;
      
      final isValid = syncMetadataAccessible && mutationQueueAccessible;
      debugPrint('Data integrity validation: ${isValid ? 'PASSED' : 'FAILED'}');
      return isValid;
    } catch (e) {
      debugPrint('Error validating data integrity: $e');
      return false;
    }
  }
}