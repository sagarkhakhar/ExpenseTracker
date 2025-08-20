// Simple integration test to verify our systems work together
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/validation/simple_validators.dart';
import 'package:expense_tracker/core/types/result.dart';
import 'package:expense_tracker/core/errors/exceptions.dart';

void main() {
  group('Simple Integration Test', () {
    test('Result types work correctly', () {
      // Test success case
      const successResult = Result.success('test value');
      expect(successResult.isSuccess, true);
      expect(successResult.isFailure, false);
      expect(successResult.valueOrNull, 'test value');

      // Test failure case
      final exception = AppException.create(
        message: 'Test error',
        errorCode: 'TEST_ERROR',
      );
      final failureResult = Result.failure(exception);
      expect(failureResult.isFailure, true);
      expect(failureResult.isSuccess, false);
      expect(failureResult.exceptionOrNull, exception);

      // Test pattern matching
      String result = '';
      successResult.when(
        success: (value) => result = 'Got success: $value',
        failure: (error) => result = 'Got failure: ${error.message}',
        loading: (_) => result = 'Got loading',
      );
      expect(result, 'Got success: test value');
    });

    test('Simple validation works with Result types', () {
      // Test successful validation
      final titleResult = ExpenseValidators.validateTitle('Valid Title');
      expect(titleResult.isRight(), true);

      final validTitle = titleResult.fold(
        (error) => throw Exception('Expected success'),
        (title) => title,
      );
      expect(validTitle, 'Valid Title');

      // Test failed validation
      final emptyTitleResult = ExpenseValidators.validateTitle('');
      expect(emptyTitleResult.isLeft(), true);

      final error = emptyTitleResult.fold(
        (error) => error,
        (title) => throw Exception('Expected error'),
      );
      expect(error, 'Title is required');
    });

    test('Exception creation works correctly', () {
      final exception = AppException.create(
        message: 'Test message',
        errorCode: 'TEST_CODE',
        technicalDetails: 'Technical info',
        severity: ErrorSeverity.medium,
      );

      expect(exception.message, 'Test message');
      expect(exception.errorCode, 'TEST_CODE');
      expect(exception.technicalDetails, 'Technical info');
      expect(exception.severity, ErrorSeverity.medium);

      // Test toString doesn't crash
      final stringForm = exception.toString();
      expect(stringForm, contains('Test message'));
      expect(stringForm, contains('TEST_CODE'));
    });

    test('Expense validation covers all required fields', () {
      // Test all validators work
      final titleResult = ExpenseValidators.validateTitle('Test Title');
      final amountResult = ExpenseValidators.validateAmount(50.0);
      final categoryResult = ExpenseValidators.validateCategory('Food');
      final dateResult = ExpenseValidators.validateDate(DateTime.now());

      expect(titleResult.isRight(), true);
      expect(amountResult.isRight(), true);
      expect(categoryResult.isRight(), true);
      expect(dateResult.isRight(), true);

      // Test validation failures
      expect(ExpenseValidators.validateTitle('').isLeft(), true);
      expect(ExpenseValidators.validateAmount(-1.0).isLeft(), true);
      expect(ExpenseValidators.validateCategory('').isLeft(), true);
      expect(ExpenseValidators.validateDate(null).isLeft(), true);
    });

    test('Performance measurement simulation', () {
      final stopwatch = Stopwatch()..start();
      
      // Simulate some work
      for (int i = 0; i < 1000; i++) {
        ExpenseValidators.validateTitle('Test $i');
      }
      
      stopwatch.stop();
      final duration = stopwatch.elapsed;
      
      expect(duration.inMicroseconds, greaterThan(0));
      
      // Simulate performance logging (without actual logging dependencies)
      final performanceData = {
        'operation': 'validation_batch',
        'duration_ms': duration.inMilliseconds,
        'iterations': 1000,
      };
      
      expect(performanceData['operation'], 'validation_batch');
      expect(performanceData['iterations'], 1000);
      expect(performanceData['duration_ms'], isA<int>());
    });
  });
}