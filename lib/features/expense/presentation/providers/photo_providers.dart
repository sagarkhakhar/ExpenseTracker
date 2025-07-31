// This file defines Riverpod providers for receipt photo state management.
// It provides reactive state management for photo operations in the presentation layer.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/receipt_photo.dart';
import '../../domain/repositories/receipt_photo_repository.dart';
import '../../domain/usecases/capture_photo.dart';
import '../../domain/usecases/save_photo.dart';
import '../../domain/usecases/get_photos_for_expense.dart';
import '../../domain/services/photo_service.dart';
import '../../data/repositories/receipt_photo_repository_impl.dart';
import '../../data/datasources/receipt_photo_local_data_source.dart';

// Repository provider
final receiptPhotoRepositoryProvider = Provider<ReceiptPhotoRepository>((ref) {
  final localDataSource = ReceiptPhotoLocalDataSourceImpl();
  return ReceiptPhotoRepositoryImpl(localDataSource: localDataSource);
});

// Use case providers
final capturePhotoProvider = Provider<CapturePhoto>((ref) {
  final repository = ref.watch(receiptPhotoRepositoryProvider);
  return CapturePhoto(repository: repository);
});

final savePhotoProvider = Provider<SavePhoto>((ref) {
  final repository = ref.watch(receiptPhotoRepositoryProvider);
  return SavePhoto(repository: repository);
});

final getPhotosForExpenseProvider = Provider<GetPhotosForExpense>((ref) {
  final repository = ref.watch(receiptPhotoRepositoryProvider);
  return GetPhotosForExpense(repository: repository);
});

// Service provider
final photoServiceProvider = Provider<PhotoService>((ref) {
  final repository = ref.watch(receiptPhotoRepositoryProvider);
  return PhotoService(repository: repository);
});

// State providers
final photosForExpenseProvider =
    FutureProvider.family<List<ReceiptPhoto>, String>((ref, expenseId) async {
  final useCase = ref.watch(getPhotosForExpenseProvider);
  final result = await useCase(expenseId);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (photos) => photos,
  );
});

final photoCountProvider =
    FutureProvider.family<int, String>((ref, expenseId) async {
  final service = ref.watch(photoServiceProvider);
  final result = await service.getPhotoCountForExpense(expenseId);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (count) => count,
  );
});

final hasPhotosProvider =
    FutureProvider.family<bool, String>((ref, expenseId) async {
  final service = ref.watch(photoServiceProvider);
  final result = await service.hasPhotos(expenseId);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (hasPhotos) => hasPhotos,
  );
});

final totalStorageProvider =
    FutureProvider.family<int, String>((ref, expenseId) async {
  final service = ref.watch(photoServiceProvider);
  final result = await service.getTotalStorageForExpense(expenseId);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (totalSize) => totalSize,
  );
});

// Notifier for photo capture state
class PhotoCaptureNotifier
    extends StateNotifier<AsyncValue<Either<Failure, ReceiptPhoto>?>> {
  final CapturePhoto _capturePhoto;

  PhotoCaptureNotifier(this._capturePhoto) : super(const AsyncValue.data(null));

  Future<void> capturePhoto({
    required String expenseId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required DateTime capturedAt,
  }) async {
    state = const AsyncValue.loading();

    try {
      final result = await _capturePhoto(
        expenseId: expenseId,
        filePath: filePath,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        capturedAt: capturedAt,
      );

      state = AsyncValue.data(result);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final photoCaptureNotifierProvider = StateNotifierProvider<PhotoCaptureNotifier,
    AsyncValue<Either<Failure, ReceiptPhoto>?>>((ref) {
  final capturePhoto = ref.watch(capturePhotoProvider);
  return PhotoCaptureNotifier(capturePhoto);
});

// Notifier for photo deletion state
class PhotoDeletionNotifier
    extends StateNotifier<AsyncValue<Either<Failure, void>?>> {
  final ReceiptPhotoRepository _repository;

  PhotoDeletionNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> deletePhoto(String photoId) async {
    state = const AsyncValue.loading();

    try {
      final result = await _repository.deleteReceiptPhoto(photoId);
      state = AsyncValue.data(result);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deletePhotosForExpense(String expenseId) async {
    state = const AsyncValue.loading();

    try {
      final result = await _repository.deleteReceiptPhotosForExpense(expenseId);
      state = AsyncValue.data(result);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final photoDeletionNotifierProvider = StateNotifierProvider<
    PhotoDeletionNotifier, AsyncValue<Either<Failure, void>?>>((ref) {
  final repository = ref.watch(receiptPhotoRepositoryProvider);
  return PhotoDeletionNotifier(repository);
});
