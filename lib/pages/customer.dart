import 'package:pos/controller/customer_controller.dart';
import 'package:pos/pages/customer/customer_list.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

class Customer extends HookWidget {
  const Customer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: context.panelBackground,
        foregroundColor: context.appTextColor,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (item) async {
              if (item == 'sync') {
                await customerService.syncCustomers();
                customerController.customer.refresh();
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
      body: const CustomerList(),
      floatingActionButton: FloatingActionButton(
                  backgroundColor: context.panelBackground,
                  foregroundColor: context.appTextColor,
        onPressed: () => context.push('/customer/form'),
        tooltip: 'Add Customer',
        child: const Icon(Icons.add),
      ),
    );
  }
}
