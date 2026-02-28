// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import '../models/transaction.dart';
import '../models/category.dart';
import 'csv_service.dart';

/// Lưu CSV và chia sẻ (Web - không dùng)
Future<bool> saveCsvAndShare(String csv, String fileName) async {
  // Web sử dụng downloadCsvWeb thay thế
  await downloadCsvWeb(csv, fileName);
  return true;
}

/// Download CSV trên Web thông qua Blob URL
Future<void> downloadCsvWeb(String csv, String fileName) async {
  try {
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    html.Url.revokeObjectUrl(url);
  } catch (e) {
    // Ignore web download errors
  }
}

/// Nhập CSV từ file picker (Web)
Future<List<Transaction>> importCsvWeb(List<Category> categories) async {
  try {
    final completer = html.FileUploadInputElement()
      ..accept = '.csv'
      ..click();

    await completer.onChange.first;

    if (completer.files == null || completer.files!.isEmpty) return [];

    final file = completer.files!.first;
    final reader = html.FileReader();
    reader.readAsText(file);

    await reader.onLoad.first;

    final content = reader.result as String?;
    if (content == null) return [];

    return CsvService.parseCsvContent(content, categories);
  } catch (e) {
    return [];
  }
}

/// Nhập CSV từ IO (không dùng trên Web)
Future<List<Transaction>> importCsvIo(List<Category> categories) async {
  return [];
}
