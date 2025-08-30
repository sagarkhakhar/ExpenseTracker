import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/features/expense/data/models/expense_model.dart';
import 'package:expense_tracker/features/expense/data/datasources/expense_local_data_source_impl.dart';
import 'package:expense_tracker/features/expense/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/expense/domain/usecases/create_expense.dart';
import 'package:expense_tracker/features/expense/domain/usecases/get_all_expenses.dart';
import 'package:expense_tracker/features/expense/domain/usecases/update_expense.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Expense CRUD Integration Tests', () {
    late ExpenseLocalDataSourceImpl dataSource;
    late ExpenseRepositoryImpl repository;
    late CreateExpense createExpenseUseCase;
    late GetAllExpenses getAllExpensesUseCase;
    late UpdateExpense updateExpenseUseCase;

    setUpAll(() async {
      // Initialize Hive for testing
      const MethodChannel('plugins.flutter.io/path_provider')
          .setMockMethodCallHandler((MethodCall methodCall) async {
        return '.';
      });
      
      Hive.init('.');
      
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(ExpenseModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ExpenseTypeAdapter());
      }
    });

    setUp(() async {
      // Delete any existing test box
      try {
        await Hive.deleteBoxFromDisk('test_expenses');
      } catch (e) {
        // Box might not exist, ignore
      }

      // Initialize data source with test box
      dataSource = ExpenseLocalDataSourceImpl();
      // Override box name for testing
      await dataSource.init();
      
      // Clear any existing data
      await dataSource.clearAllExpenses();

      // Initialize repository and use cases
      repository = ExpenseRepositoryImpl(dataSource);
      createExpenseUseCase = CreateExpense(repository);
      getAllExpensesUseCase = GetAllExpenses(repository);
      updateExpenseUseCase = UpdateExpense(repository);
    });

    tearDown(() async {
      // Clean up
      await dataSource.clearAllExpenses();
      try {
        await Hive.box('expenses').close();
      } catch (e) {
        // Box might already be closed
      }
    });

    tearDownAll(() async {
      await Hive.close();
    });

    group('Create Expense Operations', () {
      test('should create expense successfully', () async {
        // Arrange
        const uuid = Uuid();
        final now = DateTime.now();
        final expense = Expense(
          id: uuid.v4(),
          title: 'Test Expense',
          description: 'Integration test expense',
          amount: 100.0,
          category: 'food',
          type: ExpenseType.expense,
          date: now,
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final result = await createExpenseUseCase(expense);

        // Assert
        expect(result.isRight(), true);
        
        // Verify expense was stored
        final allExpensesResult = await getAllExpensesUseCase();
        expect(allExpensesResult.isRight(), true);
        
        allExpensesResult.fold(
          (failure) => fail('Should not fail'),
          (expenses) {
            expect(expenses.length, 1);
            expect(expenses.first.id, expense.id);
            expect(expenses.first.title, expense.title);
            expect(expenses.first.amount, expense.amount);
          },
        );
      });

      test('should create income successfully', () async {
        // Arrange
        const uuid = Uuid();
        final now = DateTime.now();
        final income = Expense(
          id: uuid.v4(),
          title: 'Test Income',
          description: 'Integration test income',
          amount: 500.0,
          category: 'salary',
          type: ExpenseType.income,
          date: now,
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final result = await createExpenseUseCase(income);

        // Assert
        expect(result.isRight(), true);
        
        // Verify income was stored
        final allExpensesResult = await getAllExpensesUseCase();
        expect(allExpensesResult.isRight(), true);
        
        allExpensesResult.fold(
          (failure) => fail('Should not fail'),
          (expenses) {
            expect(expenses.length, 1);
            expect(expenses.first.type, ExpenseType.income);
            expect(expenses.first.amount, 500.0);
          },
        );
      });

      test('should reject invalid expense data', () async {
        // Arrange
        const uuid = Uuid();
        final now = DateTime.now();
        final invalidExpense = Expense(
          id: uuid.v4(),
          title: '', // Empty title should fail validation
          description: 'Test description',
          amount: 100.0,
          category: 'food',
          type: ExpenseType.expense,
          date: now,
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final result = await createExpenseUseCase(invalidExpense);

        // Assert
        expect(result.isLeft(), true);
        
        // Verify no expense was stored
        final allExpensesResult = await getAllExpensesUseCase();
        allExpensesResult.fold(
          (failure) => fail('Should not fail to get expenses'),
          (expenses) => expect(expenses.length, 0),
        );
      });

      test('should reject negative amounts', () async {
        // Arrange
        const uuid = Uuid();
        final now = DateTime.now();
        final invalidExpense = Expense(
          id: uuid.v4(),
          title: 'Test Expense',
          description: 'Test description',
          amount: -50.0, // Negative amount should fail
          category: 'food',
          type: ExpenseType.expense,
          date: now,
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final result = await createExpenseUseCase(invalidExpense);

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('Read Expense Operations', () {
      test('should retrieve all expenses', () async {
        // Arrange - Create multiple expenses
        const uuid = Uuid();
        final now = DateTime.now();
        
        final expenses = [
          Expense(
            id: uuid.v4(),
            title: 'Expense 1',
            description: 'First expense',
            amount: 100.0,
            category: 'food',
            type: ExpenseType.expense,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
          Expense(
            id: uuid.v4(),
            title: 'Income 1',
            description: 'First income',
            amount: 200.0,
            category: 'salary',
            type: ExpenseType.income,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
          Expense(
            id: uuid.v4(),
            title: 'Expense 2',
            description: 'Second expense',
            amount: 50.0,
            category: 'transport',
            type: ExpenseType.expense,
            date: now,
            createdAt: now,
            updatedAt: now,
          ),
        ];

        // Create all expenses
        for (final expense in expenses) {
          await createExpenseUseCase(expense);
        }

        // Act
        final result = await getAllExpensesUseCase();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (retrievedExpenses) {
            expect(retrievedExpenses.length, 3);
            
            // Verify all expenses are present
            final expenseIds = retrievedExpenses.map((e) => e.id).toSet();
            for (final originalExpense in expenses) {
              expect(expenseIds.contains(originalExpense.id), true);
            }
          },
        );
      });

      test('should return empty list when no expenses exist', () async {
        // Act
        final result = await getAllExpensesUseCase();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (expenses) => expect(expenses.length, 0),
        );
      });
    });

    group('Update Expense Operations', () {
      late Expense originalExpense;

      setUp(() async {
        // Create an expense to update
        const uuid = Uuid();
        final now = DateTime.now();
        originalExpense = Expense(
          id: uuid.v4(),
          title: 'Original Title',
          description: 'Original description',
          amount: 100.0,
          category: 'food',
          type: ExpenseType.expense,
          date: now,
          createdAt: now,
          updatedAt: now,
        );

        await createExpenseUseCase(originalExpense);
      });

      test('should update expense successfully', () async {
        // Arrange
        final updatedExpense = Expense(
          id: originalExpense.id,
          title: 'Updated Title',
          description: 'Updated description',
          amount: 150.0,
          category: 'entertainment',
          type: ExpenseType.expense,
          date: originalExpense.date,
          createdAt: originalExpense.createdAt,
          updatedAt: DateTime.now(),
        );

        // Act
        final result = await updateExpenseUseCase(updatedExpense);

        // Assert
        expect(result.isRight(), true);
        
        // Verify expense was updated
        final allExpensesResult = await getAllExpensesUseCase();
        allExpensesResult.fold(
          (failure) => fail('Should not fail'),
          (expenses) {
            expect(expenses.length, 1);
            final expense = expenses.first;
            expect(expense.id, originalExpense.id);
            expect(expense.title, 'Updated Title');
            expect(expense.description, 'Updated description');
            expect(expense.amount, 150.0);
            expect(expense.category, 'entertainment');
          },
        );
      });

      test('should reject invalid update data', () async {
        // Arrange
        final invalidUpdate = Expense(
          id: originalExpense.id,
          title: '', // Empty title should fail
          description: 'Updated description',
          amount: 150.0,
          category: 'entertainment',
          type: ExpenseType.expense,
          date: originalExpense.date,
          createdAt: originalExpense.createdAt,
          updatedAt: DateTime.now(),
        );

        // Act
        final result = await updateExpenseUseCase(invalidUpdate);

        // Assert
        expect(result.isLeft(), true);
        
        // Verify original expense is unchanged
        final allExpensesResult = await getAllExpensesUseCase();
        allExpensesResult.fold(
          (failure) => fail('Should not fail'),
          (expenses) {
            expect(expenses.length, 1);
            expect(expenses.first.title, 'Original Title');
          },
        );
      });
    });

    group('Delete Expense Operations', () {
      late Expense expenseToDelete;

      setUp(() async {
        // Create an expense to delete
        const uuid = Uuid();
        final now = DateTime.now();
        expenseToDelete = Expense(
          id: uuid.v4(),
          title: 'To Delete',
          description: 'This will be deleted',
          amount: 100.0,
          category: 'food',
          type: ExpenseType.expense,
          date: now,
          createdAt: now,
          updatedAt: now,
        );

        await createExpenseUseCase(expenseToDelete);
      });

      test('should delete expense successfully', () async {
        // Act
        final result = await repository.deleteExpense(expenseToDelete.id);

        // Assert
        expect(result.isRight(), true);
        
        // Verify expense was deleted
        final allExpensesResult = await getAllExpensesUseCase();
        allExpensesResult.fold(
          (failure) => fail('Should not fail'),
          (expenses) => expect(expenses.length, 0),
        );
      });

      test('should handle deleting non-existent expense', () async {
        // Arrange
        const nonExistentId = 'non-existent-id';

        // Act
        final result = await repository.deleteExpense(nonExistentId);

        // Assert
        expect(result.isLeft(), true);
        
        // Verify original expense is still there
        final allExpensesResult = await getAllExpensesUseCase();
        allExpensesResult.fold(
          (failure) => fail('Should not fail'),
          (expenses) => expect(expenses.length, 1),
        );
      });
    });

    group('Complex Scenarios', () {
      test('should handle multiple concurrent operations', () async {
        // Arrange
        const uuid = Uuid();
        final now = DateTime.now();
        
        final expenses = List.generate(10, (index) => Expense(
          id: uuid.v4(),
          title: 'Expense $index',
          description: 'Test expense $index',
          amount: (index + 1) * 10.0,
          category: index % 2 == 0 ? 'food' : 'transport',
          type: ExpenseType.expense,
          date: now.add(Duration(days: index)),
          createdAt: now,
          updatedAt: now,
        ));

        // Act - Create multiple expenses concurrently
        final futures = expenses.map((expense) => createExpenseUseCase(expense)).toList();
        final results = await Future.wait(futures);

        // Assert
        for (final result in results) {
          expect(result.isRight(), true);
        }

        // Verify all expenses were created
        final allExpensesResult = await getAllExpensesUseCase();
        allExpensesResult.fold(
          (failure) => fail('Should not fail'),
          (retrievedExpenses) => expect(retrievedExpenses.length, 10),
        );
      });

      test('should handle large amounts correctly', () async {
        // Arrange
        const uuid = Uuid();
        final now = DateTime.now();
        final expenseWithLargeAmount = Expense(
          id: uuid.v4(),
          title: 'Large Amount',
          description: 'Expensive item',
          amount: 999999.99,
          category: 'shopping',
          type: ExpenseType.expense,
          date: now,
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final result = await createExpenseUseCase(expenseWithLargeAmount);

        // Assert
        expect(result.isRight(), true);
        
        final allExpensesResult = await getAllExpensesUseCase();
        allExpensesResult.fold(
          (failure) => fail('Should not fail'),
          (expenses) {
            expect(expenses.length, 1);
            expect(expenses.first.amount, 999999.99);
          },
        );
      });

      test('should handle special characters in text fields', () async {
        // Arrange
        const uuid = Uuid();
        final now = DateTime.now();
        final expenseWithSpecialChars = Expense(
          id: uuid.v4(),
          title: 'Special Chars: àáâãäå æç èéêë ìíîï ñ òóôõö ùúûü ýÿ 🍕💰',
          description: 'Description with quotes "test" and symbols @#\$%^&*()',
          amount: 25.50,
          category: 'food & drinks',
          type: ExpenseType.expense,
          date: now,
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final result = await createExpenseUseCase(expenseWithSpecialChars);

        // Assert
        expect(result.isRight(), true);
        
        final allExpensesResult = await getAllExpensesUseCase();
        allExpensesResult.fold(
          (failure) => fail('Should not fail'),
          (expenses) {
            expect(expenses.length, 1);
            expect(expenses.first.title, contains('🍕💰'));
            expect(expenses.first.description, contains('"test"'));
            expect(expenses.first.category, 'food & drinks');
          },
        );
      });
    });
  });
}