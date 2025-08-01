import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../repositories/filter_repository.dart';

/// Use case for searching expenses by text query.
/// This encapsulates the business logic for text-based expense search.
class SearchExpenses {
  final FilterRepository repository;

  SearchExpenses(this.repository);

  /// Search expenses by text query.
  /// Returns a list of expenses that match the search query in title or description.
  Future<Either<Failure, List<Expense>>> call(String query) async {
    if (query.trim().isEmpty) {
      // Return empty list for empty queries
      return const Right([]);
    }
    return await repository.searchByText(query);
  }
}
