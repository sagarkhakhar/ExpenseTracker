// This file defines the ReceiptPhoto entity, which represents a photo attached to an expense.
// It is used throughout the domain, data, and presentation layers.

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'receipt_photo.g.dart';

/// The ReceiptPhoto entity represents a photo attached to an expense.
/// It is immutable and uses Equatable for value equality.
/// It is also annotated for Hive (local database) serialization.
@HiveType(typeId: 5)
class ReceiptPhoto extends Equatable {
  // Unique identifier for the photo (UUID string)
  @HiveField(0)
  final String id;
  // Reference to the associated expense
  @HiveField(1)
  final String expenseId;
  // Local file path where photo is stored
  @HiveField(2)
  final String filePath;
  // Original filename of the photo
  @HiveField(3)
  final String fileName;
  // Size of the photo file in bytes
  @HiveField(4)
  final int fileSize;
  // MIME type of the photo (e.g., 'image/jpeg')
  @HiveField(5)
  final String mimeType;
  // When the photo was captured/selected
  @HiveField(6)
  final DateTime capturedAt;
  // When this record was created
  @HiveField(7)
  final DateTime createdAt;
  // When this record was last updated
  @HiveField(8)
  final DateTime updatedAt;

  /// Constructor for ReceiptPhoto. All fields are required.
  const ReceiptPhoto({
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

  /// Equatable: defines which fields are used for value equality.
  @override
  List<Object?> get props => [
        id,
        expenseId,
        filePath,
        fileName,
        fileSize,
        mimeType,
        capturedAt,
        createdAt,
        updatedAt,
      ];

  /// Returns a copy of this receipt photo with the given fields replaced.
  ReceiptPhoto copyWith({
    String? id,
    String? expenseId,
    String? filePath,
    String? fileName,
    int? fileSize,
    String? mimeType,
    DateTime? capturedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReceiptPhoto(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Utility: true if this is a JPEG image
  bool get isJpeg => mimeType.toLowerCase() == 'image/jpeg';

  /// Utility: true if this is a PNG image
  bool get isPng => mimeType.toLowerCase() == 'image/png';

  /// Utility: returns file size in MB
  double get fileSizeInMB => fileSize / (1024 * 1024);

  /// Utility: returns file size in KB
  double get fileSizeInKB => fileSize / 1024;
}
