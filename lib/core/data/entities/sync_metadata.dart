import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sync_metadata.g.dart';

/// Sync metadata for tracking synchronization state
@HiveType(typeId: 100)
@JsonSerializable()
class SyncMetadata extends HiveObject {
  @HiveField(0)
  final String entityType;

  @HiveField(1)
  final DateTime? lastPullCursor;

  @HiveField(2)
  final DateTime? lastSuccessfulSync;

  @HiveField(3)
  final int syncVersion;

  @HiveField(4)
  final Map<String, dynamic> metadata;

  SyncMetadata({
    required this.entityType,
    this.lastPullCursor,
    this.lastSuccessfulSync,
    this.syncVersion = 0,
    this.metadata = const {},
  });

  factory SyncMetadata.fromJson(Map<String, dynamic> json) =>
      _$SyncMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$SyncMetadataToJson(this);

  SyncMetadata copyWith({
    String? entityType,
    DateTime? lastPullCursor,
    DateTime? lastSuccessfulSync,
    int? syncVersion,
    Map<String, dynamic>? metadata,
  }) {
    return SyncMetadata(
      entityType: entityType ?? this.entityType,
      lastPullCursor: lastPullCursor ?? this.lastPullCursor,
      lastSuccessfulSync: lastSuccessfulSync ?? this.lastSuccessfulSync,
      syncVersion: syncVersion ?? this.syncVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMetadata &&
          runtimeType == other.runtimeType &&
          entityType == other.entityType &&
          lastPullCursor == other.lastPullCursor &&
          lastSuccessfulSync == other.lastSuccessfulSync &&
          syncVersion == other.syncVersion;

  @override
  int get hashCode =>
      entityType.hashCode ^
      lastPullCursor.hashCode ^
      lastSuccessfulSync.hashCode ^
      syncVersion.hashCode;

  @override
  String toString() {
    return 'SyncMetadata{entityType: $entityType, lastPullCursor: $lastPullCursor, lastSuccessfulSync: $lastSuccessfulSync, syncVersion: $syncVersion}';
  }
}