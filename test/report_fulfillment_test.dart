import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:pos/model/item_model.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/service/database.dart';
import 'package:pos/service/inventory_service.dart';
import 'package:pos/service/report_service.dart';

import 'test_isar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late ReportService reportService;
  late InventoryService inventoryService;
  late Directory tempDir;

  setUpAll(() async {
    await TestIsar.initializeCore();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pos_fulfill_test');
    isar = await Isar.open(
      Database.schemas,
      directory: tempDir.path,
      inspector: false,
    );
    // Construct the services directly (no get_it/Supabase needed — these
    // code paths are Isar-only; _canSync is false in tests).
    final db = _StubDatabase(isar);
    reportService = ReportService(db);
    inventoryService = InventoryService(db);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    await tempDir.delete(recursive: true);
  });

  PenjualanModel order({
    int? id,
    String? orderStatus,
    bool isDeleted = false,
    DateTime? createdAt,
    double totalHarga = 10,
    List<ProductItemModel> items = const [],
  }) {
    final now = DateTime.now();
    return PenjualanModel(
      id: id,
      items: items,
      totalItem: items.fold(0, (s, i) => s + (i.quantity ?? 0)),
      totalHarga: totalHarga,
      diskon: 0,
      staffId: 1,
      createdAt: createdAt ?? now,
      isDeleted: isDeleted,
      orderStatus: orderStatus,
    );
  }

  ProductItemModel lineItem({required int id, int qty = 1}) =>
      ProductItemModel()
        ..id = id
        ..nama = 'Latte'
        ..code = 'SKU-$id'
        ..quantity = qty
        ..hargaJual = 1200
        ..isHargaJualPersen = false
        ..isSynced = true;

  group('Revenue counts only fulfilled orders', () {
    test('getReportToday excludes pending, includes done and legacy',
        () async {
      await isar.writeTxn(() async {
        await isar.penjualanModels.put(
            order(orderStatus: PenjualanModel.statusPending, totalHarga: 10));
        await isar.penjualanModels.put(
            order(orderStatus: PenjualanModel.statusDone, totalHarga: 20));
        await isar.penjualanModels
            .put(order(orderStatus: null, totalHarga: 30));
      });

      final revenue = await reportService.getReportToday();
      expect(revenue, hasLength(2));
      expect(revenue.fold<double>(0, (s, r) => s + r.totalHarga), 50.0);
      expect(
        revenue.every((r) => r.orderStatus != PenjualanModel.statusPending),
        isTrue,
      );
    });

    test('getReport excludes pending across a date range', () async {
      final now = DateTime.now();
      await isar.writeTxn(() async {
        await isar.penjualanModels.put(order(
            orderStatus: PenjualanModel.statusPending,
            createdAt: now,
            totalHarga: 10));
        await isar.penjualanModels.put(order(
            orderStatus: PenjualanModel.statusDone,
            createdAt: now,
            totalHarga: 20));
      });

      final revenue = await reportService.getReport(start: now, end: now);
      expect(revenue, hasLength(1));
      expect(revenue.single.orderStatus, PenjualanModel.statusDone);
    });

    test('getSalesByUser excludes pending orders per staff', () async {
      await isar.writeTxn(() async {
        await isar.penjualanModels.put(order(
            orderStatus: PenjualanModel.statusPending, totalHarga: 10));
        await isar.penjualanModels.put(
            order(orderStatus: PenjualanModel.statusDone, totalHarga: 40));
      });

      final byUser = await reportService.getSalesByUser();
      expect(byUser[1], hasLength(1));
      expect(byUser[1]!.single.orderStatus, PenjualanModel.statusDone);
    });

    test('getSalesByDate excludes pending orders', () async {
      final now = DateTime.now();
      await isar.writeTxn(() async {
        await isar.penjualanModels.put(order(
            orderStatus: PenjualanModel.statusPending,
            createdAt: now,
            totalHarga: 10));
        await isar.penjualanModels.put(order(
            orderStatus: PenjualanModel.statusDone,
            createdAt: now,
            totalHarga: 40));
      });

      final byDate =
          await reportService.getSalesByDate(start: now, end: now);
      final dayKey = DateTime(now.year, now.month, now.day);
      expect(byDate[dayKey], hasLength(1));
      expect(byDate[dayKey]!.single.orderStatus, PenjualanModel.statusDone);
    });

    test('markOrderDone moves a pending order into revenue', () async {
      int pendingId = 0;
      await isar.writeTxn(() async {
        pendingId = await isar.penjualanModels
            .put(order(orderStatus: PenjualanModel.statusPending));
      });
      expect(await reportService.getReportToday(), isEmpty);

      await reportService.markOrderDone(pendingId);

      final revenue = await reportService.getReportToday();
      expect(revenue, hasLength(1));
      expect(revenue.single.orderStatus, PenjualanModel.statusDone);
    });

    test('soft-deleted orders never count, regardless of status', () async {
      await isar.writeTxn(() async {
        await isar.penjualanModels.put(order(
            orderStatus: PenjualanModel.statusDone, isDeleted: true));
        await isar.penjualanModels
            .put(order(orderStatus: null, isDeleted: true));
      });
      expect(await reportService.getReportToday(), isEmpty);
    });
  });

  group('Awaiting order cancellation', () {
    test('cancelOrder removes the order from awaiting list and revenue',
        () async {
      int orderId = 0;
      await isar.writeTxn(() async {
        orderId = await isar.penjualanModels.put(order(
            orderStatus: PenjualanModel.statusPending,
            items: [lineItem(id: 42, qty: 2)]));
      });
      await isar.writeTxn(() async {
        await isar.itemModels.put(ItemModel(
          id: 42,
          nama: 'Latte',
          code: 'SKU-42',
          jumlahBarang: 8,
          quantity: 8,
          ukuran: 'M',
          hargaDasar: 800,
          hargaJual: 1200,
          isHargaJualPersen: false,
        ));
      });

      // Sanity: pending order is awaiting but not revenue.
      expect(await reportService.getAwaitingOrders(), hasLength(1));
      expect(await reportService.getReportToday(), isEmpty);

      await reportService.removePenjualan(orderId);

      expect(await reportService.getAwaitingOrders(), isEmpty);
      expect(await reportService.getReportToday(), isEmpty);
      // Offline (no Supabase in tests): soft-deleted, record still exists.
      final removed = await isar.penjualanModels.get(orderId);
      expect(removed!.isDeleted, isTrue);
    });

    test('incrementStock restores deducted quantity', () async {
      await isar.writeTxn(() async {
        await isar.itemModels.put(ItemModel(
          id: 7,
          nama: 'Beans',
          code: 'SKU-7',
          jumlahBarang: 5,
          quantity: 5,
          ukuran: 'M',
          hargaDasar: 800,
          hargaJual: 1200,
          isHargaJualPersen: false,
        ));
      });

      await inventoryService.decrementStock(7, 2);
      expect((await isar.itemModels.get(7))!.jumlahBarang, 3);

      await inventoryService.incrementStock(7, 2);
      expect((await isar.itemModels.get(7))!.jumlahBarang, 5);
    });

    test('cancelOrder restores stock for every line item', () async {
      // Seed two products.
      await isar.writeTxn(() async {
        await isar.itemModels.put(ItemModel(
          id: 42,
          nama: 'Latte',
          code: 'SKU-42',
          jumlahBarang: 10,
          quantity: 10,
          ukuran: 'M',
          hargaDasar: 800,
          hargaJual: 1200,
          isHargaJualPersen: false,
        ));
        await isar.itemModels.put(ItemModel(
          id: 43,
          nama: 'Croissant',
          code: 'SKU-43',
          jumlahBarang: 6,
          quantity: 6,
          ukuran: '-',
          hargaDasar: 300,
          hargaJual: 500,
          isHargaJualPersen: false,
        ));
      });

      // Paid order still awaiting preparation.
      await isar.writeTxn(() async {
        await isar.penjualanModels.put(order(
            orderStatus: PenjualanModel.statusPending,
            items: [
              lineItem(id: 42, qty: 3),
              lineItem(id: 43, qty: 1),
            ]));
      });

      final awaitingBefore = await reportService.getAwaitingOrders();
      expect(awaitingBefore, hasLength(1));

      // Same steps the controller's cancelOrder performs (stock first, then
      // remove) — the controller itself needs get_it/Supabase wiring that
      // is unavailable in unit tests.
      for (final item in awaitingBefore.single.items) {
        await inventoryService.incrementStock(item.id!, item.quantity!);
      }
      await reportService.removePenjualan(awaitingBefore.single.id!);

      expect((await isar.itemModels.get(42))!.jumlahBarang, 13);
      expect((await isar.itemModels.get(43))!.jumlahBarang, 7);
      expect(await reportService.getAwaitingOrders(), isEmpty);
    });
  });
}

/// Minimal Database stand-in: ReportService/InventoryService only use
/// [isar], [supabaseHelper], [canSync] and [now]. canSync=false keeps every
/// code path offline so no Supabase client is constructed.
class _StubDatabase implements Database {
  _StubDatabase(this.isar);

  @override
  final Isar isar;

  @override
  bool get canSync => false;

  @override
  DateTime get now => DateTime.now();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
