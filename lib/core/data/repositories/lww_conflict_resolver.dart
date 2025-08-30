import '../../domain/base_entity.dart';
import 'sync_repository.dart';

/// Last Write Wins (LWW) conflict resolver
/// Implements conflict resolution based on version and timestamp
class LWWConflictResolver {
  
  /// Resolve conflict between local and remote entities using LWW strategy
  /// 
  /// Resolution rules:
  /// 1. Higher version always wins
  /// 2. If versions are equal, newer timestamp wins
  /// 3. If timestamps are also equal, server (remote) wins
  /// 4. Handle tombstones (deleted records) specially
  T resolveConflict<T extends BaseEntity>(T local, T remote) {
    // Handle tombstone cases first
    if (remote.isTombstone && !local.isTombstone) {
      // Remote is deleted, local is not - apply deletion
      return remote;
    }
    
    if (local.isTombstone && !remote.isTombstone) {
      // Local is deleted, remote is not - keep deletion if local is newer
      if (local.isNewerThan(remote)) {
        return local;
      } else {
        return remote;
      }
    }
    
    if (local.isTombstone && remote.isTombstone) {
      // Both are tombstones - apply LWW to determine which deletion is newer
      return _applyLWWRule(local, remote);
    }
    
    // Normal conflict resolution using LWW
    return _applyLWWRule(local, remote);
  }
  
  /// Apply Last Write Wins rule between two entities
  T _applyLWWRule<T extends BaseEntity>(T local, T remote) {
    // Higher version always wins
    if (local.version != remote.version) {
      return local.version > remote.version ? local : remote;
    }
    
    // If versions equal, newer timestamp wins
    if (local.updatedAt.isAfter(remote.updatedAt)) {
      return local;
    } else if (remote.updatedAt.isAfter(local.updatedAt)) {
      return remote;
    } else {
      // Exact tie - server (remote) wins
      return remote;
    }
  }
  
  /// Create a sync conflict record for debugging/logging
  SyncConflict<T> createConflictRecord<T extends BaseEntity>(
    T local,
    T remote,
    T resolved,
  ) {
    return SyncConflict<T>(
      entityId: local.id,
      localEntity: local,
      remoteEntity: remote,
      resolvedEntity: resolved,
      resolutionStrategy: ConflictResolutionStrategy.lastWriteWins,
    );
  }
  
  /// Check if two entities are in conflict (have different content but same ID)
  bool hasConflict<T extends BaseEntity>(T local, T remote) {
    // Same ID but different version or timestamp indicates a conflict
    return local.id == remote.id && 
           (local.version != remote.version || local.updatedAt != remote.updatedAt);
  }
  
  /// Determine if an entity should be synchronized based on sync rules
  bool shouldSync<T extends BaseEntity>(T entity, {DateTime? lastSyncTime}) {
    if (lastSyncTime == null) {
      // First sync - sync everything
      return true;
    }
    
    // Sync if entity was modified after last sync
    return entity.updatedAt.isAfter(lastSyncTime);
  }
  
  /// Sort entities by sync priority for batch processing
  List<T> sortBySyncPriority<T extends BaseEntity>(List<T> entities) {
    final sortedEntities = List<T>.from(entities);
    sortedEntities.sort((a, b) {
      // Higher priority first
      final priorityDiff = b.syncPriority - a.syncPriority;
      if (priorityDiff != 0) return priorityDiff;
      
      // Earlier created date first (FIFO for same priority)
      return a.createdAt.compareTo(b.createdAt);
    });
    return sortedEntities;
  }
  
  /// Filter tombstones that are older than a certain threshold
  List<T> filterOldTombstones<T extends BaseEntity>(
    List<T> entities, {
    Duration threshold = const Duration(days: 30),
  }) {
    final cutoffDate = DateTime.now().toUtc().subtract(threshold);
    
    return entities.where((entity) {
      if (entity.isTombstone) {
        // Keep recent tombstones, remove old ones
        return entity.updatedAt.isAfter(cutoffDate);
      }
      // Keep all non-tombstone entities
      return true;
    }).toList();
  }
  
  /// Validate entity for conflict resolution
  void validateEntity<T extends BaseEntity>(T entity) {
    if (entity.id.isEmpty) {
      throw ArgumentError('Entity ID cannot be empty');
    }
    
    if (entity.version <= 0) {
      throw ArgumentError('Entity version must be positive');
    }
    
    if (entity.updatedAt.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5)))) {
      throw ArgumentError('Entity timestamp cannot be in the future');
    }
  }
}

/// Implementation of LWW conflict resolver
class LWWConflictResolverImpl extends LWWConflictResolver {
  // Inherits all functionality from LWWConflictResolver
}