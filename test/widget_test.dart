// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/main.dart';
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

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ExpenseTrackerApp()),
    );

    // Wait for initial build
    await tester.pump(const Duration(milliseconds: 500));

    // The app should build successfully without crashing
    // Check for basic app structure - either Material or Cupertino widgets
    final hasMaterialApp = find.byType(MaterialApp).evaluate().isNotEmpty;
    final hasCupertinoApp = find.byType(CupertinoApp).evaluate().isNotEmpty;

    // At least one app type should be present
    expect(hasMaterialApp || hasCupertinoApp, isTrue,
        reason:
            'App should build successfully with either MaterialApp or CupertinoApp');
  });
}
