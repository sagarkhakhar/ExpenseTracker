import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/filter_criteria.dart';
import '../entities/search_result.dart';
import '../repositories/filter_repository.dart';

/// Use case for applying filters to expenses.
/// This encapsulates the business logic for filtering expenses based on criteria.
class ApplyFilters {
  final FilterRepository repository;

  ApplyFilters(this.repository);

  /// Apply filter criteria to expenses and return search results.
  /// Returns a SearchResult with filtered expenses and metadata.
  Future<Either<Failure, SearchResult>> call(
      FilterCriteria filterCriteria) async {
    return await repository.searchExpenses(filterCriteria);
  }
}
