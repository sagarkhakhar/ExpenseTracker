import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/sync_account.dart';

part 'account_dto.g.dart';

/// DTO for accounts when communicating with Supabase
/// Maps to the "accounts" table schema
@JsonSerializable(explicitToJson: true)
class AccountDto {
  const AccountDto({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.isDeleted,
    this.deviceId,
    this.lastEditor,
  });

  final String id;
  final String name;
  final String type;
  final double balance;
  
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
  factory AccountDto.fromEntity(SyncAccount entity) {
    return AccountDto(
      id: entity.id,
      name: entity.name,
      type: entity.type.name,
      balance: entity.balance,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      version: entity.version,
      isDeleted: entity.isDeleted,
      deviceId: entity.deviceId,
      lastEditor: entity.lastEditor,
    );
  }

  /// Convert to domain entity
  SyncAccount toEntity() {
    return SyncAccount(
      id: id,
      name: name,
      type: AccountType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => AccountType.cash,
      ),
      balance: balance,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      isDeleted: isDeleted,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  /// JSON serialization
  factory AccountDto.fromJson(Map<String, dynamic> json) => 
      _$AccountDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$AccountDtoToJson(this);

  @override
  String toString() => 'AccountDto(id: $id, name: $name, type: $type, balance: $balance)';
}