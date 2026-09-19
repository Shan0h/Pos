import 'dart:io';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:pos/controller/expenses_controller.dart';
import 'package:pos/model/expenses_model.dart';
import 'package:pos/pages/expenses/expenses_form.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/utils/constant.dart';
import 'package:pos/utils/date_utils.dart';
import 'package:pos/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

class Expanses extends StatelessWidget {
  const Expanses({super.key});

  @override
  Widget build(BuildContext context) {
    final dateRange = expensesController.dateRange.watch(context);
    final expenses = expensesController.expenses.watch(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: context.panelBackground,
        foregroundColor: context.appTextColor,
        centerTitle: false,
        actions: [
          ShadButton.ghost(
            onPressed: () {
              expensesController.expenses.refresh();
            },
            icon: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.refresh,
                size: 16,
              ),
            ),
            child: const Text('Refresh'),
          ),
          PopupMenuButton<String>(
            onSelected: (item) async {
              if (item == 'sync') {
                await expensesService.expensesSync();
                await expensesController.expenses.refresh();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'sync',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text('Sync'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ShadButton.outline(
                      child: Text(
                          'Filter Date: ${dateWithoutTime.format(dateRange.first)} - ${dateWithoutTime.format(dateRange.last)}'),
                      onPressed: () async {
                        var results = await showCalendarDatePicker2Dialog(
                          context: context,
                          config: CalendarDatePicker2WithActionButtonsConfig(
                            calendarType: CalendarDatePicker2Type.range,
                          ),
                          dialogSize: const Size(325, 400),
                          value: dateRange,
                          borderRadius: BorderRadius.circular(15),
                        );
                        if (results != null) {
                          expensesController.dateRange.value = [
                            results.first!,
                            results.last!
                          ];
                        }
                      }),
                  const SizedBox(width: 8),
                  ShadButton(
                    child: const Text('Reset'),
                    onPressed: () => expensesController.dateRange.value = [
                      DateTime.now().subtract(const Duration(days: 30)),
                      DateTime.now()
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),
              expenses.map(
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text('No expenses recorded in this period'),
                      ),
                    );
                  }
                  if (PlatformExtension.isMobile) {
                    return Column(
                      children: data.map((v) {
                        final hasImage = v.imagePath != null &&
                            File(v.imagePath!).existsSync();
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          shadowColor: Colors.black12,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showExpenseDetail(context, v),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: hasImage
                                        ? Image.file(
                                            File(v.imagePath!),
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8B5E3C)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                                Icons.receipt_long,
                                                color: Color(0xFF8B5E3C)),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(v.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15)),
                                        if (v.storeName != null &&
                                            v.storeName!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.storefront,
                                                  size: 13,
                                                  color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  v.storeName!,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        if (v.category != null &&
                                            v.category!.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8B5E3C)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              v.category!,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF8B5E3C)),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currency.format(v.realAmount),
                                          style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        dateWithoutTime.format(
                                            v.createdAt ?? DateTime.now()),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 11),
                                      ),
                                      const SizedBox(height: 12),
                                      const Icon(Icons.chevron_right,
                                          color: Colors.grey, size: 20),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Receipt')),
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Store / Merchant')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Option')),
                        ],
                        rows: data.map((val) {
                          final hasImage = val.imagePath != null &&
                              File(val.imagePath!).existsSync();
                          return DataRow(cells: [
                            DataCell(
                              InkWell(
                                onTap: () =>
                                    _showExpenseDetail(context, val),
                                child: hasImage
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        child: Image.file(
                                          File(val.imagePath!),
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.grey
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.receipt_long,
                                            size: 18, color: Colors.grey),
                                      ),
                              ),
                            ),
                            DataCell(
                              InkWell(
                                onTap: () =>
                                    _showExpenseDetail(context, val),
                                child: Text(val.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                            DataCell(Text(val.storeName ?? '-')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5E3C)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(val.category ?? 'General',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8B5E3C))),
                              ),
                            ),
                            DataCell(Text(
                              currency.format(val.realAmount),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            )),
                            DataCell(Text(dateWithTime.format(
                                val.createdAt ?? DateTime.now()))),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility,
                                        size: 18),
                                    tooltip: 'View Details',
                                    onPressed: () =>
                                        _showExpenseDetail(context, val),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    tooltip: 'Delete',
                                    onPressed: () async {
                                      await expensesService
                                          .deleteExpenses(val.id!);
                                      await expensesController.expenses
                                          .refresh();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ],
                  );
                },
                error: (e, __) => Text('$e'),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.panelBackground,
        foregroundColor: context.appTextColor,
        onPressed: () => showShadSheet(
          side: ShadSheetSide.right,
          context: context,
          builder: (context) => const ExpensesForm(),
        ),
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showExpenseDetail(BuildContext context, ExpensesModel expense) {
    final hasImage =
        expense.imagePath != null && File(expense.imagePath!).existsSync();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5E3C).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long,
                  color: Color(0xFF8B5E3C), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                expense.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Paid',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(expense.realAmount),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (expense.storeName != null &&
                  expense.storeName!.isNotEmpty) ...[
                _buildDetailItem(
                    Icons.storefront, 'Store / Merchant', expense.storeName!),
                const SizedBox(height: 10),
              ],
              if (expense.category != null &&
                  expense.category!.isNotEmpty) ...[
                _buildDetailItem(
                    Icons.category, 'Category', expense.category!),
                const SizedBox(height: 10),
              ],
              _buildDetailItem(
                Icons.calendar_today,
                'Date',
                dateWithTime.format(expense.createdAt ?? DateTime.now()),
              ),
              if (expense.note != null && expense.note!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildDetailItem(Icons.notes, 'Note', expense.note!),
              ],
              const SizedBox(height: 16),
              const Text('Receipt Photo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              if (hasImage) ...[
                GestureDetector(
                  onTap: () =>
                      _showFullImagePreview(context, expense.imagePath!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Image.file(
                          File(expense.imagePath!),
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Tap to zoom',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: const Center(
                    child: Text('No receipt attached',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await expensesService.deleteExpenses(expense.id!);
              await expensesController.expenses.refresh();
            },
            icon: const Icon(Icons.delete, color: Colors.red, size: 16),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  void _showFullImagePreview(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
            IconButton(
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
