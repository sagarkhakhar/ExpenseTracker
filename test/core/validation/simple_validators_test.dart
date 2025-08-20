// Test file to verify our simple validation actually works
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/validation/simple_validators.dart';

void main() {
  group('ExpenseValidators', () {
    group('validateTitle', () {
      test('should return success for valid title', () {
        final result = ExpenseValidators.validateTitle('Valid Title');
        expect(result.isRight(), true);
        result.fold(
          (error) => fail('Expected success but got error: $error'),
          (title) => expect(title, 'Valid Title'),
        );
      });

      test('should return error for null title', () {
        final result = ExpenseValidators.validateTitle(null);
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, 'Title is required'),
          (title) => fail('Expected error but got success: $title'),
        );
      });

      test('should return error for empty title', () {
        final result = ExpenseValidators.validateTitle('   ');
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, 'Title is required'),
          (title) => fail('Expected error but got success: $title'),
        );
      });

      test('should return error for too long title', () {
        final longTitle = 'x' * 101;
        final result = ExpenseValidators.validateTitle(longTitle);
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, 'Title cannot exceed 100 characters'),
          (title) => fail('Expected error but got success: $title'),
        );
      });
    });

    group('validateAmount', () {
      test('should return success for valid amount', () {
        final result = ExpenseValidators.validateAmount(50.0);
        expect(result.isRight(), true);
        result.fold(
          (error) => fail('Expected success but got error: $error'),
          (amount) => expect(amount, 50.0),
        );
      });

      test('should return error for null amount', () {
        final result = ExpenseValidators.validateAmount(null);
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, 'Amount must be positive'),
          (amount) => fail('Expected error but got success: $amount'),
        );
      });

      test('should return error for negative amount', () {
        final result = ExpenseValidators.validateAmount(-10.0);
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, 'Amount must be positive'),
          (amount) => fail('Expected error but got success: $amount'),
        );
      });

      test('should return error for zero amount', () {
        final result = ExpenseValidators.validateAmount(0.0);
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, 'Amount must be positive'),
          (amount) => fail('Expected error but got success: $amount'),
        );
      });

      test('should return error for too large amount', () {
        final result = ExpenseValidators.validateAmount(2000000.0);
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, 'Amount cannot exceed \$1,000,000'),
          (amount) => fail('Expected error but got success: $amount'),
        );
      });
    });

    group('validateCategory', () {
      test('should return success for valid category', () {
        final result = ExpenseValidators.validateCategory('Food');
        expect(result.isRight(), true);
        result.fold(
          (error) => fail('Expected success but got error: $error'),
          (category) => expect(category, 'Food'),
        );
      });

      test('should return error for null category', () {
        final result = ExpenseValidators.validateCategory(null);
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, 'Category is required'),
          (category) => fail('Expected error but got success: $category'),
        );
      });
    });

    group('validateDate', () {
      test('should return success for valid date', () {
        final validDate = DateTime.now();
        final result = ExpenseValidators.validateDate(validDate);
        expect(result.isRight(), true);
        result.fold(
          (error) => fail('Expected success but got error: $error'),
          (date) => expect(date, validDate),
        );
      });

      test('should return error for null date', () {
        final result = ExpenseValidators.validateDate(null);
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, 'Date is required'),
          (date) => fail('Expected error but got success: $date'),
        );
      });

      test('should return error for date too far in past', () {
        final oldDate = DateTime.now().subtract(const Duration(days: 400));
        final result = ExpenseValidators.validateDate(oldDate);
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, 'Date must be within one year of today'),
          (date) => fail('Expected error but got success: $date'),
        );
      });
    });
  });
}