// This file defines the Expense entity, which represents a single expense or income record in the app.
// It is used throughout the domain, data, and presentation layers.

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'expense.g.dart';

// Enum for the type of transaction: expense or income.
@HiveType(typeId: 2)
enum ExpenseType {
  @HiveField(0)
  expense, // Money spent
  @HiveField(1)
  income, // Money received
}

/// The Expense entity is the core business object for this app.
/// It is immutable and uses Equatable for value equality.
/// It is also annotated for Hive (local database) serialization.
@HiveType(typeId: 3)
class Expense extends Equatable {
  // Unique identifier for the expense (UUID string)
  @HiveField(0)
  final String id;
  // Short title or description (e.g., 'Lunch')
  @HiveField(1)
  final String title;
  // Optional longer description
  @HiveField(2)
  final String description;
  // Amount of money (must be positive)
  @HiveField(3)
  final double amount;
  // Category (e.g., 'food', 'travel')
  @HiveField(4)
  final String category;
  // Type: expense or income
  @HiveField(5)
  final ExpenseType type;
  // Date of the transaction
  @HiveField(6)
  final DateTime date;
  // When this record was created
  @HiveField(7)
  final DateTime createdAt;
  // When this record was last updated
  @HiveField(8)
  final DateTime updatedAt;
  // Optional metadata for extensibility (e.g., tags, location)
  @HiveField(9)
  final Map<String, dynamic>? metadata;
  // Recurring transaction fields
  @HiveField(10)
  final bool isRecurring;
  @HiveField(11)
  final String? recurringFrequency; // e.g., 'monthly'
  @HiveField(12)
  final DateTime? nextOccurrence;
  @HiveField(13)
  final DateTime? endDate;

  /// Constructor for Expense. All fields are required except metadata and recurring fields.
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

  /// Equatable: defines which fields are used for value equality.
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

  /// Returns a copy of this expense with the given fields replaced.
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

  /// Utility: true if this is an expense (not income)
  bool get isExpense => type == ExpenseType.expense;

  /// Utility: true if this is an income
  bool get isIncome => type == ExpenseType.income;

  /// Utility: returns the signed amount (negative for expenses, positive for income)
  double get signedAmount => isExpense ? -amount : amount;
}
