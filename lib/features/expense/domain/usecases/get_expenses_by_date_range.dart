import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpensesByDateRange {
  final ExpenseRepository repository;

  GetExpensesByDateRange(this.repository);

  Future<Either<Failure, List<Expense>>> call(
    DateTime start,
    DateTime end,
  ) async {
    return await repository.getExpensesByDateRange(start, end);
  }
}
