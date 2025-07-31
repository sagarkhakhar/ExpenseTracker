import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/expense/domain/entities/receipt_photo.dart';
import 'package:expense_tracker/features/expense/domain/repositories/receipt_photo_repository.dart';
import 'package:expense_tracker/features/expense/domain/usecases/capture_photo.dart';
import 'package:expense_tracker/core/errors/failures.dart';

class MockReceiptPhotoRepository extends Mock
    implements ReceiptPhotoRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      ReceiptPhoto(
        id: 'test-id',
        expenseId: 'test-expense-id',
        filePath: '/test/path/photo.jpg',
        fileName: 'photo.jpg',
        fileSize: 1024,
        mimeType: 'image/jpeg',
        capturedAt: DateTime(2024, 1, 1, 12, 0),
        createdAt: DateTime(2024, 1, 1, 12, 0),
        updatedAt: DateTime(2024, 1, 1, 12, 0),
      ),
    );
  });
  late CapturePhoto useCase;
  late MockReceiptPhotoRepository mockRepository;

  setUp(() {
    mockRepository = MockReceiptPhotoRepository();
    useCase = CapturePhoto(repository: mockRepository);
  });

  const testExpenseId = 'test-expense-id';
  const testFilePath = '/test/path/photo.jpg';
  const testFileName = 'photo.jpg';
  const testFileSize = 1024;
  const testMimeType = 'image/jpeg';
  final testCapturedAt = DateTime(2024, 1, 1, 12, 0);

  test('should capture photo successfully', () async {
    // Arrange
    when(() => mockRepository.saveReceiptPhoto(any()))
        .thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(
      expenseId: testExpenseId,
      filePath: testFilePath,
      fileName: testFileName,
      fileSize: testFileSize,
      mimeType: testMimeType,
      capturedAt: testCapturedAt,
    );

    // Assert
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Should not return failure'),
      (receiptPhoto) {
        expect(receiptPhoto.expenseId, testExpenseId);
        expect(receiptPhoto.filePath, testFilePath);
        expect(receiptPhoto.fileName, testFileName);
        expect(receiptPhoto.fileSize, testFileSize);
        expect(receiptPhoto.mimeType, testMimeType);
        expect(receiptPhoto.capturedAt, testCapturedAt);
        expect(receiptPhoto.id.isNotEmpty, true);
        expect(receiptPhoto.createdAt.isAfter(testCapturedAt), true);
        expect(receiptPhoto.updatedAt.isAfter(testCapturedAt), true);
      },
    );

    verify(() => mockRepository.saveReceiptPhoto(any())).called(1);
  });

  test('should return failure when repository fails', () async {
    // Arrange
    const failure = DatabaseFailure('Failed to save photo');
    when(() => mockRepository.saveReceiptPhoto(any()))
        .thenAnswer((_) async => Left(failure));

    // Act
    final result = await useCase(
      expenseId: testExpenseId,
      filePath: testFilePath,
      fileName: testFileName,
      fileSize: testFileSize,
      mimeType: testMimeType,
      capturedAt: testCapturedAt,
    );

    // Assert
    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, isA<DatabaseFailure>()),
      (receiptPhoto) => fail('Should not return receipt photo'),
    );

    verify(() => mockRepository.saveReceiptPhoto(any())).called(1);
  });

  test('should generate unique photo IDs', () async {
    // Arrange
    when(() => mockRepository.saveReceiptPhoto(any()))
        .thenAnswer((_) async => const Right(null));

    // Act
    final result1 = await useCase(
      expenseId: testExpenseId,
      filePath: testFilePath,
      fileName: testFileName,
      fileSize: testFileSize,
      mimeType: testMimeType,
      capturedAt: testCapturedAt,
    );

    final result2 = await useCase(
      expenseId: testExpenseId,
      filePath: testFilePath,
      fileName: testFileName,
      fileSize: testFileSize,
      mimeType: testMimeType,
      capturedAt: testCapturedAt,
    );

    // Assert
    expect(result1.isRight(), true);
    expect(result2.isRight(), true);

    result1.fold(
      (failure) => fail('Should not return failure'),
      (photo1) {
        result2.fold(
          (failure) => fail('Should not return failure'),
          (photo2) {
            expect(photo1.id, isNot(equals(photo2.id)));
          },
        );
      },
    );
  });
}
