import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/export/domain/entities/export_history.dart';
import 'package:expense_tracker/features/export/domain/usecases/export_to_csv.dart';
import 'package:expense_tracker/features/export/domain/usecases/export_to_json.dart';
import 'package:expense_tracker/features/export/domain/usecases/get_export_history.dart';
import 'package:expense_tracker/features/export/domain/services/export_service.dart';
import 'package:expense_tracker/features/export/data/repositories/export_repository_impl.dart';

// Providers for dependencies
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

final exportRepositoryProvider = Provider<ExportRepositoryImpl>((ref) {
  return ExportRepositoryImpl();
});

// Use case providers
final exportToCsvProvider = Provider<ExportToCsv>((ref) {
  return ExportToCsv(
    exportService: ref.watch(exportServiceProvider),
    exportRepository: ref.watch(exportRepositoryProvider),
  );
});

final exportToJsonProvider = Provider<ExportToJson>((ref) {
  return ExportToJson(
    exportService: ref.watch(exportServiceProvider),
    exportRepository: ref.watch(exportRepositoryProvider),
  );
});

final getExportHistoryProvider = Provider<GetExportHistory>((ref) {
  return GetExportHistory(
    exportRepository: ref.watch(exportRepositoryProvider),
  );
});

// State providers
final exportHistoryProvider = FutureProvider<List<ExportHistory>>((ref) async {
  final getExportHistory = ref.watch(getExportHistoryProvider);
  final result = await getExportHistory();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (exportHistory) => exportHistory,
  );
});

// Export state provider
final exportStateProvider =
    StateNotifierProvider<ExportStateNotifier, ExportState>((ref) {
  return ExportStateNotifier(
    exportToCsv: ref.watch(exportToCsvProvider),
    exportToJson: ref.watch(exportToJsonProvider),
  );
});

/// State class for export operations
class ExportState {
  final bool isExporting;
  final String? error;
  final ExportHistory? lastExport;

  const ExportState({
    this.isExporting = false,
    this.error,
    this.lastExport,
  });

  ExportState copyWith({
    bool? isExporting,
    String? error,
    ExportHistory? lastExport,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      error: error ?? this.error,
      lastExport: lastExport ?? this.lastExport,
    );
  }
}

/// State notifier for export operations
class ExportStateNotifier extends StateNotifier<ExportState> {
  final ExportToCsv _exportToCsv;
  final ExportToJson _exportToJson;

  ExportStateNotifier({
    required ExportToCsv exportToCsv,
    required ExportToJson exportToJson,
  })  : _exportToCsv = exportToCsv,
        _exportToJson = exportToJson,
        super(const ExportState());

  /// Export expenses to CSV format
  Future<void> exportToCsv(List<Expense> expenses) async {
    state = state.copyWith(isExporting: true, error: null);

    try {
      final result = await _exportToCsv(expenses);
      result.fold(
        (failure) {
          state = state.copyWith(
            isExporting: false,
            error: failure.message,
          );
        },
        (exportHistory) {
          state = state.copyWith(
            isExporting: false,
            lastExport: exportHistory,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
    }
  }

  /// Export expenses to JSON format
  Future<void> exportToJson(List<Expense> expenses) async {
    state = state.copyWith(isExporting: true, error: null);

    try {
      final result = await _exportToJson(expenses);
      result.fold(
        (failure) {
          state = state.copyWith(
            isExporting: false,
            error: failure.message,
          );
        },
        (exportHistory) {
          state = state.copyWith(
            isExporting: false,
            lastExport: exportHistory,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
      );
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear last export
  void clearLastExport() {
    state = state.copyWith(lastExport: null);
  }
}
