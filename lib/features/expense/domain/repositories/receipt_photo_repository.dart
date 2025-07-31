// This file defines the ReceiptPhotoRepository interface for the domain layer.
// It abstracts the details of how receipt photos are stored and retrieved.
// The use cases depend on this interface, not on a concrete implementation (Dependency Inversion Principle).

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/receipt_photo.dart';

/// Interface for repository operations related to receipt photos.
/// Implemented by a concrete class (e.g., using local storage).
abstract class ReceiptPhotoRepository {
  /// Save a receipt photo to storage.
  Future<Either<Failure, void>> saveReceiptPhoto(ReceiptPhoto receiptPhoto);

  /// Get all receipt photos for a specific expense.
  Future<Either<Failure, List<ReceiptPhoto>>> getReceiptPhotosForExpense(
      String expenseId);

  /// Get a specific receipt photo by ID.
  Future<Either<Failure, ReceiptPhoto?>> getReceiptPhoto(String id);

  /// Delete a receipt photo from storage.
  Future<Either<Failure, void>> deleteReceiptPhoto(String id);

  /// Delete all receipt photos for a specific expense.
  Future<Either<Failure, void>> deleteReceiptPhotosForExpense(String expenseId);

  /// Get all receipt photos.
  Future<Either<Failure, List<ReceiptPhoto>>> getAllReceiptPhotos();
}
