import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/model/expenses_model.dart';
import 'package:pos/model/store_model.dart';
import 'package:pos/widget/pdf_receipt_generator.dart';

Future<PdfExportResult> monthlyReportPdfGenerator({
  required StoreModel store,
  required List<PenjualanModel> sales,
  required List<ExpensesModel> expenses,
  required DateTime month,
}) async {
  final pdf = pw.Document();
  final monthName = DateFormat('MMMM').format(month);
  final year = month.year;
  final monthYear = DateFormat('MMMM yyyy').format(month);

  // Calculate totals
  final totalRevenue = sales.fold<double>(0, (sum, s) => sum + s.totalHarga);
  final totalOrders = sales.length;
  final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
  final totalHargaDasar = sales.fold<double>(0, (sum, s) {
    return sum + s.items.fold<double>(0, (p, c) {
      final cost = (c.hargaDasar ?? 0).toDouble();
      return p + (cost * (c.quantity ?? 1));
    });
  });
  final profit = totalRevenue - totalHargaDasar - totalExpenses;

  // Payment method breakdown
  Map<String, int> paymentCounts = {};
  Map<String, double> paymentTotals = {};
  for (var sale in sales) {
    final method = sale.paymentMethod ?? 'unknown';
    paymentCounts[method] = (paymentCounts[method] ?? 0) + 1;
    paymentTotals[method] = (paymentTotals[method] ?? 0) + sale.totalHarga;
  }

  // Daily breakdown
  Map<DateTime, List<PenjualanModel>> dailySales = {};
  for (var sale in sales) {
    final date = DateTime(sale.createdAt.year, sale.createdAt.month, sale.createdAt.day);
    dailySales[date] = [...(dailySales[date] ?? []), sale];
  }
  final sortedDates = dailySales.keys.toList()..sort((a, b) => a.compareTo(b));

  // Best sellers
  Map<String, int> itemCounts = {};
  Map<String, double> itemRevenue = {};
  for (var sale in sales) {
    for (var item in sale.items) {
      final name = item.nama ?? 'Unknown';
      final qty = item.quantity ?? 1;
      final price = (item.hargaJual ?? 0).toDouble();
      itemCounts[name] = (itemCounts[name] ?? 0) + qty;
      itemRevenue[name] = (itemRevenue[name] ?? 0) + (price * qty);
    }
  }
  final bestSellers = itemCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Center(
              child: pw.Text(
                'MONTHLY REPORT',
                style: pw.TextStyle(
                  color: PdfColors.brown,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                monthYear,
                style: pw.TextStyle(
                  color: PdfColors.brown,
                  fontSize: 18,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Store Info
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(store.title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text(store.description),
                  pw.Text(store.phone),
                  if (store.footer != null) pw.Text(store.footer!, style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Cards
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildSummaryCard('Total Revenue', 'RM ${_formatCurrency(totalRevenue)}'),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildSummaryCard('Total Orders', '$totalOrders'),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildSummaryCard('Total Expenses', 'RM ${_formatCurrency(totalExpenses)}'),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _buildSummaryCard('Est. Profit', 'RM ${_formatCurrency(profit)}'),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Payment Methods
            pw.Text('Payment Methods', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.brown),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Method', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Transactions', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...paymentCounts.entries.map((e) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(e.key.toUpperCase())),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${e.value}')),
                    pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('RM ${_formatCurrency(paymentTotals[e.key] ?? 0)}')),
                  ],
                )),
              ],
            ),
            pw.SizedBox(height: 20),

            // Best Sellers
            pw.Text('Best Sellers', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            ...bestSellers.take(10).map((entry) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(entry.key),
                  pw.Text('${entry.value} sold - RM ${_formatCurrency(itemRevenue[entry.key] ?? 0)}'),
                ],
              ),
            )),
            pw.SizedBox(height: 20),

            // Daily Breakdown
            pw.Text('Daily Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Orders', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Revenue', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...sortedDates.map((date) {
                  final daySales = dailySales[date]!;
                  final dayTotal = daySales.fold<double>(0, (sum, s) => sum + s.totalHarga);
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateFormat('dd MMM yyyy').format(date))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${daySales.length}')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('RM ${_formatCurrency(dayTotal)}')),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // Footer
            pw.Center(
              child: pw.Text(
                'Generated on ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
              ),
            ),
          ],
        );
      },
    ),
  );

  final output = await getApplicationDocumentsDirectory();
  final file = File('${output.path}/monthly_report_${monthYear.replaceAll(' ', '_')}.pdf');
  final bytes = await pdf.save();
  await file.writeAsBytes(bytes);

  String defaultFileName = 'Monthly-Report-${monthName}-${year}.pdf';
  String? outputFile;
  try {
    outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Monthly Report',
      fileName: defaultFileName,
      // FileType.any: FileType.custom + allowedExtensions throws
      // ArgumentError on some platforms; the default file name already
      // ends with .pdf so extension filtering is unnecessary.
      type: FileType.any,
      // bytes are REQUIRED by file_picker on Android & iOS (the plugin
      // writes the file itself there); ignored on desktop.
      bytes: bytes,
      lockParentWindow: true,
    );
  } catch (e) {
    throw Exception('Save dialog failed: $e');
  }

  if (outputFile == null || outputFile.isEmpty) {
    // User cancelled — clean up the temp file.
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
    return PdfExportResult.cancelled;
  }

  final target =
      outputFile.toLowerCase().endsWith('.pdf') ? outputFile : '$outputFile.pdf';

  // On Android/iOS the plugin already wrote `bytes` to the chosen
  // location, and the returned path may be a virtual SAF URI
  // (e.g. /document/document:123) that dart:io cannot open — never
  // rewrite it there. Desktop: the plugin only returns a path, so
  // write the content if the file is missing or empty.
  final isMobile = Platform.isAndroid || Platform.isIOS;
  if (!isMobile) {
    final saved = File(target);
    if (!await saved.exists() || await saved.length() == 0) {
      try {
        await saved.writeAsBytes(bytes);
      } catch (e) {
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}
        throw Exception('Could not write PDF file: $e');
      }
    }
  }

  try {
    if (await file.exists()) await file.delete();
  } catch (_) {}
  return PdfExportResult.saved;
}

pw.Widget _buildSummaryCard(String title, String value) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.brown100,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.brown200),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 10, color: PdfColors.brown700)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.brown900)),
      ],
    ),
  );
}

String _formatCurrency(double amount) {
  return amount.toStringAsFixed(2);
}
