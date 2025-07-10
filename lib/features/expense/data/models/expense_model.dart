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
  final String category; // Now a string

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
  // Recurring fields
  @HiveField(10)
  final bool isRecurring;
  @HiveField(11)
  final String? recurringFrequency;
  @HiveField(12)
  final DateTime? nextOccurrence;
  @HiveField(13)
  final DateTime? endDate;

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
    this.isRecurring = false,
    this.recurringFrequency,
    this.nextOccurrence,
    this.endDate,
  })  : assert(id.trim().isNotEmpty, 'ID cannot be empty'),
        assert(
            title.trim().isNotEmpty, 'Title cannot be empty'),
        assert(category.trim().isNotEmpty,
            'Category cannot be empty'),
        assert(!amount.isNaN && !amount.isInfinite && amount > 0,
            'Amount must be positive and finite');

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
      isRecurring: expense.isRecurring,
      recurringFrequency: expense.recurringFrequency,
      nextOccurrence: expense.nextOccurrence,
      endDate: expense.endDate,
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
      isRecurring: isRecurring,
      recurringFrequency: recurringFrequency,
      nextOccurrence: nextOccurrence,
      endDate: endDate,
    );
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
