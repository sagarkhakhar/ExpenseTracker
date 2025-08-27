import 'package:hive/hive.dart';
import '../base_entity.dart';

part 'sync_category.g.dart';

/// Sync-enabled Category entity with BaseEntity fields
@HiveType(typeId: 21)
class SyncCategory extends BaseEntity {
  /// Business logic fields
  @HiveField(0)
  final String name;
  
  @HiveField(1)
  final String? icon; // Emoji or icon identifier
  
  @HiveField(2)
  final String color; // Hex color code
  
  @HiveField(3)
  final String? description;
  
  @HiveField(4)
  final bool isDefault; // System-provided categories

  // BaseEntity fields - need HiveField annotations for Hive serialization
  @override
  @HiveField(10)
  final String id;
  
  @override
  @HiveField(11)
  final DateTime createdAt;
  
  @override
  @HiveField(12)
  final DateTime updatedAt;
  
  @override
  @HiveField(13)
  final int version;
  
  @override
  @HiveField(14)
  final bool isDeleted;
  
  @override
  @HiveField(15)
  final String? deviceId;
  
  @override
  @HiveField(16)
  final String? lastEditor;

  const SyncCategory({
    // Business fields
    required this.name,
    this.icon,
    required this.color,
    this.description,
    this.isDefault = false,
    // BaseEntity fields
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.isDeleted = false,
    this.deviceId,
    this.lastEditor,
  }) : super(
         id: id,
         createdAt: createdAt,
         updatedAt: updatedAt,
         version: version,
         isDeleted: isDeleted,
         deviceId: deviceId,
         lastEditor: lastEditor,
       );

  @override
  List<Object?> get props => [
        ...super.props,
        name,
        icon,
        color,
        description,
        isDefault,
      ];

  @override
  SyncCategory copyWithSyncMetadata({
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
    String? lastEditor,
  }) {
    return copyWith(
      updatedAt: updatedAt,
      version: version,
      isDeleted: isDeleted,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  SyncCategory copyWith({
    String? name,
    String? icon,
    String? color,
    String? description,
    bool? isDefault,
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
    String? deviceId,
    String? lastEditor,
  }) {
    return SyncCategory(
      // Business fields
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      // BaseEntity fields
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
      deviceId: deviceId ?? this.deviceId,
      lastEditor: lastEditor ?? this.lastEditor,
    );
  }

  /// Create new category with sync metadata
  factory SyncCategory.create({
    required String name,
    required String color,
    required String deviceId,
    required String lastEditor,
    String? icon,
    String? description,
    bool isDefault = false,
  }) {
    final now = EntityUtils.now();
    return SyncCategory(
      name: name,
      icon: icon,
      color: color,
      description: description,
      isDefault: isDefault,
      id: EntityUtils.generateId(),
      createdAt: now,
      updatedAt: now,
      version: 1,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  @override
  int get syncPriority => isDefault ? 2 : 1; // Default categories sync first
}