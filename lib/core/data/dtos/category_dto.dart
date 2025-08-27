import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/sync_category.dart';

part 'category_dto.g.dart';

/// DTO for categories when communicating with Supabase
/// Maps to the "categories" table schema
@JsonSerializable(explicitToJson: true)
class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.name,
    this.icon,
    required this.color,
    this.description,
    this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.isDeleted,
    this.deviceId,
    this.lastEditor,
  });

  final String id;
  final String name;
  final String? icon;
  final String color;
  final String? description;
  
  @JsonKey(name: 'is_default')
  final bool? isDefault;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  final int version;
  
  @JsonKey(name: 'is_deleted')
  final bool isDeleted;
  
  @JsonKey(name: 'device_id')
  final String? deviceId;
  
  @JsonKey(name: 'last_editor')
  final String? lastEditor;

  /// Create DTO from domain entity
  factory CategoryDto.fromEntity(SyncCategory entity) {
    return CategoryDto(
      id: entity.id,
      name: entity.name,
      icon: entity.icon,
      color: entity.color,
      description: entity.description,
      isDefault: entity.isDefault,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      version: entity.version,
      isDeleted: entity.isDeleted,
      deviceId: entity.deviceId,
      lastEditor: entity.lastEditor,
    );
  }

  /// Convert to domain entity
  SyncCategory toEntity() {
    return SyncCategory(
      id: id,
      name: name,
      icon: icon,
      color: color,
      description: description,
      isDefault: isDefault ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      isDeleted: isDeleted,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  /// JSON serialization
  factory CategoryDto.fromJson(Map<String, dynamic> json) => 
      _$CategoryDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$CategoryDtoToJson(this);

  @override
  String toString() => 'CategoryDto(id: $id, name: $name, color: $color)';
}