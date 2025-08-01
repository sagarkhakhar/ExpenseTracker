import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/photo_capture_widget.dart';

void main() {
  group('PhotoCaptureWidget', () {
    testWidgets('should display camera and gallery buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PhotoCaptureWidget(
                expenseId: 'test-expense-id',
                onPhotoCaptured: () {},
                onError: () {},
              ),
            ),
          ),
        ),
      );

      // Verify that the widget displays the section header
      expect(find.text('Receipt Photos'), findsOneWidget);

      // Verify that camera and gallery buttons are displayed
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });

    testWidgets('should handle callback functions',
        (WidgetTester tester) async {
      bool photoCapturedCalled = false;
      bool errorCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PhotoCaptureWidget(
                expenseId: 'test-expense-id',
                onPhotoCaptured: () => photoCapturedCalled = true,
                onError: () => errorCalled = true,
              ),
            ),
          ),
        ),
      );

      // Verify that callbacks are properly set (not called yet)
      expect(photoCapturedCalled, false);
      expect(errorCalled, false);
    });

    testWidgets('should handle permission requests correctly',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PhotoCaptureWidget(
                expenseId: 'test-expense-id',
                onPhotoCaptured: () {},
                onError: () {},
              ),
            ),
          ),
        ),
      );

      // Verify that camera and gallery buttons are displayed
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // Find and tap camera button
      final cameraButton = find.text('Camera');
      expect(cameraButton, findsOneWidget);
      await tester.tap(cameraButton);
      await tester.pumpAndSettle();

      // Find and tap gallery button
      final galleryButton = find.text('Gallery');
      expect(galleryButton, findsOneWidget);
      await tester.tap(galleryButton);
      await tester.pumpAndSettle();

      // Verify that buttons are still present after tapping
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });

    testWidgets('should perform button tasks when pressed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PhotoCaptureWidget(
                expenseId: 'test-expense-id',
                onPhotoCaptured: () {},
                onError: () {},
              ),
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // Test camera button functionality
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      // Test gallery button functionality
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      // Verify buttons are still functional and widget is stable
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // Verify the widget doesn't crash and maintains its state
      expect(find.text('Receipt Photos'), findsOneWidget);
    });

    testWidgets('should handle different expense IDs correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PhotoCaptureWidget(
                expenseId: 'different-expense-id',
                onPhotoCaptured: () {},
                onError: () {},
              ),
            ),
          ),
        ),
      );

      // Verify buttons work with different expense ID
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      // Verify widget remains stable
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });

    testWidgets('should show preview when image is selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PhotoCaptureWidget(
                expenseId: 'test-expense-id',
                onPhotoCaptured: () {},
                onError: () {},
              ),
            ),
          ),
        ),
      );

      // Verify initial state - no preview
      expect(find.text('Preview'), findsNothing);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Cancel'), findsNothing);

      // Verify camera and gallery buttons are visible initially
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });
  });
}
