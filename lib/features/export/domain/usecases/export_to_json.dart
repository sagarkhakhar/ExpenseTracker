import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';
import 'package:expense_tracker/features/export/domain/repositories/export_repository.dart';
import 'package:expense_tracker/features/export/domain/services/export_service.dart';

/// Use case for exporting expenses to JSON format
class ExportToJson {
  final ExportService _exportService;
  final ExportRepository _exportRepository;

  const ExportToJson({
    required ExportService exportService,
    required ExportRepository exportRepository,
  })  : _exportService = exportService,
        _exportRepository = exportRepository;

  /// Executes the JSON export operation
  ///
  /// [expenses] - List of expenses to export
  /// Returns Either<Failure, ExportHistory> with export result
  Future<Either<Failure, ExportHistory>> call(List<Expense> expenses) async {
    try {
      // Export to JSON using the service
      final exportHistory = await _exportService.exportToJson(expenses);

      // Save export history to repository
      final saveResult =
          await _exportRepository.saveExportHistory(exportHistory);

      return saveResult.fold(
        (failure) => Left(failure),
        (_) => Right(exportHistory),
      );
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
