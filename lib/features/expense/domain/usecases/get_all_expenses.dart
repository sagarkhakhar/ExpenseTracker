import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetAllExpenses {
  final ExpenseRepository repository;

  GetAllExpenses(this.repository);

  Future<Either<Failure, List<Expense>>> call() async {
    return await repository.getAllExpenses();
  }
}
