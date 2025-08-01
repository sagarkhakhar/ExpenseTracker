import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/expense/presentation/views/filter_screen.dart';
import 'package:expense_tracker/features/expense/presentation/providers/filter_providers.dart';
import 'package:expense_tracker/features/expense/domain/entities/filter_criteria.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

void main() {
  setUpAll(() async {
    final testDir = Directory('./test/hive_testing').absolute;
    if (!testDir.existsSync()) {
      testDir.createSync(recursive: true);
    }
    Hive.init(testDir.path);
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(ExpenseTypeAdapter());
  });

  setUp(() async {
    // Clear any existing boxes
    await Hive.deleteBoxFromDisk('expenses');
    await Hive.deleteBoxFromDisk('categories');
    await Hive.deleteBoxFromDisk('budgets');
  });

  tearDown(() async {
    // Close boxes after each test
    await Hive.close();
  });

  group('FilterScreen', () {
    testWidgets('should display filter controls', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FilterScreen(),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify filter screen title is displayed
      expect(find.text('Filter Expenses'), findsOneWidget);

      // Verify filter controls are present
      expect(find.text('Date Range'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Amount Range'), findsOneWidget);
      expect(find.text('Expense Type'), findsOneWidget);

      // Verify apply filters button is present
      expect(find.text('Apply Filters'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('should show search bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FilterScreen(),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify search bar is present (there are multiple TextFields, so check for search icon)
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Search expenses...'), findsOneWidget);
    });

    testWidgets('should display filter results section',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FilterScreen(),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify filter results section is present
      expect(find.byType(Consumer), findsWidgets);
    });

    testWidgets('should handle clear filters action',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FilterScreen(),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify the clear all button is present
      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('should handle apply filters action',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FilterScreen(),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify the apply filters button is present
      expect(find.text('Apply Filters'), findsOneWidget);
    });
  });
}
