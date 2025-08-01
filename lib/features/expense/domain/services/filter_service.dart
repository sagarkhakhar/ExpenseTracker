// This file defines the FilterService for the domain layer.
// It encapsulates business logic for expense filtering and search operations.

import '../entities/expense.dart';
import '../entities/filter_criteria.dart';
import '../entities/search_result.dart';

/// Service for expense filtering and search business logic.
/// This encapsulates complex filtering operations and search processing.
class FilterService {
  /// Apply date range filter to a list of expenses.
  /// Returns filtered expenses that fall within the specified date range.
  List<Expense> applyDateRangeFilter(
    List<Expense> expenses,
    DateTimeRange dateRange,
  ) {
    return expenses.where((expense) {
      return expense.date
              .isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(dateRange.end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Apply category filter to a list of expenses.
  /// Returns filtered expenses that match any of the specified categories.
  List<Expense> applyCategoryFilter(
    List<Expense> expenses,
    List<String> categories,
  ) {
    if (categories.isEmpty) return expenses;

    return expenses.where((expense) {
      return categories.contains(expense.category);
    }).toList();
  }

  /// Apply amount range filter to a list of expenses.
  /// Returns filtered expenses that fall within the specified amount range.
  List<Expense> applyAmountRangeFilter(
    List<Expense> expenses,
    Range amountRange,
  ) {
    return expenses.where((expense) {
      final amount = expense.amount;
      final min = amountRange.min;
      final max = amountRange.max;

      if (min != null && amount < min) return false;
      if (max != null && amount > max) return false;

      return true;
    }).toList();
  }

  /// Apply expense type filter to a list of expenses.
  /// Returns filtered expenses that match the specified expense type.
  List<Expense> applyExpenseTypeFilter(
    List<Expense> expenses,
    ExpenseType expenseType,
  ) {
    return expenses.where((expense) {
      return expense.type == expenseType;
    }).toList();
  }

  /// Apply text search filter to a list of expenses.
  /// Returns filtered expenses that match the search query in title or description.
  List<Expense> applyTextSearchFilter(
    List<Expense> expenses,
    String searchQuery,
  ) {
    if (searchQuery.trim().isEmpty) return expenses;

    final query = searchQuery.toLowerCase().trim();

    return expenses.where((expense) {
      final title = expense.title.toLowerCase();
      final description = expense.description.toLowerCase();

      return title.contains(query) || description.contains(query);
    }).toList();
  }

  /// Apply all filters to a list of expenses.
  /// Returns filtered expenses that match all specified criteria.
  List<Expense> applyFilters(
    List<Expense> expenses,
    FilterCriteria filterCriteria,
  ) {
    if (!filterCriteria.hasActiveFilters) return expenses;

    var filteredExpenses = List<Expense>.from(expenses);

    // Apply date range filter
    if (filterCriteria.dateRange != null) {
      filteredExpenses = applyDateRangeFilter(
        filteredExpenses,
        filterCriteria.dateRange!,
      );
    }

    // Apply category filter
    if (filterCriteria.categories != null &&
        filterCriteria.categories!.isNotEmpty) {
      filteredExpenses = applyCategoryFilter(
        filteredExpenses,
        filterCriteria.categories!,
      );
    }

    // Apply amount range filter
    if (filterCriteria.amountRange != null) {
      filteredExpenses = applyAmountRangeFilter(
        filteredExpenses,
        filterCriteria.amountRange!,
      );
    }

    // Apply expense type filter
    if (filterCriteria.expenseType != null) {
      filteredExpenses = applyExpenseTypeFilter(
        filteredExpenses,
        filterCriteria.expenseType!,
      );
    }

    // Apply text search filter
    if (filterCriteria.searchQuery != null &&
        filterCriteria.searchQuery!.isNotEmpty) {
      filteredExpenses = applyTextSearchFilter(
        filteredExpenses,
        filterCriteria.searchQuery!,
      );
    }

    return filteredExpenses;
  }

  /// Create a SearchResult from filtered expenses.
  /// Returns a SearchResult object with the filtered data and metadata.
  SearchResult createSearchResult(
    List<Expense> originalExpenses,
    List<Expense> filteredExpenses,
    FilterCriteria filterCriteria,
    String? searchQuery,
  ) {
    return SearchResult(
      expenses: filteredExpenses,
      totalCount: filteredExpenses.length,
      filterCriteria: filterCriteria,
      searchQuery: searchQuery,
    );
  }

  /// Get available categories from a list of expenses.
  /// Returns a sorted list of unique categories.
  List<String> getAvailableCategories(List<Expense> expenses) {
    final categories = expenses.map((expense) => expense.category).toSet();
    return categories.toList()..sort();
  }

  /// Get available expense types from a list of expenses.
  /// Returns a list of unique expense types.
  List<ExpenseType> getAvailableExpenseTypes(List<Expense> expenses) {
    final types = expenses.map((expense) => expense.type).toSet();
    return types.toList();
  }

  /// Get amount range from a list of expenses.
  /// Returns the minimum and maximum amounts.
  Range getAmountRange(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return const Range();
    }

    final amounts = expenses.map((expense) => expense.amount).toList();
    final min = amounts.reduce((a, b) => a < b ? a : b);
    final max = amounts.reduce((a, b) => a > b ? a : b);

    return Range(min: min, max: max);
  }

  /// Get date range from a list of expenses.
  /// Returns the earliest and latest dates.
  DateTimeRange? getDateRange(List<Expense> expenses) {
    if (expenses.isEmpty) return null;

    final dates = expenses.map((expense) => expense.date).toList();
    final start = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final end = dates.reduce((a, b) => a.isAfter(b) ? a : b);

    return DateTimeRange(start: start, end: end);
  }

  /// Validate filter criteria.
  /// Returns true if the filter criteria is valid.
  bool isValidFilterCriteria(FilterCriteria filterCriteria) {
    // Validate date range
    if (filterCriteria.dateRange != null) {
      if (filterCriteria.dateRange!.start
          .isAfter(filterCriteria.dateRange!.end)) {
        return false;
      }
    }

    // Validate amount range
    if (filterCriteria.amountRange != null) {
      final min = filterCriteria.amountRange!.min;
      final max = filterCriteria.amountRange!.max;

      if (min != null && max != null && min > max) {
        return false;
      }
    }

    // Validate search query
    if (filterCriteria.searchQuery != null &&
        filterCriteria.searchQuery!.trim().isEmpty) {
      return false;
    }

    return true;
  }

  /// Get filter summary for display purposes.
  /// Returns a human-readable summary of applied filters.
  String getFilterSummary(FilterCriteria filterCriteria) {
    final parts = <String>[];

    if (filterCriteria.dateRange != null) {
      parts.add(
          'Date: ${filterCriteria.dateRange!.start.toString().substring(0, 10)} - ${filterCriteria.dateRange!.end.toString().substring(0, 10)}');
    }

    if (filterCriteria.categories != null &&
        filterCriteria.categories!.isNotEmpty) {
      parts.add('Categories: ${filterCriteria.categories!.join(', ')}');
    }

    if (filterCriteria.amountRange != null) {
      final min = filterCriteria.amountRange!.min;
      final max = filterCriteria.amountRange!.max;
      if (min != null || max != null) {
        final range = '${min ?? '0'} - ${max ?? '∞'}';
        parts.add('Amount: \$$range');
      }
    }

    if (filterCriteria.expenseType != null) {
      parts.add('Type: ${filterCriteria.expenseType!.name}');
    }

    if (filterCriteria.searchQuery != null &&
        filterCriteria.searchQuery!.isNotEmpty) {
      parts.add('Search: "${filterCriteria.searchQuery}"');
    }

    return parts.isEmpty ? 'No filters applied' : parts.join(', ');
  }
}
