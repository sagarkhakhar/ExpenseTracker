import 'package:flutter/material.dart';

class AddExpenseFAB extends StatelessWidget {
  const AddExpenseFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).pushNamed('/add-expense');
      },
      child: const Icon(Icons.add),
      tooltip: 'Add Expense',
    );
  }
}
