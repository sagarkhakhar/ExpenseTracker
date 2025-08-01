// This file defines the SearchResult entity, which represents the results of filtered expense queries.
// It is used throughout the domain, data, and presentation layers for displaying filtered results.

import 'package:equatable/equatable.dart';
import 'expense.dart';
import 'filter_criteria.dart';

/// The SearchResult entity represents the results of a filtered expense query.
/// It is immutable and uses Equatable for value equality.
class SearchResult extends Equatable {
  // Filtered expense results
  final List<Expense> expenses;
  // Total number of matching expenses
  final int totalCount;
  // Applied filter criteria
  final FilterCriteria filterCriteria;
  // Applied search query
  final String? searchQuery;

  /// Constructor for SearchResult. All fields are required.
  const SearchResult({
    required this.expenses,
    required this.totalCount,
    required this.filterCriteria,
    this.searchQuery,
  });

  /// Returns true if there are any results
  bool get hasResults => expenses.isNotEmpty;

  /// Returns true if the search was performed with active filters
  bool get wasFiltered => filterCriteria.hasActiveFilters;

  /// Returns a copy of this search result with the given fields replaced.
  SearchResult copyWith({
    List<Expense>? expenses,
    int? totalCount,
    FilterCriteria? filterCriteria,
    String? searchQuery,
  }) {
    return SearchResult(
      expenses: expenses ?? this.expenses,
      totalCount: totalCount ?? this.totalCount,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Equatable: defines which fields are used for value equality.
  @override
  List<Object?> get props => [
        expenses,
        totalCount,
        filterCriteria,
        searchQuery,
      ];

  @override
  String toString() {
    return 'SearchResult(expenses: ${expenses.length}, totalCount: $totalCount, filterCriteria: $filterCriteria, searchQuery: $searchQuery)';
  }
}
