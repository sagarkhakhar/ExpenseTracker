import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/data/mappers/sync_mapper.dart';
import 'package:expense_tracker/core/domain/entities/sync_expense.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';
import 'package:expense_tracker/core/data/dtos/expense_dto.dart';

void main() {
  group('SyncMapper', () {
    late Expense sampleExpense;
    late SyncExpense sampleSyncExpense;
    late ExpenseDto sampleExpenseDto;

    setUp(() {
      sampleExpense = Expense(
        id: '123e4567-e89b-12d3-a456-426614174000',
        title: 'Test Expense',
        description: 'Test Description',
        amount: 25.99,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime(2024, 1, 15),
        createdAt: DateTime(2024, 1, 15, 10, 0),
        updatedAt: DateTime(2024, 1, 15, 10, 30),
        metadata: const {'source': 'test'},
        isRecurring: false,
      );

      sampleSyncExpense = SyncExpense.create(
        title: 'Test Sync Expense',
        description: 'Test Sync Description',
        amount: 35.99,
        category: 'Shopping',
        type: ExpenseType.expense,
        date: DateTime(2024, 2, 15),
        deviceId: 'device123',
        lastEditor: 'user123',
        accountId: 'account456',
        categoryId: 'category789',
      );

      sampleExpenseDto = ExpenseDto(
        id: '987fcdeb-51a2-43d1-9f3e-123456789abc',
        title: 'Test DTO Expense',
        amount: 45.99,
        date: DateTime(2024, 3, 15),
        description: 'Test DTO Description',
        createdAt: DateTime(2024, 3, 15, 9, 0),
        updatedAt: DateTime(2024, 3, 15, 9, 30),
        version: 1,
        isDeleted: false,
        categoryId: 'cat123',
        accountId: 'acc456',
        deviceId: 'device789',
        lastEditor: 'user789',
      );
    });

    group('Expense Mappings', () {
      test('should convert legacy Expense to SyncExpense correctly', () {
        final result = SyncMapper.expenseToSync(
          sampleExpense,
          deviceId: 'testDevice',
          lastEditor: 'testUser',
          accountId: 'testAccount',
          categoryId: 'testCategory',
        );

        expect(result.title, equals(sampleExpense.title));
        expect(result.description, equals(sampleExpense.description));
        expect(result.amount, equals(sampleExpense.amount));
        expect(result.category, equals(sampleExpense.category));
        expect(result.type, equals(sampleExpense.type));
        expect(result.date, equals(sampleExpense.date));
        expect(result.deviceId, equals('testDevice'));
        expect(result.lastEditor, equals('testUser'));
        expect(result.accountId, equals('testAccount'));
        expect(result.categoryId, equals('testCategory'));
        expect(result.version, equals(1));
        expect(result.isDeleted, isFalse);
      });

      test('should convert SyncExpense to legacy Expense correctly', () {
        final result = SyncMapper.syncToExpense(sampleSyncExpense);

        expect(result.id, equals(sampleSyncExpense.id));
        expect(result.title, equals(sampleSyncExpense.title));
        expect(result.description, equals(sampleSyncExpense.description));
        expect(result.amount, equals(sampleSyncExpense.amount));
        expect(result.category, equals(sampleSyncExpense.category));
        expect(result.type, equals(sampleSyncExpense.type));
        expect(result.date, equals(sampleSyncExpense.date));
        expect(result.createdAt, equals(sampleSyncExpense.createdAt));
        expect(result.updatedAt, equals(sampleSyncExpense.updatedAt));
      });

      test('should convert SyncExpense to ExpenseDto correctly', () {
        final result = SyncMapper.syncExpenseToDto(sampleSyncExpense);

        expect(result.id, equals(sampleSyncExpense.id));
        expect(result.title, equals(sampleSyncExpense.title));
        expect(result.amount, equals(sampleSyncExpense.amount));
        expect(result.date, equals(sampleSyncExpense.date));
        expect(result.description, equals(sampleSyncExpense.description));
        expect(result.createdAt, equals(sampleSyncExpense.createdAt));
        expect(result.updatedAt, equals(sampleSyncExpense.updatedAt));
        expect(result.version, equals(sampleSyncExpense.version));
        expect(result.isDeleted, equals(sampleSyncExpense.isDeleted));
        expect(result.categoryId, equals(sampleSyncExpense.categoryId));
        expect(result.accountId, equals(sampleSyncExpense.accountId));
        expect(result.deviceId, equals(sampleSyncExpense.deviceId));
        expect(result.lastEditor, equals(sampleSyncExpense.lastEditor));
      });

      test('should convert ExpenseDto to SyncExpense correctly', () {
        final result = SyncMapper.dtoToSyncExpense(sampleExpenseDto);

        expect(result.id, equals(sampleExpenseDto.id));
        expect(result.title, equals(sampleExpenseDto.title));
        expect(result.amount, equals(sampleExpenseDto.amount));
        expect(result.date, equals(sampleExpenseDto.date));
        expect(result.description, equals(sampleExpenseDto.description));
        expect(result.createdAt, equals(sampleExpenseDto.createdAt));
        expect(result.updatedAt, equals(sampleExpenseDto.updatedAt));
        expect(result.version, equals(sampleExpenseDto.version));
        expect(result.isDeleted, equals(sampleExpenseDto.isDeleted));
        expect(result.categoryId, equals(sampleExpenseDto.categoryId));
        expect(result.accountId, equals(sampleExpenseDto.accountId));
        expect(result.deviceId, equals(sampleExpenseDto.deviceId));
        expect(result.lastEditor, equals(sampleExpenseDto.lastEditor));
      });
    });

    group('Batch Operations', () {
      test('should convert list of SyncExpense to list of ExpenseDto', () {
        final expenses = [sampleSyncExpense, sampleSyncExpense];
        final result = SyncMapper.syncExpensesToDtos(expenses);

        expect(result.length, equals(2));
        expect(result[0].id, equals(sampleSyncExpense.id));
        expect(result[1].id, equals(sampleSyncExpense.id));
      });

      test('should convert list of ExpenseDto to list of SyncExpense', () {
        final dtos = [sampleExpenseDto, sampleExpenseDto];
        final result = SyncMapper.dtosToSyncExpenses(dtos);

        expect(result.length, equals(2));
        expect(result[0].id, equals(sampleExpenseDto.id));
        expect(result[1].id, equals(sampleExpenseDto.id));
      });
    });

    group('JSON Conversion Utilities', () {
      test('should convert SyncExpense to JSON correctly', () {
        final result = SyncMapper.expenseToJson(sampleSyncExpense);

        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], equals(sampleSyncExpense.id));
        expect(result['title'], equals(sampleSyncExpense.title));
        expect(result['amount'], equals(sampleSyncExpense.amount));
        expect(result['version'], equals(sampleSyncExpense.version));
        expect(result['is_deleted'], equals(sampleSyncExpense.isDeleted));
      });

      test('should convert JSON to SyncExpense correctly', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'title': 'JSON Expense',
          'amount': 55.99,
          'date': '2024-04-15T00:00:00.000Z',
          'description': 'JSON Description',
          'created_at': '2024-04-15T10:00:00.000Z',
          'updated_at': '2024-04-15T10:30:00.000Z',
          'version': 2,
          'is_deleted': false,
          'category_id': 'jsonCat',
          'account_id': 'jsonAcc',
          'device_id': 'jsonDevice',
          'last_editor': 'jsonUser',
        };

        final result = SyncMapper.expenseFromJson(json);

        expect(result.id, equals(json['id']));
        expect(result.title, equals(json['title']));
        expect(result.amount, equals(json['amount']));
        expect(result.version, equals(json['version']));
        expect(result.isDeleted, equals(json['is_deleted']));
        expect(result.categoryId, equals(json['category_id']));
        expect(result.accountId, equals(json['account_id']));
        expect(result.deviceId, equals(json['device_id']));
        expect(result.lastEditor, equals(json['last_editor']));
      });

      test('should handle round-trip JSON conversion without data loss', () {
        final json = SyncMapper.expenseToJson(sampleSyncExpense);
        final recreated = SyncMapper.expenseFromJson(json);

        expect(recreated.id, equals(sampleSyncExpense.id));
        expect(recreated.title, equals(sampleSyncExpense.title));
        expect(recreated.description, equals(sampleSyncExpense.description));
        expect(recreated.amount, equals(sampleSyncExpense.amount));
        expect(recreated.categoryId, equals(sampleSyncExpense.categoryId));
        expect(recreated.accountId, equals(sampleSyncExpense.accountId));
        expect(recreated.version, equals(sampleSyncExpense.version));
        expect(recreated.isDeleted, equals(sampleSyncExpense.isDeleted));
        expect(recreated.deviceId, equals(sampleSyncExpense.deviceId));
        expect(recreated.lastEditor, equals(sampleSyncExpense.lastEditor));
      });
    });

    group('Edge Cases', () {
      test('should handle null/optional fields correctly in conversion', () {
        final expenseWithNulls = SyncExpense(
          title: 'Minimal Expense',
          description: '',
          amount: 10.0,
          category: 'Other',
          type: ExpenseType.expense,
          date: DateTime(2024, 1, 1),
          id: '123',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          version: 1,
          isDeleted: false,
          // All optional fields are null
        );

        final dto = SyncMapper.syncExpenseToDto(expenseWithNulls);
        final recreated = SyncMapper.dtoToSyncExpense(dto);

        expect(recreated.receiptPhotoId, isNull);
        expect(recreated.accountId, isNull);
        expect(recreated.categoryId, isNull);
        expect(recreated.deviceId, isNull);
        expect(recreated.lastEditor, isNull);
      });

      test('should handle empty lists correctly', () {
        final emptyList = <SyncExpense>[];
        final result = SyncMapper.syncExpensesToDtos(emptyList);
        expect(result, isEmpty);
      });
    });
  });
}