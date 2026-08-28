import 'package:pos/controller/selling/events.dart';
import 'package:pos/controller/selling_controller.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/service/database.dart';
import 'package:pos/service/get_it.dart';
import 'package:pos/utils/constant.dart';
import 'package:pos/utils/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

class SellingLeft extends HookWidget {
  const SellingLeft({super.key});
  @override
  Widget build(context) {
    final editingBarcode = useTextEditingController(text: 'Scan Barcode...');
    final list = getIt.get<SellingController>().cart.watch(context);
    final isSearch = getIt.get<SellingController>().isSearch.watch(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (PlatformExtension.isMobile)
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
                        final data = await Database().searchByBarcode(res);
                        if (data != null) {
                          editingBarcode.text = res;
                          getIt
                              .get<SellingController>()
                              .dispatch(CartItemAdded(data));
                        } else {
                          if (context.mounted) {
                            ShadToaster.of(context).show(
                              ShadToast(
                                backgroundColor: Colors.red,
                                title: const Text('Item Not Found'),
                                description:
                                    const Text('You can add it on inventory'),
                                action: ShadButton.outline(
                                  child: const Text('Ok'),
                                  onPressed: () =>
                                      ShadToaster.of(context).hide(),
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                IconButton(
                  color: !isSearch ? Colors.blue : null,
                  onPressed: () =>
                      getIt.get<SellingController>().isSearch.value = !isSearch,
                  icon: const Icon(Icons.qr_code_scanner),
                ),
                if (isSearch)
                  Expanded(
                    child: Autocomplete<ItemModel>(
                      optionsBuilder:
                          (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text == '') {
                          return const Iterable<ItemModel>.empty();
                        }
                        final data = await Database()
                            .searchInventorys(value: textEditingValue.text);
                        return data;
                      },
                      onSelected: (ItemModel value) {
                        getIt
                            .get<SellingController>()
                            .dispatch(CartItemAdded(value));
                      },
                      displayStringForOption: (option) => '',
                      optionsViewBuilder: (context, onSelected, options) {
                        return Material(
                          child: ListView(
                            children: options
                                .map(
                                  (option) => GestureDetector(
                                    onTap: () {
                                      if (option.jumlahBarang == 0) return;
                                      onSelected(option);
                                    },
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            option.jumlahBarang == 0
                                                ? Colors.red
                                                : null,
                                        child: Text(
                                          option.jumlahBarang.toString(),
                                        ),
                                      ),
                                      title: Text(option.nama),
                                      subtitle: Row(
                                        children: [
                                          Text(
                                            currency.format(option.hargaJual),
                                            style: TextStyle(
                                                color: option.diskonPersen ==
                                                            null ||
                                                        option.diskonPersen == 0
                                                    ? Colors.green
                                                    : Colors.red,
                                                decoration: option
                                                                .diskonPersen ==
                                                            null ||
                                                        option.diskonPersen == 0
                                                    ? null
                                                    : TextDecoration
                                                        .lineThrough),
                                          ),
                                          if (option.diskonPersen != null &&
                                              option.diskonPersen != 0)
                                            Text(
                                              ' >> ${currency.format(option.hargaJual - option.hargaJual * (option.diskonPersen! / 100))}',
                                              style: const TextStyle(
                                                  color: Colors.green),
                                            ),
                                          Text(' - ${option.code}')
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      },
                      fieldViewBuilder: (context, textEditingController,
                              focusNode, onFieldSubmitted) =>
                          TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        onEditingComplete: onFieldSubmitted,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(10),
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search',
                          suffixIcon: IconButton(
                            onPressed: () => textEditingController.clear(),
                            icon: const Icon(Icons.clear),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  BarcodeKeyboardListener(
                    bufferDuration: const Duration(milliseconds: 200),
                    onBarcodeScanned: (barcode) async {
                      final data = await Database()
                          .searchByBarcode(barcode.replaceAll('½', '-'));
                      if (data != null) {
                        editingBarcode.text = barcode.replaceAll('½', '-');
                        getIt
                            .get<SellingController>()
                            .dispatch(CartItemAdded(data));
                      } else {
                        if (context.mounted) {
                          ShadToaster.of(context).show(
                            ShadToast(
                              backgroundColor: Colors.red,
                              title: const Text('Item Not Found'),
                              description:
                                  const Text('You can add it on inventory'),
                              action: ShadButton.outline(
                                child: const Text('Ok'),
                                onPressed: () => ShadToaster.of(context).hide(),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Expanded(
                      child: TextField(
                        readOnly: true,
                        controller: editingBarcode,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(10),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            list.map(
              data: (item) => Column(
                children: item.items
                    .map(
                      (val) => Container(
                        decoration: val.quantity > val.jumlahBarang
                            ? BoxDecoration(
                                border: Border.all(
                                  color: Colors.red,
                                  style: BorderStyle.solid,
                                  width: 1.0,
                                ),
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(10.0),
                              )
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (val.quantity > val.jumlahBarang)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 8.0, top: 8.0),
                                child: Text(
                                  'Exceeds Stock! Available ${val.jumlahBarang}',
                                  style: ShadTheme.of(context)
                                      .textTheme
                                      .small
                                      .copyWith(color: Colors.red),
                                ),
                              ),
                            ListTile(
                              title: Text(val.nama),
                              subtitle: Row(
                                children: [
                                  Text(
                                    currency.format(val.hargaJual),
                                    style: TextStyle(
                                        color: val.diskonPersen == null ||
                                                val.diskonPersen == 0
                                            ? null
                                            : Colors.red,
                                        decoration: val.diskonPersen == null ||
                                                val.diskonPersen == 0
                                            ? null
                                            : TextDecoration.lineThrough),
                                  ),
                                  if (val.diskonPersen != null &&
                                      val.diskonPersen != 0)
                                    Text(
                                        ' >> ${currency.format(val.hargaJual - val.hargaJual * (val.diskonPersen! / 100))}'),
                                ],
                              ),
                              trailing: Text(val.quantity.toString()),
                              leading: IconButton(
                                  onPressed: () => showShadDialog(
                                        context: context,
                                        builder: (context) => ShadDialog.alert(
                                          title: const Text(
                                              'Are you sure you want to delete this?'),
                                          description: const Padding(
                                            padding: EdgeInsets.only(bottom: 8),
                                            child: Text(
                                              'This action cannot be undone, the data will be removed from the list.',
                                            ),
                                          ),
                                          actions: [
                                            ShadButton.outline(
                                              child: const Text('Cancel'),
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                            ),
                                            ShadButton(
                                                child: const Text('Continue'),
                                                onPressed: () {
                                                  getIt
                                                      .get<SellingController>()
                                                      .dispatch(
                                                          CartItemRemoved(val));
                                                  Navigator.of(context)
                                                      .pop(true);
                                                }),
                                          ],
                                        ),
                                      ),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  )),
                            )
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
              error: (e, st) => Text('$st'),
              loading: () => const Text('Loading'),
            ),
          ],
        ),
      ),
    );
  }
}
