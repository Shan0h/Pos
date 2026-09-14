import 'dart:async';
import 'dart:io';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/model/store_model.dart';
import 'package:pos/controller/store_controller.dart';
import 'package:pos/enum/payment_enum.dart';
import 'package:pos/service/app_services.dart';
import 'package:pos/utils/constant.dart';
import 'package:pos/utils/extension.dart';
import 'package:pos/utils/order_ref.dart';
import 'package:usb_esc_printer_windows/usb_esc_printer_windows.dart' as usb_esc_printer_windows;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/controller/inventory_controller.dart';
import 'package:pos/controller/awaiting_orders_controller.dart';
import 'package:pos/controller/selling/events.dart';
import 'package:pos/controller/selling_controller.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/service/get_it.dart';
import 'package:signals/signals_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:pos/pages/home/users_sheet.dart';
import 'catalog_panel.dart';
import 'ticket_panel.dart';
import 'price_numpad_dialog.dart';
import 'awaiting_orders_page.dart';
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
  /// Hard cap on the receipt print. The Bluetooth plugin can hang
  /// indefinitely (printer off / out of range), so payment feedback must
  /// never wait on it — see _handlePay.
  static const Duration _printTimeout = Duration(seconds: 20);

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool isConnected = false;
  late Future<CapabilityProfile> _profile;

  /// Re-entrancy guard: a quick double-tap on PAY NOW must not create
  /// two orders / double-charge the customer.
  bool _isProcessingPayment = false;

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
    // Always (re)fetch menu items when the POS page is opened so the
    // catalog is populated even if the signal was idle/errored previously.
    inventoryController.menuItems.reload();
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
    final inventoryState = inventoryController.menuItems.watch(context);
    final allProducts = inventoryState.value ?? [];

    // Extract menu categories from the real menuCategory field.
    // Legacy rows without a category fall under "Others".
    const othersCategory = 'Others';
    final Set<String> uniqueCategories = {'All'};
    final hasUncategorized = allProducts.any((p) => p.menuCategory == null);
    if (hasUncategorized) uniqueCategories.add(othersCategory);
    for (var p in allProducts) {
      final cat = p.menuCategory;
      if (cat != null && cat.trim().isNotEmpty) {
        uniqueCategories.add(cat.trim());
      }
    }
    final categories = uniqueCategories.toList();

    // Watch cart
    final cartState = getIt.get<SellingController>().cart.watch(context);
    final cartItems = cartState.value?.items ?? [];

    List<ItemModel> filteredProducts = allProducts.where((product) {
      final matchesSearch = product.nama.toLowerCase().contains(_searchQuery.toLowerCase());
      final bool matchesCategory;
      if (_selectedCategory == 'All') {
        matchesCategory = true;
      } else if (_selectedCategory == othersCategory) {
        matchesCategory = product.menuCategory == null;
      } else {
        matchesCategory = product.menuCategory == _selectedCategory;
      }
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
      // Wide tablets/desktops get a vertical category rail on the left.
      showCategoryRail: MediaQuery.of(context).size.width >= 1000,
      onProductTap: _handleProductTap,
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
        backgroundColor: const Color(0xFF5D3A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Identity chip: shows who is operating the register. Tap to
          // switch staff (current order stays in the cart).
          _StaffIdentityChip(
            staffName:
                getIt.get<SellingController>().staffId.value?.nama ?? 'Staff',
            onTap: () {
              showShadSheet(
                side: isDesktop ? ShadSheetSide.right : ShadSheetSide.bottom,
                context: context,
                builder: (context) => const UsersSheet(),
              );
            },
          ),
          const SizedBox(width: 4),
          // Awaiting Orders shortcut with a live pending-count badge so the
          // worker can see unfinished orders at a glance.
          Watch((context) {
            final countState = awaitingOrdersController.pendingCount.watch(context);
            final pendingCount = countState.value ?? 0;
            return _PendingOrdersButton(
              pendingCount: pendingCount,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AwaitingOrdersPage()),
                );
              },
            );
          }),
          const SizedBox(width: 4),
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
      backgroundColor: context.pageBackground,
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
                color: context.panelBackground,
                boxShadow: [
                  BoxShadow(color: context.appShadowColor, blurRadius: 10, offset: const Offset(0, -5))
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
                        Text('${cartItems.length} items', style: TextStyle(color: context.secondaryTextColor)),
                        Text(
                          'Total RM ${(cartState.value?.totalPrice ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(color: context.appTextColor, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5E3C),
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
                                decoration: BoxDecoration(
                                  color: context.panelBackground,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Watch((context) {
                                  final currentCart = getIt.get<SellingController>().cart.value.value?.items ?? [];
                                  return TicketPanel(
                                    cartItems: currentCart,
                                    onClear: () {
                                      _handleClear();
                                      Navigator.pop(context); // Close bottom sheet when cleared
                                    },
                                    onIncrement: _handleIncrement,
                                    onDecrement: _handleDecrement,
                                    onPay: () {
                                      Navigator.pop(context); // Close bottom sheet
                                      _handlePay(currentCart); // Proceed to pay
                                    },
                                  );
                                }),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('View Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        // Quantity badge on the cart button.
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            child: Text(
                              '${cartState.value?.totalItem ?? 0}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _handleProductTap(ItemModel product) async {
    double itemPrice = product.price;
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
      final customResult = await CoffeeCustomDialog.show(context, item: product);
      if (customResult == null) {
        // User cancelled the customize dialog (X, Cancel, or tapped outside)
        // — do NOT add the plain item to the cart.
        return;
      }
      itemPrice += customResult.extraPrice;
      newName = '${product.nama} ${customResult.appendedName}';
      newDesc = customResult.description;
    }

    final newItem = ItemModel(
      id: product.id,
      nama: newName,
      code: product.code,
      jumlahBarang: product.jumlahBarang,
      quantity: 1, // Start with 1 qty when adding
      ukuran: product.ukuran,
      hargaDasar: product.hargaDasar,
      hargaJual: product.hargaJual,
      hargaJualExact: itemPrice, // sen-precise (base + surcharges/open price)
      isHargaJualPersen: product.isHargaJualPersen,
      hargaJualPersen: product.hargaJualPersen,
      diskonPersen: product.diskonPersen,
      deskripsi: newDesc,
      category: product.category,
      customizationsJson: product.customizationsJson,
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

  Future<void> _handlePay(List<ItemModel> cartItems) async {
    if (cartItems.isEmpty) return;
    if (_isProcessingPayment) return;
    _isProcessingPayment = true;
    try {
      await _processPayment(cartItems);
    } finally {
      _isProcessingPayment = false;
    }
  }

  Future<void> _processPayment(List<ItemModel> cartItems) async {
    final store =
        storeController.store.value.value ?? await storeService.getStore();
    if (store == null) {
      if (!mounted) return;
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
    if (paymentResult == null) {
      // User closed/cancelled the payment dialog — tell them the order
      // is still in the cart instead of failing silently.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled — order kept in cart.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final staffId = sellingController.staffId.value;
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
          ..hargaJualExact = p.hargaJualExact
          ..ukuran = p.ukuran
          ..isHargaJualPersen = p.isHargaJualPersen
          ..hargaJualPersen = p.hargaJualPersen
          ..hargaDasar = p.hargaDasar
          ..diskonPersen = p.diskonPersen
          ..deskripsi = p.deskripsi
          ..jumlahBarang = p.jumlahBarang
          ..isSynced = p.isSynced
          ..category = p.category,
      );
    }
    
    final newItem = PenjualanModel(
      id: DateTime.now().microsecondsSinceEpoch,
      items: products,
      staffId: staffId?.id ?? 1,
      keterangan: 'Modern POS Checkout',
      diskon: 0,
      totalHarga: totalPrice,
      totalItem: cartStateValue?.totalItem ?? 0,
      pembeli: pelanggan?.id,
      createdAt: DateTime.now(),
      tenderedAmount: tipeBayar == TypePayment.cash ? paymentResult.cashAmount : totalPrice,
      changeAmount: tipeBayar == TypePayment.cash ? (paymentResult.cashAmount - totalPrice) : 0.0,
      paymentMethod: tipeBayar.name,
      // New orders start as "awaiting preparation" — the worker marks them
      // done from the Awaiting Orders screen.
      orderStatus: PenjualanModel.statusPending,
    );

    if (products.isEmpty) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    // 1) Save the order. A failed save must NOT clear the cart — the old
    //    .whenComplete() chain cleared it even on save errors.
    try {
      await reportService.addPenjualan(newItem);
    } catch (e) {
      debugPrint('Failed to save order: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Payment could not be saved — order kept in cart. ($e)'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // 2) Instant success feedback + instant cart clear. Payment confirmation
    //    must never wait on the printer: the Bluetooth plugin can hang
    //    indefinitely when the printer is off/out of range, which used to
    //    swallow the notification and leave the cart stuck.
    //    Revenue note: this order is NOT counted in revenue reports yet —
    //    it only counts once the worker taps "Mark as Done" on the Awaiting
    //    Orders screen (or if it is a legacy order with no status).
    awaitingOrdersController.refreshAll();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
            'Payment successful! Order #${orderRef(newItem.id)} saved — awaiting preparation.'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
    sellingController.updateBatch(cartItems); // stock decrement in background
    sellingController.dispatch(CartPaid()); // cart clears immediately

    // 3) Receipt printing runs in the background with a hard timeout and
    //    reports its own failure — it can no longer block checkout.
    unawaited(
      letsPrint(
        store: store,
        model: newItem,
        staffId: staffId?.nama ?? 'Umum',
        tipe: tipeBayar,
        total: paymentResult.cashAmount.toStringAsFixed(2),
        kembalian: (paymentResult.cashAmount - totalPrice).toStringAsFixed(2),
        printName: printName,
      ).timeout(_printTimeout).then((_) {
        debugPrint('Receipt printed for order ${orderRef(newItem.id)}');
      }).catchError((Object e) {
        debugPrint('Print failed: $e');
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
                'Receipt was not printed (printer not connected or timed out).'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }),
    );
  }

  Future<void> letsPrint({
    required StoreModel store,
    required PenjualanModel model,
    required String staffId,
    required TypePayment tipe,
    String? total,
    String? kembalian,
    String? printName,
  }) async {
    // Bluetooth printers must be connected before printing; without this
    // check a disconnected printer fails silently.
    if (!Platform.isWindows && !Platform.isMacOS) {
      isConnected = await PrintBluetoothThermal.connectionStatus;
      if (!isConnected) {
        throw Exception('Printer not connected');
      }
    }
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
    bytes += generator.text('Date/Time : ${DateFormat('EEEE, dd MMM yyyy HH:mm').format(DateTime.now())}');
    bytes += generator.text('Staff   : $staffId');
    bytes += generator.feed(1);

    bytes += [27, 97, 0];
    bytes += generator.row([
      PosColumn(text: 'QTY', width: 1, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: 'S/T/DESCRIPTION', width: 9, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: 'TOTAL', width: 2, styles: const PosStyles(align: PosAlign.left, bold: true)),
    ]);
    bytes += generator.hr();
    
    for (ProductItemModel i in model.items) {
      final categoryStr = i.category != null ? ' [${i.category}]' : '';
      bytes += generator.text('${i.nama ?? '-'}$categoryStr');
      bytes += generator.row([
        PosColumn(
          text: i.diskonPersen == null || i.diskonPersen == 0.0
              ? '${i.quantity ?? 0} x ${currency.format(i.price)}'
              : '${i.quantity ?? 0} x ${currency.format(i.price)} >> ${currency.format(i.price - i.price * (i.diskonPersen! / 100))} (Disc ${i.diskonPersen!.toStringAsFixed(0)}%)',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: i.diskonPersen == null || i.diskonPersen == 0.0
              ? currency.format((i.quantity ?? 0) * i.price)
              : currency.format((i.quantity ?? 0) * (i.price - i.price * (i.diskonPersen! / 100))),
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

/// App-bar chip showing the staff operating the register. Tapping opens
/// the switch-staff sheet.
class _StaffIdentityChip extends StatelessWidget {
  final String staffName;
  final VoidCallback onTap;

  const _StaffIdentityChip({
    required this.staffName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        staffName.isNotEmpty ? staffName[0].toUpperCase() : '?';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                staffName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down,
                size: 18, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

/// App-bar icon button opening the Awaiting Orders page. Shows a red badge
/// with the number of pending orders when there is at least one.
class _PendingOrdersButton extends StatelessWidget {
  final int pendingCount;
  final VoidCallback onPressed;

  const _PendingOrdersButton({
    required this.pendingCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Awaiting Orders',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.receipt_long),
          if (pendingCount > 0)
            Positioned(
              top: -6,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  pendingCount > 9 ? '9+' : '$pendingCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: onPressed,
    );
  }
}
