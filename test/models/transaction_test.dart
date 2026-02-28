import 'package:flutter_test/flutter_test.dart';
import 'package:expense_manager/models/transaction.dart';

void main() {
  group('Transaction Model Tests', () {
    test('Transaction.fromMap() parses correctly', () {
      final map = {
        'id': 1,
        'category_id': 2,
        'wallet_id': 1,
        'amount': 150000.0,
        'date': '2026-02-27T10:00:00.000',
        'description': 'Ăn sáng',
        'type': 'expense',
        'notes': 'Phở bò',
        'receipt_path': null,
        'created_at': '2026-02-27T10:00:00.000',
      };

      final transaction = Transaction.fromMap(map);

      expect(transaction.id, 1);
      expect(transaction.categoryId, 2);
      expect(transaction.walletId, 1);
      expect(transaction.amount, 150000.0);
      expect(transaction.type, 'expense');
      expect(transaction.description, 'Ăn sáng');
      expect(transaction.notes, 'Phở bò');
    });

    test('Transaction.fromMap() handles int amount', () {
      final map = {
        'id': 1,
        'category_id': 1,
        'amount': 500000, // int thay vì double
        'date': '2026-02-27',
        'type': 'income',
      };

      final transaction = Transaction.fromMap(map);
      expect(transaction.amount, 500000.0);
      expect(transaction.amount, isA<double>());
    });

    test('Transaction.fromMap() handles null values safely', () {
      final map = {
        'id': null,
        'category_id': 1,
        'amount': 100.0,
        'date': '2026-02-27',
        'type': 'expense',
        'description': null,
        'notes': null,
      };

      final transaction = Transaction.fromMap(map);
      expect(transaction.id, isNull);
      expect(transaction.description, isNull);
      expect(transaction.notes, isNull);
    });

    test('Transaction.toMap() excludes null id', () {
      final transaction = Transaction(
        categoryId: 1,
        amount: 100000.0,
        date: '2026-02-27',
        type: 'expense',
      );

      final map = transaction.toMap();
      expect(map.containsKey('id'), isFalse);
    });

    test('Transaction.toMap() includes id when not null', () {
      final transaction = Transaction(
        id: 5,
        categoryId: 1,
        amount: 100000.0,
        date: '2026-02-27',
        type: 'expense',
      );

      final map = transaction.toMap();
      expect(map['id'], 5);
    });

    test('Transaction.copyWith() creates new instance with updated fields', () {
      final original = Transaction(
        id: 1,
        categoryId: 1,
        amount: 100000.0,
        date: '2026-02-27',
        type: 'expense',
        description: 'Ăn sáng',
      );

      final updated = original.copyWith(
        amount: 200000.0,
        description: 'Ăn trưa',
      );

      expect(updated.id, 1); // Giữ nguyên
      expect(updated.amount, 200000.0); // Cập nhật
      expect(updated.description, 'Ăn trưa'); // Cập nhật
      expect(updated.type, 'expense'); // Giữ nguyên
    });

    test('Transaction equality based on id', () {
      final t1 = Transaction(
        id: 1,
        categoryId: 1,
        amount: 100.0,
        date: '2026-02-27',
        type: 'expense',
      );
      final t2 = Transaction(
        id: 1,
        categoryId: 2,
        amount: 200.0,
        date: '2026-02-28',
        type: 'income',
      );

      expect(t1, equals(t2)); // Same id = equal
    });

    test('Transaction type validation', () {
      expect(
        () => Transaction(
          categoryId: 1,
          amount: 100.0,
          date: '2026-02-27',
          type: 'invalid_type',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Transaction amount validation', () {
      expect(
        () => Transaction(
          categoryId: 1,
          amount: -100.0,
          date: '2026-02-27',
          type: 'expense',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
