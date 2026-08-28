import 'package:pos/controller/due_payment_controller.dart';
import 'package:pos/pages/drawer.dart';
import 'package:pos/service/database.dart';
import 'package:pos/utils/constant.dart';
import 'package:pos/utils/date_utils.dart';
import 'package:pos/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';

class DuePayment extends StatefulWidget {
  const DuePayment({super.key});

  @override
  State<DuePayment> createState() => _DuePaymentState();
}

class _DuePaymentState extends State<DuePayment> with SignalsMixin {
  @override
  Widget build(BuildContext context) {
    final payment = duePaymentController.payments.watch(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Due Payments'),
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        centerTitle: false,
        actions: [
          ShadButton.ghost(
            onPressed: () {
              duePaymentController.payments.refresh();
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
                await Database().duePaymentSync();
                await duePaymentController.payments.refresh();
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
        padding: const EdgeInsets.only(bottom: 100),
        child: payment.map(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('There is no Data'));
            }
            if (PlatformExtension.isMobile) {
              return Column(
                children: items
                    .map((i) => Card(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          shadowColor: Colors.black12,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: CircleAvatar(
                              backgroundColor: (i.status == 'paid' ? Colors.green : Colors.red).withValues(alpha: 0.1),
                              child: Icon(
                                i.status == 'paid' ? Icons.check_circle : Icons.warning,
                                color: i.status == 'paid' ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text('${i.name} ${i.invoice != null ? '(${i.invoice})' : ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                ShadBadge(
                                  backgroundColor: i.status == 'paid' ? Colors.green : Colors.red,
                                  child: Text(i.status.toUpperCase()),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currency.format(i.amount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Due: ${dateWithoutTime.format(i.dueDate)}',
                                  style: TextStyle(
                                      color: i.status == 'paid' ? Colors.green : Colors.red,
                                      fontStyle: FontStyle.italic),
                                )
                              ],
                            ),
                            trailing: const Icon(Icons.edit, color: Colors.blue),
                            onTap: () {
                              duePaymentController.paymentSelected.value = i;
                              context.push('/due-payment/form');
                            },
                          ),
                        ))
                    .toList(),
              );
            }
            return DataTable(
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Note')),
                DataColumn(label: Text('Incoming')),
                DataColumn(label: Text('Tempo')),
                DataColumn(label: Text('More')),
              ],
              dataRowMaxHeight: 80.0,
              rows: items
                  .map((item) => DataRow(cells: [
                        DataCell(Text(item.id.toString())),
                        DataCell(SizedBox(
                          width: 180,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name),
                              Text(item.invoice ?? ''),
                            ],
                          ),
                        )),
                        DataCell(Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.itemName ?? ''),
                            Text('${item.itemAmount} Items')
                          ],
                        )),
                        DataCell(Text(currency.format(item.amount))),
                        DataCell(
                          item.status == 'paid'
                              ? ShadBadge(
                                  backgroundColor: Colors.green,
                                  child: Text(item.status.toUpperCase()),
                                )
                              : ShadBadge.destructive(
                                  child: Text(item.status.toUpperCase()),
                                ),
                        ),
                        DataCell(Text(item.note ?? '')),
                        DataCell(Text(dateWithoutTime.format(item.dateIn))),
                        DataCell(Text(dateWithoutTime.format(item.dueDate))),
                        DataCell(
                          const Icon(Icons.more_horiz),
                          onTap: () {
                            duePaymentController.paymentSelected.value = item;
                            context.push('/due-payment/form');
                          },
                        ),
                      ]))
                  .toList(),
            );
          },
          error: (error, __) => Center(
            child: Text('$error'),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown[800],
        foregroundColor: Colors.white,
        onPressed: () => context.push('/due-payment/form'),
        tooltip: 'Add Due Payment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
