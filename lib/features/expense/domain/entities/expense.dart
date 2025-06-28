import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 1)
enum ExpenseCategory {
  @HiveField(0)
  food,
  @HiveField(1)
  transportation,
  @HiveField(2)
  entertainment,
  @HiveField(3)
  shopping,
  @HiveField(4)
  health,
  @HiveField(5)
  education,
  @HiveField(6)
  utilities,
  @HiveField(7)
  rent,
  @HiveField(8)
  insurance,
  @HiveField(9)
  other,
}

@HiveType(typeId: 2)
enum ExpenseType {
  @HiveField(0)
  expense,
  @HiveField(1)
  income,
}

class Expense extends Equatable {
  final String id;
  final String title;
  final String description;
  final double amount;
  final ExpenseCategory category;
  final ExpenseType type;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  const Expense({
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

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        amount,
        category,
        type,
        date,
        createdAt,
        updatedAt,
        metadata,
      ];

  Expense copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    ExpenseCategory? category,
    ExpenseType? type,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpense => type == ExpenseType.expense;
  bool get isIncome => type == ExpenseType.income;
  double get signedAmount => isExpense ? -amount : amount;
}
