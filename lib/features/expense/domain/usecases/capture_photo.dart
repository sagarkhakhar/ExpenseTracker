// This file defines the CapturePhoto use case for the domain layer.
// It encapsulates the business logic for capturing a photo from camera or gallery.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/receipt_photo.dart';
import '../repositories/receipt_photo_repository.dart';

/// Use case for capturing a photo from camera or gallery.
/// This encapsulates the business logic for photo capture operations.
class CapturePhoto {
  final ReceiptPhotoRepository repository;

  CapturePhoto({required this.repository});

  /// Execute the photo capture use case.
  /// Returns either a ReceiptPhoto entity or a Failure.
  Future<Either<Failure, ReceiptPhoto>> call({
    required String expenseId,
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required DateTime capturedAt,
  }) async {
    try {
      // Create a new ReceiptPhoto entity
      final receiptPhoto = ReceiptPhoto(
        id: _generatePhotoId(),
        expenseId: expenseId,
        filePath: filePath,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        capturedAt: capturedAt,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save the photo to storage
      final saveResult = await repository.saveReceiptPhoto(receiptPhoto);

      return saveResult.fold(
        (failure) => Left(failure),
        (_) => Right(receiptPhoto),
      );
    } catch (e) {
      return Left(DatabaseFailure('Failed to capture photo: $e'));
    }
  }

  /// Generate a unique photo ID.
  String _generatePhotoId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (DateTime.now().microsecond % 9000)).toString();
  }
}
