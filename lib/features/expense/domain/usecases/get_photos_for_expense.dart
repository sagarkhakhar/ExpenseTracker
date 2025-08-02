// This file defines the GetPhotosForExpense use case for the domain layer.
// It encapsulates the business logic for retrieving photos for a specific expense.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/receipt_photo.dart';
import '../repositories/receipt_photo_repository.dart';

/// Use case for getting all photos for a specific expense.
/// This encapsulates the business logic for photo retrieval operations.
class GetPhotosForExpense {
  final ReceiptPhotoRepository repository;

  GetPhotosForExpense({required this.repository});

  /// Execute the get photos for expense use case.
  /// Returns either a list of ReceiptPhoto entities or a Failure.
  Future<Either<Failure, List<ReceiptPhoto>>> call(String expenseId) async {
    try {
      // Validate expense ID
      if (expenseId.isEmpty) {
        return const Left(ValidationFailure('Expense ID cannot be empty'));
      }

      // Get photos for the expense
      return await repository.getReceiptPhotosForExpense(expenseId);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get photos for expense: $e'));
    }
  }
}
