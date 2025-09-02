// Category domain entity for the future-proof schema
// Represents expense/income categories with proper normalization

import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name; // Internal key (lowercase, no spaces)
  final String displayName; // Human-readable name
  final String? description;
  final String? icon; // Icon identifier for UI
  final String? color; // Hex color code
  final bool isIncomeCategory;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    this.icon,
    this.color,
    required this.isIncomeCategory,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this category with some fields changed
  Category copyWith({
    String? id,
    String? name,
    String? displayName,
    String? description,
    String? icon,
    String? color,
    bool? isIncomeCategory,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isIncomeCategory: isIncomeCategory ?? this.isIncomeCategory,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this category is for expenses
  bool get isExpenseCategory => !isIncomeCategory;

  /// Get appropriate categories for a given expense type
  static List<Category> filterByType(List<Category> categories, bool isIncome) {
    return categories
        .where((cat) => cat.isActive && cat.isIncomeCategory == isIncome)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  List<Object?> get props => [
        id,
        name,
        displayName,
        description,
        icon,
        color,
        isIncomeCategory,
        isActive,
        sortOrder,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'Category(id: $id, name: $name, displayName: $displayName)';
}