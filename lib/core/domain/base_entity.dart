import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Base entity class for all domain entities with sync support
/// Contains common fields needed for offline-first synchronization
abstract class BaseEntity extends Equatable {
  const BaseEntity({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.isDeleted = false,
    this.deviceId,
    this.lastEditor,
  });

  /// Unique identifier (UUID v4)
  final String id;
  
  /// Timestamp when record was created (UTC)
  final DateTime createdAt;
  
  /// Timestamp when record was last updated (UTC) 
  /// Auto-updated by server triggers on changes
  final DateTime updatedAt;
  
  /// Version number for conflict resolution
  /// Incremented automatically by server triggers
  final int version;
  
  /// Soft delete flag for tombstone records
  /// When true, record is marked as deleted but not removed
  final bool isDeleted;
  
  /// ID of device that created/last modified this record
  /// Used for conflict resolution and sync tracking
  final String? deviceId;
  
  /// User/device identifier for the last editor
  /// Used for conflict resolution (Last Write Wins)
  final String? lastEditor;

  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        version,
        isDeleted,
        deviceId,
        lastEditor,
      ];

  /// Check if this entity is newer than another based on version and timestamp
  /// Used for Last Write Wins (LWW) conflict resolution
  bool isNewerThan(BaseEntity other) {
    // Higher version always wins
    if (version != other.version) {
      return version > other.version;
    }
    
    // If versions equal, use timestamp (server wins ties)
    return updatedAt.isAfter(other.updatedAt);
  }

  /// Check if this entity represents a tombstone (deleted record)
  bool get isTombstone => isDeleted;

  /// Get the sync priority of this entity
  /// Higher priority = sync first
  /// 0 = normal, 1 = high priority, 2 = critical
  int get syncPriority => 0; // Override in subclasses if needed

  /// Create a copy of this entity with updated sync metadata
  BaseEntity copyWithSyncMetadata({
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
    String? lastEditor,
  });

  /// Create a tombstone version of this entity (soft delete)
  BaseEntity toTombstone({
    required String deviceId,
    required String lastEditor,
  }) {
    return copyWithSyncMetadata(
      updatedAt: DateTime.now().toUtc(),
      version: version + 1,
      isDeleted: true,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  @override
  String toString() => '$runtimeType('
      'id: ${id.length > 8 ? id.substring(0, 8) + '...' : id}, '
      'version: $version, '
      'updated: ${updatedAt.toIso8601String()}, '
      'deleted: $isDeleted)';
}

/// Utility class for generating entity IDs and sync metadata
class EntityUtils {
  static const Uuid _uuid = Uuid();

  /// Generate a new UUID v4 for entity ID
  static String generateId() => _uuid.v4();

  /// Get current UTC timestamp
  static DateTime now() => DateTime.now().toUtc();

  /// Create initial sync metadata for new entities
  static Map<String, dynamic> createSyncMetadata({
    required String deviceId,
    required String lastEditor,
  }) {
    final now = DateTime.now().toUtc();
    return {
      'id': generateId(),
      'createdAt': now,
      'updatedAt': now,
      'version': 1,
      'isDeleted': false,
      'deviceId': deviceId,
      'lastEditor': lastEditor,
    };
  }

  /// Validate entity ID format (should be UUID v4)
  static bool isValidId(String id) {
    try {
      return RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
          .hasMatch(id.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  /// Compare two entities for sync ordering
  /// Returns negative if a should sync first, positive if b should sync first
  static int compareForSync(BaseEntity a, BaseEntity b) {
    // Higher priority first
    final priorityDiff = b.syncPriority - a.syncPriority;
    if (priorityDiff != 0) return priorityDiff;
    
    // Earlier created date first (FIFO for same priority)
    return a.createdAt.compareTo(b.createdAt);
  }
}