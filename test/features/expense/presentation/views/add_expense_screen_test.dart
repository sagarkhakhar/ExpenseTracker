import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/expense/presentation/views/add_expense_screen.dart';

void main() {
  testWidgets('AddExpenseScreen shows validation errors and submits',
      (tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: AddExpenseScreen())));
    // Try submitting with empty fields
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(find.textContaining('Enter a title'), findsOneWidget);
    expect(find.textContaining('Enter a valid amount'), findsOneWidget);
    // Fill in valid data
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'), 'Test Expense');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '123');
    // Select category/type if dropdowns present
    // Submit
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    // Should not show validation errors now
    expect(find.textContaining('Enter a title'), findsNothing);
    expect(find.textContaining('Enter a valid amount'), findsNothing);
  });
}
