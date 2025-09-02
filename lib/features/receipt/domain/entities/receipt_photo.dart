// Receipt photo domain entity for expense photo management
// Represents photo metadata and storage information

import 'package:equatable/equatable.dart';

class ReceiptPhoto extends Equatable {
  final String id;
  final String userId;
  final String? originalFilename;
  final String storagePath; // Path in Supabase storage or local storage
  final int? fileSize; // Size in bytes
  final String? mimeType; // image/jpeg, image/png, etc.
  final int? width; // Image width in pixels
  final int? height; // Image height in pixels
  final bool isProcessed; // Whether OCR or other processing has been done
  final String? ocrText; // Extracted text from OCR (future feature)
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReceiptPhoto({
    required this.id,
    required this.userId,
    this.originalFilename,
    required this.storagePath,
    this.fileSize,
    this.mimeType,
    this.width,
    this.height,
    required this.isProcessed,
    this.ocrText,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this photo with some fields changed
  ReceiptPhoto copyWith({
    String? id,
    String? userId,
    String? originalFilename,
    String? storagePath,
    int? fileSize,
    String? mimeType,
    int? width,
    int? height,
    bool? isProcessed,
    String? ocrText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReceiptPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      originalFilename: originalFilename ?? this.originalFilename,
      storagePath: storagePath ?? this.storagePath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      isProcessed: isProcessed ?? this.isProcessed,
      ocrText: ocrText ?? this.ocrText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if this is a valid image file
  bool get isValidImage => 
      mimeType != null && 
      (mimeType!.startsWith('image/') || 
       mimeType! == 'application/pdf'); // PDF receipts are also valid

  /// Get file extension from mime type
  String? get fileExtension {
    if (mimeType == null) return null;
    
    switch (mimeType!) {
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'application/pdf':
        return '.pdf';
      default:
        return null;
    }
  }

  /// Get human-readable file size
  String get formattedFileSize {
    if (fileSize == null) return 'Unknown size';
    
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;
    
    if (fileSize! >= gb) {
      return '${(fileSize! / gb).toStringAsFixed(1)} GB';
    } else if (fileSize! >= mb) {
      return '${(fileSize! / mb).toStringAsFixed(1)} MB';
    } else if (fileSize! >= kb) {
      return '${(fileSize! / kb).toStringAsFixed(1)} KB';
    } else {
      return '$fileSize bytes';
    }
  }

  /// Get image dimensions as string
  String? get dimensionsString {
    if (width == null || height == null) return null;
    return '${width}x$height';
  }

  /// Mark as processed with OCR text
  ReceiptPhoto markProcessed({String? extractedText}) {
    return copyWith(
      isProcessed: true,
      ocrText: extractedText,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        originalFilename,
        storagePath,
        fileSize,
        mimeType,
        width,
        height,
        isProcessed,
        ocrText,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'ReceiptPhoto(id: $id, filename: $originalFilename, size: $formattedFileSize)';
}