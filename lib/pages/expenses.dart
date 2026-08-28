import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:pos/controller/expenses_controller.dart';
import 'package:pos/pages/drawer.dart';
import 'package:pos/pages/expenses/expenses_form.dart';
import 'package:pos/service/database.dart';
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
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
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
                await Database().expensesSync();
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
                ShadButton(
                  child: const Text('Reset'),
                  onPressed: () => expensesController.dateRange.value = [
                    DateTime.now().subtract(const Duration(days: 30)),
                    DateTime.now()
                  ],
                )
              ],
            ),
            expenses.map(
              data: (data) {
                if (data.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('There is no Data'),
                    ),
                  );
                }
                if (PlatformExtension.isMobile) {
                  return Column(
                    children: data
                        .map((v) => Card(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              shadowColor: Colors.black12,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                                  child: const Icon(Icons.monetization_on, color: Colors.green),
                                ),
                                title: Text(v.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      currency.format(v.amount),
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (v.note != null && v.note!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(v.note!, style: const TextStyle(fontStyle: FontStyle.italic)),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  dateWithoutTime.format(v.createdAt!),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                            ))
                        .toList(),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Note')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Option')),
                        ],
                        rows: data
                            .map((val) => DataRow(cells: [
                                  DataCell(Text(val.id.toString())),
                                  DataCell(Text(val.title)),
                                  DataCell(Text(currency.format(val.amount))),
                                  DataCell(Text(val.note ?? '')),
                                  DataCell(Text(dateWithTime.format(
                                      val.createdAt ?? DateTime.now()))),
                                  DataCell(
                                    ShadButton.destructive(
                                      onPressed: () {
                                        expensesController.expenses.refresh();
                                      },
                                      icon: const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Icon(
                                          Icons.delete,
                                          size: 16,
                                        ),
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ),
                                ]))
                            .toList()),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
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
}
