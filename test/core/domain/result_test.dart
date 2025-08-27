import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/domain/result.dart';
import 'package:expense_tracker/core/domain/errors/sync_errors.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create successful result with data', () {
        const result = Result<String>.success('test data');
        
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.data, equals('test data'));
        expect(result.error, isNull);
      });

      test('should support equality comparison', () {
        const result1 = Result<String>.success('test');
        const result2 = Result<String>.success('test');
        const result3 = Result<String>.success('different');
        
        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('should have proper string representation', () {
        const result = Result<String>.success('test');
        expect(result.toString(), equals('Success(test)'));
      });
    });

    group('Failure', () {
      const error = NetworkError.noConnection();

      test('should create failure result with error', () {
        const result = Result<String>.failure(error);
        
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.data, isNull);
        expect(result.error, equals(error));
      });

      test('should support equality comparison', () {
        const result1 = Result<String>.failure(error);
        const result2 = Result<String>.failure(error);
        const differentError = NetworkError.timeout();
        const result3 = Result<String>.failure(differentError);
        
        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('should have proper string representation', () {
        const result = Result<String>.failure(error);
        expect(result.toString(), contains('Failure('));
        expect(result.toString(), contains('NO_CONNECTION'));
      });
    });

    group('Transformations', () {
      test('should map success data correctly', () {
        const result = Result<int>.success(5);
        final mapped = result.map((data) => data.toString());
        
        expect(mapped.isSuccess, isTrue);
        expect(mapped.data, equals('5'));
      });

      test('should preserve failure when mapping', () {
        final error = ValidationError.requiredField(field: 'name');
        final result = Result<int>.failure(error);
        final mapped = result.map((data) => data.toString());
        
        expect(mapped.isFailure, isTrue);
        expect(mapped.error, equals(error));
      });

      test('should map error correctly', () {
        const originalError = NetworkError.noConnection();
        const newError = NetworkError.timeout();
        const result = Result<String>.failure(originalError);
        final mapped = result.mapError((_) => newError);
        
        expect(mapped.isFailure, isTrue);
        expect(mapped.error, equals(newError));
      });

      test('should preserve success when mapping error', () {
        const result = Result<String>.success('test');
        const newError = NetworkError.timeout();
        final mapped = result.mapError((_) => newError);
        
        expect(mapped.isSuccess, isTrue);
        expect(mapped.data, equals('test'));
      });
    });

    group('Fold', () {
      test('should fold success result', () {
        const result = Result<int>.success(42);
        final folded = result.fold(
          onSuccess: (data) => 'Success: $data',
          onFailure: (error) => 'Error: ${error.code}',
        );
        
        expect(folded, equals('Success: 42'));
      });

      test('should fold failure result', () {
        final error = ValidationError.requiredField(field: 'email');
        final result = Result<int>.failure(error);
        final folded = result.fold(
          onSuccess: (data) => 'Success: $data',
          onFailure: (error) => 'Error: ${error.code}',
        );
        
        expect(folded, equals('Error: REQUIRED_FIELD'));
      });
    });

    group('Side Effects', () {
      test('should execute onSuccess callback for success result', () {
        var called = false;
        var receivedData = '';
        
        const result = Result<String>.success('test data');
        final returnedResult = result.onSuccess((data) {
          called = true;
          receivedData = data;
        });
        
        expect(called, isTrue);
        expect(receivedData, equals('test data'));
        expect(returnedResult, equals(result));
      });

      test('should not execute onSuccess callback for failure result', () {
        var called = false;
        
        const error = NetworkError.noConnection();
        const result = Result<String>.failure(error);
        final returnedResult = result.onSuccess((data) {
          called = true;
        });
        
        expect(called, isFalse);
        expect(returnedResult, equals(result));
      });

      test('should execute onFailure callback for failure result', () {
        var called = false;
        var receivedError = '';
        
        const error = NetworkError.noConnection();
        const result = Result<String>.failure(error);
        final returnedResult = result.onFailure((error) {
          called = true;
          receivedError = error.code;
        });
        
        expect(called, isTrue);
        expect(receivedError, equals('NO_CONNECTION'));
        expect(returnedResult, equals(result));
      });

      test('should not execute onFailure callback for success result', () {
        var called = false;
        
        const result = Result<String>.success('test');
        final returnedResult = result.onFailure((error) {
          called = true;
        });
        
        expect(called, isFalse);
        expect(returnedResult, equals(result));
      });
    });

    group('Pattern Matching', () {
      test('should support switch expressions on Result', () {
        const successResult = Result<String>.success('data');
        const failureResult = Result<String>.failure(NetworkError.noConnection());
        
        final successMessage = switch (successResult) {
          Success(data: final data) => 'Got data: $data',
          Failure(error: final error) => 'Got error: ${error.code}',
        };
        
        final failureMessage = switch (failureResult) {
          Success(data: final data) => 'Got data: $data',
          Failure(error: final error) => 'Got error: ${error.code}',
        };
        
        expect(successMessage, equals('Got data: data'));
        expect(failureMessage, equals('Got error: NO_CONNECTION'));
      });
    });

    group('Complex Types', () {
      test('should handle List<T> success results', () {
        const result = Result<List<int>>.success([1, 2, 3]);
        
        expect(result.isSuccess, isTrue);
        expect(result.data, equals([1, 2, 3]));
      });

      test('should handle Map<String, dynamic> success results', () {
        const data = {'key': 'value', 'count': 42};
        const result = Result<Map<String, dynamic>>.success(data);
        
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(data));
      });

      test('should handle null success results', () {
        const result = Result<String?>.success(null);
        
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });
    });
  });

  group('AppError', () {
    group('NetworkError', () {
      test('should create no connection error', () {
        const error = NetworkError.noConnection();
        
        expect(error.code, equals('NO_CONNECTION'));
        expect(error.message, equals('No internet connection available'));
        expect(error.details, isNull);
      });

      test('should create timeout error', () {
        const error = NetworkError.timeout();
        
        expect(error.code, equals('CONNECTION_TIMEOUT'));
        expect(error.message, equals('Connection timed out'));
      });

      test('should support equality comparison', () {
        const error1 = NetworkError.noConnection();
        const error2 = NetworkError.noConnection();
        const error3 = NetworkError.timeout();
        
        expect(error1, equals(error2));
        expect(error1, isNot(equals(error3)));
      });
    });

    group('ValidationError', () {
      test('should create required field error', () {
        final error = ValidationError.requiredField(field: 'email');
        
        expect(error.code, equals('REQUIRED_FIELD'));
        expect(error.message, equals('Required field is missing or empty'));
        expect(error.details, equals({'field': 'email'}));
      });

      test('should create invalid ID error', () {
        final error = ValidationError.invalidId(id: 'invalid-id');
        
        expect(error.code, equals('INVALID_ID'));
        expect(error.details, equals({'id': 'invalid-id'}));
      });
    });

    group('ConflictError', () {
      test('should create version conflict error', () {
        final error = ConflictError.versionConflict(
          entityId: 'expense-123',
          localVersion: 2,
          remoteVersion: 3,
        );
        
        expect(error.code, equals('VERSION_CONFLICT'));
        expect(error.details, equals({
          'entityId': 'expense-123',
          'localVersion': 2,
          'remoteVersion': 3,
        }));
      });
    });
  });
}