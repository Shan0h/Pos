import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:pos/controller/expenses_controller.dart';
import 'package:pos/controller/inventory_controller.dart';
import 'package:pos/controller/report_controller.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/model/user_model.dart';
import 'package:pos/pages/drawer.dart';
import 'package:pos/pages/report/report_bestseller.dart';
import 'package:pos/pages/report/report_delete_dialog.dart';
import 'package:pos/pages/report/report_out_of_stock_all.dart';
import 'package:pos/pages/report/report_revenue.dart';
import 'package:pos/pages/report/report_sync_dialog.dart';
import 'package:pos/pages/report/report_visitor_weekly.dart';
import 'package:pos/pages/report/report_visitors.dart';
import 'package:pos/service/database.dart';
import 'package:pos/utils/constant.dart';
import 'package:pos/utils/date_utils.dart';
import 'package:pos/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

final isRefreshReport = signal(false);

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  int touchedIndex = -1;
  @override
  Widget build(BuildContext context) {
    final isLoading = isRefreshReport.watch(context);
    final dateRange = reportController.dateRange.watch(context);
    final isMobile = context.isMobile;
    final report = reportController.report.watch(context);
    final reportToday = reportController.reportToday.watch(context);
    final reportYesteday = reportController.reportYesterday.watch(context);
    final reportOutOfStcok = reportController.reportOutOfStcok.watch(context);
    final rentRevenue = reportController.rentRevenue.watch(context);
    final expenses = expensesController.expenses.watch(context);
    final theme = ShadTheme.of(context);
    final screen = isMobile ? context.width : (context.width - 60) / 3;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          ShadButton.ghost(
            onPressed: isLoading
                ? null
                : () async {
                    isRefreshReport.value = true;
                    await reportController.report.refresh();
                    await reportController.reportToday.refresh();
                    await reportController.reportYesterday.refresh();
                    await Future.delayed(Durations.medium1);
                    isRefreshReport.value = false;
                  },
            icon: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.refresh,
                size: 16,
              ),
            ),
            child: Text(isLoading ? 'Loading...' : 'Refresh'),
          ),
          PopupMenuButton<String>(
            onSelected: (item) async {
              if (item == 'sync') {
                await Database().checkIsReportSynced();
                reportController.report.refresh();
                reportController.reportToday.refresh();
                reportController.reportYesterday.refresh();
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton.outline(
                    child: Text(
                        'Filter: ${dateWithoutTime.format(dateRange.first)} - ${dateWithoutTime.format(dateRange.last)}'),
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
                        reportController.dateRange.value = [
                          results.first!,
                          results.last!
                        ];
                      }
                    }),
                ShadButton(
                  child: const Text('Reset'),
                  onPressed: () => reportController.dateRange.value = [
                    DateTime.now().subtract(const Duration(days: 30)),
                    DateTime.now()
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                Column(
                  children: [
                    _buildSummaryCard('Total Sales Today', currency.format(sumReport(reportToday.value ?? [])), Icons.today, Colors.green, screen),
                    const SizedBox(height: 10),
                    _buildSummaryCard('Total Sales Yesterday', currency.format(sumReport(reportYesteday.value ?? [])), Icons.history, Colors.blue, screen),
                  ],
                ),
                if (report.hasValue)
                  Column(
                    children: [
                      _buildSummaryCard('Total Revenue', currency.format(sumReport(report.value ?? [])), Icons.monetization_on, Colors.teal, screen),
                      const SizedBox(height: 10),
                      _buildSummaryCard('Estimated Profit', currency.format(report.value!.fold(0, (p, c) => p + c.totalHarga.toInt()) - report.value!.fold(0, (p, c) => p + c.items.fold(0, (p, c) => p + c.hargaDasar! * c.quantity!))), Icons.trending_up, Colors.indigo, screen),
                    ],
                  ),
                Column(
                  children: [
                    _buildSummaryCard('Total Orders Today', '${reportToday.value?.length ?? 0} Orders', Icons.receipt_long, Colors.orange, screen),
                    const SizedBox(height: 10),
                    if (expenses.hasValue)
                      _buildSummaryCard('Total Expenses', currency.format(expenses.value!.fold(0, (p, c) => p + c.amount)), Icons.money_off, Colors.red, screen),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                ReportVisitors(width: screen),
                ShadCard(
                  width: screen,
                  title: const Text('Out of Stock'),
                  description: Text(
                      'You have ${reportOutOfStcok.value?.length} item out of stock.'),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      if (reportOutOfStcok.hasValue) ...[
                        ...reportOutOfStcok.value!.take(8).map(
                              (n) => Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  '${n.nama} - ${n.jumlahBarang} Item Left',
                                                  style: theme.textTheme.small),
                                              const SizedBox(height: 4),
                                              Text(
                                                  '${currency.format(n.hargaDasar)} - ${n.code}',
                                                  style: theme.textTheme.muted),
                                            ],
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                          onPressed: () {
                                            inventoryController
                                                .inventorySelected.value = n;
                                            context.push('/inventory/form');
                                          },
                                          icon: const Icon(Icons.arrow_right))
                                    ],
                                  ),
                                  const Divider(),
                                ],
                              ),
                            ),
                        ShadButton(
                          width: double.infinity,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ReportOutOfStock(
                                      items: reportOutOfStcok.value!)),
                            );
                          },
                          child: const Text('See All'),
                        ),
                      ]
                    ],
                  ),
                ),
                ReportBestSeller(width: screen),
              ],
            ),
            const SizedBox(height: 20),
            const ShadCard(
              title: Text('Report Revenue by Day'),
              child: Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: ReportRevenue(),
              ),
            ),
            const SizedBox(height: 20),
            const ReportVisitorWeekLy(),
            const SizedBox(height: 20),
            ShadCard(
              title: const Text('List Sales'),
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  children: [
                    ShadAccordion<PenjualanModel>.multiple(
                      children: (report.value ?? []).reversed.map(
                            (detail) => ShadAccordionItem(
                              value: detail,
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 5,
                                    runSpacing: 5,
                                    children: [
                                      Text(
                                        '${detail.id}.',
                                        style: ShadTheme.of(context)
                                            .textTheme
                                            .small,
                                      ),
                                      FutureBuilder<UserModel?>(
                                        future: Database()
                                            .getUserById(detail.staffId),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Text(
                                                snapshot.data?.nama ?? 'Admin');
                                          }
                                          return const Text('Admin');
                                        },
                                      ),
                                    ],
                                  ),
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 5,
                                    runSpacing: 5,
                                    children: [
                                      Text(
                                        '${currency.format(detail.totalHarga)} (${detail.totalItem.toString()})',
                                        style: ShadTheme.of(context)
                                            .textTheme
                                            .small,
                                      ),
                                      Text(
                                          dateDayWithTime
                                              .format(detail.createdAt),
                                          style: ShadTheme.of(context)
                                              .textTheme
                                              .muted),
                                    ],
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  ...detail.items.map(
                                    (val) => ListTile(
                                      title: Text('${val.nama} - ${val.code}'),
                                      subtitle: Row(
                                        children: [
                                          Text('${val.quantity} x '),
                                          Text(val.diskonPersen == null ||
                                                  val.diskonPersen == 0
                                              ? currency.format(val.hargaJual)
                                              : currency.format(val.hargaJual! -
                                                  val.hargaJual! *
                                                      (val.diskonPersen! /
                                                          100))),
                                        ],
                                      ),
                                      trailing: Text(val.diskonPersen == null ||
                                              val.diskonPersen == 0
                                          ? currency.format(
                                              val.hargaJual! * val.quantity!)
                                          : currency.format((val.hargaJual! -
                                                  val.hargaJual! *
                                                      (val.diskonPersen! /
                                                          100)) *
                                              val.quantity!)),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ShadButton.secondary(
                                        onPressed: () {
                                          showShadDialog(
                                            context: context,
                                            builder: (context) =>
                                                ReportSyncDialog(
                                              id: detail.id!,
                                              detail: detail,
                                            ),
                                          );
                                        },
                                        icon: const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Icon(
                                            Icons.sync,
                                            size: 16,
                                          ),
                                        ),
                                        child: const Text('Sync'),
                                      ),
                                      ShadButton.outline(
                                        onPressed: () {
                                          showShadDialog(
                                              context: context,
                                              builder: (context) =>
                                                  ReportDeleteDialog(
                                                      id: detail.id!));
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
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
