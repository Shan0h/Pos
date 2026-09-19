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

  // The exact period the report covers (first..last day of the month) —
  // printed in the document so an empty-looking PDF is self-explanatory.
  final periodStart = DateTime(month.year, month.month, 1);
  final periodEnd = DateTime(month.year, month.month + 1, 0);
  final periodLabel =
      '${DateFormat('dd MMM yyyy').format(periodStart)} – ${DateFormat('dd MMM yyyy').format(periodEnd)}';

  // Calculate totals
  final totalRevenue = sales.fold<double>(0, (sum, s) => sum + s.totalHarga);
  final totalOrders = sales.length;
  final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.realAmount);
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

  Map<DateTime, double> dailyExpenses = {};
  for (var expense in expenses) {
    if (expense.createdAt != null) {
      final date = DateTime(expense.createdAt!.year, expense.createdAt!.month, expense.createdAt!.day);
      dailyExpenses[date] = (dailyExpenses[date] ?? 0) + expense.realAmount;
    }
  }

  final allDates = <DateTime>{...dailySales.keys, ...dailyExpenses.keys};
  final sortedDates = allDates.toList()..sort((a, b) => a.compareTo(b));

  // Best sellers
  Map<String, int> itemCounts = {};
  Map<String, double> itemRevenue = {};
  for (var sale in sales) {
    for (var item in sale.items) {
      final name = item.nama ?? 'Unknown';
      final qty = item.quantity ?? 1;
      // Effective selling price after item discount
      final effectivePrice = (item.diskonPersen == null || item.diskonPersen == 0)
          ? item.price
          : item.price - (item.price * (item.diskonPersen! / 100));
      itemCounts[name] = (itemCounts[name] ?? 0) + qty;
      itemRevenue[name] = (itemRevenue[name] ?? 0) + (effectivePrice * qty);
    }
  }
  final bestSellers = itemCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  pdf.addPage(
    // MultiPage with top-level items so busy months paginate onto more
    // pages instead of failing with column overflow.
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context context) => [
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
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            periodLabel,
            style: const pw.TextStyle(
              color: PdfColors.grey600,
              fontSize: 11,
            ),
          ),
        ),
        pw.SizedBox(height: 20),

        // Store Info
        pw.Container(
          width: double.infinity,
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

        // Empty-period hint: the export worked, the period simply had no
        // fulfilled sales — shown prominently so it never looks broken.
        if (sales.isEmpty)
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              border: pw.Border.all(color: PdfColors.amber200),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Text(
                'No fulfilled sales in this period',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.brown700,
                ),
              ),
            ),
          ),

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
            if (paymentCounts.isEmpty)
              _buildNoDataRow(3),
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
        if (bestSellers.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: pw.Text('No data', style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 11)),
          )
        else
          ...bestSellers.take(10).map((entry) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Text(entry.key)),
                pw.SizedBox(width: 8),
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
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Revenue', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Expenses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            if (sortedDates.isEmpty)
              _buildNoDataRow(3),
            ...sortedDates.map((date) {
              final daySales = dailySales[date] ?? [];
              final dayRevenue = daySales.fold<double>(0, (sum, s) => sum + s.totalHarga);
              final dayExpense = dailyExpenses[date] ?? 0;
              return pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateFormat('dd MMM yyyy').format(date))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('RM ${_formatCurrency(dayRevenue)}')),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('RM ${_formatCurrency(dayExpense)}')),
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

/// A single italic "No data" row spanning [columns] cells, shown in the
/// Payment Methods / Daily Breakdown tables when the period is empty.
pw.TableRow _buildNoDataRow(int columns) {
  return pw.TableRow(
    children: List.generate(
      columns,
      (i) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: i == 0
            ? pw.Text('No data',
                style: const pw.TextStyle(
                    color: PdfColors.grey600, fontSize: 11, fontStyle: pw.FontStyle.italic))
            : pw.SizedBox(),
      ),
    ),
  );
}

String _formatCurrency(double amount) {
  return amount.toStringAsFixed(2);
}
