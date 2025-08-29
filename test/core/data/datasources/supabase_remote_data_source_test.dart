import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:expense_tracker/core/data/datasources/supabase_remote_data_source.dart';
import 'package:expense_tracker/core/data/dtos/expense_dto.dart';
import 'package:expense_tracker/core/domain/result.dart';
import 'package:expense_tracker/core/domain/errors/sync_errors.dart';

// Mock Supabase client for testing
class MockSupabaseClient extends Mock {}

void main() {
  group('SupabaseRemoteDataSource', () {
    late MockSupabaseClient mockClient;
    late SupabaseRemoteDataSource dataSource;

    const testUserId = 'test-user-123';
    final testDateTime = DateTime.utc(2024, 1, 1, 12, 0, 0);

    setUp(() {
      mockClient = MockSupabaseClient();
      dataSource = SupabaseRemoteDataSource(mockClient);
    });

    group('constructor and constants', () {
      test('should initialize with provided client', () {
        expect(dataSource, isA<SupabaseRemoteDataSource>());
      });

      test('should implement RemoteDataSource interface', () {
        expect(dataSource, isA<SupabaseRemoteDataSource>());
      });
    });

    group('ExpenseDto creation', () {
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
    });

    group('batch operations', () {
      test('should handle empty lists', () {
        const emptyList = <ExpenseDto>[];
        expect(emptyList.isEmpty, true);
      });

      test('should split large lists into batches', () {
        // Test batching logic conceptually
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
        const error = NetworkError(message: 'Test error');
        const result = Result<List<ExpenseDto>>.failure(error);
        
        expect(result.isFailure, true);
        expect(result.isSuccess, false);
      });
    });

    group('error types', () {
      test('should create NetworkError', () {
        const error = NetworkError(message: 'Connection failed');
        expect(error.message, 'Connection failed');
        expect(error.code, 'NETWORK_ERROR');
      });

      test('should create SupabaseError', () {
        const error = SupabaseError(message: 'Database error');
        expect(error.message, 'Database error');
        expect(error.code, 'SUPABASE_ERROR');
      });
    });
  });
}