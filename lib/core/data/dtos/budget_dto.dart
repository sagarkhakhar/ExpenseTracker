import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/sync_budget.dart';

part 'budget_dto.g.dart';

/// DTO for budgets when communicating with Supabase
/// Maps to the "budgets" table schema
@JsonSerializable(explicitToJson: true)
class BudgetDto {
  const BudgetDto({
    required this.id,
    required this.name,
    required this.amount,
    this.categoryId,
    required this.period,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.isDeleted,
    this.deviceId,
    this.lastEditor,
  });

  final String id;
  final String name;
  final double amount;
  
  @JsonKey(name: 'category_id')
  final String? categoryId;
  
  final String period;
  
  @JsonKey(name: 'start_date')
  final DateTime? startDate;
  
  @JsonKey(name: 'end_date')
  final DateTime? endDate;
  
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
  factory BudgetDto.fromEntity(SyncBudget entity) {
    return BudgetDto(
      id: entity.id,
      name: entity.name,
      amount: entity.amount,
      categoryId: entity.categoryId,
      period: entity.period.name,
      startDate: entity.startDate,
      endDate: entity.endDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      version: entity.version,
      isDeleted: entity.isDeleted,
      deviceId: entity.deviceId,
      lastEditor: entity.lastEditor,
    );
  }

  /// Convert to domain entity
  SyncBudget toEntity() {
    return SyncBudget(
      id: id,
      name: name,
      amount: amount,
      categoryId: categoryId,
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == period,
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      isDeleted: isDeleted,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  /// JSON serialization
  factory BudgetDto.fromJson(Map<String, dynamic> json) => 
      _$BudgetDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$BudgetDtoToJson(this);

  @override
  String toString() => 'BudgetDto(id: $id, name: $name, amount: $amount)';
}