import 'package:pos/model/penjualan_model.dart';
import 'package:pos/utils/constant.dart';
import 'package:pos/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ReportVisitorAll extends StatelessWidget {
  final Map<DateTime, List<PenjualanModel>> items;
  const ReportVisitorAll({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    // Newest day first.
    final sortedDays = items.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders by Day'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ...ListTile.divideTiles(
              context: context,
              tiles: sortedDays
                  .map(
                    (day) => ListTile(
                      title: Text(dateWithoutTime.format(day)),
                      subtitle: Text(
                        currency.format(items[day]!
                            .fold<double>(0, (p, c) => p + c.totalHarga)),
                      ),
                      trailing: Text('${items[day]!.length} Orders',
                          style: ShadTheme.of(context).textTheme.muted),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
