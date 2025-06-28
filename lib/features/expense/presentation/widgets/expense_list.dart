import 'package:flutter/material.dart';
import '../../domain/entities/expense.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;

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
    if (expenses.isEmpty) {
      return const Center(child: Text('No expenses found.'));
    }
    return ListView.separated(
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Dismissible(
          key: ValueKey(expense.id),
          background: Container(
            color: Colors.blue[100],
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            child: const Icon(Icons.edit, color: Colors.blue),
          ),
          secondaryBackground: Container(
            color: Colors.red[100],
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete, color: Colors.red),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              // Delete
              return await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Expense'),
                  content: const Text(
                      'Are you sure you want to delete this expense?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
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
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  expense.isExpense ? Colors.red[100] : Colors.green[100],
              child: Icon(
                expense.isExpense ? Icons.remove : Icons.add,
                color: expense.isExpense ? Colors.red : Colors.green,
              ),
            ),
            title: Text(expense.title),
            subtitle: Text(app_date_utils.DateUtils.formatDate(expense.date)),
            trailing: Text(
              CurrencyUtils.formatCurrency(expense.amount),
              style: TextStyle(
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
}
