import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'csv_service.dart';

/// Lưu CSV và chia sẻ (Mobile/Desktop)
Future<bool> saveCsvAndShare(String csv, String fileName) async {
  try {
    final directory = await getTemporaryDirectory();
    final shareDir = Directory('${directory.path}/share');
    if (!await shareDir.exists()) {
      await shareDir.create(recursive: true);
    }

    final file = File('${shareDir.path}/$fileName');
    await file.writeAsString(csv, encoding: const Utf8Codec());

    final result = await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'SpendWise - Xuất dữ liệu giao dịch',
      subject: 'SpendWise Export',
    );

    return result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed;
  } catch (e) {
    return false;
  }
}

/// Download CSV (không dùng trên IO, chỉ dùng trên Web)
Future<void> downloadCsvWeb(String csv, String fileName) async {
  // Không làm gì trên IO platform
}

/// Nhập CSV từ file picker (Mobile/Desktop)
Future<List<Transaction>> importCsvIo(List<Category> categories) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return [];

    final filePath = result.files.single.path;
    if (filePath == null) return [];

    final file = File(filePath);
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    return CsvService.parseCsvContent(content, categories);
  } catch (e) {
    return [];
  }
}

/// Nhập CSV từ web (không dùng trên IO)
Future<List<Transaction>> importCsvWeb(List<Category> categories) async {
  return [];
}
