import 'package:collection/collection.dart';
import 'package:isar/isar.dart';
import 'package:pos/model/penjualan_model.dart';
import 'package:pos/service/database.dart';
import 'package:pos/service/supabase_service.dart';

class ReportService {
  final Database _database;
  ReportService(this._database);

  IsarCollection<PenjualanModel> get _collection => _database.isar.penjualanModels;
  SupabaseHelper get _supabase => _database.supabaseHelper;
  bool get _canSync => _database.canSync;
  DateTime get _now => _database.now;

  Future<void> _markSynced(int id) async {
    final item = await _collection.get(id);
    if (item == null) return;
    item.isSynced = true;
    await _database.isar.writeTxn(() async => await _collection.put(item));
  }

  Future<void> addPenjualan(PenjualanModel val) async {
    val.updatedAt = _now;
    val.isDeleted = false;
    val.isSynced = !_canSync;
    await _database.isar.writeTxn(() async => await _collection.put(val));
    if (_canSync) {
      await _supabase.addReport(val.toJson());
      await _markSynced(val.id!);
    }
  }

  Future<void> syncItemPenjualan(PenjualanModel val) async {
    if (_canSync) {
      final exists = await _supabase.getReportById(val.id!);
      if (exists) {
        await _supabase.updateReport(val);
      } else {
        await _supabase.addReport(val.toJson());
      }
      await _markSynced(val.id!);
    }
  }

  Future<void> removePenjualan(int val) async {
    final existing = await _collection.get(val);
    if (existing == null) return;
    if (_canSync) {
      await _supabase.removeReport(val);
      await _database.isar.writeTxn(() async => await _collection.delete(val));
      return;
    }
    existing
      ..updatedAt = _now
      ..isDeleted = true
      ..isSynced = false;
    await _database.isar.writeTxn(() async => await _collection.put(existing));
  }

  // ---------------------------------------------------------------------------
  // Revenue reporting
  //
  // Every revenue query below counts only FULFILLED orders: the worker has
  // tapped "Mark as Done" (orderStatus == 'done') or the order is a legacy
  // record from before fulfillment tracking existed (orderStatus == null).
  // Orders still awaiting preparation (orderStatus == 'pending') are paid but
  // not handed over yet, so they stay out of revenue until marked done.
  // getReportAll()/checkIsReportSynced() intentionally have no such filter —
  // sync must always see every record.
  // The fulfillment condition (orderStatus is null OR == 'done') is inlined
  // in each query — Isar's QueryBuilder is instance-scoped so it cannot be
  // hoisted into a shared helper.
  // ---------------------------------------------------------------------------

  Future<List<PenjualanModel>> getReport({required DateTime start, required DateTime end}) async {
    return _collection
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(start.copyWith(hour: 0, minute: 0, second: 0),
            end.copyWith(hour: 23, minute: 59, second: 59))
        .group((q) => q
            .orderStatusIsNull()
            .or()
            .orderStatusEqualTo(PenjualanModel.statusDone))
        .findAll();
  }

  Future<List<PenjualanModel>> getReportById({required DateTime start, required DateTime end, int? userId}) async {
    return _collection
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(
          start.copyWith(hour: 0, minute: 0, second: 0),
          end.copyWith(hour: 23, minute: 59, second: 59),
        )
        .staffIdEqualTo(userId ?? 0)
        .group((q) => q
            .orderStatusIsNull()
            .or()
            .orderStatusEqualTo(PenjualanModel.statusDone))
        .findAll();
  }

  Future<List<PenjualanModel>> getReportToday() async {
    return _collection
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(
            DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
            DateTime.now().copyWith(hour: 23, minute: 59, second: 59))
        .group((q) => q
            .orderStatusIsNull()
            .or()
            .orderStatusEqualTo(PenjualanModel.statusDone))
        .findAll();
  }

  Future<List<PenjualanModel>> getReportYesterday() async {
    return _collection
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(
            DateTime.now().subtract(const Duration(days: 1)).copyWith(hour: 0, minute: 0, second: 0),
            DateTime.now().subtract(const Duration(days: 1)).copyWith(hour: 23, minute: 59, second: 59))
        .group((q) => q
            .orderStatusIsNull()
            .or()
            .orderStatusEqualTo(PenjualanModel.statusDone))
        .findAll();
  }

  Future<Map<int, List<PenjualanModel>>> getSalesByUser() async {
    final items = await _collection
        .filter()
        .isDeletedEqualTo(false)
        .group((q) => q
            .orderStatusIsNull()
            .or()
            .orderStatusEqualTo(PenjualanModel.statusDone))
        .findAll();
    return items.groupListsBy((i) => i.staffId);
  }

  Future<Map<DateTime, List<PenjualanModel>>> getSalesByDate({required DateTime start, required DateTime end}) async {
    final items = _collection
        .where()
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(start.copyWith(hour: 0, minute: 0, second: 0),
            end.copyWith(hour: 23, minute: 59, second: 59))
        .group((q) => q
            .orderStatusIsNull()
            .or()
            .orderStatusEqualTo(PenjualanModel.statusDone))
        .findAllSync();
    return items.groupListsBy((order) => DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day));
  }

  Future<List<PenjualanModel>> getReportAll() async {
    return _collection.where().findAll();
  }

  // ---------------------------------------------------------------------------
  // Awaiting Orders (local fulfillment tracking)
  // Status lives only in Isar (PenjualanModel.orderStatus) and is intentionally
  // excluded from the Supabase payload — see penjualan_model.dart.
  // ---------------------------------------------------------------------------

  /// Today's orders still awaiting preparation, newest first.
  /// Legacy orders (orderStatus == null) are never listed.
  Future<List<PenjualanModel>> getAwaitingOrders() async {
    final now = DateTime.now();
    return _collection
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(
          now.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0),
          now.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 999),
        )
        .orderStatusEqualTo(PenjualanModel.statusPending)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Today's completed orders (orderStatus == 'done'), newest first.
  /// Legacy orders (orderStatus == null) are never listed.
  Future<List<PenjualanModel>> getCompletedOrdersToday() async {
    final now = DateTime.now();
    return _collection
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(
          now.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0),
          now.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 999),
        )
        .orderStatusEqualTo(PenjualanModel.statusDone)
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// Number of today's orders awaiting preparation (for live badges).
  Future<int> countAwaitingOrders() async {
    final now = DateTime.now();
    return _collection
        .filter()
        .isDeletedEqualTo(false)
        .createdAtBetween(
          now.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0),
          now.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 999),
        )
        .orderStatusEqualTo(PenjualanModel.statusPending)
        .count();
  }

  /// Marks a local order as done. Isar-only by design: no Supabase write,
  /// so no cloud schema change is required.
  Future<void> markOrderDone(int id) async {
    final order = await _collection.get(id);
    if (order == null) return;
    order
      ..orderStatus = PenjualanModel.statusDone
      ..updatedAt = _now;
    await _database.isar.writeTxn(() async => await _collection.put(order));
  }

  Future<void> checkIsReportSynced() async {
    if (!_canSync) return;
    final localReports = await getReportAll();
    for (final report in localReports.where((r) => !r.isSynced)) {
      if (report.isDeleted) {
        await _supabase.removeReport(report.id!);
        await _database.isar.writeTxn(() async => await _collection.delete(report.id!));
        continue;
      }
      final exists = await _supabase.getReportById(report.id!);
      if (exists) {
        await _supabase.updateReport(report);
      } else {
        await _supabase.addReport(report.toJson());
      }
      await _markSynced(report.id!);
    }
    final remoteReports = await _supabase.getRepots();
    await _database.isar.writeTxn(() async {
      for (final remote in remoteReports) {
        final local = await _collection.get(remote.id!);
        if (local != null && !local.isSynced) continue;
        remote
          ..isDeleted = false
          ..isSynced = true;
        await _collection.put(remote);
      }
    });
  }
}
