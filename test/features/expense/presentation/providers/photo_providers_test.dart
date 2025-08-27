import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:expense_tracker/features/expense/domain/entities/receipt_photo.dart';
import 'package:expense_tracker/features/expense/domain/repositories/receipt_photo_repository.dart';
import 'package:expense_tracker/features/expense/domain/usecases/capture_photo.dart';
import 'package:expense_tracker/features/expense/domain/usecases/save_photo.dart';
import 'package:expense_tracker/features/expense/domain/usecases/get_photos_for_expense.dart';
import 'package:expense_tracker/features/expense/domain/services/photo_service.dart';
import 'package:expense_tracker/features/expense/data/datasources/receipt_photo_local_data_source.dart';
import 'package:expense_tracker/features/expense/presentation/providers/photo_providers.dart';
import 'package:expense_tracker/core/errors/failures.dart';

// Mock classes
class MockReceiptPhotoRepository extends Mock implements ReceiptPhotoRepository {}
class MockReceiptPhotoLocalDataSourceImpl extends Mock implements ReceiptPhotoLocalDataSourceImpl {}
class MockCapturePhoto extends Mock implements CapturePhoto {}
class MockSavePhoto extends Mock implements SavePhoto {}
class MockGetPhotosForExpense extends Mock implements GetPhotosForExpense {}
class MockPhotoService extends Mock implements PhotoService {}

// Fake classes for fallback values
class FakeReceiptPhoto extends Fake implements ReceiptPhoto {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeReceiptPhoto());
  });

  // Test data
  final testPhoto = ReceiptPhoto(
    id: 'photo-1',
    expenseId: 'expense-1',
    filePath: '/path/to/photo.jpg',
    fileName: 'photo.jpg',
    fileSize: 12345,
    mimeType: 'image/jpeg',
    capturedAt: DateTime(2024, 1, 1),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  final testPhotos = [testPhoto];
  const testFailure = DatabaseFailure('Test error');

  group('Photo Providers', () {
    group('Repository Provider', () {
      test('should provide receipt photo repository instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final repository = container.read(receiptPhotoRepositoryProvider);
        expect(repository, isA<ReceiptPhotoRepository>());
      });
    });

    group('Use Case Providers', () {
      test('should provide CapturePhoto use case', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final useCase = container.read(capturePhotoProvider);
        expect(useCase, isA<CapturePhoto>());
      });

      test('should provide SavePhoto use case', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final useCase = container.read(savePhotoProvider);
        expect(useCase, isA<SavePhoto>());
      });

      test('should provide GetPhotosForExpense use case', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final useCase = container.read(getPhotosForExpenseProvider);
        expect(useCase, isA<GetPhotosForExpense>());
      });
    });

    group('Service Provider', () {
      test('should provide photo service instance', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final service = container.read(photoServiceProvider);
        expect(service, isA<PhotoService>());
      });
    });

    group('State Providers', () {
      late MockGetPhotosForExpense mockGetPhotos;
      late MockPhotoService mockPhotoService;

      setUp(() {
        mockGetPhotos = MockGetPhotosForExpense();
        mockPhotoService = MockPhotoService();
      });

      test('photosForExpenseProvider should return photos on success', () async {
        when(() => mockGetPhotos('expense-1'))
            .thenAnswer((_) async => Right(testPhotos));

        final container = ProviderContainer(
          overrides: [
            getPhotosForExpenseProvider.overrideWithValue(mockGetPhotos),
          ],
        );
        addTearDown(container.dispose);

        final photos = await container.read(photosForExpenseProvider('expense-1').future);
        expect(photos, equals(testPhotos));
        verify(() => mockGetPhotos('expense-1')).called(1);
      });

      test('photosForExpenseProvider should throw exception on failure', () async {
        when(() => mockGetPhotos('expense-1'))
            .thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            getPhotosForExpenseProvider.overrideWithValue(mockGetPhotos),
          ],
        );
        addTearDown(container.dispose);

        expect(
          () => container.read(photosForExpenseProvider('expense-1').future),
          throwsException,
        );
      });

      test('photoCountProvider should return count on success', () async {
        when(() => mockPhotoService.getPhotoCountForExpense('expense-1'))
            .thenAnswer((_) async => const Right(5));

        final container = ProviderContainer(
          overrides: [
            photoServiceProvider.overrideWithValue(mockPhotoService),
          ],
        );
        addTearDown(container.dispose);

        final count = await container.read(photoCountProvider('expense-1').future);
        expect(count, equals(5));
        verify(() => mockPhotoService.getPhotoCountForExpense('expense-1')).called(1);
      });

      test('photoCountProvider should throw exception on failure', () async {
        when(() => mockPhotoService.getPhotoCountForExpense('expense-1'))
            .thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            photoServiceProvider.overrideWithValue(mockPhotoService),
          ],
        );
        addTearDown(container.dispose);

        expect(
          () => container.read(photoCountProvider('expense-1').future),
          throwsException,
        );
      });

      test('hasPhotosProvider should return true when photos exist', () async {
        when(() => mockPhotoService.hasPhotos('expense-1'))
            .thenAnswer((_) async => const Right(true));

        final container = ProviderContainer(
          overrides: [
            photoServiceProvider.overrideWithValue(mockPhotoService),
          ],
        );
        addTearDown(container.dispose);

        final hasPhotos = await container.read(hasPhotosProvider('expense-1').future);
        expect(hasPhotos, isTrue);
        verify(() => mockPhotoService.hasPhotos('expense-1')).called(1);
      });

      test('hasPhotosProvider should return false when no photos exist', () async {
        when(() => mockPhotoService.hasPhotos('expense-1'))
            .thenAnswer((_) async => const Right(false));

        final container = ProviderContainer(
          overrides: [
            photoServiceProvider.overrideWithValue(mockPhotoService),
          ],
        );
        addTearDown(container.dispose);

        final hasPhotos = await container.read(hasPhotosProvider('expense-1').future);
        expect(hasPhotos, isFalse);
      });

      test('totalStorageProvider should return storage size on success', () async {
        when(() => mockPhotoService.getTotalStorageForExpense('expense-1'))
            .thenAnswer((_) async => const Right(123456));

        final container = ProviderContainer(
          overrides: [
            photoServiceProvider.overrideWithValue(mockPhotoService),
          ],
        );
        addTearDown(container.dispose);

        final totalSize = await container.read(totalStorageProvider('expense-1').future);
        expect(totalSize, equals(123456));
        verify(() => mockPhotoService.getTotalStorageForExpense('expense-1')).called(1);
      });
    });

    group('PhotoCaptureNotifier', () {
      late MockCapturePhoto mockCapturePhoto;

      setUp(() {
        mockCapturePhoto = MockCapturePhoto();
      });

      test('should start with null data state', () {
        final container = ProviderContainer(
          overrides: [
            capturePhotoProvider.overrideWithValue(mockCapturePhoto),
          ],
        );
        addTearDown(container.dispose);

        final state = container.read(photoCaptureNotifierProvider);
        expect(state, isA<AsyncData>());
        expect(state.value, isNull);
      });

      test('should capture photo successfully', () async {
        when(() => mockCapturePhoto(
              expenseId: any(named: 'expenseId'),
              filePath: any(named: 'filePath'),
              fileName: any(named: 'fileName'),
              fileSize: any(named: 'fileSize'),
              mimeType: any(named: 'mimeType'),
              capturedAt: any(named: 'capturedAt'),
            )).thenAnswer((_) async => Right(testPhoto));

        final container = ProviderContainer(
          overrides: [
            capturePhotoProvider.overrideWithValue(mockCapturePhoto),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(photoCaptureNotifierProvider.notifier);
        
        final captureOperation = notifier.capturePhoto(
          expenseId: 'expense-1',
          filePath: '/path/to/photo.jpg',
          fileName: 'photo.jpg',
          fileSize: 12345,
          mimeType: 'image/jpeg',
          capturedAt: DateTime(2024, 1, 1),
        );

        // Should be loading during operation
        expect(container.read(photoCaptureNotifierProvider), isA<AsyncLoading>());
        
        // Wait for completion
        await captureOperation;
        
        // Should have data with success result
        final state = container.read(photoCaptureNotifierProvider);
        expect(state, isA<AsyncData>());
        expect(state.value, isA<Right>());
        
        verify(() => mockCapturePhoto(
          expenseId: 'expense-1',
          filePath: '/path/to/photo.jpg',
          fileName: 'photo.jpg',
          fileSize: 12345,
          mimeType: 'image/jpeg',
          capturedAt: any(named: 'capturedAt'),
        )).called(1);
      });

      test('should handle capture photo error', () async {
        when(() => mockCapturePhoto(
              expenseId: any(named: 'expenseId'),
              filePath: any(named: 'filePath'),
              fileName: any(named: 'fileName'),
              fileSize: any(named: 'fileSize'),
              mimeType: any(named: 'mimeType'),
              capturedAt: any(named: 'capturedAt'),
            )).thenAnswer((_) async => const Left(testFailure));

        final container = ProviderContainer(
          overrides: [
            capturePhotoProvider.overrideWithValue(mockCapturePhoto),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(photoCaptureNotifierProvider.notifier);
        
        await notifier.capturePhoto(
          expenseId: 'expense-1',
          filePath: '/path/to/photo.jpg',
          fileName: 'photo.jpg',
          fileSize: 12345,
          mimeType: 'image/jpeg',
          capturedAt: DateTime(2024, 1, 1),
        );
        
        // Should have data with failure result
        final state = container.read(photoCaptureNotifierProvider);
        expect(state, isA<AsyncData>());
        expect(state.value, isA<Left>());
      });

      test('should reset state', () {
        final container = ProviderContainer(
          overrides: [
            capturePhotoProvider.overrideWithValue(mockCapturePhoto),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(photoCaptureNotifierProvider.notifier);
        notifier.reset();

        final state = container.read(photoCaptureNotifierProvider);
        expect(state, isA<AsyncData>());
        expect(state.value, isNull);
      });
    });

    group('PhotoDeletionNotifier', () {
      late MockReceiptPhotoRepository mockRepository;

      setUp(() {
        mockRepository = MockReceiptPhotoRepository();
      });

      test('should start with null data state', () {
        final container = ProviderContainer(
          overrides: [
            receiptPhotoRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final state = container.read(photoDeletionNotifierProvider);
        expect(state, isA<AsyncData>());
        expect(state.value, isNull);
      });

      test('should delete photo successfully', () async {
        when(() => mockRepository.deleteReceiptPhoto('photo-1'))
            .thenAnswer((_) async => const Right(null));

        final container = ProviderContainer(
          overrides: [
            receiptPhotoRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(photoDeletionNotifierProvider.notifier);
        
        final deleteOperation = notifier.deletePhoto('photo-1');

        // Should be loading during operation
        expect(container.read(photoDeletionNotifierProvider), isA<AsyncLoading>());
        
        // Wait for completion
        await deleteOperation;
        
        // Should have data with success result
        final state = container.read(photoDeletionNotifierProvider);
        expect(state, isA<AsyncData>());
        expect(state.value, isA<Right>());
        
        verify(() => mockRepository.deleteReceiptPhoto('photo-1')).called(1);
      });

      test('should delete photos for expense successfully', () async {
        when(() => mockRepository.deleteReceiptPhotosForExpense('expense-1'))
            .thenAnswer((_) async => const Right(null));

        final container = ProviderContainer(
          overrides: [
            receiptPhotoRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(photoDeletionNotifierProvider.notifier);
        
        await notifier.deletePhotosForExpense('expense-1');
        
        final state = container.read(photoDeletionNotifierProvider);
        expect(state, isA<AsyncData>());
        expect(state.value, isA<Right>());
        
        verify(() => mockRepository.deleteReceiptPhotosForExpense('expense-1')).called(1);
      });

      test('should reset deletion state', () {
        final container = ProviderContainer(
          overrides: [
            receiptPhotoRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(photoDeletionNotifierProvider.notifier);
        notifier.reset();

        final state = container.read(photoDeletionNotifierProvider);
        expect(state, isA<AsyncData>());
        expect(state.value, isNull);
      });
    });

    group('Provider Types', () {
      test('should have correct provider types', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Test that all providers return the correct types without calling them
        expect(receiptPhotoRepositoryProvider, isA<Provider<ReceiptPhotoRepository>>());
        expect(capturePhotoProvider, isA<Provider<CapturePhoto>>());
        expect(savePhotoProvider, isA<Provider<SavePhoto>>());
        expect(getPhotosForExpenseProvider, isA<Provider<GetPhotosForExpense>>());
        expect(photoServiceProvider, isA<Provider<PhotoService>>());
        expect(photosForExpenseProvider, isA<FutureProviderFamily>());
        expect(photoCountProvider, isA<FutureProviderFamily>());
        expect(hasPhotosProvider, isA<FutureProviderFamily>());
        expect(totalStorageProvider, isA<FutureProviderFamily>());
        expect(photoCaptureNotifierProvider, isA<StateNotifierProvider>());
        expect(photoDeletionNotifierProvider, isA<StateNotifierProvider>());
      });
    });
  });
}