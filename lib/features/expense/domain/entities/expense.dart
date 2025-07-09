import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'expense.g.dart';

// Remove ExpenseCategory enum and its HiveType

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
  final String category; // Now a string
  final ExpenseType type;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  // Recurring fields
  final bool isRecurring;
  final String?
      recurringFrequency; // e.g., 'daily', 'weekly', 'monthly', 'custom'
  final DateTime? nextOccurrence;
  final DateTime? endDate;

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
    this.isRecurring = false,
    this.recurringFrequency,
    this.nextOccurrence,
    this.endDate,
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
        isRecurring,
        recurringFrequency,
        nextOccurrence,
        endDate,
      ];

  Expense copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    String? category,
    ExpenseType? type,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    bool? isRecurring,
    String? recurringFrequency,
    DateTime? nextOccurrence,
    DateTime? endDate,
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
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      endDate: endDate ?? this.endDate,
    );
  }

  bool get isExpense => type == ExpenseType.expense;
  bool get isIncome => type == ExpenseType.income;
  double get signedAmount => isExpense ? -amount : amount;
}
