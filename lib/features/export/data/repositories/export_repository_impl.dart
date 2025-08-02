import 'package:dartz/dartz.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:expense_tracker/core/errors/failures.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';
import 'package:expense_tracker/features/export/domain/repositories/export_repository.dart';

/// Implementation of ExportRepository using Hive database
class ExportRepositoryImpl implements ExportRepository {
  static const String _boxName = 'export_history';
  late Box<ExportHistory> _box;

  /// Initializes the Hive box for export history
  Future<void> _initBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<ExportHistory>(_boxName);
    } else {
      _box = Hive.box<ExportHistory>(_boxName);
    }
  }

  @override
  Future<Either<Failure, void>> saveExportHistory(
      ExportHistory exportHistory) async {
    try {
      await _initBox();
      await _box.put(exportHistory.id, exportHistory);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ExportHistory>>> getExportHistory() async {
    try {
      await _initBox();
      final exportHistory = _box.values.toList();
      // Sort by timestamp, newest first
      exportHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Right(exportHistory);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExportHistory?>> getExportHistoryById(
      String id) async {
    try {
      await _initBox();
      final exportHistory = _box.get(id);
      return Right(exportHistory);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExportHistory(String id) async {
    try {
      await _initBox();
      await _box.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearExportHistory() async {
    try {
      await _initBox();
      await _box.clear();
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getExportHistoryCount() async {
    try {
      await _initBox();
      final count = _box.length;
      return Right(count);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
