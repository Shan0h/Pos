import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:pos/controller/expenses_controller.dart';
import 'package:pos/controller/inventory_controller.dart';
import 'package:pos/controller/report_controller.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/model/user_model.dart';
import 'package:pos/pages/report/report_bestseller.dart';
import 'package:pos/pages/report/report_delete_dialog.dart';
import 'package:pos/pages/report/report_out_of_stock_all.dart';
import 'package:pos/pages/report/report_revenue.dart';
import 'package:pos/pages/report/report_visitor_weekly.dart';
import 'package:pos/pages/report/report_visitors.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/widget/pdf_receipt_generator.dart';
import 'package:pos/widget/monthly_report_pdf_generator.dart';
import 'package:pos/controller/store_controller.dart';
import 'package:pos/utils/constant.dart';
import 'package:pos/utils/date_utils.dart';
import 'package:pos/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

final isRefreshReport = signal(false);

/// True while any PDF export is running (Formal or Monthly). Buttons
/// disable and show progress so the export can never look unresponsive.
final isGeneratingPdf = signal(false);

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
    final isGenerating = isGeneratingPdf.watch(context);
    final dateRange = reportController.dateRange.watch(context);
    final isMobile = context.isMobile;
    final report = reportController.report.watch(context);
    final reportToday = reportController.reportToday.watch(context);
    final reportYesteday = reportController.reportYesterday.watch(context);
    final reportOutOfStcok = reportController.reportOutOfStcok.watch(context);
    final expenses = expensesController.expenses.watch(context);
    final theme = ShadTheme.of(context);
    final screen = isMobile ? context.width : (context.width - 60) / 3;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: context.panelBackground,
        foregroundColor: context.appTextColor,
        centerTitle: false,
        actions: [
          if (!isMobile)
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
          if (!isMobile)
            ShadButton.ghost(
              onPressed: isGenerating
                  ? null
                  : () => _generateMonthlyPdf(context),
              icon: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.summarize, size: 16),
              ),
              child: Text(isGenerating ? 'Generating...' : 'Monthly PDF'),
            ),
          PopupMenuButton<String>(
            onSelected: (item) async {
              if (item == 'refresh') {
                if (isLoading) return;
                isRefreshReport.value = true;
                await reportController.report.refresh();
                await reportController.reportToday.refresh();
                await reportController.reportYesterday.refresh();
                await Future.delayed(Durations.medium1);
                isRefreshReport.value = false;
              } else if (item == 'monthly_pdf') {
                await _generateMonthlyPdf(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (isMobile)
                const PopupMenuItem<String>(
                  value: 'refresh',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
              if (isMobile)
                const PopupMenuItem<String>(
                  value: 'monthly_pdf',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.summarize),
                      SizedBox(width: 8),
                      Text('Monthly PDF'),
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
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
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
                  child: const Text('3 Months'),
                  onPressed: () => reportController.dateRange.value = [
                    DateTime.now().subtract(const Duration(days: 90)),
                    DateTime.now()
                  ],
                ),
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
                    _buildSummaryCard('Total Sales Today', currency.format(sumReport(reportToday.value ?? [])), Icons.today, const Color(0xFF8B5E3C), screen),
                    const SizedBox(height: 10),
                    _buildSummaryCard('Total Sales Yesterday', currency.format(sumReport(reportYesteday.value ?? [])), Icons.history, const Color(0xFF6B4226), screen),
                  ],
                ),
                if (report.hasValue)
                  Column(
                    children: [
                      _buildSummaryCard('Total Revenue', currency.format(sumReport(report.value ?? [])), Icons.monetization_on, const Color(0xFF5D3A1A), screen),
                      const SizedBox(height: 10),
                      _buildSummaryCard('Estimated Profit', currency.format(report.value!.fold<double>(0, (p, c) => p + c.totalHarga) - report.value!.fold<double>(0, (p, c) => p + c.items.fold<double>(0, (p, c2) => p + (c2.hargaDasar ?? 0) * (c2.quantity ?? 0)))), Icons.trending_up, const Color(0xFFA0522D), screen),
                    ],
                  ),
                Column(
                  children: [
                    _buildSummaryCard('Total Orders Today', '${reportToday.value?.length ?? 0} Orders', Icons.receipt_long, const Color(0xFF7B5B3A), screen),
                    const SizedBox(height: 10),
                    if (expenses.hasValue)
                      _buildSummaryCard('Total Expenses', currency.format(expenses.value!.fold(0, (p, c) => p + c.amount)), Icons.money_off, const Color(0xFF9C6634), screen),
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
                                        future: userService
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
                                    (val) {
                                      final unitPrice =
                                          val.diskonPersen == null ||
                                                  val.diskonPersen == 0
                                              ? val.price
                                              : val.price -
                                                  val.price *
                                                      (val.diskonPersen! /
                                                          100);
                                      return ListTile(
                                        title: Text('${val.nama} - ${val.code}'),
                                        subtitle: Row(
                                          children: [
                                            Text('${val.quantity ?? 0} x '),
                                            Text(currency.format(unitPrice)),
                                          ],
                                        ),
                                        trailing: Text(
                                            currency.format((val.quantity ?? 0) *
                                                unitPrice)),
                                      );
                                    },
                                  ),
                                  Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ShadButton.outline(
                                        onPressed: isGenerating
                                            ? null
                                            : () async {
                                                isGeneratingPdf.value = true;
                                                try {
                                                  final store = storeController
                                                          .store
                                                          .value
                                                          .value ??
                                                      await storeService
                                                          .getStore();
                                                  final user =
                                                      await userService
                                                          .getUserById(
                                                              detail.staffId);
                                                  if (store == null) {
                                                    if (context.mounted) {
                                                      ShadToaster.of(context)
                                                          .show(
                                                        const ShadToast(
                                                          backgroundColor:
                                                              Colors.red,
                                                          description: Text(
                                                              'Store info is missing!'),
                                                        ),
                                                      );
                                                    }
                                                    return;
                                                  }
                                                  final result =
                                                      await pdfReceiptGenerator(
                                                    store: store,
                                                    sale: detail,
                                                    staffName:
                                                        user?.nama ?? 'Admin',
                                                  );
                                                  if (context.mounted) {
                                                    switch (result) {
                                                      case PdfExportResult
                                                            .saved:
                                                        ShadToaster.of(context)
                                                            .show(
                                                          const ShadToast(
                                                            backgroundColor:
                                                                Color(0xFF8B5E3C),
                                                            description: Text(
                                                                'Receipt PDF saved!'),
                                                          ),
                                                        );
                                                      case PdfExportResult
                                                            .cancelled:
                                                        ShadToaster.of(context)
                                                            .show(
                                                          const ShadToast(
                                                            description: Text(
                                                                'Save cancelled'),
                                                          ),
                                                        );
                                                    }
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ShadToaster.of(context)
                                                        .show(
                                                      ShadToast(
                                                        description: Text(
                                                            'Failed to generate PDF: $e'),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                } finally {
                                                  isGeneratingPdf.value = false;
                                                }
                                              },
                                        icon: const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Icon(
                                            Icons.picture_as_pdf,
                                            size: 16,
                                          ),
                                        ),
                                        child: const Text('Formal PDF'),
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

  Future<void> _generateMonthlyPdf(BuildContext context) async {
    if (isGeneratingPdf.value) return;
    isGeneratingPdf.value = true;
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final store = storeController.store.value.value ??
          await storeService.getStore();
      if (store == null) {
        if (context.mounted) {
          ShadToaster.of(context).show(
            const ShadToast(
              description: Text('Store info is missing!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final monthlySales =
          await reportService.getReport(start: firstDay, end: lastDay);
      // Expenses for the calendar month of the report, not the page filter.
      final monthlyExpenses =
          await expensesService.getExpenses(start: firstDay, end: lastDay);

      final result = await monthlyReportPdfGenerator(
        store: store,
        sales: monthlySales,
        expenses: monthlyExpenses,
        month: now,
      );

      if (context.mounted) {
        switch (result) {
          case PdfExportResult.saved:
            ShadToaster.of(context).show(
              const ShadToast(
                backgroundColor: Color(0xFF8B5E3C),
                description: Text('Monthly report PDF saved!'),
              ),
            );
          case PdfExportResult.cancelled:
            ShadToaster.of(context).show(
              const ShadToast(
                description: Text('Save cancelled'),
              ),
            );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            description: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isGeneratingPdf.value = false;
    }
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: context.panelBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.appShadowColor,
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
                  style: TextStyle(
                    fontSize: 14,
                    color: context.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.appTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
