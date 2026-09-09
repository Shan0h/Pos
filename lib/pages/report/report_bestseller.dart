import 'package:collection/collection.dart';
import 'package:pos/controller/report_controller.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/pages/report/report_bestseller_all.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

class ReportBestSeller extends StatelessWidget {
  final double width;
  const ReportBestSeller({super.key, required this.width});

  /// Pure derivation of the current report value — recomputed on every
  /// rebuild, so counts can never accumulate across report changes.
  List<ProductItemModel> computeBestSellers(List<PenjualanModel> sales) {
    final Map<int, ProductItemModel> totals = {};
    for (final sale in sales) {
      for (final item in sale.items) {
        final key = item.id;
        if (key == null) continue;
        final existing = totals[key];
        if (existing != null) {
          existing.quantity = (existing.quantity ?? 0) + (item.quantity ?? 0);
        } else {
          totals[key] = item.copy();
        }
      }
    }
    return totals.values
        .sorted((a, b) => (b.quantity ?? 0).compareTo(a.quantity ?? 0))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = reportController.report.watch(context);
    final items = computeBestSellers(reportState.value ?? []);

    final theme = ShadTheme.of(context);
    return ShadCard(
      width: width,
      title: const Text('Best Seller'),
      description: const Text('Items base on how many item sold'),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...items.take(10).map(
                (n) => Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.nama ?? '-', style: theme.textTheme.small),
                                const SizedBox(height: 4),
                                Text(' ${n.quantity ?? 0} Sold',
                                    style: theme.textTheme.muted),
                              ],
                            ),
                          ),
                        ),
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
                    builder: (context) => ReportBestSellerAll(items: items)),
              );
            },
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }
}
