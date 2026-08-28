import 'dart:io';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/model/store_model.dart';
import 'package:pos/controller/store_controller.dart';
import 'package:pos/enum/payment_enum.dart';
import 'package:pos/utils/constant.dart';
import 'package:usb_esc_printer_windows/usb_esc_printer_windows.dart' as usb_esc_printer_windows;
import 'package:pos/service/database.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/controller/inventory_controller.dart';
import 'package:pos/controller/selling/events.dart';
import 'package:pos/controller/selling_controller.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/service/get_it.dart';
import 'package:signals/signals_flutter.dart';
import 'catalog_panel.dart';
import 'ticket_panel.dart';
import 'price_numpad_dialog.dart';
import 'package:pos/pages/drawer.dart';
import 'coffee_custom_dialog.dart';
import 'quick_payment_modal.dart';
import 'owner_pin_dialog.dart';
import 'owner_dashboard_page.dart';

class PosModernPage extends StatefulWidget {
  const PosModernPage({super.key});

  @override
  State<PosModernPage> createState() => _PosModernPageState();
}

class _PosModernPageState extends State<PosModernPage> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool isConnected = false;
  late Future<CapabilityProfile> _profile;

  @override
  void initState() {
    super.initState();
    // Allow all orientations for responsiveness
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (Platform.isWindows) {
      _profile = CapabilityProfile.load();
    } else {
      if (!Platform.isMacOS) _checkConnection();
    }
  }

  void _checkConnection() async {
    isConnected = await PrintBluetoothThermal.connectionStatus;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // Reset to any orientation when leaving (if preferred)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch inventory
    // The inventoryController is a global variable from its file, not registered in getIt.
    final inventoryState = inventoryController.inventorys.watch(context);
    final allProducts = inventoryState.value ?? [];

    // Extract Pseudo-Categories
    final Set<String> uniqueCategories = {'All'};
    for (var p in allProducts) {
      if (p.nama.isNotEmpty) {
        uniqueCategories.add(p.nama.split(' ').first);
      }
    }
    final categories = uniqueCategories.toList();

    // Watch cart
    final cartState = getIt.get<SellingController>().cart.watch(context);
    final cartItems = cartState.value?.items ?? [];

    List<ItemModel> filteredProducts = allProducts.where((product) {
      final matchesSearch = product.nama.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || product.nama.startsWith(_selectedCategory);
      return matchesSearch && matchesCategory;
    }).toList();

    final isDesktop = MediaQuery.of(context).size.width >= 800;
    
    Widget catalogWidget = CatalogPanel(
      searchQuery: _searchQuery,
      onSearchChanged: (query) => setState(() => _searchQuery = query),
      selectedCategory: _selectedCategory,
      onCategorySelected: (category) => setState(() => _selectedCategory = category),
      products: filteredProducts,
      categories: categories,
      onProductTap: _handleProductTap,
      onBarcodeScanned: (code) {
        final matchedProduct = allProducts.where((p) => p.code == code).firstOrNull;
        if (matchedProduct != null) {
          _handleProductTap(matchedProduct);
          setState(() => _searchQuery = ''); // clear search
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product with barcode $code not found!')),
          );
        }
      },
    );

    Widget ticketWidget = TicketPanel(
      cartItems: cartItems,
      onClear: _handleClear,
      onIncrement: _handleIncrement,
      onDecrement: _handleDecrement,
      onPay: () => _handlePay(cartItems),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern POS'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Owner Access',
            onPressed: () async {
              final authSuccess = await OwnerPinDialog.show(context);
              if (authSuccess && context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerDashboardPage()));
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const NavDrawer(),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  Expanded(flex: 7, child: catalogWidget),
                  Expanded(flex: 5, child: ticketWidget),
                ],
              )
            : catalogWidget,
      ),
      bottomNavigationBar: isDesktop || cartItems.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${cartItems.length} items', style: const TextStyle(color: Colors.grey)),
                        Text(
                          'Total RM ${(cartState.value?.totalPrice ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
                            height: MediaQuery.of(context).size.height * 0.85,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: TicketPanel(
                              cartItems: cartItems,
                              onClear: _handleClear,
                              onIncrement: _handleIncrement,
                              onDecrement: _handleDecrement,
                              onPay: () {
                                Navigator.pop(context); // Close bottom sheet
                                _handlePay(cartItems); // Proceed to pay
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('View Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _handleProductTap(ItemModel product) async {
    double itemPrice = product.hargaJual.toDouble();
    String newName = product.nama;
    String newDesc = product.deskripsi ?? '';

    if (itemPrice == 0) {
      final enteredPrice = await PriceNumpadDialog.show(
        context,
        itemName: product.nama,
      );

      if (enteredPrice == null || enteredPrice <= 0) {
        return; // User canceled or entered invalid price
      }
      itemPrice = enteredPrice;
    } else {
      // It's a standard priced item (like a coffee), show customization dialog
      final customResult = await CoffeeCustomDialog.show(context, itemName: product.nama, basePrice: itemPrice);
      if (customResult != null) {
        itemPrice += customResult.extraPrice;
        newName = '${product.nama} ${customResult.appendedName}';
        newDesc = customResult.description;
      }
    }

    final newItem = ItemModel(
      id: product.id,
      nama: newName,
      code: product.code,
      jumlahBarang: product.jumlahBarang,
      quantity: 1, // Start with 1 qty when adding
      ukuran: product.ukuran,
      hargaDasar: product.hargaDasar,
      hargaJual: itemPrice.toInt(),
      isHargaJualPersen: product.isHargaJualPersen,
      deskripsi: newDesc,
    );
    
    getIt.get<SellingController>().dispatch(CartItemAdded(newItem));
  }

  void _handleIncrement(ItemModel item) {
    getIt.get<SellingController>().dispatch(CartItemAdded(item));
  }

  void _handleDecrement(ItemModel item) {
    getIt.get<SellingController>().dispatch(CartItemDecremented(item));
  }

  void _handleClear() {
    getIt.get<SellingController>().dispatch(CartPaid());
  }

  void _handlePay(List<ItemModel> cartItems) async {
    if (cartItems.isEmpty) return;

    final store = storeController.store.value.value;
    if (store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store information is missing!')),
      );
      return;
    }

    final sellingController = getIt.get<SellingController>();
    final cartStateValue = sellingController.cart.value.value;
    final totalPrice = cartStateValue?.totalPrice ?? 0.0;

    // Show Quick Payment Modal
    final paymentResult = await QuickPaymentModal.show(context, totalPrice);
    if (paymentResult == null) return; // User cancelled

    final kasir = sellingController.kasir.value;
    final pelanggan = sellingController.pelanggan.value;
    final tipeBayar = paymentResult.type;
    final printName = sellingController.selectedPrint.value;

    List<ProductItemModel> products = [];
    for (ItemModel p in cartItems) {
      products.add(
        ProductItemModel()
          ..id = p.id!
          ..nama = p.nama
          ..code = p.code
          ..quantity = p.quantity
          ..hargaJual = p.hargaJual
          ..ukuran = p.ukuran
          ..isHargaJualPersen = p.isHargaJualPersen
          ..hargaJualPersen = p.hargaJualPersen
          ..hargaDasar = p.hargaDasar
          ..diskonPersen = p.diskonPersen
          ..deskripsi = p.deskripsi
          ..jumlahBarang = p.jumlahBarang
          ..isSynced = p.isSynced,
      );
    }
    
    final newItem = PenjualanModel(
      id: DateTime.now().microsecondsSinceEpoch,
      items: products,
      kasir: kasir?.id ?? 1,
      keterangan: 'Modern POS Checkout',
      diskon: 0,
      totalHarga: totalPrice,
      totalItem: cartStateValue?.totalItem ?? 0,
      pembeli: pelanggan?.id,
      createdAt: DateTime.now(),
    );

    if (products.isEmpty) return;

    Database().addPenjualan(newItem).whenComplete(() {
      letsPrint(
        store: store,
        model: newItem,
        kasir: kasir?.nama ?? 'Umum',
        tipe: tipeBayar,
        total: paymentResult.cashAmount.toStringAsFixed(2),
        kembalian: (paymentResult.cashAmount - totalPrice).toStringAsFixed(2),
        printName: printName,
      ).whenComplete(() {
        sellingController.tipeBayar.value = TypePayment.qris;
        sellingController.updateBatch(cartItems).whenComplete(() {
          sellingController.dispatch(CartPaid());
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment processed and printed successfully!'),
                backgroundColor: Colors.teal,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      });
    });
  }

  Future<void> letsPrint({
    required StoreModel store,
    required PenjualanModel model,
    required String kasir,
    required TypePayment tipe,
    String? total,
    String? kembalian,
    String? printName,
  }) async {
    final profile = await CapabilityProfile.load();
    late CapabilityProfile winProfile;
    if (Platform.isWindows) {
      winProfile = await _profile;
    }
    final generator = Generator(PaperSize.mm80, Platform.isWindows ? winProfile : profile);
    List<int> bytes = [];

    bytes += generator.text(store.title,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));
    bytes += generator.feed(1);
    bytes += generator.text(store.description, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(store.phone, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);
    bytes += generator.hr();
    bytes += generator.text('Date/Time : ${DateFormat.yMd().add_jm().format(DateTime.now())}');
    bytes += generator.text('Cashier   : $kasir');
    bytes += generator.feed(1);

    bytes += [27, 97, 0];
    bytes += generator.row([
      PosColumn(text: 'QTY', width: 1, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: 'S/T/DESCRIPTION', width: 9, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: 'TOTAL', width: 2, styles: const PosStyles(align: PosAlign.left, bold: true)),
    ]);
    bytes += generator.hr();
    
    for (ProductItemModel i in model.items) {
      bytes += generator.text(i.nama!);
      bytes += generator.row([
        PosColumn(
          text: '${i.diskonPersen == null || i.diskonPersen == 0.0 ? '' : 'Disc'} ${i.quantity} x ${i.diskonPersen == null || i.diskonPersen == 0.0 ? i.hargaJual : '${i.hargaJual} >> ${i.hargaJual! - i.hargaJual! * (i.diskonPersen! / 100)}'}',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: i.diskonPersen == null || i.diskonPersen == 0.0
              ? '${i.quantity! * i.hargaJual!}'
              : '${i.quantity! * (i.hargaJual! - i.hargaJual! * (i.diskonPersen! / 100))}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();
    bytes += [27, 97, 2];
    bytes += generator.text('Total ${currency.format(model.totalHarga)}',
      styles: const PosStyles(height: PosTextSize.size2, bold: true));
    bytes += [27, 97, 1];
    bytes += generator.text('Transaction details');
    bytes += generator.text('*****************************************');
    bytes += generator.row([
      PosColumn(text: 'Pay', width: 6, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: tipe == TypePayment.cash ? total! : tipe.name, width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (tipe == TypePayment.cash) {
      bytes += generator.row([
        PosColumn(text: 'Change', width: 6, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: kembalian ?? '0', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.feed(2);
    if (store.footer != null) {
      bytes += generator.text(store.footer!, styles: const PosStyles(align: PosAlign.center));
    }
    if (store.subFooter != null) {
      bytes += generator.text(store.subFooter!, styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.feed(2);
    bytes += generator.cut();
    bytes += generator.drawer();
    
    if (Platform.isWindows) {
      await usb_esc_printer_windows.sendPrintRequest(bytes, printName ?? 'Xprinter XP-T371U');
    } else {
      await PrintBluetoothThermal.writeBytes(bytes);
    }
  }
}
