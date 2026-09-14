import 'package:pos/controller/report_controller.dart';
import 'package:pos/pages/report/report_visitors_all.dart';
import 'package:pos/utils/constant.dart';
import 'package:pos/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

class ReportVisitors extends StatelessWidget {
  final double width;
  const ReportVisitors({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final reportIncome = reportController.reportIncome.watch(context);
    // Sort by date and take the LATEST 7 days (the map itself has no
    // guaranteed order). Each entry is one day's orders.
    final days = (reportIncome.value?.keys.toList() ?? <DateTime>[])
      ..sort((a, b) => b.compareTo(a));
    final latest7 = days.take(7);

    return ShadCard(
      width: width,
      title: const Text('Daily Orders'),
      description: const Text('How many orders per day (last 7 days)'),
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (reportIncome.hasValue) ...[
            for (var day in latest7)
              Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(dateWithoutTime.format(day)),
                    subtitle: Text(
                      currency.format(
                          reportIncome.value![day]!
                              .fold<double>(0, (p, c) => p + c.totalHarga)),
                    ),
                    trailing: Text(
                        '${reportIncome.value![day]!.length} Orders',
                        style: ShadTheme.of(context).textTheme.muted),
                  ),
                  const Divider()
                ],
              ),
            ShadButton(
              width: double.infinity,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ReportVisitorAll(items: reportIncome.value!)),
                );
              },
              child: const Text('See All'),
            ),
          ]
        ],
      ),
    );
  }
}
