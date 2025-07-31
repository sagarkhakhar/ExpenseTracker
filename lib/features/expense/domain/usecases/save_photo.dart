// This file defines the SavePhoto use case for the domain layer.
// It encapsulates the business logic for saving a photo to storage.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/receipt_photo.dart';
import '../repositories/receipt_photo_repository.dart';

/// Use case for saving a photo to storage.
/// This encapsulates the business logic for photo storage operations.
class SavePhoto {
  final ReceiptPhotoRepository repository;

  SavePhoto({required this.repository});

  /// Execute the save photo use case.
  /// Returns either void (success) or a Failure.
  Future<Either<Failure, void>> call(ReceiptPhoto receiptPhoto) async {
    try {
      // Update the updatedAt timestamp
      final updatedPhoto = receiptPhoto.copyWith(
        updatedAt: DateTime.now(),
      );

      // Save the photo to storage
      return await repository.saveReceiptPhoto(updatedPhoto);
    } catch (e) {
      return Left(DatabaseFailure('Failed to save photo: $e'));
    }
  }
}
