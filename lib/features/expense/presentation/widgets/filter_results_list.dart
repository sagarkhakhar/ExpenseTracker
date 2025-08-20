import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/expense_list.dart';
import 'package:expense_tracker/features/expense/presentation/views/add_expense_screen.dart';
import 'package:expense_tracker/features/expense/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/features/expense/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/shared/widgets/platform_widgets.dart';

class FilterResultsList extends ConsumerWidget {
  final List<Expense> expenses;

  const FilterResultsList({
    super.key,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No expenses found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results Header
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.filter_list,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${expenses.length} expense${expenses.length == 1 ? '' : 's'} found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                'Total: \$${_calculateTotal().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Expense List
        Expanded(
          child: SingleChildScrollView(
            child: ExpenseList(
              expenses: expenses,
              onExpenseTap: (expense) => _navigateToEditExpense(context, expense),
              onExpenseDelete: (expense) => _deleteExpense(expense, ref),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateTotal() {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Navigates to the edit expense screen with the selected expense.
  /// Handles the navigation logic for editing expenses from filtered results.
  void _navigateToEditExpense(BuildContext context, Expense expense) {
    if (PlatformWidgets.isIOS) {
      // iOS-style navigation with slide transition
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => AddExpenseScreen(expense: expense),
        ),
      );
    } else {
      // Android-style navigation with default transition
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(expense: expense),
        ),
      );
    }
  }

  /// Deletes an expense and refreshes the filtered results.
  /// Handles the deletion process for filtered expense lists.
  void _deleteExpense(Expense expense, WidgetRef ref) async {
    try {
      // Delete from the main expense provider
      await ref.read(expenseNotifierProvider.notifier).deleteExpense(expense.id);
      
      // Invalidate and refresh the filtered results provider to get updated data
      ref.invalidate(filteredExpensesProvider);
      
      // Re-apply current filters if they are active
      final currentFilters = ref.read(filterCriteriaProvider);
      if (currentFilters.isActive) {
        // Small delay to ensure state has propagated
        Future.microtask(() {
          ref.read(filteredExpensesProvider.notifier).applyFilters(currentFilters);
        });
      }
      
      // Show success feedback to the user
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('Expense "${expense.title}" deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      // Show error feedback to the user
      if (ref.context.mounted) {
        ScaffoldMessenger.of(ref.context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete expense: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
