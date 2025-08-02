import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'export_history.g.dart';

@HiveType(typeId: 12)
enum ExportFormat {
  @HiveField(0)
  csv,
  @HiveField(1)
  json,
}

@HiveType(typeId: 13)
enum ExportStatus {
  @HiveField(0)
  inProgress,
  @HiveField(1)
  success,
  @HiveField(2)
  failed,
}

@HiveType(typeId: 14)
class ExportHistory extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final ExportFormat format;

  @HiveField(3)
  final String fileName;

  @HiveField(4)
  final int fileSize;

  @HiveField(5)
  final int recordCount;

  @HiveField(6)
  final ExportStatus status;

  @HiveField(7)
  final String? errorMessage;

  const ExportHistory({
    required this.id,
    required this.timestamp,
    required this.format,
    required this.fileName,
    required this.fileSize,
    required this.recordCount,
    required this.status,
    this.errorMessage,
  });

  ExportHistory copyWith({
    String? id,
    DateTime? timestamp,
    ExportFormat? format,
    String? fileName,
    int? fileSize,
    int? recordCount,
    ExportStatus? status,
    String? errorMessage,
  }) {
    return ExportHistory(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      format: format ?? this.format,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      recordCount: recordCount ?? this.recordCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        format,
        fileName,
        fileSize,
        recordCount,
        status,
        errorMessage,
      ];
}
