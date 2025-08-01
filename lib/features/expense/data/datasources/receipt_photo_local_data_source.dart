// This file defines the ReceiptPhotoLocalDataSource interface and implementation.
// It handles local storage operations for receipt photos using Hive.

import 'package:hive/hive.dart';
import '../models/receipt_photo_model.dart';
import '../../domain/entities/receipt_photo.dart';
import 'package:flutter/foundation.dart';

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

  /// Seed comprehensive photo dummy data for widget testing
  Future<void> seedComprehensivePhotoData() async {
    // Force reseed for testing - clear existing data first
    if (_box.isNotEmpty) {
      debugPrint('Clearing existing photo data for fresh seeding...');
      await _box.clear();
    }

    debugPrint('Seeding comprehensive photo dummy data...');
    final now = DateTime.now();
    final List<ReceiptPhotoModel> dummyPhotos = [];

    // Helper function to add photo with validation
    void addIfValid({
      required String id,
      required String expenseId,
      required String filePath,
      required String fileName,
      required int fileSize,
      required DateTime capturedAt,
      required DateTime createdAt,
      String mimeType = 'image/jpeg',
    }) {
      try {
        final photo = ReceiptPhotoModel(
          id: id,
          expenseId: expenseId,
          filePath: filePath,
          fileName: fileName,
          fileSize: fileSize,
          mimeType: mimeType,
          capturedAt: capturedAt,
          createdAt: createdAt,
          updatedAt: createdAt,
        );
        dummyPhotos.add(photo);
      } catch (e) {
        debugPrint('Failed to create photo $id: $e');
      }
    }

    int id = 1;

    // 1. REGULAR RECEIPT PHOTOS - Various file sizes and types
    final expenseIds = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];

    for (final expenseId in expenseIds) {
      // Single photo per expense
      addIfValid(
        id: (id++).toString(),
        expenseId: expenseId,
        filePath: '/photos/receipt_${expenseId}_1.jpg',
        fileName: 'receipt_${expenseId}_1.jpg',
        fileSize: 500000 + (id % 1000000), // 500KB to 1.5MB
        capturedAt: now.subtract(Duration(days: id % 30)),
        createdAt: now.subtract(Duration(days: id % 30)),
      );
    }

    // 2. MULTIPLE PHOTOS PER EXPENSE
    for (int i = 1; i <= 3; i++) {
      addIfValid(
        id: (id++).toString(),
        expenseId: '1', // Multiple photos for expense 1
        filePath: '/photos/receipt_1_${i}.jpg',
        fileName: 'receipt_1_${i}.jpg',
        fileSize: 300000 + (i * 100000), // 300KB, 400KB, 500KB
        capturedAt: now.subtract(Duration(days: i)),
        createdAt: now.subtract(Duration(days: i)),
      );
    }

    // 3. EDGE CASES - File sizes
    addIfValid(
      id: (id++).toString(),
      expenseId: '11',
      filePath: '/photos/tiny_receipt.jpg',
      fileName: 'tiny_receipt.jpg',
      fileSize: 1024, // 1KB
      capturedAt: now,
      createdAt: now,
    );

    addIfValid(
      id: (id++).toString(),
      expenseId: '12',
      filePath: '/photos/large_receipt.jpg',
      fileName: 'large_receipt.jpg',
      fileSize: 9500000, // 9.5MB (near 10MB limit)
      capturedAt: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(days: 1)),
    );

    // 4. DIFFERENT FILE TYPES
    addIfValid(
      id: (id++).toString(),
      expenseId: '13',
      filePath: '/photos/receipt_png.png',
      fileName: 'receipt_png.png',
      fileSize: 800000,
      capturedAt: now.subtract(const Duration(days: 2)),
      createdAt: now.subtract(const Duration(days: 2)),
    );

    addIfValid(
      id: (id++).toString(),
      expenseId: '14',
      filePath: '/photos/receipt_heic.heic',
      fileName: 'receipt_heic.heic',
      fileSize: 600000,
      capturedAt: now.subtract(const Duration(days: 3)),
      createdAt: now.subtract(const Duration(days: 3)),
    );

    // 5. SPECIAL CHARACTERS IN FILENAMES
    addIfValid(
      id: (id++).toString(),
      expenseId: '15',
      filePath: '/photos/receipt with spaces.jpg',
      fileName: 'receipt with spaces.jpg',
      fileSize: 400000,
      capturedAt: now.subtract(const Duration(days: 4)),
      createdAt: now.subtract(const Duration(days: 4)),
    );

    addIfValid(
      id: (id++).toString(),
      expenseId: '16',
      filePath: '/photos/receipt-emoji-🛒.jpg',
      fileName: 'receipt-emoji-🛒.jpg',
      fileSize: 350000,
      capturedAt: now.subtract(const Duration(days: 5)),
      createdAt: now.subtract(const Duration(days: 5)),
    );

    addIfValid(
      id: (id++).toString(),
      expenseId: '17',
      filePath: '/photos/receipt_special_chars.jpg',
      fileName: 'receipt_special_chars.jpg',
      fileSize: 450000,
      capturedAt: now.subtract(const Duration(days: 6)),
      createdAt: now.subtract(const Duration(days: 6)),
    );

    // 6. LONG FILENAMES
    addIfValid(
      id: (id++).toString(),
      expenseId: '18',
      filePath:
          '/photos/very_long_filename_that_should_test_ui_layout_and_text_wrapping_capabilities_in_the_photo_list_widget.jpg',
      fileName:
          'very_long_filename_that_should_test_ui_layout_and_text_wrapping_capabilities_in_the_photo_list_widget.jpg',
      fileSize: 500000,
      capturedAt: now.subtract(const Duration(days: 7)),
      createdAt: now.subtract(const Duration(days: 7)),
    );

    // 7. HISTORICAL PHOTOS
    addIfValid(
      id: (id++).toString(),
      expenseId: '19',
      filePath: '/photos/old_receipt.jpg',
      fileName: 'old_receipt.jpg',
      fileSize: 200000,
      capturedAt: now.subtract(const Duration(days: 365)),
      createdAt: now.subtract(const Duration(days: 365)),
    );

    addIfValid(
      id: (id++).toString(),
      expenseId: '20',
      filePath: '/photos/very_old_receipt.jpg',
      fileName: 'very_old_receipt.jpg',
      fileSize: 150000,
      capturedAt: DateTime(2020, 1, 1),
      createdAt: DateTime(2020, 1, 1),
    );

    // 8. RECENT PHOTOS
    addIfValid(
      id: (id++).toString(),
      expenseId: '21',
      filePath: '/photos/today_receipt.jpg',
      fileName: 'today_receipt.jpg',
      fileSize: 300000,
      capturedAt: now,
      createdAt: now,
    );

    addIfValid(
      id: (id++).toString(),
      expenseId: '22',
      filePath: '/photos/yesterday_receipt.jpg',
      fileName: 'yesterday_receipt.jpg',
      fileSize: 250000,
      capturedAt: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(days: 1)),
    );

    // 9. PHOTOS FOR SAME EXPENSE (Multiple photos)
    for (int i = 1; i <= 5; i++) {
      addIfValid(
        id: (id++).toString(),
        expenseId: '23', // Multiple photos for same expense
        filePath: '/photos/multi_receipt_${i}.jpg',
        fileName: 'multi_receipt_${i}.jpg',
        fileSize: 200000 + (i * 50000), // 200KB to 450KB
        capturedAt: now.subtract(Duration(minutes: i * 5)),
        createdAt: now.subtract(Duration(minutes: i * 5)),
      );
    }

    // 10. PHOTOS WITH DIFFERENT CAPTURE TIMES
    addIfValid(
      id: (id++).toString(),
      expenseId: '24',
      filePath: '/photos/morning_receipt.jpg',
      fileName: 'morning_receipt.jpg',
      fileSize: 350000,
      capturedAt: DateTime(now.year, now.month, now.day, 8, 30),
      createdAt: DateTime(now.year, now.month, now.day, 8, 30),
    );

    addIfValid(
      id: (id++).toString(),
      expenseId: '25',
      filePath: '/photos/afternoon_receipt.jpg',
      fileName: 'afternoon_receipt.jpg',
      fileSize: 400000,
      capturedAt: DateTime(now.year, now.month, now.day, 14, 15),
      createdAt: DateTime(now.year, now.month, now.day, 14, 15),
    );

    addIfValid(
      id: (id++).toString(),
      expenseId: '26',
      filePath: '/photos/evening_receipt.jpg',
      fileName: 'evening_receipt.jpg',
      fileSize: 380000,
      capturedAt: DateTime(now.year, now.month, now.day, 20, 45),
      createdAt: DateTime(now.year, now.month, now.day, 20, 45),
    );

    // 11. PHOTOS FOR TESTING FILTERING
    final categories = ['food', 'transport', 'shopping', 'entertainment'];
    for (int i = 0; i < categories.length; i++) {
      addIfValid(
        id: (id++).toString(),
        expenseId: (27 + i).toString(),
        filePath: '/photos/${categories[i]}_receipt.jpg',
        fileName: '${categories[i]}_receipt.jpg',
        fileSize: 300000 + (i * 50000),
        capturedAt: now.subtract(Duration(days: i + 1)),
        createdAt: now.subtract(Duration(days: i + 1)),
      );
    }

    // 12. PHOTOS WITH ZERO FILE SIZE (Edge case)
    addIfValid(
      id: (id++).toString(),
      expenseId: '31',
      filePath: '/photos/empty_receipt.jpg',
      fileName: 'empty_receipt.jpg',
      fileSize: 0,
      capturedAt: now,
      createdAt: now,
    );

    // Batch insert all valid photos
    final validPhotos = dummyPhotos
        .where((photo) =>
            photo.fileSize >= 0 &&
            photo.fileName.isNotEmpty &&
            photo.filePath.isNotEmpty)
        .toList();

    debugPrint('Adding ${validPhotos.length} dummy photos...');

    // Use batch operation for efficiency
    final batch = <String, ReceiptPhotoModel>{};
    for (final photo in validPhotos) {
      batch[photo.id] = photo;
    }

    await _box.putAll(batch);
    debugPrint('Successfully added ${batch.length} dummy photos');
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
