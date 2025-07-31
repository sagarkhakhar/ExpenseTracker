// This file defines the ReceiptPhotoModel, which is the data-layer representation of a ReceiptPhoto.
// It is used for local storage (Hive) and for mapping to/from the domain entity.

import 'package:hive/hive.dart';
import '../../domain/entities/receipt_photo.dart';

part 'receipt_photo_model.g.dart';

/// Data model for storing receipt photos in Hive.
/// This class is used only in the data layer and is mapped to/from the domain entity (ReceiptPhoto).
@HiveType(typeId: 5)
class ReceiptPhotoModel extends HiveObject {
  // All fields must match those in the ReceiptPhoto entity for easy mapping.
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String expenseId;
  @HiveField(2)
  final String filePath;
  @HiveField(3)
  final String fileName;
  @HiveField(4)
  final int fileSize;
  @HiveField(5)
  final String mimeType;
  @HiveField(6)
  final DateTime capturedAt;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final DateTime updatedAt;

  /// Constructor for ReceiptPhotoModel. All fields are required.
  ReceiptPhotoModel({
    required this.id,
    required this.expenseId,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.capturedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert a domain entity (ReceiptPhoto) to a data model (ReceiptPhotoModel).
  factory ReceiptPhotoModel.fromEntity(ReceiptPhoto receiptPhoto) {
    return ReceiptPhotoModel(
      id: receiptPhoto.id,
      expenseId: receiptPhoto.expenseId,
      filePath: receiptPhoto.filePath,
      fileName: receiptPhoto.fileName,
      fileSize: receiptPhoto.fileSize,
      mimeType: receiptPhoto.mimeType,
      capturedAt: receiptPhoto.capturedAt,
      createdAt: receiptPhoto.createdAt,
      updatedAt: receiptPhoto.updatedAt,
    );
  }

  /// Convert this data model to a domain entity (ReceiptPhoto).
  ReceiptPhoto toEntity() {
    return ReceiptPhoto(
      id: id,
      expenseId: expenseId,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      capturedAt: capturedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
