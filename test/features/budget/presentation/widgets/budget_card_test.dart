import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budget/domain/entities/budget.dart';
import 'package:expense_tracker/features/budget/presentation/widgets/budget_card.dart';

void main() {
  group('BudgetCard', () {
    testWidgets('should display budget information correctly', (WidgetTester tester) async {
      final budget = Budget(
        id: '1',
        categoryId: 'Food',
        amount: 100.0,
        period: 'monthly',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        spentAmount: 75.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetCard(budget: budget),
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Period: Monthly'), findsOneWidget);
      expect(find.text('\$75.00'), findsOneWidget);
      expect(find.text('\$100.00'), findsOneWidget);
      expect(find.text('75.0% used'), findsOneWidget);
    });

    testWidgets('should show warning status when approaching limit', (WidgetTester tester) async {
      final budget = Budget(
        id: '1',
        categoryId: 'Food',
        amount: 100.0,
        period: 'monthly',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        spentAmount: 85.0,
        alertThreshold: 80.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetCard(budget: budget),
          ),
        ),
      );

      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('Approaching budget limit'), findsOneWidget);
    });

    testWidgets('should show exceeded status when budget is exceeded', (WidgetTester tester) async {
      final budget = Budget(
        id: '1',
        categoryId: 'Food',
        amount: 100.0,
        period: 'monthly',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        spentAmount: 110.0,
        alertThreshold: 80.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetCard(budget: budget),
          ),
        ),
      );

      expect(find.text('Exceeded'), findsOneWidget);
      expect(find.text('Budget exceeded by 10.0%'), findsOneWidget);
    });

    testWidgets('should show on track status when within limit', (WidgetTester tester) async {
      final budget = Budget(
        id: '1',
        categoryId: 'Food',
        amount: 100.0,
        period: 'monthly',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        spentAmount: 50.0,
        alertThreshold: 80.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetCard(budget: budget),
          ),
        ),
      );

      expect(find.text('On Track'), findsOneWidget);
    });
  });
} 