import 'package:flutter_test/flutter_test.dart';
import 'package:expense_manager/models/recurring_transaction.dart';

void main() {
  group('RecurringTransaction Model Tests', () {
    test('RepeatInterval.nextDate() - daily', () {
      final from = DateTime(2026, 2, 27, 10, 0);
      final next = RepeatInterval.daily.nextDate(from);
      expect(next, DateTime(2026, 2, 28, 10, 0));
    });

    test('RepeatInterval.nextDate() - weekly', () {
      final from = DateTime(2026, 2, 27, 10, 0);
      final next = RepeatInterval.weekly.nextDate(from);
      expect(next, DateTime(2026, 3, 6, 10, 0));
    });

    test('RepeatInterval.nextDate() - monthly', () {
      final from = DateTime(2026, 2, 27, 10, 0);
      final next = RepeatInterval.monthly.nextDate(from);
      expect(next, DateTime(2026, 3, 27, 10, 0));
    });

    test('RepeatInterval.nextDate() - monthly handles December to January', () {
      final from = DateTime(2026, 12, 15, 10, 0);
      final next = RepeatInterval.monthly.nextDate(from);
      expect(next, DateTime(2027, 1, 15, 10, 0));
    });

    test('RepeatInterval.nextDate() - monthly handles end of month', () {
      // Tháng 1 có 31 ngày, tháng 2 có 28 ngày (2026 không phải năm nhuận)
      final from = DateTime(2026, 1, 31, 10, 0);
      final next = RepeatInterval.monthly.nextDate(from);
      // Ngày 31 không tồn tại trong tháng 2, nên lấy ngày cuối tháng (28)
      expect(next.month, 2);
      expect(next.day, 28);
    });

    test('RepeatInterval.nextDate() - yearly', () {
      final from = DateTime(2026, 2, 27, 10, 0);
      final next = RepeatInterval.yearly.nextDate(from);
      expect(next, DateTime(2027, 2, 27, 10, 0));
    });

    test('RepeatInterval.displayName returns Vietnamese names', () {
      expect(RepeatInterval.daily.displayName, 'Hàng ngày');
      expect(RepeatInterval.weekly.displayName, 'Hàng tuần');
      expect(RepeatInterval.monthly.displayName, 'Hàng tháng');
      expect(RepeatInterval.yearly.displayName, 'Hàng năm');
    });

    test('RecurringTransaction.fromMap() parses correctly', () {
      final map = {
        'id': 1,
        'amount': 5000000.0,
        'category_id': 1,
        'description': 'Tiền thuê nhà',
        'type': 'expense',
        'repeat_interval': 'monthly',
        'next_run_date': '2026-03-01T00:00:00.000',
        'is_active': 1,
        'notification_enabled': 1,
      };

      final recurring = RecurringTransaction.fromMap(map);

      expect(recurring.id, 1);
      expect(recurring.amount, 5000000.0);
      expect(recurring.description, 'Tiền thuê nhà');
      expect(recurring.interval, RepeatInterval.monthly);
      expect(recurring.isActive, true);
      expect(recurring.notificationEnabled, true);
    });

    test('RecurringTransaction.fromMap() handles invalid interval gracefully', () {
      final map = {
        'id': 1,
        'amount': 100.0,
        'category_id': 1,
        'description': 'Test',
        'type': 'expense',
        'repeat_interval': 'invalid_interval',
        'next_run_date': '2026-03-01T00:00:00.000',
        'is_active': 1,
      };

      // Không nên throw exception
      final recurring = RecurringTransaction.fromMap(map);
      expect(recurring.interval, RepeatInterval.monthly); // Default
    });

    test('RecurringTransaction.isDue returns true when past due', () {
      final pastDate = DateTime.now().subtract(const Duration(hours: 1));
      final recurring = RecurringTransaction(
        amount: 100.0,
        categoryId: 1,
        description: 'Test',
        type: 'expense',
        interval: RepeatInterval.monthly,
        nextRunDate: pastDate,
        isActive: true,
      );

      expect(recurring.isDue, true);
    });

    test('RecurringTransaction.isDue returns false when not yet due', () {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final recurring = RecurringTransaction(
        amount: 100.0,
        categoryId: 1,
        description: 'Test',
        type: 'expense',
        interval: RepeatInterval.monthly,
        nextRunDate: futureDate,
        isActive: true,
      );

      expect(recurring.isDue, false);
    });

    test('RecurringTransaction.isDue returns false when inactive', () {
      final pastDate = DateTime.now().subtract(const Duration(hours: 1));
      final recurring = RecurringTransaction(
        amount: 100.0,
        categoryId: 1,
        description: 'Test',
        type: 'expense',
        interval: RepeatInterval.monthly,
        nextRunDate: pastDate,
        isActive: false, // Inactive
      );

      expect(recurring.isDue, false);
    });

    test('RecurringTransaction.toMap() serializes correctly', () {
      final recurring = RecurringTransaction(
        id: 1,
        amount: 1000000.0,
        categoryId: 2,
        description: 'Lương',
        type: 'income',
        interval: RepeatInterval.monthly,
        nextRunDate: DateTime(2026, 3, 1),
        isActive: true,
        notificationEnabled: true,
      );

      final map = recurring.toMap();

      expect(map['id'], 1);
      expect(map['amount'], 1000000.0);
      expect(map['repeat_interval'], 'monthly');
      expect(map['is_active'], 1);
      expect(map['notification_enabled'], 1);
    });
  });
}
