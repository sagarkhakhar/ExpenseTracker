import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/data/dtos/expense_dto.dart';
import 'package:expense_tracker/core/domain/entities/sync_expense.dart';
import 'package:expense_tracker/features/expense/domain/entities/expense.dart';

void main() {
  group('ExpenseDto', () {
    late Map<String, dynamic> sampleJson;
    late ExpenseDto sampleDto;
    late SyncExpense sampleSyncExpense;

    setUp(() {
      sampleJson = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'title': 'Test Expense',
        'amount': 25.99,
        'date': '2024-01-15T00:00:00.000Z',
        'category_id': 'cat123',
        'account_id': 'acc456',
        'description': 'Test Description',
        'receipt_photo_id': 'photo789',
        'created_at': '2024-01-15T10:00:00.000Z',
        'updated_at': '2024-01-15T10:30:00.000Z',
        'version': 1,
        'is_deleted': false,
        'device_id': 'device123',
        'last_editor': 'user123',
      };

      sampleDto = ExpenseDto(
        id: '987fcdeb-51a2-43d1-9f3e-123456789abc',
        title: 'Sample DTO',
        amount: 35.50,
        date: DateTime(2024, 2, 20),
        categoryId: 'catDto',
        accountId: 'accDto',
        description: 'Sample DTO Description',
        receiptPhotoId: 'photoDto',
        createdAt: DateTime(2024, 2, 20, 14, 0),
        updatedAt: DateTime(2024, 2, 20, 14, 30),
        version: 2,
        isDeleted: false,
        deviceId: 'deviceDto',
        lastEditor: 'userDto',
      );

      sampleSyncExpense = SyncExpense.create(
        title: 'Sample Sync',
        description: 'Sample Sync Description',
        amount: 45.75,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime(2024, 3, 25),
        deviceId: 'syncDevice',
        lastEditor: 'syncUser',
        accountId: 'syncAccount',
        categoryId: 'syncCategory',
        receiptPhotoId: 'syncPhoto',
      );
    });

    group('JSON Serialization', () {
      test('should create ExpenseDto from JSON correctly', () {
        final dto = ExpenseDto.fromJson(sampleJson);

        expect(dto.id, equals(sampleJson['id']));
        expect(dto.title, equals(sampleJson['title']));
        expect(dto.amount, equals(sampleJson['amount']));
        expect(dto.date, equals(DateTime.parse(sampleJson['date'])));
        expect(dto.categoryId, equals(sampleJson['category_id']));
        expect(dto.accountId, equals(sampleJson['account_id']));
        expect(dto.description, equals(sampleJson['description']));
        expect(dto.receiptPhotoId, equals(sampleJson['receipt_photo_id']));
        expect(dto.createdAt, equals(DateTime.parse(sampleJson['created_at'])));
        expect(dto.updatedAt, equals(DateTime.parse(sampleJson['updated_at'])));
        expect(dto.version, equals(sampleJson['version']));
        expect(dto.isDeleted, equals(sampleJson['is_deleted']));
        expect(dto.deviceId, equals(sampleJson['device_id']));
        expect(dto.lastEditor, equals(sampleJson['last_editor']));
      });

      test('should convert ExpenseDto to JSON correctly', () {
        final json = sampleDto.toJson();

        expect(json['id'], equals(sampleDto.id));
        expect(json['title'], equals(sampleDto.title));
        expect(json['amount'], equals(sampleDto.amount));
        expect(json['date'], equals(sampleDto.date.toIso8601String()));
        expect(json['category_id'], equals(sampleDto.categoryId));
        expect(json['account_id'], equals(sampleDto.accountId));
        expect(json['description'], equals(sampleDto.description));
        expect(json['receipt_photo_id'], equals(sampleDto.receiptPhotoId));
        expect(json['created_at'], equals(sampleDto.createdAt.toIso8601String()));
        expect(json['updated_at'], equals(sampleDto.updatedAt.toIso8601String()));
        expect(json['version'], equals(sampleDto.version));
        expect(json['is_deleted'], equals(sampleDto.isDeleted));
        expect(json['device_id'], equals(sampleDto.deviceId));
        expect(json['last_editor'], equals(sampleDto.lastEditor));
      });

      test('should handle null values in JSON correctly', () {
        final jsonWithNulls = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'title': 'Minimal Expense',
          'amount': 10.0,
          'date': '2024-01-01T00:00:00.000Z',
          'category_id': null,
          'account_id': null,
          'description': null,
          'receipt_photo_id': null,
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-01T00:00:00.000Z',
          'version': 1,
          'is_deleted': false,
          'device_id': null,
          'last_editor': null,
        };

        final dto = ExpenseDto.fromJson(jsonWithNulls);

        expect(dto.categoryId, isNull);
        expect(dto.accountId, isNull);
        expect(dto.description, isNull);
        expect(dto.receiptPhotoId, isNull);
        expect(dto.deviceId, isNull);
        expect(dto.lastEditor, isNull);
      });

      test('should handle round-trip JSON serialization without data loss', () {
        final originalJson = sampleDto.toJson();
        final recreatedDto = ExpenseDto.fromJson(originalJson);
        final finalJson = recreatedDto.toJson();

        expect(finalJson['id'], equals(originalJson['id']));
        expect(finalJson['title'], equals(originalJson['title']));
        expect(finalJson['amount'], equals(originalJson['amount']));
        expect(finalJson['version'], equals(originalJson['version']));
        expect(finalJson['is_deleted'], equals(originalJson['is_deleted']));
      });
    });

    group('Entity Conversion', () {
      test('should create ExpenseDto from SyncExpense correctly', () {
        final dto = ExpenseDto.fromEntity(sampleSyncExpense);

        expect(dto.id, equals(sampleSyncExpense.id));
        expect(dto.title, equals(sampleSyncExpense.title));
        expect(dto.amount, equals(sampleSyncExpense.amount));
        expect(dto.date, equals(sampleSyncExpense.date));
        expect(dto.description, equals(sampleSyncExpense.description));
        expect(dto.categoryId, equals(sampleSyncExpense.categoryId));
        expect(dto.accountId, equals(sampleSyncExpense.accountId));
        expect(dto.receiptPhotoId, equals(sampleSyncExpense.receiptPhotoId));
        expect(dto.createdAt, equals(sampleSyncExpense.createdAt));
        expect(dto.updatedAt, equals(sampleSyncExpense.updatedAt));
        expect(dto.version, equals(sampleSyncExpense.version));
        expect(dto.isDeleted, equals(sampleSyncExpense.isDeleted));
        expect(dto.deviceId, equals(sampleSyncExpense.deviceId));
        expect(dto.lastEditor, equals(sampleSyncExpense.lastEditor));
      });

      test('should convert ExpenseDto to SyncExpense correctly', () {
        final entity = sampleDto.toEntity();

        expect(entity.id, equals(sampleDto.id));
        expect(entity.title, equals(sampleDto.title));
        expect(entity.amount, equals(sampleDto.amount));
        expect(entity.date, equals(sampleDto.date));
        expect(entity.description, equals(sampleDto.description));
        expect(entity.categoryId, equals(sampleDto.categoryId));
        expect(entity.accountId, equals(sampleDto.accountId));
        expect(entity.receiptPhotoId, equals(sampleDto.receiptPhotoId));
        expect(entity.createdAt, equals(sampleDto.createdAt));
        expect(entity.updatedAt, equals(sampleDto.updatedAt));
        expect(entity.version, equals(sampleDto.version));
        expect(entity.isDeleted, equals(sampleDto.isDeleted));
        expect(entity.deviceId, equals(sampleDto.deviceId));
        expect(entity.lastEditor, equals(sampleDto.lastEditor));
      });

      test('should determine expense type correctly based on amount', () {
        // Positive amount should be income
        final positiveDto = sampleDto.copyWith(amount: 100.0);
        final positiveEntity = positiveDto.toEntity();
        expect(positiveEntity.type, equals(ExpenseType.income));

        // Negative amount should be expense
        final negativeDto = sampleDto.copyWith(amount: -50.0);
        final negativeEntity = negativeDto.toEntity();
        expect(negativeEntity.type, equals(ExpenseType.expense));

        // Zero amount should be income (by default)
        final zeroDto = sampleDto.copyWith(amount: 0.0);
        final zeroEntity = zeroDto.toEntity();
        expect(zeroEntity.type, equals(ExpenseType.income));
      });

      test('should handle entity round-trip conversion without data loss', () {
        final dto = ExpenseDto.fromEntity(sampleSyncExpense);
        final recreatedEntity = dto.toEntity();

        expect(recreatedEntity.id, equals(sampleSyncExpense.id));
        expect(recreatedEntity.title, equals(sampleSyncExpense.title));
        expect(recreatedEntity.description, equals(sampleSyncExpense.description));
        expect(recreatedEntity.amount, equals(sampleSyncExpense.amount));
        expect(recreatedEntity.date, equals(sampleSyncExpense.date));
        expect(recreatedEntity.categoryId, equals(sampleSyncExpense.categoryId));
        expect(recreatedEntity.accountId, equals(sampleSyncExpense.accountId));
        expect(recreatedEntity.receiptPhotoId, equals(sampleSyncExpense.receiptPhotoId));
        expect(recreatedEntity.version, equals(sampleSyncExpense.version));
        expect(recreatedEntity.isDeleted, equals(sampleSyncExpense.isDeleted));
        expect(recreatedEntity.deviceId, equals(sampleSyncExpense.deviceId));
        expect(recreatedEntity.lastEditor, equals(sampleSyncExpense.lastEditor));
      });
    });

    group('Edge Cases and Validation', () {
      test('should handle minimum required fields', () {
        final minimalJson = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'title': 'Minimal',
          'amount': 1.0,
          'date': '2024-01-01T00:00:00.000Z',
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-01T00:00:00.000Z',
          'version': 1,
          'is_deleted': false,
        };

        expect(() => ExpenseDto.fromJson(minimalJson), returnsNormally);
      });

      test('should have correct toString representation', () {
        final string = sampleDto.toString();
        expect(string, contains('ExpenseDto'));
        expect(string, contains(sampleDto.id));
        expect(string, contains(sampleDto.title));
        expect(string, contains(sampleDto.amount.toString()));
      });

      test('should handle large amounts correctly', () {
        final largeAmountDto = sampleDto.copyWith(amount: 999999.99);
        final json = largeAmountDto.toJson();
        final recreated = ExpenseDto.fromJson(json);
        
        expect(recreated.amount, equals(999999.99));
      });

      test('should handle very old and future dates correctly', () {
        final oldDate = DateTime(1900, 1, 1);
        final futureDate = DateTime(2100, 12, 31);
        
        final oldDto = sampleDto.copyWith(date: oldDate);
        final futureDto = sampleDto.copyWith(date: futureDate);
        
        expect(() => oldDto.toJson(), returnsNormally);
        expect(() => futureDto.toJson(), returnsNormally);
        
        final oldJson = oldDto.toJson();
        final futureJson = futureDto.toJson();
        
        expect(ExpenseDto.fromJson(oldJson).date, equals(oldDate));
        expect(ExpenseDto.fromJson(futureJson).date, equals(futureDate));
      });
    });
  });
}

extension on ExpenseDto {
    ExpenseDto copyWith({
      String? id,
      String? title,
      double? amount,
      DateTime? date,
      String? categoryId,
      String? accountId,
      String? description,
      String? receiptPhotoId,
      DateTime? createdAt,
      DateTime? updatedAt,
      int? version,
      bool? isDeleted,
      String? deviceId,
      String? lastEditor,
    }) {
      return ExpenseDto(
        id: id ?? this.id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        categoryId: categoryId ?? this.categoryId,
        accountId: accountId ?? this.accountId,
        description: description ?? this.description,
        receiptPhotoId: receiptPhotoId ?? this.receiptPhotoId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        version: version ?? this.version,
        isDeleted: isDeleted ?? this.isDeleted,
        deviceId: deviceId ?? this.deviceId,
        lastEditor: lastEditor ?? this.lastEditor,
      );
    }
}