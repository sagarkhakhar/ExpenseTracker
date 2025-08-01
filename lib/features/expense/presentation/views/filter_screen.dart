import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/expense/domain/entities/filter_criteria.dart'
    as filter_entities;
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/filter_chip.dart'
    as custom_filter_chip;
import 'package:expense_tracker/features/expense/presentation/widgets/search_bar.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/filter_results_list.dart';

class FilterScreen extends ConsumerStatefulWidget {
  const FilterScreen({super.key});

  @override
  ConsumerState<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends ConsumerState<FilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  List<String> _selectedCategories = [];
  filter_entities.Range? _selectedAmountRange;
  ExpenseType? _selectedExpenseType;

  @override
  void initState() {
    super.initState();
    _loadCurrentFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCurrentFilters() {
    final currentFilters = ref.read(filterCriteriaProvider);
    _searchController.text = currentFilters.searchQuery ?? '';
    _selectedDateRange = currentFilters.dateRange != null
        ? DateTimeRange(
            start: currentFilters.dateRange!.start,
            end: currentFilters.dateRange!.end,
          )
        : null;
    _selectedCategories = currentFilters.categories ?? [];
    _selectedAmountRange = currentFilters.amountRange;
    _selectedExpenseType = currentFilters.expenseType;
  }

  void _applyFilters() {
    final filterCriteria = filter_entities.FilterCriteria(
      dateRange: _selectedDateRange != null
          ? filter_entities.DateTimeRange(
              start: _selectedDateRange!.start,
              end: _selectedDateRange!.end,
            )
          : null,
      categories: _selectedCategories.isEmpty ? null : _selectedCategories,
      amountRange: _selectedAmountRange,
      expenseType: _selectedExpenseType,
      searchQuery: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      isActive: true,
    );

    ref
        .read(filterCriteriaProvider.notifier)
        .updateFilterCriteria(filterCriteria);
    ref.read(filteredExpensesProvider.notifier).applyFilters(filterCriteria);
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedDateRange = null;
      _selectedCategories.clear();
      _selectedAmountRange = null;
      _selectedExpenseType = null;
    });

    final clearCriteria = const filter_entities.FilterCriteria(isActive: false);
    ref
        .read(filterCriteriaProvider.notifier)
        .updateFilterCriteria(clearCriteria);
    ref.read(filteredExpensesProvider.notifier).clearFilters();
  }

  void _removeCategory(String category) {
    setState(() {
      _selectedCategories.remove(category);
    });
  }

  void _removeDateRange() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  void _removeAmountRange() {
    setState(() {
      _selectedAmountRange = null;
    });
  }

  void _removeExpenseType() {
    setState(() {
      _selectedExpenseType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Expenses'),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear All'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                SearchBarWidget(
                  controller: _searchController,
                  onSearchChanged: (query) {
                    // Real-time search updates
                    ref
                        .read(filteredExpensesProvider.notifier)
                        .searchExpenses(query);
                  },
                ),
                const SizedBox(height: 16),

                // Date Range Filter
                _buildDateRangeFilter(),
                const SizedBox(height: 16),

                // Category Filter
                _buildCategoryFilter(),
                const SizedBox(height: 16),

                // Amount Range Filter
                _buildAmountRangeFilter(),
                const SizedBox(height: 16),

                // Expense Type Filter
                _buildExpenseTypeFilter(),
                const SizedBox(height: 16),

                // Active Filters Display
                _buildActiveFilters(),
                const SizedBox(height: 16),

                // Apply Filters Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Filter Results
        Expanded(
          flex: 2,
          child: Consumer(
            builder: (context, ref, child) {
              final filteredExpensesAsync = ref.watch(filteredExpensesProvider);

              return filteredExpensesAsync.when(
                data: (expenses) => FilterResultsList(expenses: expenses),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error: ${error.toString()}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDateRange != null
                        ? '${_selectedDateRange!.start.toString().split(' ')[0]} - ${_selectedDateRange!.end.toString().split(' ')[0]}'
                        : 'Select date range',
                    style: TextStyle(
                      color: _selectedDateRange != null ? null : Colors.grey,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange,
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDateRange = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer(
      builder: (context, ref, child) {
        final categoriesAsync = ref.watch(availableCategoriesProvider);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  data: (categories) => Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: categories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error: ${error.toString()}'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountRangeFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Amount Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Min Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final min = double.tryParse(value);
                      setState(() {
                        _selectedAmountRange = filter_entities.Range(
                          min: min,
                          max: _selectedAmountRange?.max,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Max Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final max = double.tryParse(value);
                      setState(() {
                        _selectedAmountRange = filter_entities.Range(
                          min: _selectedAmountRange?.min,
                          max: max,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTypeFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: ExpenseType.values.map((type) {
                final isSelected = _selectedExpenseType == type;
                return FilterChip(
                  label: Text(type.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedExpenseType = selected ? type : null;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final hasActiveFilters = _selectedDateRange != null ||
        _selectedCategories.isNotEmpty ||
        _selectedAmountRange != null ||
        _selectedExpenseType != null ||
        _searchController.text.isNotEmpty;

    if (!hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                if (_selectedDateRange != null)
                  custom_filter_chip.FilterChip(
                    label: Text(
                      'Date: ${_selectedDateRange!.start.toString().split(' ')[0]} - ${_selectedDateRange!.end.toString().split(' ')[0]}',
                    ),
                    onDeleted: _removeDateRange,
                  ),
                ..._selectedCategories
                    .map((category) => custom_filter_chip.FilterChip(
                          label: Text('Category: $category'),
                          onDeleted: () => _removeCategory(category),
                        )),
                if (_selectedAmountRange != null)
                  custom_filter_chip.FilterChip(
                    label: Text(
                      'Amount: \$${_selectedAmountRange!.min?.toStringAsFixed(2) ?? '0'} - \$${_selectedAmountRange!.max?.toStringAsFixed(2) ?? '∞'}',
                    ),
                    onDeleted: _removeAmountRange,
                  ),
                if (_selectedExpenseType != null)
                  custom_filter_chip.FilterChip(
                    label: Text('Type: ${_selectedExpenseType!.name}'),
                    onDeleted: _removeExpenseType,
                  ),
                if (_searchController.text.isNotEmpty)
                  custom_filter_chip.FilterChip(
                    label: Text('Search: "${_searchController.text}"'),
                    onDeleted: () => _searchController.clear(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
