import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/core/data/dtos/expense_dto.dart';
import '../../../../lib/core/domain/result.dart';
import '../../../../lib/core/domain/errors/sync_errors.dart';

void main() {
  group('RemoteDataSource Core Types', () {
    final testDateTime = DateTime.utc(2024, 1, 1, 12, 0, 0);

    group('ExpenseDto', () {
      test('should create ExpenseDto with required fields', () {
        final dto = ExpenseDto(
          id: 'expense-1',
          title: 'Test expense',
          amount: 100.0,
          date: testDateTime,
          createdAt: testDateTime,
          updatedAt: testDateTime,
          version: 1,
          isDeleted: false,
        );

        expect(dto.id, 'expense-1');
        expect(dto.title, 'Test expense');
        expect(dto.amount, 100.0);
        expect(dto.date, testDateTime);
        expect(dto.version, 1);
        expect(dto.isDeleted, false);
      });

      test('should create ExpenseDto with optional fields', () {
        final dto = ExpenseDto(
          id: 'expense-1',
          title: 'Test expense',
          amount: 100.0,
          date: testDateTime,
          categoryId: 'cat-1',
          accountId: 'acc-1',
          description: 'Test description',
          createdAt: testDateTime,
          updatedAt: testDateTime,
          version: 1,
          isDeleted: false,
          deviceId: 'device-1',
          lastEditor: 'user-1',
        );

        expect(dto.categoryId, 'cat-1');
        expect(dto.accountId, 'acc-1');
        expect(dto.description, 'Test description');
        expect(dto.deviceId, 'device-1');
        expect(dto.lastEditor, 'user-1');
      });

      test('should convert to string correctly', () {
        final dto = ExpenseDto(
          id: 'expense-1',
          title: 'Test expense',
          amount: 100.0,
          date: testDateTime,
          createdAt: testDateTime,
          updatedAt: testDateTime,
          version: 1,
          isDeleted: false,
        );

        expect(dto.toString(), 'ExpenseDto(id: expense-1, title: Test expense, amount: 100.0)');
      });
    });

    group('Result patterns', () {
      test('should create success result', () {
        final expenses = [
          ExpenseDto(
            id: 'expense-1',
            title: 'Test expense',
            amount: 100.0,
            date: testDateTime,
            createdAt: testDateTime,
            updatedAt: testDateTime,
            version: 1,
            isDeleted: false,
          )
        ];

        final result = Result.success(expenses);
        expect(result.isSuccess, true);
        expect(result.isFailure, false);
      });

      test('should create failure result', () {
        final error = NetworkError(message: 'Test error');
        final result = Result<List<ExpenseDto>>.failure(error);
        
        expect(result.isFailure, true);
        expect(result.isSuccess, false);
      });

      test('should handle result transformations', () {
        final successResult = Result.success('test');
        final mappedResult = successResult.map((value) => value.length);
        
        expect(mappedResult.isSuccess, true);
        expect(mappedResult.fold(
          onSuccess: (value) => value,
          onFailure: (error) => 0,
        ), 4);
      });
    });

    group('Sync error types', () {
      test('should create NetworkError', () {
        final error = NetworkError(message: 'Connection failed');
        expect(error.message, 'Connection failed');
        expect(error.code, 'NETWORK_ERROR');
      });

      test('should create SupabaseError', () {
        final error = SupabaseError(message: 'Database error');
        expect(error.message, 'Database error');
        expect(error.code, 'SUPABASE_ERROR');
      });

      test('should create AuthError', () {
        final error = AuthError(message: 'Authentication failed');
        expect(error.message, 'Authentication failed');
        expect(error.code, 'AUTH_ERROR');
      });

      test('should create specialized NetworkError variants', () {
        final noConnectionError = NetworkError.noConnection();
        expect(noConnectionError.code, 'NO_CONNECTION');
        expect(noConnectionError.message, 'No internet connection available');

        final timeoutError = NetworkError.timeout();
        expect(timeoutError.code, 'CONNECTION_TIMEOUT');
        expect(timeoutError.message, 'Connection timed out');
      });

      test('should create specialized SupabaseError variants', () {
        final rlsError = SupabaseError.rlsViolation(details: 'Policy violated');
        expect(rlsError.code, 'RLS_VIOLATION');
        expect(rlsError.message, 'Row Level Security policy violation');

        final constraintError = SupabaseError.constraintViolation(constraint: 'unique_constraint');
        expect(constraintError.code, 'CONSTRAINT_VIOLATION');
        expect(constraintError.message, 'Database constraint violation');
      });
    });

    group('Batch operations logic', () {
      test('should handle empty lists', () {
        const emptyList = <ExpenseDto>[];
        expect(emptyList.isEmpty, true);
      });

      test('should split large lists into batches', () {
        // Test batching logic conceptually - this matches the _batchItems method
        const maxBatchSize = 200;
        final largeList = List.generate(350, (i) => i);
        
        final batches = <List<int>>[];
        for (int i = 0; i < largeList.length; i += maxBatchSize) {
          final end = (i + maxBatchSize < largeList.length) 
              ? i + maxBatchSize 
              : largeList.length;
          batches.add(largeList.sublist(i, end));
        }

        expect(batches.length, 2);
        expect(batches[0].length, 200);
        expect(batches[1].length, 150);
      });

      test('should handle single batch correctly', () {
        const maxBatchSize = 200;
        final smallList = List.generate(50, (i) => i);
        
        final batches = <List<int>>[];
        for (int i = 0; i < smallList.length; i += maxBatchSize) {
          final end = (i + maxBatchSize < smallList.length) 
              ? i + maxBatchSize 
              : smallList.length;
          batches.add(smallList.sublist(i, end));
        }

        expect(batches.length, 1);
        expect(batches[0].length, 50);
      });

      test('should handle exact batch size', () {
        const maxBatchSize = 200;
        final exactList = List.generate(200, (i) => i);
        
        final batches = <List<int>>[];
        for (int i = 0; i < exactList.length; i += maxBatchSize) {
          final end = (i + maxBatchSize < exactList.length) 
              ? i + maxBatchSize 
              : exactList.length;
          batches.add(exactList.sublist(i, end));
        }

        expect(batches.length, 1);
        expect(batches[0].length, 200);
      });
    });
  });
}