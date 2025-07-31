// This file defines the ExpenseModel, which is the data-layer representation of an Expense.
// It is used for local storage (Hive) and for mapping to/from the domain entity.

import 'package:hive/hive.dart';
import '../../domain/entities/expense.dart';

part 'expense_model.g.dart';

/// Data model for storing expenses in Hive.
/// This class is used only in the data layer and is mapped to/from the domain entity (Expense).
@HiveType(typeId: 4)
class ExpenseModel extends HiveObject {
  // All fields must match those in the Expense entity for easy mapping.
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final double amount;
  @HiveField(4)
  final String category;
  @HiveField(5)
  final ExpenseType type;
  @HiveField(6)
  final DateTime date;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final DateTime updatedAt;
  @HiveField(9)
  final Map<String, dynamic>? metadata;
  @HiveField(10)
  final bool isRecurring;
  @HiveField(11)
  final String? recurringFrequency;
  @HiveField(12)
  final DateTime? nextOccurrence;
  @HiveField(13)
  final DateTime? endDate;

  /// Constructor for ExpenseModel. All fields are required except metadata and recurring fields.
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
  });

  /// Convert a domain entity (Expense) to a data model (ExpenseModel).
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

  /// Convert this data model to a domain entity (Expense).
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
