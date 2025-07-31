// This file defines the ExpenseList widget, which displays a scrollable list of expenses.
// It handles expense item rendering, user interactions, and empty state management.
// This demonstrates proper list widget implementation and user experience patterns.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../shared/widgets/platform_widgets.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// A scrollable list widget that displays expense items with interactive features.
/// This widget handles expense rendering, user interactions, and empty states.
class ExpenseList extends ConsumerWidget {
  final List<Expense> expenses;
  final bool showDeleteButton;
  final Function(Expense)? onExpenseTap;
  final Function(Expense)? onExpenseDelete;

  const ExpenseList({
    super.key,
    required this.expenses,
    this.showDeleteButton = true,
    this.onExpenseTap,
    this.onExpenseDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;

    // Handle empty state when no expenses are available
    if (expenses.isEmpty) {
      return _buildEmptyState(context, localizations);
    }

    // Build the scrollable list of expenses
    return ListView.separated(
      // Disable scrolling if this list is inside another scrollable widget
      physics: const NeverScrollableScrollPhysics(),
      // Shrink the list to fit its content
      shrinkWrap: true,
      // Number of items in the list
      itemCount: expenses.length,
      // Spacing between list items
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.paddingS),
      // Builder for each expense item
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return _buildExpenseItem(
          context,
          expense,
          localizations,
          ref,
        );
      },
    );
  }

  /// Builds the empty state widget when no expenses are available.
  /// Provides a helpful message and visual indicator to guide users.
  Widget _buildEmptyState(
      BuildContext context, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state icon
          Icon(
            PlatformWidgets.isIOS
                ? CupertinoIcons.money_dollar
                : Icons.attach_money,
            size: AppConstants.iconSizeXXL,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppConstants.paddingL),

          // Empty state title
          Text(
            localizations.noExpenses,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingM),

          // Empty state description
          Text(
            'Add your first expense to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds an individual expense item widget.
  /// Handles the layout, styling, and interactions for each expense.
  Widget _buildExpenseItem(
    BuildContext context,
    Expense expense,
    AppLocalizations localizations,
    WidgetRef ref,
  ) {
    return Card(
      // Add subtle elevation for visual separation
      elevation: AppConstants.shadowS,
      // Use platform-appropriate styling
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: InkWell(
        // Handle tap events on the expense item
        onTap: onExpenseTap != null ? () => onExpenseTap!(expense) : null,
        // Use platform-appropriate border radius
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Row(
            children: [
              // Category icon and color indicator
              _buildCategoryIndicator(context, expense),
              const SizedBox(width: AppConstants.paddingM),

              // Expense details (title, category, date)
              Expanded(
                child: _buildExpenseDetails(context, expense, localizations),
              ),

              // Expense amount
              _buildExpenseAmount(context, expense),

              // Delete button (if enabled)
              if (showDeleteButton) ...[
                const SizedBox(width: AppConstants.paddingS),
                _buildDeleteButton(context, expense, ref),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the category indicator with icon and color.
  /// Provides visual identification of expense categories.
  Widget _buildCategoryIndicator(BuildContext context, Expense expense) {
    // Get category color based on expense type
    final color = expense.amount < 0
        ? const Color(AppConstants.errorColor)
        : const Color(AppConstants.successColor);

    // Get appropriate icon for the category
    final icon = _getCategoryIcon(expense.category);

    return Container(
      width: AppConstants.iconSizeXL,
      height: AppConstants.iconSizeXL,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Icon(
        icon,
        color: color,
        size: AppConstants.iconSizeM,
      ),
    );
  }

  /// Builds the expense details section (title, category, date).
  /// Displays the main information about the expense.
  Widget _buildExpenseDetails(
    BuildContext context,
    Expense expense,
    AppLocalizations localizations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expense title
        Text(
          expense.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppConstants.paddingXS),

        // Category name
        Text(
          expense.category,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: AppConstants.paddingXS),

        // Date information
        Text(
          _getDateDisplay(expense.date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }

  /// Builds the expense amount display.
  /// Shows the amount with appropriate formatting and color coding.
  Widget _buildExpenseAmount(BuildContext context, Expense expense) {
    final isExpense = expense.amount < 0;
    final color = isExpense
        ? const Color(AppConstants.errorColor)
        : const Color(AppConstants.successColor);
    final prefix = isExpense ? '-' : '+';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Formatted amount
        Text(
          '$prefix${CurrencyUtils.formatCurrency(expense.amount.abs())}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.paddingXS),

        // Expense type indicator
        Text(
          isExpense ? 'Expense' : 'Income',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  /// Builds the delete button for expense items.
  /// Provides a way to remove expenses with confirmation.
  Widget _buildDeleteButton(
    BuildContext context,
    Expense expense,
    WidgetRef ref,
  ) {
    return IconButton(
      onPressed: () => _showDeleteConfirmation(context, expense, ref),
      icon: Icon(
        PlatformWidgets.isIOS ? CupertinoIcons.delete : Icons.delete_outline,
        color: const Color(AppConstants.errorColor),
        size: AppConstants.iconSizeM,
      ),
      tooltip: 'Delete expense',
    );
  }

  /// Shows a confirmation dialog before deleting an expense.
  /// Prevents accidental deletions and provides user feedback.
  void _showDeleteConfirmation(
    BuildContext context,
    Expense expense,
    WidgetRef ref,
  ) {
    final localizations = AppLocalizations.of(context)!;

    if (PlatformWidgets.isIOS) {
      // iOS-style confirmation dialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(localizations.deleteExpense),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: [
            CupertinoDialogAction(
              child: Text(localizations.cancel),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(localizations.delete),
              onPressed: () {
                Navigator.pop(context);
                _deleteExpense(expense, ref);
              },
            ),
          ],
        ),
      );
    } else {
      // Android-style confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localizations.deleteExpense),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteExpense(expense, ref);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(AppConstants.errorColor),
              ),
              child: Text(localizations.delete),
            ),
          ],
        ),
      );
    }
  }

  /// Deletes the expense and shows feedback to the user.
  /// Handles the actual deletion process and user notification.
  void _deleteExpense(Expense expense, WidgetRef ref) {
    // Call the delete function from the provider
    if (onExpenseDelete != null) {
      onExpenseDelete!(expense);
    } else {
      // Default deletion through the provider
      ref.read(expenseNotifierProvider.notifier).deleteExpense(expense.id);
    }
  }

  /// Gets the appropriate icon for a given category.
  /// Maps category names to their corresponding icons.
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return PlatformWidgets.isIOS ? CupertinoIcons.cart : Icons.restaurant;
      case 'transportation':
        return PlatformWidgets.isIOS
            ? CupertinoIcons.car_detailed
            : Icons.directions_car;
      case 'entertainment':
        return PlatformWidgets.isIOS
            ? CupertinoIcons.gamecontroller
            : Icons.movie;
      case 'shopping':
        return PlatformWidgets.isIOS ? CupertinoIcons.bag : Icons.shopping_bag;
      case 'health':
        return PlatformWidgets.isIOS
            ? CupertinoIcons.heart
            : Icons.health_and_safety;
      case 'education':
        return PlatformWidgets.isIOS ? CupertinoIcons.book : Icons.school;
      case 'utilities':
        return PlatformWidgets.isIOS
            ? CupertinoIcons.lightbulb
            : Icons.lightbulb;
      case 'rent':
        return PlatformWidgets.isIOS ? CupertinoIcons.house : Icons.home;
      case 'insurance':
        return PlatformWidgets.isIOS ? CupertinoIcons.shield : Icons.security;
      case 'salary':
        return PlatformWidgets.isIOS
            ? CupertinoIcons.money_dollar
            : Icons.attach_money;
      case 'investment':
        return PlatformWidgets.isIOS
            ? CupertinoIcons.graph_circle
            : Icons.trending_up;
      case 'gift':
        return PlatformWidgets.isIOS
            ? CupertinoIcons.gift
            : Icons.card_giftcard;
      default:
        return PlatformWidgets.isIOS ? CupertinoIcons.circle : Icons.category;
    }
  }

  /// Gets the appropriate date display format.
  /// Shows relative dates for recent expenses and absolute dates for older ones.
  String _getDateDisplay(DateTime date) {
    if (app_date_utils.DateUtils.isToday(date)) {
      return 'Today';
    } else if (app_date_utils.DateUtils.isYesterday(date)) {
      return 'Yesterday';
    } else if (app_date_utils.DateUtils.isTomorrow(date)) {
      return 'Tomorrow';
    } else {
      // Show full date for older expenses
      return app_date_utils.DateUtils.formatDate(date);
    }
  }
}
