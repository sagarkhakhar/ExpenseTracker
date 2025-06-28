import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/expense.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  @JsonKey(fromJson: _categoryFromJson, toJson: _categoryToJson)
  final ExpenseCategory category;

  @HiveField(5)
  @JsonKey(fromJson: _typeFromJson, toJson: _typeToJson)
  final ExpenseType type;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final Map<String, dynamic>? metadata;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);

  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      title: expense.title,
      description: expense.description,
      amount: expense.amount,
      category: expense.category,
      type: expense.type,
      date: expense.date,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
      metadata: expense.metadata,
    );
  }

  Expense toEntity() {
    return Expense(
      id: id,
      title: title,
      description: description,
      amount: amount,
      category: category,
      type: type,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      metadata: metadata,
    );
  }

  static ExpenseCategory _categoryFromJson(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => ExpenseCategory.other,
    );
  }

  static String _categoryToJson(ExpenseCategory category) {
    return category.toString().split('.').last;
  }

  static ExpenseType _typeFromJson(String value) {
    return ExpenseType.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => ExpenseType.expense,
    );
  }

  static String _typeToJson(ExpenseType type) {
    return type.toString().split('.').last;
  }
}
