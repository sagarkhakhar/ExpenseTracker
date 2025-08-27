import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/domain/entities/expense_sync.dart';

void main() {
  group('ExpenseSync', () {
    test('should create new expense with sync metadata', () {
      final expense = ExpenseSync.create(
        title: 'Coffee',
        description: 'Morning coffee',
        amount: 4.50,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime(2024, 1, 15),
        deviceId: 'device1',
        lastEditor: 'user1',
      );

      expect(expense.title, equals('Coffee'));
      expect(expense.amount, equals(4.50));
      expect(expense.type, equals(ExpenseType.expense));
      expect(expense.version, equals(1));
      expect(expense.isDeleted, isFalse);
      expect(expense.deviceId, equals('device1'));
      expect(expense.lastEditor, equals('user1'));
    });

    test('should support business logic methods', () {
      final expenseRecord = ExpenseSync.create(
        title: 'Coffee',
        description: 'Morning coffee',
        amount: 4.50,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        deviceId: 'device1',
        lastEditor: 'user1',
      );

      final incomeRecord = ExpenseSync.create(
        title: 'Salary',
        description: 'Monthly salary',
        amount: 5000.00,
        category: 'Income',
        type: ExpenseType.income,
        date: DateTime.now(),
        deviceId: 'device1',
        lastEditor: 'user1',
      );

      expect(expenseRecord.isExpense, isTrue);
      expect(expenseRecord.isIncome, isFalse);
      expect(expenseRecord.signedAmount, equals(-4.50));

      expect(incomeRecord.isExpense, isFalse);
      expect(incomeRecord.isIncome, isTrue);
      expect(incomeRecord.signedAmount, equals(5000.00));
    });

    test('should support sync operations', () {
      final expense = ExpenseSync.create(
        title: 'Coffee',
        description: 'Morning coffee',
        amount: 4.50,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        deviceId: 'device1',
        lastEditor: 'user1',
      );

      // Update sync metadata
      final updated = expense.copyWithSyncMetadata(
        version: 2,
        deviceId: 'device2',
        lastEditor: 'user2',
      );

      expect(updated.version, equals(2));
      expect(updated.deviceId, equals('device2'));
      expect(updated.lastEditor, equals('user2'));
      // Business data should remain the same
      expect(updated.title, equals('Coffee'));
      expect(updated.amount, equals(4.50));
    });

    test('should support business data updates', () {
      final expense = ExpenseSync.create(
        title: 'Coffee',
        description: 'Morning coffee',
        amount: 4.50,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        deviceId: 'device1',
        lastEditor: 'user1',
      );

      // Update business data
      final updated = expense.copyWithBusinessData(
        title: 'Expensive Coffee',
        amount: 6.00,
      );

      expect(updated.title, equals('Expensive Coffee'));
      expect(updated.amount, equals(6.00));
      // Sync metadata should remain the same
      expect(updated.version, equals(expense.version));
      expect(updated.deviceId, equals(expense.deviceId));
    });

    test('should compare for sync correctly', () {
      final older = ExpenseSync.create(
        title: 'Coffee',
        description: 'Morning coffee',
        amount: 4.50,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        deviceId: 'device1',
        lastEditor: 'user1',
      );

      final newer = older.copyWithSyncMetadata(
        version: 2,
        updatedAt: DateTime.now().add(const Duration(minutes: 1)),
        lastEditor: 'user2',
      );

      expect(newer.isNewerThan(older), isTrue);
      expect(older.isNewerThan(newer), isFalse);
    });

    test('should convert to map for serialization', () {
      final expense = ExpenseSync.create(
        title: 'Coffee',
        description: 'Morning coffee',
        amount: 4.50,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime(2024, 1, 15),
        deviceId: 'device1',
        lastEditor: 'user1',
        receiptPhotoId: 'photo123',
      );

      final map = expense.toMap();

      expect(map['title'], equals('Coffee'));
      expect(map['amount'], equals(4.50));
      expect(map['type'], equals('expense'));
      expect(map['version'], equals(1));
      expect(map['receiptPhotoId'], equals('photo123'));
      expect(map['deviceId'], equals('device1'));
    });

    test('should handle photo attachment', () {
      final expense = ExpenseSync.create(
        title: 'Restaurant',
        description: 'Dinner',
        amount: 45.00,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        deviceId: 'device1',
        lastEditor: 'user1',
        receiptPhotoId: 'photo123',
      );

      expect(expense.hasPhotos, isTrue);
      expect(expense.receiptPhotoId, equals('photo123'));

      // Create new expense without photo to test the false case
      final expenseWithoutPhoto = ExpenseSync.create(
        title: 'Restaurant',
        description: 'Dinner',
        amount: 45.00,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime.now(),
        deviceId: 'device1',
        lastEditor: 'user1',
        // No receiptPhotoId provided
      );
      expect(expenseWithoutPhoto.hasPhotos, isFalse);
    });
  });

  group('ExpenseBusinessData', () {
    test('should support copyWith correctly', () {
      final originalData = ExpenseBusinessData(
        title: 'Coffee',
        description: 'Morning coffee',
        amount: 4.50,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime(2024, 1, 15),
      );

      final updatedData = originalData.copyWith(
        title: 'Tea',
        amount: 3.00,
      );

      expect(updatedData.title, equals('Tea'));
      expect(updatedData.amount, equals(3.00));
      // Other fields should remain unchanged
      expect(updatedData.category, equals('Food'));
      expect(updatedData.type, equals(ExpenseType.expense));
      expect(updatedData.description, equals('Morning coffee'));
    });

    test('should maintain equality correctly', () {
      final data1 = ExpenseBusinessData(
        title: 'Coffee',
        description: 'Morning coffee',
        amount: 4.50,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime(2024, 1, 15),
      );

      final data2 = ExpenseBusinessData(
        title: 'Coffee',
        description: 'Morning coffee',
        amount: 4.50,
        category: 'Food',
        type: ExpenseType.expense,
        date: DateTime(2024, 1, 15),
      );

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
    });
  });
}