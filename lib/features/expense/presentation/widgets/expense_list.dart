import 'package:flutter/material.dart';
import '../../domain/entities/expense.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../../shared/widgets/platform_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;
  final void Function(Expense)? onTap;
  final void Function(Expense)? onDelete;
  final void Function(Expense)? onEdit;

  const ExpenseList({
    super.key,
    required this.expenses,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    if (expenses.isEmpty) {
      return Center(child: Text(localizations.noExpenses));
    }
    return ListView.separated(
      itemCount: expenses.length,
      separatorBuilder: (_, __) => Container(
        height: 1,
        color: PlatformWidgets.isIOS
            ? CupertinoColors.separator
            : AppConstants.dividerColor,
      ),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Dismissible(
          key: ValueKey(expense.id),
          background: Container(
            color: Colors.blue[100],
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: AppConstants.paddingL),
            child: Icon(
              PlatformWidgets.isIOS ? CupertinoIcons.pencil : Icons.edit,
              color: Colors.blue,
              semanticLabel: localizations.editExpense,
            ),
          ),
          secondaryBackground: Container(
            color: Colors.red[100],
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppConstants.paddingL),
            child: Icon(
              PlatformWidgets.isIOS ? CupertinoIcons.delete : Icons.delete,
              color: Colors.red,
              semanticLabel: localizations.delete,
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              // Delete
              return await PlatformWidgets.showPlatformDialog(
                context: context,
                title: localizations.deleteExpense,
                content: localizations.deleteExpenseConfirm,
                confirmText: localizations.delete,
                destructive: true,
              );
            } else if (direction == DismissDirection.startToEnd) {
              // Edit
              if (onEdit != null) onEdit!(expense);
              return false;
            }
            return false;
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart && onDelete != null) {
              onDelete!(expense);
            }
          },
          child: PlatformWidgets.platformListTile(
            context: context,
            leading: CircleAvatar(
              radius: 20.0, // Increased for better alignment
              backgroundColor:
                  expense.isExpense ? Colors.red[100] : Colors.green[100],
              child: Icon(
                expense.isExpense
                    ? (PlatformWidgets.isIOS
                        ? CupertinoIcons.minus
                        : Icons.remove)
                    : (PlatformWidgets.isIOS ? CupertinoIcons.add : Icons.add),
                color: expense.isExpense ? Colors.red : Colors.green,
                size: 20.0, // Explicit icon size for alignment
                semanticLabel: expense.isExpense
                    ? localizations.expense
                    : localizations.income,
              ),
            ),
            title: Text(expense.title),
            subtitle: Text(app_date_utils.DateUtils.formatDate(expense.date)),
            trailing: Text(
              CurrencyUtils.formatCurrency(expense.amount),
              style: AppTextStyles.body1.copyWith(
                color: expense.isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: onTap != null ? () => onTap!(expense) : null,
          ),
        );
      },
    );
  }

  static Widget sliver({
    required BuildContext context,
    required List<Expense> expenses,
    void Function(Expense)? onTap,
    void Function(Expense)? onDelete,
    void Function(Expense)? onEdit,
  }) {
    final localizations = AppLocalizations.of(context)!;
    if (expenses.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text(localizations.noExpenses)),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final expense = expenses[index];
          return Dismissible(
            key: ValueKey(expense.id),
            background: Container(
              color: Colors.blue[100],
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: AppConstants.paddingL),
              child: Icon(
                PlatformWidgets.isIOS ? CupertinoIcons.pencil : Icons.edit,
                color: Colors.blue,
                semanticLabel: localizations.editExpense,
              ),
            ),
            secondaryBackground: Container(
              color: Colors.red[100],
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppConstants.paddingL),
              child: Icon(
                PlatformWidgets.isIOS ? CupertinoIcons.delete : Icons.delete,
                color: Colors.red,
                semanticLabel: localizations.delete,
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                // Delete
                return await PlatformWidgets.showPlatformDialog(
                  context: context,
                  title: localizations.deleteExpense,
                  content: localizations.deleteExpenseConfirm,
                  confirmText: localizations.delete,
                  destructive: true,
                );
              } else if (direction == DismissDirection.startToEnd) {
                // Edit
                if (onEdit != null) onEdit(expense);
                return false;
              }
              return false;
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart &&
                  onDelete != null) {
                onDelete(expense);
              }
            },
            child: PlatformWidgets.platformListTile(
              context: context,
              leading: CircleAvatar(
                radius: 20.0, // Increased for better alignment
                backgroundColor:
                    expense.isExpense ? Colors.red[100] : Colors.green[100],
                child: Icon(
                  expense.isExpense
                      ? (PlatformWidgets.isIOS
                          ? CupertinoIcons.minus
                          : Icons.remove)
                      : (PlatformWidgets.isIOS
                          ? CupertinoIcons.add
                          : Icons.add),
                  color: expense.isExpense ? Colors.red : Colors.green,
                  size: 20.0, // Explicit icon size for alignment
                  semanticLabel: expense.isExpense
                      ? localizations.expense
                      : localizations.income,
                ),
              ),
              title: Text(expense.title),
              subtitle: Text(app_date_utils.DateUtils.formatDate(expense.date)),
              trailing: Text(
                CurrencyUtils.formatCurrency(expense.amount),
                style: AppTextStyles.body1.copyWith(
                  color: expense.isExpense ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: onTap != null ? () => onTap(expense) : null,
            ),
          );
        },
        childCount: expenses.length,
      ),
    );
  }
}
