// This file defines the PhotoService for the domain layer.
// It encapsulates business logic for photo operations and processing.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/receipt_photo.dart';
import '../repositories/receipt_photo_repository.dart';

/// Service for photo-related business logic.
/// This encapsulates complex photo operations and processing.
class PhotoService {
  final ReceiptPhotoRepository repository;

  PhotoService({required this.repository});

  /// Validate photo file size.
  /// Returns true if the file size is within acceptable limits.
  bool isValidFileSize(int fileSizeInBytes) {
    const maxSizeInMB = 10; // 10MB limit
    const maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    return fileSizeInBytes > 0 && fileSizeInBytes <= maxSizeInBytes;
  }

  /// Validate photo MIME type.
  /// Returns true if the MIME type is supported.
  bool isValidMimeType(String mimeType) {
    final supportedTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/heic',
      'image/heif',
    ];
    return supportedTypes.contains(mimeType.toLowerCase());
  }

  /// Get total storage used by photos for an expense.
  /// Returns the total size in bytes.
  Future<Either<Failure, int>> getTotalStorageForExpense(
      String expenseId) async {
    try {
      final photosResult =
          await repository.getReceiptPhotosForExpense(expenseId);

      return photosResult.fold(
        (failure) => Left(failure),
        (photos) {
          final totalSize = photos.fold<int>(
            0,
            (sum, photo) => sum + photo.fileSize,
          );
          return Right(totalSize);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure('Failed to calculate storage: $e'));
    }
  }

  /// Get photo count for an expense.
  /// Returns the number of photos attached to the expense.
  Future<Either<Failure, int>> getPhotoCountForExpense(String expenseId) async {
    try {
      final photosResult =
          await repository.getReceiptPhotosForExpense(expenseId);

      return photosResult.fold(
        (failure) => Left(failure),
        (photos) => Right(photos.length),
      );
    } catch (e) {
      return Left(DatabaseFailure('Failed to get photo count: $e'));
    }
  }

  /// Check if an expense has photos.
  /// Returns true if the expense has at least one photo.
  Future<Either<Failure, bool>> hasPhotos(String expenseId) async {
    try {
      final countResult = await getPhotoCountForExpense(expenseId);

      return countResult.fold(
        (failure) => Left(failure),
        (count) => Right(count > 0),
      );
    } catch (e) {
      return Left(DatabaseFailure('Failed to check if expense has photos: $e'));
    }
  }

  /// Get photos sorted by capture date (newest first).
  /// Returns a sorted list of photos.
  Future<Either<Failure, List<ReceiptPhoto>>> getPhotosSortedByDate(
      String expenseId) async {
    try {
      final photosResult =
          await repository.getReceiptPhotosForExpense(expenseId);

      return photosResult.fold(
        (failure) => Left(failure),
        (photos) {
          final sortedPhotos = List<ReceiptPhoto>.from(photos);
          sortedPhotos.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
          return Right(sortedPhotos);
        },
      );
    } catch (e) {
      return Left(DatabaseFailure('Failed to get sorted photos: $e'));
    }
  }

  /// Validate photo metadata before saving.
  /// Returns true if all metadata is valid.
  bool validatePhotoMetadata({
    required String expenseId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
  }) {
    if (expenseId.isEmpty) return false;
    if (filePath.isEmpty) return false;
    if (fileName.isEmpty) return false;
    if (!isValidFileSize(fileSize)) return false;
    if (!isValidMimeType(mimeType)) return false;

    return true;
  }
}
