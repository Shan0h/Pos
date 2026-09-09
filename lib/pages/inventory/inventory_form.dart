import 'package:pos/controller/inventory_controller.dart';
import 'package:pos/main.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/service/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class InventoryForm extends HookWidget {
  InventoryForm({super.key});
  final statusData = {true: 'Active', false: 'Non Active'};
  @override
  Widget build(context) {
    final inventoryFormKey = useMemoized(GlobalKey<FormState>.new);
    final item = inventoryController.inventorySelected.watch(context);
    final editingName = useTextEditingController(text: item?.nama ?? '');
    final editingCode = useTextEditingController(text: item?.code ?? '');
    final editingUkuran = useTextEditingController(text: item?.ukuran ?? '');

    final stock = useState(item?.jumlahBarang ?? 0);
    // Base Price as Cost for Raw Materials
    final editingHargaDasar = useTextEditingController(text: (item?.hargaDasar ?? '0').toString());

    useListenable(editingName);
    useListenable(editingCode);
    useListenable(editingUkuran);
    useListenable(editingHargaDasar);

    final isConnected = isDeviceConnected.watch(context);
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: inventoryFormKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.circle,
                        color: isConnected ? Colors.green : null),
                    ShadButton.ghost(
                      child: const Text('Close'),
                      onPressed: () {
                        inventoryController.inventorySelected.value = null;
                        context.pop();
                      },
                    ),
                  ],
                ),
                ShadInputFormField(
                  controller: editingName,
                  validator: (val) =>
                      val.isEmpty == true ? 'Name is required' : null,
                  label: const Text('Item Name'),
                  placeholder: const Text('Clothes'),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ShadInputFormField(
                        controller: editingCode,
                        label: const Text('Code'),
                        placeholder: const Text('HP08123'),
                      ),
                    ),
                    BarcodeKeyboardListener(
                      bufferDuration: const Duration(milliseconds: 200),
                      onBarcodeScanned: (barcode) async {
                        editingCode.text = barcode.replaceAll('½', '-');
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 5.0),
                        child: ShadButton.ghost(
                          icon: Icon(Icons.barcode_reader),
                        ),
                      ),
                    ),
                    ShadButton.ghost(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () async {
                        String? res = await SimpleBarcodeScanner.scanBarcode(
                          context,
                          lineColor: '#ff6666',
                          cancelButtonText: 'Cancel',
                          isShowFlashIcon: true,
                          scanType: ScanType.barcode,
                        );
                        if (res != null && res != '-1') {
                          editingCode.text = res;
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: ShadInputFormField(
                        controller: editingUkuran,
                        validator: (val) =>
                            val.isEmpty == true ? 'Unit is required' : null,
                        label: const Text('Unit'),
                        placeholder: const Text('ex. kg/pcs/ml'),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 25),
                        child: ShadSelect<int>(
                          placeholder: const Text('Select a Stock'),
                          initialValue: item?.jumlahBarang,
                          options: List.generate(
                              200,
                              (val) =>
                                  ShadOption(value: val, child: Text('$val'))),
                          onChanged: (val) => stock.value = val,
                          selectedOptionBuilder: (context, value) {
                            stock.value = value;
                            return Text('$value');
                          },
                        ),
                      ),
                    )
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ShadInputFormField(
                        controller: editingHargaDasar,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        label: const Text('Cost Price (RM)'),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item != null)
                        ShadButton.destructive(
                          child: const Text('Delete'),
                          onPressed: () {
                            inventoryService
                                .deleteInventory(item.id!)
                                .whenComplete(() {
                              inventoryController.inventorys.refresh();
                              if (context.mounted) Navigator.pop(context);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.blue,
                                    content: const Text(
                                        'Please refresh data to see changes'),
                                    action: SnackBarAction(
                                      label: 'Refresh',
                                      onPressed: () async {},
                                    ),
                                  ),
                                );
                              }
                            });
                          },
                        ),
                      ShadButton(
                        child: const Text('Save changes'),
                        onPressed: () {
                          if (!inventoryFormKey.currentState!.validate()) {
                            return;
                          } else {
                            if (item != null) {
                              final updateitem = ItemModel(
                                id: item.id,
                                nama: editingName.text.replaceAll(',', ' '),
                                code: editingCode.text,
                                quantity: 1,
                                hargaJual: 0,
                                ukuran: editingUkuran.text,
                                isHargaJualPersen: false,
                                hargaJualPersen: 0.0,
                                hargaDasar: int.tryParse(editingHargaDasar.text) ?? 0,
                                diskonPersen: 0.0,
                                jumlahBarang: stock.value,
                                createdAt: item.createdAt,
                                updatedAt: item.updatedAt,
                                isDeleted: item.isDeleted,
                                isSynced: item.isSynced,
                                category: 'Raw Material',
                              );

                              inventoryService
                                  .updateInventory(updateitem)
                                  .whenComplete(() {
                                Future.delayed(Durations.short1).then((_) {
                                  if (context.mounted) context.pop();
                                  inventoryController.inventorys.refresh();
                                  inventoryController.inventorySelected.value =
                                      null;
                                });
                              });
                            } else {
                              final newItem = ItemModel(
                                  id: DateTime.now().microsecondsSinceEpoch,
                                  nama: editingName.text.replaceAll(',', ' '),
                                  code: editingCode.text,
                                  quantity: 1,
                                  hargaJual: 0,
                                  ukuran: editingUkuran.text,
                                  isHargaJualPersen: false,
                                  hargaJualPersen: 0.0,
                                  hargaDasar: int.tryParse(editingHargaDasar.text) ?? 0,
                                  diskonPersen: 0.0,
                                   jumlahBarang: stock.value,
                                   createdAt: DateTime.now(),
                                   category: 'Raw Material',
                               );

                              inventoryService.addInventory(newItem).whenComplete(() {
                                inventoryController.inventorys.refresh();
                                if (context.mounted) context.pop();
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
