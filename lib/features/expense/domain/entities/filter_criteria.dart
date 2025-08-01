// This file defines the FilterCriteria entity, which represents filter parameters for expense queries.
// It is used throughout the domain, data, and presentation layers for advanced filtering functionality.

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'expense.dart';

part 'filter_criteria.g.dart';

/// The FilterCriteria entity represents the parameters used to filter expense data.
/// It is immutable and uses Equatable for value equality.
/// It is also annotated for Hive serialization for state persistence.
@HiveType(typeId: 6)
class FilterCriteria extends Equatable {
  // Optional date range filter
  @HiveField(0)
  final DateTimeRange? dateRange;
  // Optional category filter list
  @HiveField(1)
  final List<String>? categories;
  // Optional amount range filter
  @HiveField(2)
  final Range? amountRange;
  // Optional expense type filter (income/expense)
  @HiveField(3)
  final ExpenseType? expenseType;
  // Optional text search query
  @HiveField(4)
  final String? searchQuery;
  // Whether the filter is currently active
  @HiveField(5)
  final bool isActive;

  /// Constructor for FilterCriteria. All fields are optional except isActive.
  const FilterCriteria({
    this.dateRange,
    this.categories,
    this.amountRange,
    this.expenseType,
    this.searchQuery,
    this.isActive = false,
  });

  /// Returns true if any filter criteria are set
  bool get hasActiveFilters =>
      dateRange != null ||
      (categories != null && categories!.isNotEmpty) ||
      amountRange != null ||
      expenseType != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  /// Returns a copy of this filter criteria with the given fields replaced.
  FilterCriteria copyWith({
    DateTimeRange? dateRange,
    List<String>? categories,
    Range? amountRange,
    ExpenseType? expenseType,
    String? searchQuery,
    bool? isActive,
  }) {
    return FilterCriteria(
      dateRange: dateRange ?? this.dateRange,
      categories: categories ?? this.categories,
      amountRange: amountRange ?? this.amountRange,
      expenseType: expenseType ?? this.expenseType,
      searchQuery: searchQuery ?? this.searchQuery,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Returns a copy with all filters cleared
  FilterCriteria clear() {
    return const FilterCriteria(isActive: false);
  }

  /// Equatable: defines which fields are used for value equality.
  @override
  List<Object?> get props => [
        dateRange,
        categories,
        amountRange,
        expenseType,
        searchQuery,
        isActive,
      ];

  @override
  String toString() {
    return 'FilterCriteria(dateRange: $dateRange, categories: $categories, amountRange: $amountRange, expenseType: $expenseType, searchQuery: $searchQuery, isActive: $isActive)';
  }
}

/// Simple range class for amount filtering
@HiveType(typeId: 7)
class Range extends Equatable {
  @HiveField(0)
  final double? min;
  @HiveField(1)
  final double? max;

  const Range({this.min, this.max});

  @override
  List<Object?> get props => [min, max];

  @override
  String toString() => 'Range(min: $min, max: $max)';
}

/// DateTimeRange class for date filtering
@HiveType(typeId: 8)
class DateTimeRange extends Equatable {
  @HiveField(0)
  final DateTime start;
  @HiveField(1)
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];

  @override
  String toString() => 'DateTimeRange(start: $start, end: $end)';
}
