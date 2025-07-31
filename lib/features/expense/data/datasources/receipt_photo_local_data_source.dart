// This file defines the ReceiptPhotoLocalDataSource interface and implementation.
// It handles local storage operations for receipt photos using Hive.

import 'package:hive/hive.dart';
import '../models/receipt_photo_model.dart';
import '../../domain/entities/receipt_photo.dart';

/// Abstract interface for local data source operations on receipt photos.
abstract class ReceiptPhotoLocalDataSource {
  /// Save a receipt photo to local storage.
  Future<void> saveReceiptPhoto(ReceiptPhoto receiptPhoto);

  /// Get all receipt photos for a specific expense.
  Future<List<ReceiptPhoto>> getReceiptPhotosForExpense(String expenseId);

  /// Get a specific receipt photo by ID.
  Future<ReceiptPhoto?> getReceiptPhoto(String id);

  /// Delete a receipt photo from local storage.
  Future<void> deleteReceiptPhoto(String id);

  /// Delete all receipt photos for a specific expense.
  Future<void> deleteReceiptPhotosForExpense(String expenseId);

  /// Get all receipt photos.
  Future<List<ReceiptPhoto>> getAllReceiptPhotos();
}

/// Implementation of ReceiptPhotoLocalDataSource using Hive.
class ReceiptPhotoLocalDataSourceImpl implements ReceiptPhotoLocalDataSource {
  static const String _boxName = 'receipt_photos';
  late Box<ReceiptPhotoModel> _box;

  /// Initialize the data source by opening the Hive box.
  Future<void> init() async {
    _box = await Hive.openBox<ReceiptPhotoModel>(_boxName);
  }

  @override
  Future<void> saveReceiptPhoto(ReceiptPhoto receiptPhoto) async {
    final model = ReceiptPhotoModel.fromEntity(receiptPhoto);
    await _box.put(receiptPhoto.id, model);
  }

  @override
  Future<List<ReceiptPhoto>> getReceiptPhotosForExpense(
      String expenseId) async {
    final models =
        _box.values.where((model) => model.expenseId == expenseId).toList();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<ReceiptPhoto?> getReceiptPhoto(String id) async {
    final model = _box.get(id);
    return model?.toEntity();
  }

  @override
  Future<void> deleteReceiptPhoto(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> deleteReceiptPhotosForExpense(String expenseId) async {
    final keysToDelete = <String>[];

    for (final key in _box.keys) {
      final model = _box.get(key);
      if (model != null && model.expenseId == expenseId) {
        keysToDelete.add(key);
      }
    }

    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }

  @override
  Future<List<ReceiptPhoto>> getAllReceiptPhotos() async {
    final models = _box.values.toList();
    return models.map((model) => model.toEntity()).toList();
  }
}
