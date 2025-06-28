import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class CreateExpense {
  final ExpenseRepository repository;

  CreateExpense(this.repository);

  Future<Either<Failure, Expense>> call(Expense expense) async {
    return await repository.createExpense(expense);
  }
}
