import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/expense/domain/entities/receipt_photo.dart';
import 'package:expense_tracker/features/expense/presentation/widgets/photo_display_widget.dart';
import 'package:expense_tracker/features/expense/presentation/providers/photo_providers.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/expense/domain/repositories/receipt_photo_repository.dart';

class MockReceiptPhotoRepository extends Mock
    implements ReceiptPhotoRepository {}

void main() {
  group('PhotoDisplayWidget', () {
    late MockReceiptPhotoRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockReceiptPhotoRepository();
      container = ProviderContainer(
        overrides: [
          receiptPhotoRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('should render without errors when no photos exist',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockRepository.getReceiptPhotosForExpense(any()))
          .thenAnswer((_) async => const Right([]));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: Scaffold(
              body: PhotoDisplayWidget(
                expenseId: 'test-expense-id',
              ),
            ),
          ),
        ),
      );

      // Wait for async operations
      await tester.pumpAndSettle();

      // Assert - widget should render without throwing errors
      expect(find.byType(PhotoDisplayWidget), findsOneWidget);
    });

    testWidgets('should render without errors when photos exist',
        (WidgetTester tester) async {
      // Arrange
      final photos = [
        ReceiptPhoto(
          id: 'photo1',
          expenseId: 'test-expense-id',
          fileName: 'receipt1.jpg',
          filePath: '/test/path/receipt1.jpg',
          fileSize: 1024000, // 1MB
          mimeType: 'image/jpeg',
          capturedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(() => mockRepository.getReceiptPhotosForExpense(any()))
          .thenAnswer((_) async => Right(photos));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: Scaffold(
              body: PhotoDisplayWidget(
                expenseId: 'test-expense-id',
              ),
            ),
          ),
        ),
      );

      // Wait for async operations
      await tester.pumpAndSettle();

      // Assert - widget should render without throwing errors
      expect(find.byType(PhotoDisplayWidget), findsOneWidget);
    });

    testWidgets('should render without errors when repository fails',
        (WidgetTester tester) async {
      // Arrange
      when(() => mockRepository.getReceiptPhotosForExpense(any())).thenAnswer(
          (_) async => const Left(ServerFailure('Failed to load photos')));

      // Act
      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: const MaterialApp(
            home: Scaffold(
              body: PhotoDisplayWidget(
                expenseId: 'test-expense-id',
              ),
            ),
          ),
        ),
      );

      // Wait for async operations
      await tester.pumpAndSettle();

      // Assert - widget should render without throwing errors
      expect(find.byType(PhotoDisplayWidget), findsOneWidget);
    });
  });
}
