import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';

/// Repository interface for export operations
abstract class ExportRepository {
  /// Saves export history to local storage
  ///
  /// [exportHistory] - Export history record to save
  /// Returns Either<Failure, void> indicating success or failure
  Future<Either<Failure, void>> saveExportHistory(ExportHistory exportHistory);

  /// Gets all export history records
  ///
  /// Returns Either<Failure, List<ExportHistory>> with all export records
  Future<Either<Failure, List<ExportHistory>>> getExportHistory();

  /// Gets export history by ID
  ///
  /// [id] - Export history ID
  /// Returns Either<Failure, ExportHistory?> with the export record
  Future<Either<Failure, ExportHistory?>> getExportHistoryById(String id);

  /// Deletes export history by ID
  ///
  /// [id] - Export history ID to delete
  /// Returns Either<Failure, void> indicating success or failure
  Future<Either<Failure, void>> deleteExportHistory(String id);

  /// Clears all export history
  ///
  /// Returns Either<Failure, void> indicating success or failure
  Future<Either<Failure, void>> clearExportHistory();

  /// Gets export history count
  ///
  /// Returns Either<Failure, int> with the number of export records
  Future<Either<Failure, int>> getExportHistoryCount();
}
