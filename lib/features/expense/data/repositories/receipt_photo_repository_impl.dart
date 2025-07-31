// This file implements the ReceiptPhotoRepository interface using the local data source.
// It provides the data layer implementation for receipt photo operations.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/receipt_photo.dart';
import '../../domain/repositories/receipt_photo_repository.dart';
import '../datasources/receipt_photo_local_data_source.dart';

/// Implementation of ReceiptPhotoRepository using local data source.
class ReceiptPhotoRepositoryImpl implements ReceiptPhotoRepository {
  final ReceiptPhotoLocalDataSource localDataSource;

  ReceiptPhotoRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, void>> saveReceiptPhoto(
      ReceiptPhoto receiptPhoto) async {
    try {
      await localDataSource.saveReceiptPhoto(receiptPhoto);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to save receipt photo: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ReceiptPhoto>>> getReceiptPhotosForExpense(
      String expenseId) async {
    try {
      final photos =
          await localDataSource.getReceiptPhotosForExpense(expenseId);
      return Right(photos);
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to get receipt photos for expense: $e'));
    }
  }

  @override
  Future<Either<Failure, ReceiptPhoto?>> getReceiptPhoto(String id) async {
    try {
      final photo = await localDataSource.getReceiptPhoto(id);
      return Right(photo);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get receipt photo: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReceiptPhoto(String id) async {
    try {
      await localDataSource.deleteReceiptPhoto(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete receipt photo: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReceiptPhotosForExpense(
      String expenseId) async {
    try {
      await localDataSource.deleteReceiptPhotosForExpense(expenseId);
      return const Right(null);
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to delete receipt photos for expense: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ReceiptPhoto>>> getAllReceiptPhotos() async {
    try {
      final photos = await localDataSource.getAllReceiptPhotos();
      return Right(photos);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get all receipt photos: $e'));
    }
  }
}
