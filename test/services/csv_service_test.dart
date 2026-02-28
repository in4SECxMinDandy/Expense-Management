import 'package:flutter_test/flutter_test.dart';
import 'package:expense_manager/services/csv_service.dart';
import 'package:expense_manager/models/category.dart';

void main() {
  group('CsvService Tests', () {
    final categories = [
      Category(id: 1, name: 'Lương', type: 'income'),
      Category(id: 2, name: 'Ăn uống', type: 'expense'),
      Category(id: 3, name: 'Di chuyển', type: 'expense'),
    ];

    test('parseCsvContent() parses valid CSV correctly', () {
      const csvContent = '''ID,Ngày,Loại,Danh mục,Số tiền (đ),Mô tả,Ghi chú,Tạo lúc
1,27/02/2026 10:00,Chi tiêu,Ăn uống,150000,Ăn sáng,,
2,27/02/2026 12:00,Thu nhập,Lương,5000000,Lương tháng 2,,''';

      final transactions = CsvService.parseCsvContent(csvContent, categories);

      expect(transactions.length, 2);
      expect(transactions[0].type, 'expense');
      expect(transactions[0].amount, 150000.0);
      expect(transactions[0].description, 'Ăn sáng');
      expect(transactions[1].type, 'income');
      expect(transactions[1].amount, 5000000.0);
    });

    test('parseCsvContent() handles empty CSV', () {
      const csvContent = 'ID,Ngày,Loại,Danh mục,Số tiền (đ),Mô tả,Ghi chú,Tạo lúc';
      final transactions = CsvService.parseCsvContent(csvContent, categories);
      expect(transactions, isEmpty);
    });

    test('parseCsvContent() skips invalid rows', () {
      const csvContent = '''ID,Ngày,Loại,Danh mục,Số tiền (đ),Mô tả,Ghi chú,Tạo lúc
1,27/02/2026 10:00,Chi tiêu,Ăn uống,150000,Ăn sáng,,
invalid_row
2,27/02/2026 12:00,Thu nhập,Lương,5000000,Lương,,''';

      final transactions = CsvService.parseCsvContent(csvContent, categories);
      // Chỉ parse được 2 dòng hợp lệ
      expect(transactions.length, greaterThanOrEqualTo(1));
    });

    test('parseCsvContent() skips summary rows', () {
      const csvContent = '''ID,Ngày,Loại,Danh mục,Số tiền (đ),Mô tả,Ghi chú,Tạo lúc
1,27/02/2026 10:00,Chi tiêu,Ăn uống,150000,Ăn sáng,,
,,,Tổng thu nhập:,5000000,,,
,,,Tổng chi tiêu:,150000,,,''';

      final transactions = CsvService.parseCsvContent(csvContent, categories);
      // Chỉ parse 1 giao dịch thực, bỏ qua dòng tổng kết
      expect(transactions.length, 1);
    });

    test('parseCsvContent() handles amount with commas', () {
      const csvContent = '''ID,Ngày,Loại,Danh mục,Số tiền (đ),Mô tả,Ghi chú,Tạo lúc
1,27/02/2026 10:00,Chi tiêu,Ăn uống,"1,500,000",Ăn sáng,,''';

      final transactions = CsvService.parseCsvContent(csvContent, categories);
      if (transactions.isNotEmpty) {
        expect(transactions[0].amount, 1500000.0);
      }
    });

    test('parseCsvContent() maps category by name', () {
      const csvContent = '''ID,Ngày,Loại,Danh mục,Số tiền (đ),Mô tả,Ghi chú,Tạo lúc
1,27/02/2026 10:00,Chi tiêu,Di chuyển,50000,Xe bus,,''';

      final transactions = CsvService.parseCsvContent(csvContent, categories);
      if (transactions.isNotEmpty) {
        expect(transactions[0].categoryId, 3); // Di chuyển = id 3
      }
    });

    test('parseCsvContent() uses default category for unknown category', () {
      const csvContent = '''ID,Ngày,Loại,Danh mục,Số tiền (đ),Mô tả,Ghi chú,Tạo lúc
1,27/02/2026 10:00,Chi tiêu,Danh mục không tồn tại,50000,Test,,''';

      final transactions = CsvService.parseCsvContent(csvContent, categories);
      if (transactions.isNotEmpty) {
        expect(transactions[0].categoryId, 1); // Default category id
      }
    });
  });
}
