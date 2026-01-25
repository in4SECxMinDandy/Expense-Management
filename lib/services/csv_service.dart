import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';

class CsvService {
  static Future<void> exportTransactions(List<Transaction> transactions) async {
    List<List<dynamic>> rows = [];

    // Add header
    rows.add([
      'ID',
      'Category ID',
      'Amount',
      'Date',
      'Description',
      'Type',
      'Created At',
    ]);

    for (var t in transactions) {
      rows.add([
        t.id,
        t.categoryId,
        t.amount,
        t.date,
        t.description,
        t.type,
        t.createdAt,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    // Save to temp file
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/spendwise_export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv);

    // Share file
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'SpendWise Transaction Export');
  }

  static Future<List<Transaction>> importTransactions() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final String csvContent = await file.readAsString();

      List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);

      // Skip header
      if (rows.length <= 1) return [];

      List<Transaction> transactions = [];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 6) continue;

        transactions.add(
          Transaction(
            categoryId: int.tryParse(row[1].toString()) ?? 1,
            amount: double.tryParse(row[2].toString()) ?? 0.0,
            date: row[3].toString(),
            description: row[4]?.toString(),
            type: row[5].toString(),
            createdAt: row.length > 6 ? row[6]?.toString() : null,
          ),
        );
      }
      return transactions;
    }
    return [];
  }
}
