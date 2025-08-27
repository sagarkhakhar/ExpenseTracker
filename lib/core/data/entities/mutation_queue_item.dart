import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mutation_queue_item.g.dart';

/// Represents a pending mutation operation in the sync queue
@HiveType(typeId: 101)
@JsonSerializable()
class MutationQueueItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String entityType;

  @HiveField(2)
  final String entityId;

  @HiveField(3)
  final MutationType operation;

  @HiveField(4)
  final Map<String, dynamic> data;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final int retryCount;

  @HiveField(7)
  final int priority;

  @HiveField(8)
  final DateTime? scheduledFor;

  MutationQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.priority = 0,
    this.scheduledFor,
  });

  factory MutationQueueItem.fromJson(Map<String, dynamic> json) =>
      _$MutationQueueItemFromJson(json);

  Map<String, dynamic> toJson() => _$MutationQueueItemToJson(this);

  MutationQueueItem copyWith({
    String? id,
    String? entityType,
    String? entityId,
    MutationType? operation,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    int? priority,
    DateTime? scheduledFor,
  }) {
    return MutationQueueItem(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      priority: priority ?? this.priority,
      scheduledFor: scheduledFor ?? this.scheduledFor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MutationQueueItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          entityType == other.entityType &&
          entityId == other.entityId &&
          operation == other.operation;

  @override
  int get hashCode =>
      id.hashCode ^
      entityType.hashCode ^
      entityId.hashCode ^
      operation.hashCode;

  @override
  String toString() {
    return 'MutationQueueItem{id: $id, entityType: $entityType, entityId: $entityId, operation: $operation, retryCount: $retryCount}';
  }
}

/// Types of mutation operations
@HiveType(typeId: 102)
enum MutationType {
  @HiveField(0)
  create,
  
  @HiveField(1)
  update,
  
  @HiveField(2)
  delete,
}