import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/sync_expense.dart';
import '../../../features/expense/domain/entities/expense.dart';

part 'expense_dto.g.dart';

/// DTO for expenses when communicating with Supabase
/// Maps to the "expenses" table schema
@JsonSerializable(explicitToJson: true)
class ExpenseDto {
  const ExpenseDto({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.categoryId,
    this.accountId,
    this.description,
    this.receiptPhotoId,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.isDeleted,
    this.deviceId,
    this.lastEditor,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  
  @JsonKey(name: 'category_id')
  final String? categoryId;
  
  @JsonKey(name: 'account_id')
  final String? accountId;
  
  final String? description;
  
  @JsonKey(name: 'receipt_photo_id')
  final String? receiptPhotoId;
  
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
  factory ExpenseDto.fromEntity(SyncExpense entity) {
    return ExpenseDto(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      date: entity.date,
      categoryId: entity.categoryId,
      accountId: entity.accountId,
      description: entity.description,
      receiptPhotoId: entity.receiptPhotoId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      version: entity.version,
      isDeleted: entity.isDeleted,
      deviceId: entity.deviceId,
      lastEditor: entity.lastEditor,
    );
  }

  /// Convert to domain entity
  SyncExpense toEntity() {
    // Determine expense type based on amount (positive = income, negative = expense)
    final expenseType = amount >= 0 ? ExpenseType.income : ExpenseType.expense;
    
    return SyncExpense(
      title: title,
      description: description ?? '',
      amount: amount.abs(),
      category: '', // Will be populated by category lookup
      type: expenseType,
      date: date,
      receiptPhotoId: receiptPhotoId,
      accountId: accountId,
      categoryId: categoryId,
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      isDeleted: isDeleted,
      deviceId: deviceId,
      lastEditor: lastEditor,
    );
  }

  /// JSON serialization
  factory ExpenseDto.fromJson(Map<String, dynamic> json) => 
      _$ExpenseDtoFromJson(json);
  
  Map<String, dynamic> toJson() => _$ExpenseDtoToJson(this);

  @override
  String toString() => 'ExpenseDto(id: $id, title: $title, amount: $amount)';
}