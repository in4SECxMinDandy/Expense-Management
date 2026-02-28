import 'package:flutter_test/flutter_test.dart';
import 'package:expense_manager/services/sync_service.dart';

void main() {
  group('SyncResult Tests', () {
    test('SyncResult.success() creates correct result', () {
      final result = SyncResult.success(
        restoredCount: 10,
        skippedCount: 3,
      );

      expect(result.isSuccess, true);
      expect(result.restoredCount, 10);
      expect(result.skippedCount, 3);
      expect(result.errorMessage, isNull);
    });

    test('SyncResult.error() creates correct result', () {
      final result = SyncResult.error('Test error message');

      expect(result.isSuccess, false);
      expect(result.errorMessage, 'Test error message');
      expect(result.restoredCount, 0);
      expect(result.skippedCount, 0);
    });

    test('SyncResult.toString() returns meaningful message for success', () {
      final result = SyncResult.success(
        restoredCount: 5,
        skippedCount: 2,
      );

      final str = result.toString();
      expect(str, contains('Thành công'));
      expect(str, contains('5'));
      expect(str, contains('2'));
    });

    test('SyncResult.toString() returns error message for failure', () {
      final result = SyncResult.error('Database error');

      final str = result.toString();
      expect(str, contains('Lỗi'));
      expect(str, contains('Database error'));
    });
  });
}
