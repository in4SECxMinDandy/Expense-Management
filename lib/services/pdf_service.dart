import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class PdfService {
  // Cache font để không load lại nhiều lần
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  /// Load font hỗ trợ tiếng Việt (Unicode) - NotoSans có hỗ trợ tốt nhất cho tiếng Việt
  static Future<void> _loadFonts() async {
    if (_regularFont != null && _boldFont != null) return;

    try {
      // Sử dụng NotoSans - hỗ trợ tiếng Việt tốt nhất
      _regularFont = await PdfGoogleFonts.notoSansRegular();
      _boldFont = await PdfGoogleFonts.notoSansBold();
    } catch (e) {
      // Fallback: sử dụng Roboto nếu NotoSans không khả dụng
      try {
        _regularFont = await PdfGoogleFonts.robotoRegular();
        _boldFont = await PdfGoogleFonts.robotoBold();
      } catch (e2) {
        // Nếu không load được, để null và sẽ dùng font mặc định
        _regularFont = null;
        _boldFont = null;
      }
    }
  }

  /// Tạo TextStyle với font hỗ trợ tiếng Việt
  static pw.TextStyle _getTextStyle({
    double fontSize = 12,
    pw.FontWeight? fontWeight,
    PdfColor? color,
  }) {
    final isBold = fontWeight == pw.FontWeight.bold;
    final font = isBold ? _boldFont : _regularFont;

    return pw.TextStyle(
      font: font,
      fontBold: _boldFont,
      fontFallback: [if (_regularFont != null) _regularFont!],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static Future<void> exportTransactionsPdf({
    required List<Transaction> transactions,
    required List<Category> categories,
    String? title,
  }) async {
    // Load fonts trước khi tạo PDF
    await _loadFonts();

    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Calculate summary
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;

    // Group by category for summary
    final Map<int, double> categorySpending = {};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      categorySpending[t.categoryId] =
          (categorySpending[t.categoryId] ?? 0) + t.amount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  title ?? 'Báo cáo Chi tiêu SpendWise',
                  style: _getTextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Ngày xuất: ${dateFormat.format(DateTime.now())}',
                  style: _getTextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'SpendWise - Quản lý chi tiêu cá nhân',
              style: _getTextStyle(fontSize: 10, color: PdfColors.grey),
            ),
            pw.Text(
              'Trang ${context.pageNumber}/${context.pagesCount}',
              style: _getTextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
        build: (context) => [
          // Summary Section
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Tổng quan',
                  style: _getTextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Thu nhập',
                      currencyFormat.format(totalIncome),
                      PdfColors.green,
                    ),
                    _buildSummaryItem(
                      'Chi tiêu',
                      currencyFormat.format(totalExpense),
                      PdfColors.red,
                    ),
                    _buildSummaryItem(
                      'Số dư',
                      currencyFormat.format(balance),
                      balance >= 0 ? PdfColors.blue : PdfColors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Top spending categories
          if (categorySpending.isNotEmpty) ...[
            pw.Text(
              'Chi tiêu theo danh mục',
              style: _getTextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableHeader('Danh mục'),
                    _buildTableHeader('Số tiền'),
                    _buildTableHeader('%'),
                  ],
                ),
                ...categorySpending.entries.map((entry) {
                  final cat = categories.firstWhere(
                    (c) => c.id == entry.key,
                    orElse: () => Category(name: 'Khác', type: 'expense'),
                  );
                  final percent =
                      totalExpense > 0 ? (entry.value / totalExpense * 100) : 0;
                  // Loại bỏ emoji trong PDF vì không được hỗ trợ
                  final categoryName = _removeEmoji(cat.name);
                  return pw.TableRow(
                    children: [
                      _buildTableCell(categoryName),
                      _buildTableCell(currencyFormat.format(entry.value)),
                      _buildTableCell('${percent.toStringAsFixed(1)}%'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // Transaction List
          pw.Text(
            'Danh sách giao dịch (${transactions.length})',
            style: _getTextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableHeader('Ngày'),
                  _buildTableHeader('Mô tả'),
                  _buildTableHeader('Số tiền'),
                  _buildTableHeader('Loại'),
                ],
              ),
              ...transactions.map((t) {
                DateTime txDate;
                try {
                  txDate = DateTime.parse(t.date);
                } catch (e) {
                  txDate = DateTime.now();
                }
                // Loại bỏ emoji trong mô tả
                final description = _removeEmoji(t.description ?? 'Giao dịch');
                return pw.TableRow(
                  children: [
                    _buildTableCell(dateFormat.format(txDate)),
                    _buildTableCell(description),
                    _buildTableCell(
                      '${t.type == 'income' ? '+' : '-'}${currencyFormat.format(t.amount)}',
                      color: t.type == 'income' ? PdfColors.green : PdfColors.red,
                    ),
                    _buildTableCell(
                      t.type == 'income' ? 'Thu' : 'Chi',
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    // Tạo tên file an toàn (không có ký tự đặc biệt)
    final now = DateTime.now();
    final safeFileName = 'SpendWise_Report_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.millisecondsSinceEpoch}.pdf';

    // Save and share PDF
    final directory = await getTemporaryDirectory();

    // Đảm bảo thư mục tồn tại
    final shareDir = Directory('${directory.path}/share');
    if (!await shareDir.exists()) {
      await shareDir.create(recursive: true);
    }

    final file = File('${shareDir.path}/$safeFileName');
    final pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: safeFileName,
    );
  }

  /// Loại bỏ emoji và các ký tự không được hỗ trợ trong PDF
  static String _removeEmoji(String text) {
    // Regex để loại bỏ emoji và các ký tự đặc biệt không được hỗ trợ
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}]|'  // Emoticons
      r'[\u{1F300}-\u{1F5FF}]|'  // Misc Symbols and Pictographs
      r'[\u{1F680}-\u{1F6FF}]|'  // Transport and Map
      r'[\u{1F1E0}-\u{1F1FF}]|'  // Flags
      r'[\u{2600}-\u{26FF}]|'    // Misc symbols
      r'[\u{2700}-\u{27BF}]|'    // Dingbats
      r'[\u{FE00}-\u{FE0F}]|'    // Variation Selectors
      r'[\u{1F900}-\u{1F9FF}]|'  // Supplemental Symbols and Pictographs
      r'[\u{1FA00}-\u{1FA6F}]|'  // Chess Symbols
      r'[\u{1FA70}-\u{1FAFF}]|'  // Symbols and Pictographs Extended-A
      r'[\u{231A}-\u{231B}]|'    // Watch, Hourglass
      r'[\u{23E9}-\u{23F3}]|'    // Various symbols
      r'[\u{23F8}-\u{23FA}]|'    // Various symbols
      r'[\u{25AA}-\u{25AB}]|'    // Squares
      r'[\u{25B6}]|'             // Play button
      r'[\u{25C0}]|'             // Reverse button
      r'[\u{25FB}-\u{25FE}]|'    // Squares
      r'[\u{2614}-\u{2615}]|'    // Umbrella, Hot beverage
      r'[\u{2648}-\u{2653}]|'    // Zodiac
      r'[\u{267F}]|'             // Wheelchair
      r'[\u{2693}]|'             // Anchor
      r'[\u{26A1}]|'             // High voltage
      r'[\u{26AA}-\u{26AB}]|'    // Circles
      r'[\u{26BD}-\u{26BE}]|'    // Soccer, baseball
      r'[\u{26C4}-\u{26C5}]|'    // Snowman, sun
      r'[\u{26CE}]|'             // Ophiuchus
      r'[\u{26D4}]|'             // No entry
      r'[\u{26EA}]|'             // Church
      r'[\u{26F2}-\u{26F3}]|'    // Fountain, golf
      r'[\u{26F5}]|'             // Sailboat
      r'[\u{26FA}]|'             // Tent
      r'[\u{26FD}]|'             // Fuel pump
      r'[\u{2702}]|'             // Scissors
      r'[\u{2705}]|'             // Check mark
      r'[\u{2708}-\u{270D}]|'    // Airplane to writing hand
      r'[\u{270F}]|'             // Pencil
      r'[\u{2712}]|'             // Black nib
      r'[\u{2714}]|'             // Check mark
      r'[\u{2716}]|'             // X mark
      r'[\u{271D}]|'             // Latin cross
      r'[\u{2721}]|'             // Star of David
      r'[\u{2728}]|'             // Sparkles
      r'[\u{2733}-\u{2734}]|'    // Eight spoked asterisk
      r'[\u{2744}]|'             // Snowflake
      r'[\u{2747}]|'             // Sparkle
      r'[\u{274C}]|'             // Cross mark
      r'[\u{274E}]|'             // Cross mark
      r'[\u{2753}-\u{2755}]|'    // Question marks
      r'[\u{2757}]|'             // Exclamation mark
      r'[\u{2763}-\u{2764}]|'    // Heart exclamation, heart
      r'[\u{2795}-\u{2797}]|'    // Plus, minus, divide
      r'[\u{27A1}]|'             // Right arrow
      r'[\u{27B0}]|'             // Curly loop
      r'[\u{27BF}]|'             // Double curly loop
      r'[\u{2934}-\u{2935}]|'    // Arrows
      r'[\u{2B05}-\u{2B07}]|'    // Arrows
      r'[\u{2B1B}-\u{2B1C}]|'    // Squares
      r'[\u{2B50}]|'             // Star
      r'[\u{2B55}]|'             // Circle
      r'[\u{3030}]|'             // Wavy dash
      r'[\u{303D}]|'             // Part alternation mark
      r'[\u{3297}]|'             // Circled Ideograph Congratulation
      r'[\u{3299}]',             // Circled Ideograph Secret
      unicode: true,
    );

    return text.replaceAll(emojiRegex, '').trim();
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: _getTextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: _getTextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: _getTextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: _getTextStyle(fontSize: 9, color: color),
      ),
    );
  }
}
