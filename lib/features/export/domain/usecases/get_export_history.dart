import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';
import 'package:expense_tracker/features/export/domain/repositories/export_repository.dart';

/// Use case for getting export history
class GetExportHistory {
  final ExportRepository _exportRepository;

  const GetExportHistory({
    required ExportRepository exportRepository,
  }) : _exportRepository = exportRepository;

  /// Executes the get export history operation
  ///
  /// Returns Either<Failure, List<ExportHistory>> with export history
  Future<Either<Failure, List<ExportHistory>>> call() async {
    try {
      return await _exportRepository.getExportHistory();
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
