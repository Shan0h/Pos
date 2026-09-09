import 'dart:io';
import 'package:pos/model/store_model.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/utils/constant.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:intl/intl.dart';

/// Outcome of a PDF export so callers can toast success vs cancelled.
enum PdfExportResult { saved, cancelled }

Future<PdfExportResult> pdfReceiptGenerator({
  required StoreModel store,
  required PenjualanModel sale,
  required String staffName,
}) async {
  final Document pdf = Document(deflate: zlib.encode);
  pdf.addPage(
    Page(
        pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
        margin: const EdgeInsets.all(40),
        orientation: PageOrientation.portrait,
        theme: ThemeData.base(),
        build: (Context context) {
          return ListView(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(bottom: 20),
                alignment: Alignment.center,
                child: Text("INVOICE / RECEIPT", style: const TextStyle(color: PdfColors.teal, fontSize: 28, fontWeight: FontWeight.bold)),
              ),
              Container(height: 2.0, width: double.infinity, color: PdfColors.teal, margin: const EdgeInsets.fromLTRB(0, 10, 0, 10)),
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(store.title, style: const TextStyle(color: PdfColors.teal, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text(store.description),
                        Text(store.phone),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text("Invoice No: ${sale.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text("Date: ${DateFormat('EEEE, dd MMM yyyy').format(sale.createdAt)}"),
                        Text("Time: ${DateFormat('HH:mm').format(sale.createdAt)}"),
                        Text("Staff: $staffName"),
                      ],
                    ),
                  ]),
              Container(height: 1.0, width: double.infinity, color: PdfColors.grey300, margin: const EdgeInsets.fromLTRB(0, 20, 0, 20)),
              
              // Items Table
              Table(
                  border: const TableBorder(
                      horizontalInside: BorderSide(width: 1, color: PdfColors.grey300),
                      bottom: BorderSide(width: 2, color: PdfColors.teal),
                      top: BorderSide(width: 2, color: PdfColors.teal),
                  ),
                  tableWidth: TableWidth.max,
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: <TableRow>[
                    TableRow(children: <Widget>[
                      Container(padding: const EdgeInsets.all(8), child: Text("Item Description", style: const TextStyle(fontWeight: FontWeight.bold))),
                      Container(padding: const EdgeInsets.all(8), child: Text("Category", style: const TextStyle(fontWeight: FontWeight.bold))),
                      Container(padding: const EdgeInsets.all(8), alignment: Alignment.centerRight, child: Text("Qty", style: const TextStyle(fontWeight: FontWeight.bold))),
                      Container(padding: const EdgeInsets.all(8), alignment: Alignment.centerRight, child: Text("Price", style: const TextStyle(fontWeight: FontWeight.bold))),
                      Container(padding: const EdgeInsets.all(8), alignment: Alignment.centerRight, child: Text("Total", style: const TextStyle(fontWeight: FontWeight.bold))),
                    ]),
                    for (ProductItemModel item in sale.items)
                      TableRow(children: <Widget>[
                        Container(padding: const EdgeInsets.all(8), child: Text(item.nama ?? '')),
                        Container(padding: const EdgeInsets.all(8), child: Text(item.category ?? '-')),
                        Container(padding: const EdgeInsets.all(8), alignment: Alignment.centerRight, child: Text(item.quantity.toString())),
                        Container(padding: const EdgeInsets.all(8), alignment: Alignment.centerRight, child: Text(currency.format(item.hargaJual))),
                        Container(padding: const EdgeInsets.all(8), alignment: Alignment.centerRight, child: Text(currency.format((item.hargaJual ?? 0) * (item.quantity ?? 1)))),
                      ]),
                  ]),
              
              SizedBox(height: 20),
              
              // Totals
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 250,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Subtotal", style: const TextStyle(color: PdfColors.grey700)),
                            Text(currency.format(sale.totalHarga)),
                          ]
                        ),
                        if (sale.diskon > 0) ...[
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Discount", style: const TextStyle(color: PdfColors.red)),
                              Text("- ${currency.format(sale.diskon)}", style: const TextStyle(color: PdfColors.red)),
                            ]
                          ),
                        ],
                        SizedBox(height: 5),
                        Container(height: 1, color: PdfColors.grey300),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Grand Total", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(currency.format(sale.totalHarga), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: PdfColors.teal)),
                          ]
                        ),
                        SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Payment Method", style: const TextStyle(color: PdfColors.grey700)),
                            Text(sale.paymentMethod?.toUpperCase() ?? 'N/A'),
                          ]
                        ),
                        if (sale.paymentMethod?.toLowerCase() == 'cash' && sale.tenderedAmount != null) ...[
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Amount Tendered", style: const TextStyle(color: PdfColors.grey700)),
                              Text(currency.format(sale.tenderedAmount)),
                            ]
                          ),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Change", style: const TextStyle(color: PdfColors.grey700)),
                              Text(currency.format(sale.changeAmount ?? 0)),
                            ]
                          ),
                        ]
                      ]
                    )
                  )
                ]
              ),
              
              SizedBox(height: 40),
              
              // Footer
              Container(height: 1.0, width: double.infinity, color: PdfColors.grey300, margin: const EdgeInsets.only(bottom: 20)),
              Center(child: Text(store.footer ?? 'Thank you for your business!', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
              if (store.subFooter != null)
                Center(child: Text(store.subFooter!, style: const TextStyle(fontSize: 12, color: PdfColors.grey600))),
            ],
          );
        }),
  );

  final output = await getApplicationDocumentsDirectory();
  final file = File("${output.path}/receipt_temp.pdf");
  final bytes = await pdf.save();
  await file.writeAsBytes(bytes);

  String defaultFileName = 'Receipt-${sale.id}-${DateFormat('yyyyMMdd').format(sale.createdAt)}.pdf';
  String? outputFile;
  try {
    outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Formal Receipt PDF',
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
